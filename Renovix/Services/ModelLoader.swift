import SceneKit

// MARK: - Model Load Error

enum ModelLoadError: Error, LocalizedError {
    case notFound(String)
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound(let name):
            return "Model '\(name)' not found in bundle"
        case .invalidFormat(let name):
            return "Model '\(name)' has invalid format"
        }
    }
}

// MARK: - Model Loader Protocol

protocol ModelLoader {
    func loadScene(named name: String) -> Result<SCNScene, ModelLoadError>
    
    func validateModelExists(named name: String) -> Bool
    
    func modelURL(named name: String) -> URL?
}

// MARK: - Default Implementation

class DefaultModelLoader: ModelLoader {
    
    private let supportedExtensions = ["usdz", "scn", "dae"]
    
    func loadScene(named name: String) -> Result<SCNScene, ModelLoadError> {
        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let scene = try? SCNScene(url: url, options: nil) {
                return .success(scene)
            }
        }
        
        // Fallback for models packaged via SceneKit scene catalogs
        if let scene = SCNScene(named: "\(name).usdz") {
            return .success(scene)
        }
        if let scene = SCNScene(named: "\(name).scn") {
            return .success(scene)
        }
        
        return .failure(.notFound(name))
    }
    
    func validateModelExists(named name: String) -> Bool {
        return modelURL(named: name) != nil
    }
    
    func modelURL(named name: String) -> URL? {
        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}
