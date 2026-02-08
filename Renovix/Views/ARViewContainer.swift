import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    var modelName: String
    @Binding var isPlacingObject: Bool
    @Binding var pendingPlacementTransform: simd_float4x4?
    @Binding var currentGhostPosition: SIMD3<Float>
    @Binding var currentGhostScale: Float
    @Binding var currentGhostRotation: Float
    var placedItems: [PlacedItem]
    var onSessionStateChange: ((ARSessionState) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            modelName: modelName,
            isPlacingObject: $isPlacingObject,
            pendingPlacementTransform: $pendingPlacementTransform,
            currentGhostPosition: $currentGhostPosition,
            currentGhostScale: $currentGhostScale,
            currentGhostRotation: $currentGhostRotation,
            onSessionStateChange: onSessionStateChange
        )
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.debugOptions = [.showFeaturePoints]
        
        // Store reference to sceneView in coordinator for gesture handlers
        context.coordinator.sceneView = sceneView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.isLightEstimationEnabled = true
        sceneView.session.run(config)
        
        // Create focus square for real-time placement feedback
        let focusNode = context.coordinator.createFocusSquare()
        sceneView.scene.rootNode.addChildNode(focusNode)
        context.coordinator.focusSquareNode = focusNode
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = sceneView.session
        coachingOverlay.goal = .horizontalPlane
        sceneView.addSubview(coachingOverlay)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)
        
        // Two-finger gesture to adjust object height independently of plane alignment
        let verticalPanGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleVerticalPan(_:)))
        verticalPanGesture.minimumNumberOfTouches = 2
        verticalPanGesture.maximumNumberOfTouches = 2
        sceneView.addGestureRecognizer(verticalPanGesture)

        NotificationCenter.default.addObserver(forName: .addNewObject, object: nil, queue: .main) { notification in
            context.coordinator.removeGhostNode()
        }

        context.coordinator.onSessionStateChange?(.planeSearching)
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Cache screen center for use in per-frame renderer callbacks
        context.coordinator.cachedScreenCenter = CGPoint(x: uiView.bounds.midX, y: uiView.bounds.midY)
        
        if context.coordinator.modelName != modelName {
            print("🔄 ARViewContainer: Model changed from '\(context.coordinator.modelName)' to '\(modelName)'")
            context.coordinator.modelName = modelName
        }
        
        if !isPlacingObject && context.coordinator.ghostNode != nil {
            print("🔄 ARViewContainer: Placement cancelled, removing ghost")
            context.coordinator.removeGhostNode()
        }
        
        context.coordinator.updatePlacedItems(placedItems, in: uiView)
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        // Properly pause the AR session to avoid "deallocated without being paused" warning
        uiView.session.pause()
    }

    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var modelName: String
        @Binding var isPlacingObject: Bool
        @Binding var pendingPlacementTransform: simd_float4x4?
        @Binding var currentGhostPosition: SIMD3<Float>
        @Binding var currentGhostScale: Float
        @Binding var currentGhostRotation: Float
        var ghostNode: SCNNode?
        var placedNodes: [UUID: SCNNode] = [:]
        var onSessionStateChange: ((ARSessionState) -> Void)?
        
        // Reference to sceneView for gesture handlers
        weak var sceneView: ARSCNView?
        
        // Plane visualization
        var planeNodes: [UUID: SCNNode] = [:]
        var lowestPlaneY: Float = Float.greatestFiniteMagnitude  // Track the floor level
        var detectedPlaneArea: Float = 0  // Total scanned area in m²
        
        // Focus square (real-time placement feedback)
        var focusSquareNode: SCNNode?
        var canPlaceObject: Bool = false
        var cachedScreenCenter: CGPoint = .zero
        
        private let modelLoader: ModelLoader
        private var hasDetectedPlane = false

        init(modelName: String,
             isPlacingObject: Binding<Bool>,
             pendingPlacementTransform: Binding<simd_float4x4?>,
             currentGhostPosition: Binding<SIMD3<Float>>,
             currentGhostScale: Binding<Float>,
             currentGhostRotation: Binding<Float>,
             onSessionStateChange: ((ARSessionState) -> Void)?,
             modelLoader: ModelLoader = AppContainer.shared.modelLoader) {
            self.modelName = modelName
            self._isPlacingObject = isPlacingObject
            self._pendingPlacementTransform = pendingPlacementTransform
            self._currentGhostPosition = currentGhostPosition
            self._currentGhostScale = currentGhostScale
            self._currentGhostRotation = currentGhostRotation
            self.onSessionStateChange = onSessionStateChange
            self.modelLoader = modelLoader
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            if anchors.contains(where: { $0 is ARPlaneAnchor }) && !hasDetectedPlane {
                hasDetectedPlane = true
                onSessionStateChange?(.planeDetected)
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            onSessionStateChange?(.failed(error.localizedDescription))
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            onSessionStateChange?(.failed("Session interrupted"))
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            onSessionStateChange?(.planeSearching)
            hasDetectedPlane = false
        }
        
        // MARK: - ARSCNViewDelegate (Plane Visualization)
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            guard planeAnchor.alignment == .horizontal else { return }
            
            let planeNode = createPlaneNode(for: planeAnchor)
            node.addChildNode(planeNode)
            planeNodes[planeAnchor.identifier] = planeNode
            
            let planeY = planeAnchor.transform.columns.3.y
            if planeY < lowestPlaneY {
                lowestPlaneY = planeY
                print("🔵 Floor plane detected at Y = \(planeY)")
            }
            
            updateScannedArea()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            guard let planeNode = planeNodes[planeAnchor.identifier] else { return }
            
            // Update plane geometry
            if let planeGeometry = planeNode.geometry as? SCNPlane {
                planeGeometry.width = CGFloat(planeAnchor.planeExtent.width)
                planeGeometry.height = CGFloat(planeAnchor.planeExtent.height)
            }
            
            planeNode.simdPosition = planeAnchor.center
            
            // Update floor tracking
            let planeY = planeAnchor.transform.columns.3.y
            if planeY < lowestPlaneY {
                lowestPlaneY = planeY
            }
            
            updateScannedArea()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            planeNodes.removeValue(forKey: planeAnchor.identifier)
            updateScannedArea()
        }
        
        private func createPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
            let plane = SCNPlane(width: CGFloat(anchor.planeExtent.width),
                                  height: CGFloat(anchor.planeExtent.height))
            
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 0.3)
            material.isDoubleSided = true
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.simdPosition = anchor.center
            planeNode.eulerAngles.x = -.pi / 2
            
            return planeNode
        }
        
        private func updateScannedArea() {
            guard let sceneView = sceneView else { return }
            
            var totalArea: Float = 0
            if let anchors = sceneView.session.currentFrame?.anchors {
                for anchor in anchors {
                    if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
                        totalArea += planeAnchor.planeExtent.width * planeAnchor.planeExtent.height
                    }
                }
            }
            detectedPlaneArea = totalArea
        }
        
        // MARK: - Focus Square (Real-time placement feedback)
        
        func createFocusSquare() -> SCNNode {
            // Create a grid/square that shows where you can place objects
            let size: CGFloat = 0.15  // 15cm square
            let segments = 4
            
            let gridNode = SCNNode()
            
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.9)
            lineMaterial.isDoubleSided = true
            
            let cornerSize = size * 0.3
            let thickness: CGFloat = 0.003
            
            for corner in 0..<4 {
                let xSign: CGFloat = corner < 2 ? -1 : 1
                let zSign: CGFloat = corner % 2 == 0 ? -1 : 1
                
                // Horizontal line
                let hLine = SCNBox(width: cornerSize, height: thickness, length: thickness, chamferRadius: 0)
                hLine.materials = [lineMaterial]
                let hNode = SCNNode(geometry: hLine)
                hNode.position = SCNVector3(
                    Float(xSign * (size/2 - cornerSize/2)),
                    0,
                    Float(zSign * size/2)
                )
                gridNode.addChildNode(hNode)
                
                // Vertical line
                let vLine = SCNBox(width: thickness, height: thickness, length: cornerSize, chamferRadius: 0)
                vLine.materials = [lineMaterial]
                let vNode = SCNNode(geometry: vLine)
                vNode.position = SCNVector3(
                    Float(xSign * size/2),
                    0,
                    Float(zSign * (size/2 - cornerSize/2))
                )
                gridNode.addChildNode(vNode)
            }
            
            let crossSize: CGFloat = 0.02
            let crossH = SCNBox(width: crossSize, height: thickness, length: thickness, chamferRadius: 0)
            crossH.materials = [lineMaterial]
            let crossHNode = SCNNode(geometry: crossH)
            gridNode.addChildNode(crossHNode)
            
            let crossV = SCNBox(width: thickness, height: thickness, length: crossSize, chamferRadius: 0)
            crossV.materials = [lineMaterial]
            let crossVNode = SCNNode(geometry: crossV)
            gridNode.addChildNode(crossVNode)
            
            gridNode.isHidden = true
            return gridNode
        }
        
        // Called every frame - update focus square position
        // IMPORTANT: Don't use DispatchQueue.main.sync here - it causes deadlock!
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let sceneView = sceneView else { return }
            guard let focusSquare = focusSquareNode else { return }
            
            // Hide focus square during placement
            if isPlacingObject {
                focusSquare.isHidden = true
                return
            }
            
            // Use cached screen center (updated from main thread in viewWillLayoutSubviews)
            // Use a fixed estimate based on typical screen size - this avoids the deadlock
            let screenCenter = cachedScreenCenter
            
            guard screenCenter != .zero else {
                focusSquare.isHidden = true
                return
            }
            
            // Try to find a plane at the center of the screen
            if let query = sceneView.raycastQuery(from: screenCenter,
                                                   allowing: .existingPlaneGeometry,
                                                   alignment: .horizontal) {
                let results = sceneView.session.raycast(query)
                if let result = results.first {
                    focusSquare.isHidden = false
                    focusSquare.simdPosition = SIMD3<Float>(
                        result.worldTransform.columns.3.x,
                        result.worldTransform.columns.3.y,
                        result.worldTransform.columns.3.z
                    )
                    canPlaceObject = true
                    updateFocusSquareColor(focusSquare, canPlace: true)
                    return
                }
            }
            
            // Try estimated plane as fallback
            if let query = sceneView.raycastQuery(from: screenCenter,
                                                   allowing: .estimatedPlane,
                                                   alignment: .horizontal) {
                let results = sceneView.session.raycast(query)
                if let result = results.first {
                    focusSquare.isHidden = false
                    focusSquare.simdPosition = SIMD3<Float>(
                        result.worldTransform.columns.3.x,
                        result.worldTransform.columns.3.y,
                        result.worldTransform.columns.3.z
                    )
                    canPlaceObject = true
                    updateFocusSquareColor(focusSquare, canPlace: false)
                    return
                }
            }
            
            focusSquare.isHidden = true
            canPlaceObject = false
        }
        
        private func updateFocusSquareColor(_ node: SCNNode, canPlace: Bool) {
            let color = canPlace 
                ? UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.9)
                : UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 0.9)
            
            node.enumerateChildNodes { child, _ in
                if let geometry = child.geometry {
                    geometry.materials.first?.diffuse.contents = color
                }
            }
        }
        
        // MARK: - Placed Items Management
        
        func updatePlacedItems(_ items: [PlacedItem], in sceneView: ARSCNView) {
            for (id, node) in placedNodes {
                if !items.contains(where: { $0.id == id }) {
                    node.removeFromParentNode()
                    placedNodes.removeValue(forKey: id)
                }
            }
            
            for item in items {
                guard let itemId = item.id else { continue }
                
                if placedNodes[itemId] == nil {
                    guard let itemModelName = item.modelName else {
                        print("❌ Coordinator: Item has no model name")
                        continue
                    }
                    
                    // Use ModelLoader for centralized loading
                    switch modelLoader.loadScene(named: itemModelName) {
                    case .success(let scene):
                        let node = scene.rootNode.clone()
                        node.position = SCNVector3(item.x, item.y, item.z)
                        
                        let baseScale: Float = 0.01
                        let finalScale = baseScale * item.scale
                        node.scale = SCNVector3(finalScale, finalScale, finalScale)
                        node.eulerAngles.y = item.rotationY
                        
                        sceneView.scene.rootNode.addChildNode(node)
                        placedNodes[itemId] = node
                        print("✅ Coordinator: Restored item \(itemModelName) at \(node.position) with scale \(finalScale)")
                        
                    case .failure(let error):
                        print("❌ Coordinator: \(error.localizedDescription)")
                    }
                }
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            print("🔵 handleTap: Tap detected")
            
            guard let sceneView = gesture.view as? ARSCNView else {
                print("❌ handleTap: Could not get ARSCNView")
                return
            }
            let location = gesture.location(in: sceneView)
            print("🔵 handleTap: Tap location = \(location), isPlacingObject = \(isPlacingObject)")
            
            var hitResult: ARRaycastResult?
            
            if let query = sceneView.raycastQuery(from: location,
                                                   allowing: .existingPlaneGeometry,
                                                   alignment: .horizontal) {
                let results = sceneView.session.raycast(query)
                print("🔵 handleTap: Raycast (existingPlane) returned \(results.count) results")
                hitResult = results.first
            }
            
            // Fallback: try estimatedPlane
            if hitResult == nil {
                if let query = sceneView.raycastQuery(from: location,
                                                       allowing: .estimatedPlane,
                                                       alignment: .horizontal) {
                    let results = sceneView.session.raycast(query)
                    print("🔵 handleTap: Raycast (estimatedPlane) returned \(results.count) results")
                    hitResult = results.first
                }
            }
            
            guard let result = hitResult else {
                print("⚠️ handleTap: No plane found at tap location")
                return
            }
            
            // Snap to floor plane if we've detected one
            var finalTransform = result.worldTransform
            if lowestPlaneY < Float.greatestFiniteMagnitude {
                // Replace Y with the floor level to prevent floating
                finalTransform.columns.3.y = lowestPlaneY
                print("✅ handleTap: Snapped to floor Y = \(lowestPlaneY)")
            }
            
            print("✅ handleTap: Final position at \(finalTransform.columns.3)")
            
            // Update the pending transform (allows repositioning)
            pendingPlacementTransform = finalTransform
            isPlacingObject = true
            showGhostNode(at: finalTransform, in: sceneView)
        }

        func showGhostNode(at transform: simd_float4x4, in sceneView: ARSCNView) {
            print("🔵 showGhostNode: Attempting to load model '\(modelName)'")
            removeGhostNode()
            
            // Reset gesture state for new ghost
            currentGhostScale = 0.01  // Base scale
            currentGhostRotation = 0
            
            // Update position binding
            let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            currentGhostPosition = position
            
            // Use ModelLoader for ghost node too
            switch modelLoader.loadScene(named: modelName) {
            case .success(let scene):
                let node = scene.rootNode.clone()
                node.opacity = 0.5
                node.simdTransform = transform
                
                node.scale = SCNVector3(currentGhostScale, currentGhostScale, currentGhostScale)
                
                sceneView.scene.rootNode.addChildNode(node)
                ghostNode = node
                print("✅ showGhostNode: Successfully added ghost node for '\(modelName)' with scale \(currentGhostScale)")
            case .failure(let error):
                print("❌ showGhostNode: Failed to load model '\(modelName)': \(error.localizedDescription)")
            }
        }

        func removeGhostNode() {
            ghostNode?.removeFromParentNode()
            ghostNode = nil
        }
        
        // MARK: - Pan Gesture (Drag to reposition)
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isPlacingObject, let ghostNode = ghostNode, let sceneView = sceneView else { return }
            
            let location = gesture.location(in: sceneView)
            
            if let query = sceneView.raycastQuery(from: location,
                                                   allowing: .existingPlaneGeometry,
                                                   alignment: .horizontal) {
                let results = sceneView.session.raycast(query)
                if let result = results.first {
                    let newPosition = SIMD3<Float>(
                        result.worldTransform.columns.3.x,
                        result.worldTransform.columns.3.y,
                        result.worldTransform.columns.3.z
                    )
                    
                    // Update ghost position
                    ghostNode.simdPosition = newPosition
                    
                    // Update position binding for parent view
                    currentGhostPosition = newPosition
                    
                    // Update pending transform
                    pendingPlacementTransform = result.worldTransform
                }
            }
        }
        
        // MARK: - Pinch Gesture (Scale)
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard isPlacingObject, let ghostNode = ghostNode else { return }
            
            if gesture.state == .changed {
                // Scale relative to current size
                let newScale = currentGhostScale * Float(gesture.scale)
                
                // Clamp scale to reasonable bounds (0.001 to 0.1)
                let clampedScale = min(max(newScale, 0.001), 0.1)
                
                ghostNode.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
                
                // Reset gesture scale for incremental changes
                gesture.scale = 1.0
                currentGhostScale = clampedScale
                
                print("📏 Pinch: Scale = \(clampedScale)")
            }
        }
        
        // MARK: - Rotation Gesture (Rotate)
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard isPlacingObject, let ghostNode = ghostNode else { return }
            
            if gesture.state == .changed {
                let rotation = Float(gesture.rotation)
                ghostNode.eulerAngles.y = currentGhostRotation - rotation
            }
            
            if gesture.state == .ended {
                // Save final rotation
                currentGhostRotation = ghostNode.eulerAngles.y
                print("🔄 Rotation: Y = \(currentGhostRotation)")
            }
        }
        
        // MARK: - Two-Finger Vertical Pan (Height Adjustment)
        
        @objc func handleVerticalPan(_ gesture: UIPanGestureRecognizer) {
            guard isPlacingObject, let ghostNode = ghostNode else { return }
            
            if gesture.state == .changed {
                // Get the translation in screen coordinates
                let translation = gesture.translation(in: gesture.view)
                let sensitivity: Float = 0.002
                let yOffset = -Float(translation.y) * sensitivity
                
                ghostNode.position.y += yOffset
                currentGhostPosition = SIMD3<Float>(ghostNode.position.x, ghostNode.position.y, ghostNode.position.z)
                gesture.setTranslation(.zero, in: gesture.view)
                
                print("↕️ Vertical: Y = \(ghostNode.position.y)")
            }
        }
        
        func placeModel(at transform: simd_float4x4, in sceneView: ARSCNView) {
            // Logic is now handled by updatePlacedItems driven by the binding.
        }
    }
}
