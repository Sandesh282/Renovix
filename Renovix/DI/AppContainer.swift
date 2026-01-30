import Foundation

class AppContainer: ObservableObject {
    static let shared = AppContainer()
    
    let apiClient: APIClient
    let productRepository: ProductRepository
    let arItemRepository: ARItemRepository
    
    init() {
        self.apiClient = RealAPIClient()
        self.productRepository = DefaultProductRepository(apiClient: self.apiClient)
        self.arItemRepository = CoreDataARItemRepository()
    }
}
