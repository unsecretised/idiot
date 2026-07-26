import Foundation

enum CategoryType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .income:
            "Income"
        case .expense:
            "Expense"
        }
    }
}
