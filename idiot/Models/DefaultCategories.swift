import Foundation
import SwiftData

enum DefaultCategories {
    private static let didSeedKey = "didSeedCategories"

    static func seed(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didSeedKey) else {
            return
        }

        let categories = [
            Category(name: "Business", type: .expense, colorHex: "#4F8EF7", iconName: "briefcase.fill", isSystem: true, sortOrder: 1),
            Category(name: "Utilities", type: .expense, colorHex: "#FF9500", iconName: "bolt.fill", isSystem: true, sortOrder: 2),
            Category(name: "Food", type: .expense, colorHex: "#FF3B30", iconName: "fork.knife", isSystem: true, sortOrder: 3),
            Category(name: "Groceries", type: .expense, colorHex: "#34C759", iconName: "basket.fill", isSystem: true, sortOrder: 4),
            Category(name: "Transport", type: .expense, colorHex: "#FFCC00", iconName: "car.fill", isSystem: true, sortOrder: 5),
            Category(name: "Technology", type: .expense, colorHex: "#AF52DE", iconName: "desktopcomputer", isSystem: true, sortOrder: 6),
            Category(name: "Personal", type: .expense, colorHex: "#FF2D55", iconName: "person.fill", isSystem: true, sortOrder: 7),
            Category(name: "Salary", type: .income, colorHex: "#34C759", iconName: "dollarsign.circle.fill", isSystem: true, sortOrder: 1),
            Category(name: "Side Hustle", type: .income, colorHex: "#5AC8FA", iconName: "bag.fill", isSystem: true, sortOrder: 2),
        ]

        categories.forEach(context.insert)

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: didSeedKey)
        } catch {
            assertionFailure("Failed to seed default categories: \(error.localizedDescription)")
        }
    }
}
