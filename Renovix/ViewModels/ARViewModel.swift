import Foundation
import Combine
import simd

// MARK: - AR Session State

enum ARSessionState: Equatable {
    case initializing
    case planeSearching
    case planeDetected
    case ready
    case failed(String)
    
    var isReady: Bool {
        if case .ready = self { return true }
        if case .planeDetected = self { return true }
        return false
    }
}

// MARK: - AR View Model

class ARViewModel: ObservableObject {
    @Published var sessionState: ARSessionState = .initializing
    @Published var placedItems: [PlacedItem] = []
    @Published var errorMessage: String?
    @Published var availableModels: [Product] = []
    
    private let repository: ARItemRepository
    private let modelLoader: ModelLoader
    
    init(repository: ARItemRepository = AppContainer.shared.arItemRepository,
         modelLoader: ModelLoader = AppContainer.shared.modelLoader) {
        self.repository = repository
        self.modelLoader = modelLoader
        loadItems()
    }
    
    // MARK: - Session State Management
    
    func updateSessionState(_ state: ARSessionState) {
        DispatchQueue.main.async {
            self.sessionState = state
        }
    }
    
    // MARK: - Model Loading
    
    func loadModel(named name: String) -> Result<Any, ModelLoadError> {
        return modelLoader.loadScene(named: name).map { $0 as Any }
    }
    
    func isModelAvailable(named name: String) -> Bool {
        return modelLoader.validateModelExists(named: name)
    }
    
    // MARK: - Available Models
    
    func loadAvailableModels() {
        Task {
            do {
                let products = try await AppContainer.shared.productRepository.getProducts()
                let models = products.filter { product in
                    guard let modelName = product.model3DName, !modelName.isEmpty else { return false }
                    return modelLoader.validateModelExists(named: modelName)
                }
                await MainActor.run {
                    self.availableModels = models
                }
            } catch {
                print("ARViewModel: Failed to load available models: \(error)")
            }
        }
    }
    
    // MARK: - Placed Items CRUD

    func loadItems() {
        do {
            placedItems = try repository.getPlacedItems()
            print("ARViewModel: Loaded \(placedItems.count) placed items.")
        } catch {
            errorMessage = "Failed to load placed items: \(error.localizedDescription)"
            print("ARViewModel: Error loading items: \(error)")
        }
    }
    
    func saveItem(productId: String, modelName: String, position: SIMD3<Float>, rotationY: Float, scale: Float) {
        print("💾 ARViewModel: Saving item... \(modelName) at \(position)")
        do {
            try repository.saveItem(productId: productId, modelName: modelName, position: position, rotationY: rotationY, scale: scale)
            loadItems() 
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
            print("ARViewModel: Error saving item: \(error)")
        }
    }
    
    func deleteItem(_ item: PlacedItem) {
        do {
            try repository.deleteItem(item: item)
            loadItems()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
}

