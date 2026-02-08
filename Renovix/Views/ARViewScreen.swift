import SwiftUI
import simd

struct ARViewScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showModelPicker = false
    @State private var isPlacingObject = false
    @State private var pendingPlacementTransform: simd_float4x4? = nil
    @State private var selectedModelName: String
    var modelName: String

    // Ghost transform state
    @State private var currentGhostPosition: SIMD3<Float> = .zero
    @State private var currentGhostScale: Float = 0.01
    @State private var currentGhostRotation: Float = 0

    @StateObject private var arViewModel = ARViewModel()

    init(modelName: String) {
        self.modelName = modelName
        _selectedModelName = State(initialValue: modelName)
    }

    var body: some View {
        ZStack {
            ARViewContainer(modelName: selectedModelName,
                            isPlacingObject: $isPlacingObject,
                            pendingPlacementTransform: $pendingPlacementTransform,
                            currentGhostPosition: $currentGhostPosition,
                            currentGhostScale: $currentGhostScale,
                            currentGhostRotation: $currentGhostRotation,
                            placedItems: arViewModel.placedItems,
                            onSessionStateChange: { state in
                                arViewModel.updateSessionState(state)
                            })
                .edgesIgnoringSafeArea(.all)

            VStack {
                
                HStack(alignment: .center) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial) 
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(modelName.capitalized) 
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        Text("$199") 
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    Button(action: { /* Favorite Action */ }) {
                        Image(systemName: "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20) 
                
                if !isPlacingObject {
                    scanStatusIndicator
                }

                Spacer()
                
                if !isPlacingObject {
                    HStack(spacing: 40) {
                        Spacer()
                        Button(action: {
                            for item in arViewModel.placedItems {
                                arViewModel.deleteItem(item)
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 22))
                                .foregroundColor(.primary)
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: { showModelPicker = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.6)) 
                                    .frame(width: 64, height: 64) 
                                    .shadow(color: Color(red: 0.1, green: 0.6, blue: 0.6).opacity(0.4), radius: 8, x: 0, y: 4)
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .semibold)) 
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        Button(action: { /* Scan Action */ }) {
                            ZStack {
                                Circle() 
                                    .strokeBorder(.white, lineWidth: 4)
                                    .frame(width: 56, height: 56)
                                Circle() 
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 46, height: 46)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .pointerInput(enabled: !isPlacingObject) 

            if isPlacingObject {
                VStack {
                    Spacer()
                    HStack(spacing: 60) {
                        Button(action: {
                            isPlacingObject = false
                            pendingPlacementTransform = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.9))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Use actual ghost position/scale/rotation from gesture adjustments
                            arViewModel.saveItem(
                                productId: UUID().uuidString, 
                                modelName: selectedModelName,
                                position: currentGhostPosition,
                                rotationY: currentGhostRotation,
                                scale: currentGhostScale / 0.01  // Convert back to relative scale (base is 0.01)
                            )
                            
                            if let transform = pendingPlacementTransform {
                                NotificationCenter.default.post(name: .addNewObject, object: transform)
                            }
                            isPlacingObject = false
                            pendingPlacementTransform = nil
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.green.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            arViewModel.loadItems()
            arViewModel.loadAvailableModels()
        }
        .sheet(isPresented: $showModelPicker) {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text("Select Model")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(arViewModel.availableModels) { product in
                            Button(action: {
                                selectedModelName = product.model3DName ?? "chair"
                                showModelPicker = false
                            }) {
                                HStack {
                                    Image(systemName: "cube.fill")
                                        .foregroundColor(.teal)
                                    Text(product.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedModelName == (product.model3DName ?? "") {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.teal)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding(.bottom)
            .presentationDetents([.medium])
        }
        .alert(item: Binding<AlertItem?>(
            get: { arViewModel.errorMessage.map { AlertItem(message: $0) } },
            set: { _ in arViewModel.errorMessage = nil }
        )) { alert in
            Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Scan Status Indicator
    
    private var scanStatusIndicator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                
                Image(systemName: scanStatusIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(scanStatusColor)
                
                Text(scanStatusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            
            if arViewModel.sessionState == .planeSearching {
                Text("Move your phone slowly to scan the floor")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.3)))
            }
        }
        .padding(.top, 8)
    }
    
    private var scanStatusIcon: String {
        switch arViewModel.sessionState {
        case .initializing:
            return "hourglass"
        case .planeSearching:
            return "viewfinder"
        case .planeDetected:
            return "checkmark.circle.fill"
        case .ready:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var scanStatusText: String {
        switch arViewModel.sessionState {
        case .initializing:
            return "Initializing AR..."
        case .planeSearching:
            return "Scanning for surfaces..."
        case .planeDetected:
            return "Surface detected! Tap to place"
        case .ready:
            return "Ready to place objects"
        case .failed(let message):
            return "Error: \(message)"
        }
    }
    
    private var scanStatusColor: Color {
        switch arViewModel.sessionState {
        case .initializing:
            return .gray
        case .planeSearching:
            return .yellow
        case .planeDetected, .ready:
            return .green
        case .failed:
            return .red
        }
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}

extension View {
    func pointerInput(enabled: Bool) -> some View {
        self.allowsHitTesting(enabled)
    }
}
