import Foundation

class AppContainer: ObservableObject {
    static let shared = AppContainer()
    
    let apiClient: APIClient
    let productRepository: ProductRepository
    let arItemRepository: ARItemRepository
    let modelLoader: ModelLoader
    
    init() {
        self.apiClient = RealAPIClient()
        self.productRepository = DefaultProductRepository(apiClient: self.apiClient)
        self.arItemRepository = CoreDataARItemRepository()
        self.modelLoader = DefaultModelLoader()
    }
}

