import SwiftUI
import WidgetKit

struct SnapshotRow: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var amount: Double
    var isIncome: Bool
    var date: Date
    var colorHex: String
    var iconName: String
}

struct WidgetSnapshot: Codable, Hashable {
    var monthLabel: String = ""
    var income: Double = 0
    var expense: Double = 0
    var net: Double = 0
    var balance: Double = 0
    var overLimitCount: Int = 0
    var topCategoryName: String?
    var topCategoryAmount: Double = 0
    var rows: [SnapshotRow] = []
    var updatedAt: Date = .distantPast
}

extension WidgetSnapshot {
    var isEmpty: Bool {
        rows.isEmpty && income == 0 && expense == 0
    }
}

enum WidgetStore {
    static let appGroupID = "group.com.umangsurana.idiot"
    static let snapshotKey = "widgetSnapshot"

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return WidgetSnapshot()
        }
        return snapshot
    }
}

extension Double {
    var widgetCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = abs(self).truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Color {
    init(snapshotHex hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        var value: UInt64 = 0x4F8EF7
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = .init(red: r, green: g, blue: b)
    }
}
