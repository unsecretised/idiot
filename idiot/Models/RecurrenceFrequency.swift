import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }
    }

    func nextDate(after date: Date, dayNumber: Int) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: date))
        case .monthly:
            let monthStart = date.startOfMonth
            let day = min(max(dayNumber, 1), 28)
            let candidate = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
            return calendar.date(byAdding: .day, value: day - 1, to: candidate)
        case .yearly:
            let month = calendar.component(.month, from: date)
            var components = calendar.dateComponents([.year], from: calendar.date(byAdding: .year, value: 1, to: date) ?? date)
            components.month = month
            components.day = min(max(dayNumber, 1), 28)
            return calendar.date(from: components)
        }
    }

    var perMonthEstimateMultiplier: Double {
        switch self {
        case .weekly: 52.0 / 12.0
        case .monthly: 1
        case .yearly: 1.0 / 12.0
        }
    }
}
