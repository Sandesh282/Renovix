import Foundation
import Combine
import simd

class ARViewModel: ObservableObject {
    @Published var placedItems: [PlacedItem] = []
    @Published var errorMessage: String?
    
    private let repository: ARItemRepository
    
    init(repository: ARItemRepository = AppContainer.shared.arItemRepository) {
        self.repository = repository
        loadItems()
    }
    
    @Published var availableModels: [Product] = []

    func loadAvailableModels() {
        Task {
            do {
                let products = try await AppContainer.shared.productRepository.getProducts()
                let models = products.filter { !($0.model3DName?.isEmpty ?? true) }
                await MainActor.run {
                    self.availableModels = models
                }
            } catch {
                print("ARViewModel: Failed to load available models: \(error)")
            }
        }
    }

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
