import SwiftUI
import RealityKit
import ARKit

struct RealityKitARView: UIViewRepresentable {
    @Binding var sessionState: ARSessionState
    var modelName: String
    @Binding var isPlacingObject: Bool
    @Binding var pendingPlacementTransform: simd_float4x4?
    var onPlaceObject: ((simd_float4x4) -> Void)?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.isLightEstimationEnabled = true
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        // Add coaching overlay
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coaching)
        
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                          action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.modelName = modelName
        context.coordinator.isPlacingObject = isPlacingObject
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        // Properly pause the AR session to avoid deallocation warning
        uiView.session.pause()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            sessionState: $sessionState,
            modelName: modelName,
            isPlacingObject: $isPlacingObject,
            pendingPlacementTransform: $pendingPlacementTransform,
            onPlaceObject: onPlaceObject
        )
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @Binding var sessionState: ARSessionState
        var modelName: String
        @Binding var isPlacingObject: Bool
        @Binding var pendingPlacementTransform: simd_float4x4?
        var onPlaceObject: ((simd_float4x4) -> Void)?
        
        weak var arView: ARView?
        private var hasDetectedPlane = false
        private var ghostAnchor: AnchorEntity?
        private var placedAnchors: [AnchorEntity] = []
        
        init(sessionState: Binding<ARSessionState>,
             modelName: String,
             isPlacingObject: Binding<Bool>,
             pendingPlacementTransform: Binding<simd_float4x4?>,
             onPlaceObject: ((simd_float4x4) -> Void)?) {
            _sessionState = sessionState
            self.modelName = modelName
            _isPlacingObject = isPlacingObject
            _pendingPlacementTransform = pendingPlacementTransform
            self.onPlaceObject = onPlaceObject
        }
        
        // MARK: - Tap Handling
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isPlacingObject else { return }
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            
            if let result = arView.raycast(from: location,
                                            allowing: .existingPlaneGeometry,
                                            alignment: .horizontal).first {
                pendingPlacementTransform = result.worldTransform
                isPlacingObject = true
                showGhostEntity(at: result.worldTransform)
            }
        }
        
        // MARK: - Ghost Entity (Preview)
        
        func showGhostEntity(at transform: simd_float4x4) {
            removeGhostEntity()
            
            guard let arView = arView else { return }
            
            do {
                let modelEntity = try ModelEntity.loadModel(named: modelName)
                
                // Apply semi-transparent material for ghost preview
                var ghostMaterial = SimpleMaterial()
                ghostMaterial.color = .init(tint: .white.withAlphaComponent(0.5))
                modelEntity.model?.materials = [ghostMaterial]
                
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(modelEntity)
                arView.scene.addAnchor(anchor)
                ghostAnchor = anchor
            } catch {
                print("❌ RealityKit: Failed to load ghost model \(modelName): \(error)")
            }
        }
        
        func removeGhostEntity() {
            ghostAnchor?.removeFromParent()
            ghostAnchor = nil
        }
        
        // MARK: - Place Entity
        
        func placeEntity(at transform: simd_float4x4) {
            guard let arView = arView else { return }
            removeGhostEntity()
            
            do {
                let modelEntity = try ModelEntity.loadModel(named: modelName)
                
                modelEntity.generateCollisionShapes(recursive: true)
                
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(modelEntity)
                arView.scene.addAnchor(anchor)
                placedAnchors.append(anchor)
                
                print("✅ RealityKit: Placed \(modelName)")
            } catch {
                print("❌ RealityKit: Failed to place model \(modelName): \(error)") 
            }
        }
        
        func clearAllPlacements() {
            for anchor in placedAnchors {
                anchor.removeFromParent()
            }
            placedAnchors.removeAll()
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            if anchors.contains(where: { $0 is ARPlaneAnchor }) && !hasDetectedPlane {
                hasDetectedPlane = true
                DispatchQueue.main.async {
                    self.sessionState = .planeDetected
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            DispatchQueue.main.async {
                self.sessionState = .failed(error.localizedDescription)
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            DispatchQueue.main.async {
                self.sessionState = .failed("Session interrupted")
            }
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            hasDetectedPlane = false
            DispatchQueue.main.async {
                self.sessionState = .planeSearching
            }
        }
    }
}
