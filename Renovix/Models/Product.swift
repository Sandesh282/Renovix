import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let imageName: String
    let isNew: Bool
    var isFavourite: Bool
    var category: Category
    let colorOptions: [Color]
    let variantImageNames: [String]
    let model3DName: String?
}

