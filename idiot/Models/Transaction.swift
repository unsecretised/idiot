import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var title: String
    var desc: String?
    var amount: Double
    var date: Date
    var category: Category?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        desc: String? = nil,
        amount: Double = 0,
        date: Date = .now,
        category: Category? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.desc = desc
        self.amount = amount
        self.date = date
        self.category = category
        self.createdAt = createdAt
    }
}
