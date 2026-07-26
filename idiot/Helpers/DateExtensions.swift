import Foundation

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self) else {
            return self
        }

        return Calendar.current.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
    }

    var isInCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .month)
    }

    var isInPastMonth: Bool {
        startOfMonth < Date.now.startOfMonth
    }

    var weekOfMonth: Int {
        Calendar.current.component(.weekOfMonth, from: self)
    }

    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    static func weekDateRangeLabel(weekNumber: Int, in month: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        let monthStart = month.startOfMonth
        let estimatedDate = calendar.date(byAdding: .day, value: (weekNumber - 1) * 7, to: monthStart) ?? monthStart
        if let interval = calendar.dateInterval(of: .weekOfMonth, for: estimatedDate) {
            let weekStart = interval.start
            let weekEnd = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        }
        return "W\(weekNumber)"
    }
}
