import Foundation
import SwiftUI

struct ProductDTO: Codable {
    let id: String?
    let name: String
    let description: String
    let price: Double
    let imageName: String
    let isNew: Bool
    let isFavourite: Bool
    let category: String
    let colorHexes: [String]
    let variantImageNames: [String]
    let model3DName: String?

    func toDomain() -> Product {
        return Product(
            name: name,
            description: description,
            price: price,
            imageName: imageName,
            isNew: isNew,
            isFavourite: isFavourite,
            category: Category(rawValue: category) ?? .chairs,
            colorOptions: colorHexes.map { Color(hex: $0) },
            variantImageNames: variantImageNames,
            model3DName: model3DName
        )
    }
}
