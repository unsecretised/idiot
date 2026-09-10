import Foundation

extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension Double {
    var formattedCurrency: String {
        NumberFormatter.currencyFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Collection where Element == Double {
    var averageOrZero: Double {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1 } / Double(count)
    }
}
