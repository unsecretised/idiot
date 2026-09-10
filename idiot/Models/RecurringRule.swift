import Foundation
import SwiftData

@Model
final class RecurringRule {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Double = 0
    var frequencyRaw: String = RecurrenceFrequency.monthly.rawValue
    var dayNumber: Int = 1
    var startDate: Date = Date()
    var endDate: Date?
    var isActive: Bool = true
    var lastGeneratedDate: Date?
    var syncStamp: Date = Date()
    var category: Category?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        frequency: RecurrenceFrequency,
        dayNumber: Int,
        category: Category? = nil,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        frequencyRaw = frequency.rawValue
        self.dayNumber = dayNumber
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }

    var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var monthlyNormalizedCost: Double {
        amount * frequency.perMonthEstimateMultiplier
    }
}
