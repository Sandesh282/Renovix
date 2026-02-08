import Testing
import simd
import SceneKit
@testable import Renovix

// MARK: - Mock AR Item Repository

class MockARItemRepository: ARItemRepository {
    var mockItems: [PlacedItem] = []
    var shouldFailOnSave = false
    var shouldFailOnLoad = false
    var shouldFailOnDelete = false
    
    func getPlacedItems() throws -> [PlacedItem] {
        if shouldFailOnLoad {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock load failed"])
        }
        return mockItems
    }
    
    func saveItem(productId: String, modelName: String, position: SIMD3<Float>, rotationY: Float, scale: Float) throws {
        if shouldFailOnSave {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock save failed"])
        }
        // In real implementation this would create a PlacedItem
    }
    
    func deleteItem(item: PlacedItem) throws {
        if shouldFailOnDelete {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock delete failed"])
        }
    }
}

// MARK: - Mock Model Loader

class MockModelLoader: ModelLoader {
    var availableModels: Set<String> = ["chair", "sofa", "bed"]
    
    func loadScene(named name: String) -> Result<SCNScene, ModelLoadError> {
        if availableModels.contains(name) {
            return .success(SCNScene())
        }
        return .failure(.notFound(name))
    }
    
    func validateModelExists(named name: String) -> Bool {
        return availableModels.contains(name)
    }
    
    func modelURL(named name: String) -> URL? {
        if availableModels.contains(name) {
            return URL(fileURLWithPath: "/mock/\(name).usdz")
        }
        return nil
    }
}

// MARK: - AR ViewModel Tests

struct ARViewModelTests {
    
    @Test func initialSessionState_isInitializing() {
        let mockRepo = MockARItemRepository()
        let mockLoader = MockModelLoader()
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        #expect(vm.sessionState == .initializing)
    }
    
    @Test func updateSessionState_updatesState() async {
        let mockRepo = MockARItemRepository()
        let mockLoader = MockModelLoader()
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        vm.updateSessionState(.planeDetected)
        
        // Wait for main actor dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(vm.sessionState == .planeDetected)
    }
    
    @Test func sessionState_isReadyReturnsCorrectly() {
        #expect(ARSessionState.ready.isReady == true)
        #expect(ARSessionState.planeDetected.isReady == true)
        #expect(ARSessionState.initializing.isReady == false)
        #expect(ARSessionState.planeSearching.isReady == false)
        #expect(ARSessionState.failed("error").isReady == false)
    }
    
    @Test func loadItems_loadsFromRepository() {
        let mockRepo = MockARItemRepository()
        let mockLoader = MockModelLoader()
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        vm.loadItems()
        
        #expect(vm.placedItems.isEmpty)
        #expect(vm.errorMessage == nil)
    }
    
    @Test func loadItems_setsErrorOnFailure() {
        let mockRepo = MockARItemRepository()
        mockRepo.shouldFailOnLoad = true
        let mockLoader = MockModelLoader()
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        vm.loadItems()
        
        #expect(vm.errorMessage != nil)
    }
    
    @Test func isModelAvailable_checksLoader() {
        let mockRepo = MockARItemRepository()
        let mockLoader = MockModelLoader()
        mockLoader.availableModels = ["chair", "sofa"]
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        #expect(vm.isModelAvailable(named: "chair") == true)
        #expect(vm.isModelAvailable(named: "nonexistent") == false)
    }
    
    @Test func saveItem_setsErrorOnFailure() {
        let mockRepo = MockARItemRepository()
        mockRepo.shouldFailOnSave = true
        let mockLoader = MockModelLoader()
        let vm = ARViewModel(repository: mockRepo, modelLoader: mockLoader)
        
        vm.saveItem(
            productId: "test",
            modelName: "chair",
            position: SIMD3<Float>(0, 0, 0),
            rotationY: 0,
            scale: 1.0
        )
        
        #expect(vm.errorMessage != nil)
    }
}


