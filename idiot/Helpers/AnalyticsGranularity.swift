import Foundation

enum Granularity: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: .day
        case .weekly: .weekOfMonth
        case .monthly: .month
        case .yearly: .year
        }
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        guard let interval = Calendar.current.dateInterval(of: .day, for: self) else {
            return self
        }

        return interval.end.addingTimeInterval(-1)
    }

    func start(of granularity: Granularity) -> Date {
        if granularity == .daily {
            return startOfDay
        }

        return Calendar.current.dateInterval(of: granularity.calendarComponent, for: self)?.start ?? self
    }

    func periodLabel(for granularity: Granularity) -> String {
        switch granularity {
        case .daily:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: self)
        case .weekly:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            let weekStart = start(of: .weekly)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        case .monthly:
            return formatted(.dateTime.month(.abbreviated).year())
        case .yearly:
            return formatted(.dateTime.year())
        }
    }
}
