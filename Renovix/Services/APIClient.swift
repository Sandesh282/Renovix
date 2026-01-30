import Foundation

protocol APIClient {
    func fetchProducts() async throws -> [Product]
    func fetchCategories() async throws -> [Category]
}

class MockAPIClient: APIClient {
    private let simulatedDelay: TimeInterval = 0.5
    
    func fetchProducts() async throws -> [Product] {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        return MockData.products
    }
    
    func fetchCategories() async throws -> [Category] {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        return Category.allCases
    }
}

class RealAPIClient: APIClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.renovix-mock.com/v1")! 

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProducts() async throws -> [Product] {
        do {
            let (data, response) = try await session.data(from: baseURL.appendingPathComponent("products"))
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
            return dtos.map { $0.toDomain() }
        } catch {
            print("⚠️ Network fetch failed: \(error). Falling back to local data.")
            return try loadLocalProducts()
        }
    }
    
    func fetchCategories() async throws -> [Category] {
        return Category.allCases
    }
    
    private func loadLocalProducts() throws -> [Product] {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json") else {
            print("⚠️ Local products.json not found. Returning MockData.")
            return MockData.products
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }
}

// MARK: - Mock Data
struct MockData {
    static let products: [Product] = [
        Product(name: "Fanbyn",
                description: "Deep seating and high legs",
                price: 76.9,
                imageName: "chair",
                isNew: true,
                isFavourite: false,
                category: .chairs,
                colorOptions: [.gray, .brown, .black, .yellow, .blue],
                variantImageNames: ["chair", "chair_variant1", "chair_variant2", "chair_variant3"],
                model3DName: "chair"),
        
        Product(name: "Eggelstad",
                description: "Classic dining chair",
                price: 49.0,
                imageName: "chair",
                isNew: true,
                isFavourite: false,
                category: .chairs,
                colorOptions: [.gray, .orange, .blue, .green],
                variantImageNames: ["chair", "chair_variant1", "chair_variant2", "chair_variant3"],
                model3DName: "chair"),

        Product(name: "Sofastar",
                description: "Comfortable 3-seater sofa",
                price: 119.0,
                imageName: "sofa",
                isNew: false,
                isFavourite: false,
                category: .sofas,
                colorOptions: [.blue, .gray, .green, .purple],
                variantImageNames: ["sofa", "sofa_variant1", "sofa_variant2", "sofa_variant3"],
                model3DName: "sofa"),

        Product(name: "Reflecto Mirror",
                description: "Modern wall mirror",
                price: 39.0,
                imageName: "mirror",
                isNew: false,
                isFavourite: false,
                category: .mirrors,
                colorOptions: [.gray, .black, .white],
                variantImageNames: ["mirror", "mirror_variant1"],
                model3DName: "mirror"),

        Product(name: "DreamBed",
                description: "Cozy king size bed",
                price: 299.0,
                imageName: "bed",
                isNew: true,
                isFavourite: false,
                category: .beds,
                colorOptions: [.white, .gray, .blue, .yellow],
                variantImageNames: ["bed", "bed_variant1", "bed_variant2"],
                model3DName: "bed")
    ]
}
