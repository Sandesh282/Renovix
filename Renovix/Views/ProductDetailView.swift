import SwiftUI
import QuickLook
import UniformTypeIdentifiers
import simd

struct ARModelQuickLook: UIViewControllerRepresentable {
    let modelName: String
    let onDismiss: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(modelName: modelName)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let modelName: String

        init(modelName: String) {
            self.modelName = modelName
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            if let url = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
                return url as QLPreviewItem
            } else {
                print("ARModelQuickLook: Could not find model \(modelName).usdz")
                return URL(fileURLWithPath: "/dev/null") as QLPreviewItem
            }
        }
    }
}

struct ProductDetailView: View {
    let product: Product
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedColor: Color
    @State private var selectedVariantIndex: Int = 0
    @State private var isFavourite: Bool
    @State private var showARQuickLook = false
    @State private var showARViewScreen = false

    init(product: Product) {
        self.product = product
        _selectedColor = State(initialValue: product.colorOptions.first ?? .gray)
        _isFavourite = State(initialValue: product.isFavourite)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    let minY = geo.frame(in: .global).minY
                    ZStack {
                        Image(product.variantImageNames.indices.contains(selectedVariantIndex) ? product.variantImageNames[selectedVariantIndex] : product.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height + (minY > 0 ? minY : 0))
                            .clipped()
                            .offset(y: minY > 0 ? -minY : 0)
                    }
                }
                .frame(height: 450)
                
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            if product.isNew {
                                Text("NEW COLLECTION")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                            Text(product.name)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                        }
                        Spacer()
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Divider()
                    
                    if !product.variantImageNames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Variants")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(product.variantImageNames.indices, id: \.self) { idx in
                                        Image(product.variantImageNames[idx])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(idx == selectedVariantIndex ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                withAnimation { selectedVariantIndex = idx }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Colors")
                            .font(.headline)
                        HStack(spacing: 16) {
                            ForEach(product.colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .opacity(color == selectedColor ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        withAnimation { selectedColor = color }
                                    }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100) 
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .offset(y: -50)
            }
            .edgesIgnoringSafeArea(.top)
            
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button(action: { isFavourite.toggle() }) {
                        Image(systemName: isFavourite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isFavourite ? .red : .primary)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50) 
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
            .allowsHitTesting(true) 

            VStack {
                Spacer()
                HStack(spacing: 20) {
                    if let modelName = product.model3DName,
                       Bundle.main.url(forResource: modelName, withExtension: "usdz") != nil {
                        Button(action: { showARQuickLook = true }) {
                            HStack {
                                Image(systemName: "arkit")
                                Text("View in 3D")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray5))
                            .cornerRadius(16)
                            .foregroundColor(.primary)
                        }
                        
                        Button(action: { showARViewScreen = true }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("View in Room")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(16)
                            .foregroundColor(.white)
                        }
                    } else {
                        Button(action: {}) {
                            Text("Add to Cart")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showARQuickLook) {
            ZStack(alignment: .topLeading) {
                if let modelName = product.model3DName {
                    ARModelQuickLook(modelName: modelName)
                        .edgesIgnoringSafeArea(.all)
                }
                Button(action: { showARQuickLook = false }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(.top, 40)
                        .padding(.leading, 16)
                }
            }
        }
        .fullScreenCover(isPresented: $showARViewScreen) {
            if let modelName = product.model3DName {
                ARViewScreen(modelName: modelName)
            }
        }
    }
}

#Preview {
    ProductDetailView(product: Product(
        name: "Fanbyn",
        description: "Deep seating and high legs",
        price: 76.9,
        imageName: "chair",
        isNew: true,
        isFavourite: false,
        category: .chairs,
        colorOptions: [.gray, .brown, .black, .yellow, .blue],
        variantImageNames: ["chair", "chair_variant1", "chair_variant2", "chair_variant3"],
        model3DName: "chair"
    ))
}

