enum Category: String, CaseIterable {
    case chairs = "Chairs"
    case sofas = "Sofas"
    case mirrors = "Mirrors"
    case beds = "Beds"

    var icon: String {
        switch self {
        case .chairs: return "chair"
        case .sofas: return "sofa"
        case .mirrors: return "rectangle"
        case .beds: return "bed.double"
        }
    }
}
