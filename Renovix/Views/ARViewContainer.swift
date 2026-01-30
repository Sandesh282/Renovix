import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    var modelName: String
    @Binding var isPlacingObject: Bool
    @Binding var pendingPlacementTransform: simd_float4x4?
    var placedItems: [PlacedItem]

    func makeCoordinator() -> Coordinator {
        Coordinator(modelName: modelName, isPlacingObject: $isPlacingObject, pendingPlacementTransform: $pendingPlacementTransform)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = sceneView.session
        coachingOverlay.goal = .horizontalPlane
        sceneView.addSubview(coachingOverlay)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(forName: .addNewObject, object: nil, queue: .main) { notification in
            context.coordinator.removeGhostNode()
        }

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updatePlacedItems(placedItems, in: uiView)
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        var modelName: String
        @Binding var isPlacingObject: Bool
        @Binding var pendingPlacementTransform: simd_float4x4?
        var ghostNode: SCNNode?
        var placedNodes: [UUID: SCNNode] = [:]

        init(modelName: String, isPlacingObject: Binding<Bool>, pendingPlacementTransform: Binding<simd_float4x4?>) {
            self.modelName = modelName
            self._isPlacingObject = isPlacingObject
            self._pendingPlacementTransform = pendingPlacementTransform
        }
        
        func updatePlacedItems(_ items: [PlacedItem], in sceneView: ARSCNView) {
            // Remove deleted items
            for (id, node) in placedNodes {
                if !items.contains(where: { $0.id == id }) {
                    node.removeFromParentNode()
                    placedNodes.removeValue(forKey: id)
                }
            }
            
            // Add new items
            for item in items {
                guard let itemId = item.id else { continue } // Safely unwrap ID
                
                if placedNodes[itemId] == nil {
                    // Create node
                    // Try to load scn, then usdz
                    guard let scene = SCNScene(named: "\(item.modelName ?? "").scn") ?? SCNScene(named: "\(item.modelName ?? "").usdz") else {
                        print("❌ Coordinator: Could not load model \(item.modelName ?? "nil")")
                        continue
                    }
                    let node = scene.rootNode.clone()
                    // Position
                    node.position = SCNVector3(item.x, item.y, item.z)
                    // Scale
                    node.scale = SCNVector3(item.scale, item.scale, item.scale)
                    // Rotation (Y-axis)
                    node.eulerAngles.y = item.rotationY
                    
                    sceneView.scene.rootNode.addChildNode(node)
                    placedNodes[itemId] = node
                    print("✅ Coordinator: Restored item \(item.modelName ?? "nil") at \(node.position)")
                }
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isPlacingObject else { return }
            guard let sceneView = gesture.view as? ARSCNView else { return }
            let location = gesture.location(in: sceneView)
            let results = sceneView.hitTest(location, types: [.existingPlaneUsingExtent])

            if let result = results.first {
                // Show ghost node at tapped location
                pendingPlacementTransform = result.worldTransform
                isPlacingObject = true
                showGhostNode(at: result.worldTransform, in: sceneView)
            }
        }


        func showGhostNode(at transform: simd_float4x4, in sceneView: ARSCNView) {
            removeGhostNode()
            guard let scene = SCNScene(named: "\(modelName).scn") ?? SCNScene(named: "\(modelName).usdz") else { return }
            let node = scene.rootNode.clone()
            node.opacity = 0.5
            node.simdTransform = transform
            sceneView.scene.rootNode.addChildNode(node)
            ghostNode = node
        }

        func removeGhostNode() {
            ghostNode?.removeFromParentNode()
            ghostNode = nil
        }
        
        func placeModel(at transform: simd_float4x4, in sceneView: ARSCNView) {
             // Logic is now handled by updatePlacedItems driven by the binding.
        }
    }
}
