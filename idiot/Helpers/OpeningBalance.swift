import Foundation

enum OpeningBalance {
    static let key = "startingAmount"

    static var amount: Double {
        UserDefaults.standard.double(forKey: key)
    }

    static func set(_ value: Double) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults(suiteName: WidgetStore.appGroupID)?.set(value, forKey: key)
    }
}
