import Foundation
import CoreData
import Combine

protocol ARItemRepository {
    func getPlacedItems() throws -> [PlacedItem]
    func saveItem(productId: String, modelName: String, position: SIMD3<Float>, rotationY: Float, scale: Float) throws
    func deleteItem(item: PlacedItem) throws
}

class CoreDataARItemRepository: ARItemRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func getPlacedItems() throws -> [PlacedItem] {
        let request = PlacedItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlacedItem.timestamp, ascending: true)]
        return try context.fetch(request)
    }

    func saveItem(productId: String, modelName: String, position: SIMD3<Float>, rotationY: Float, scale: Float) throws {
        let newItem = PlacedItem(context: context)
        newItem.id = UUID()
        newItem.productId = productId
        newItem.modelName = modelName
        newItem.x = position.x
        newItem.y = position.y
        newItem.z = position.z
        newItem.rotationY = rotationY
        newItem.scale = scale
        newItem.timestamp = Date()

        try context.save()
    }

    func deleteItem(item: PlacedItem) throws {
        context.delete(item)
        try context.save()
    }
}
