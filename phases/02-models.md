# Phase 2: Data Models with SwiftData

## Goal
Define the core SwiftData models (`Category`, `Transaction`, `CategoryType`), configure the `ModelContainer`, and seed the default categories on first launch.

## Steps

### 1. Create `Models/CategoryType.swift`
```swift
import Foundation

enum CategoryType: String, Codable, CaseIterable {
    case income
    case expense
}
```

### 2. Create `Models/Category.swift`
- `@Model class Category`
- Properties: `id: UUID`, `name: String`, `type: CategoryType`, `limit: Double?`, `colorHex: String`, `iconName: String`, `isSystem: Bool`, `sortOrder: Int`
- `@Attribute(.unique)` on `id`
- Default initializer with sensible defaults.

### 3. Create `Models/Transaction.swift`
- `@Model class Transaction`
- Properties: `id: UUID`, `title: String`, `desc: String?`, `amount: Double`, `date: Date`, `category: Category?`, `createdAt: Date`
- `@Attribute(.unique)` on `id`
- `@Relationship(inverse: \Category.transactions)` on `category`
- Initializer that sets `createdAt` to `Date.now` and `id` to `UUID()` by default.

### 4. Update `Category` with Inverse Relationship
Add `var transactions: [Transaction]?` to `Category` with `@Relationship(inverse: \Transaction.category)`.

### 5. Configure `ModelContainer` in `idiotApp.swift`
- Replace current `WindowGroup` with a `ModelContainer` setup.
- Use `ModelContainer(for: [Category.self, Transaction.self])`.
- Pass the `modelContext` via `.environment(\.modelContext)`.

### 6. Seed Default Categories
Create a `Models/DefaultCategories.swift` that provides a static method `seed(context: ModelContext)`:

**Expense** (all `isSystem: true`):

| Name | Icon | Color | Sort |
|------|------|-------|------|
| Business | `briefcase.fill` | Blue | 1 |
| Utilities | `bolt.fill` | Orange | 2 |
| Food | `fork.knife` | Red | 3 |
| Groceries | `basket.fill` | Green | 4 |
| Transport | `car.fill` | Yellow | 5 |
| Technology | `desktopcomputer` | Purple | 6 |
| Personal | `person.fill` | Pink | 7 |

**Income** (all `isSystem: true`):

| Name | Icon | Color | Sort |
|------|------|-------|------|
| Salary | `dollarsign.circle.fill` | Green | 1 |
| Side Hustle | `bag.fill` | Teal | 2 |

- Check `UserDefaults.standard.bool(forKey: "didSeedCategories")` before seeding.
- After seeding, set `UserDefaults.standard.set(true, forKey: "didSeedCategories")`.
- Limit is `nil` for all defaults initially.

### 7. Verify Build
- Run `make build` and ensure no compilation errors.

## Implementation Guide
(To be filled after Phase 2 implementation.)
