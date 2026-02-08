import Testing
import SwiftUI
@testable import Renovix

// MARK: - Mock Product Repository

class MockProductRepository: ProductRepository {
    var mockProducts: [Product] = MockData.products
    var shouldFail = false
    var fetchDelay: TimeInterval = 0
    
    func getProducts() async throws -> [Product] {
        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }
        if shouldFail {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock fetch failed"])
        }
        return mockProducts
    }
    
    func getCategories() async throws -> [Category] {
        return Category.allCases
    }
}

// MARK: - Product ViewModel Tests

struct ProductViewModelTests {
    
    @Test func initialState_hasEmptyProducts() async throws {
        let mockRepo = MockProductRepository()
        mockRepo.mockProducts = []
        let vm = ProductViewModel(repository: mockRepo)
        
        // Wait for initial load
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(vm.products.isEmpty)
    }
    
    @Test func loadData_populatesProducts() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        
        await vm.loadData()
        
        #expect(!vm.products.isEmpty)
        #expect(vm.products.count == mockRepo.mockProducts.count)
    }
    
    @Test func loadData_setsErrorOnFailure() async throws {
        let mockRepo = MockProductRepository()
        mockRepo.shouldFail = true
        let vm = ProductViewModel(repository: mockRepo)
        
        await vm.loadData()
        
        #expect(vm.errorMessage != nil)
        #expect(vm.products.isEmpty)
    }
    
    @Test func filteredProducts_filtersByCategory() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.selectedCategory = .chairs
        let filtered = vm.filteredProducts
        
        #expect(filtered.allSatisfy { $0.category == .chairs })
    }
    
    @Test func filteredProducts_filtersBySearchQuery() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.searchQuery = "Sofa"
        vm.selectedCategory = .sofas
        let filtered = vm.filteredProducts
        
        #expect(filtered.allSatisfy { $0.name.lowercased().contains("sofa") })
    }
    
    @Test func filteredProducts_returnsEmptyForNoMatch() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.searchQuery = "NonExistentProduct12345"
        let filtered = vm.filteredProducts
        
        #expect(filtered.isEmpty)
    }
    
    @Test func sortOption_sortsByPriceLowToHigh() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.sortOption = .priceLowToHigh
        let prices = vm.filteredProducts.map { $0.price }
        
        #expect(prices == prices.sorted())
    }
    
    @Test func sortOption_sortsByPriceHighToLow() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.sortOption = .priceHighToLow
        let prices = vm.filteredProducts.map { $0.price }
        
        #expect(prices == prices.sorted(by: >))
    }
    
    @Test func sortOption_sortsByName() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        vm.sortOption = .name
        let names = vm.filteredProducts.map { $0.name }
        
        #expect(names == names.sorted())
    }
    
    @Test func toggleFavourite_togglesState() async throws {
        let mockRepo = MockProductRepository()
        let vm = ProductViewModel(repository: mockRepo)
        await vm.loadData()
        
        guard let firstProduct = vm.products.first else {
            throw TestError("No products available")
        }
        
        let originalState = firstProduct.isFavourite
        vm.toggleFavourite(for: firstProduct)
        
        let updatedProduct = vm.products.first { $0.id == firstProduct.id }
        #expect(updatedProduct?.isFavourite == !originalState)
    }
}

struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
