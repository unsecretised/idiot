import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: CategoryType
    var limit: Double?
    var colorHex: String
    var iconName: String
    var isSystem: Bool
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Transaction.category) var transactions: [Transaction]?

    init(
        id: UUID = UUID(),
        name: String = "",
        type: CategoryType = .expense,
        limit: Double? = nil,
        colorHex: String = "#4F8EF7",
        iconName: String = "tag.fill",
        isSystem: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.limit = limit
        self.colorHex = colorHex
        self.iconName = iconName
        self.isSystem = isSystem
        self.sortOrder = sortOrder
    }
}
