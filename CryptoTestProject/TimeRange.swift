enum TimeRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    
    var id: String { rawValue }
    
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        }
    }
} 