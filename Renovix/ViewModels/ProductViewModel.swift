import Foundation
import SwiftUI

class ProductViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var selectedCategory: Category = .chairs
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: ProductRepository
    
    init(repository: ProductRepository = AppContainer.shared.productRepository) {
        self.repository = repository
        Task {
            await loadData()
        }
    }
    
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await repository.getProducts()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    enum SortOption {
        case priceLowToHigh
        case priceHighToLow
        case name
    }

    @Published var sortOption: SortOption = .name

    var filteredProducts: [Product] {
        let filtered = products.filter { product in
            (product.name.lowercased().contains(searchQuery.lowercased()) || searchQuery.isEmpty) &&
            (product.category == selectedCategory)
        }
        
        switch sortOption {
        case .priceLowToHigh:
            return filtered.sorted { $0.price < $1.price }
        case .priceHighToLow:
            return filtered.sorted { $0.price > $1.price }
        case .name:
            return filtered.sorted { $0.name < $1.name }
        }
    }

    func toggleFavourite(for product: Product) {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index].isFavourite.toggle()
        }
    }
}
