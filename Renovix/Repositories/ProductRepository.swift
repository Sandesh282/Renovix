import Foundation

protocol ProductRepository {
    func getProducts() async throws -> [Product]
    func getCategories() async throws -> [Category]
}

class DefaultProductRepository: ProductRepository {
    private let apiClient: APIClient
    
    private var cachedProducts: [Product]?
    private var cachedCategories: [Category]?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getProducts() async throws -> [Product] {
        if let cached = cachedProducts {
            return cached
        }
        let products = try await apiClient.fetchProducts()
        cachedProducts = products
        return products
    }
    
    func getCategories() async throws -> [Category] {
        if let cached = cachedCategories {
            return cached
        }
        let categories = try await apiClient.fetchCategories()
        cachedCategories = categories
        return categories
    }
}
