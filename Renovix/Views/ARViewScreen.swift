import SwiftUI
import simd

struct ARViewScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showModelPicker = false
    @State private var isPlacingObject = false
    @State private var pendingPlacementTransform: simd_float4x4? = nil
    @State private var selectedModelName: String
    var modelName: String

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
                            placedItems: arViewModel.placedItems)
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
                            if let transform = pendingPlacementTransform {
                                let translation = transform.columns.3
                                let position = SIMD3<Float>(translation.x, translation.y, translation.z)
                                let rotationY = atan2(transform.columns.2.x, transform.columns.2.z)
                                
                                arViewModel.saveItem(
                                    productId: UUID().uuidString, 
                                    modelName: selectedModelName,
                                    position: position,
                                    rotationY: rotationY,
                                    scale: 1.0 
                                )
                                
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
