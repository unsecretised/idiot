# Phase 3: Settings & Category Management

## Goal
Build the Settings view — a modal sheet with a list of categories grouped by type (income / expense), allowing the user to add, edit, and delete categories.

## Steps

### 1. Create `Views/SettingsView.swift`
- A `View` that fetches all `Category` objects using `@Query(sort: \Category.sortOrder)`.
- Group categories into two sections: **Expense** and **Income** based on their `type`.
- Each row shows: color dot, icon, name, and (for expense categories) limit if set.
- Navigation: a `ToolbarItem` with "Done" button that dismisses the sheet using `@Environment(\.dismiss)`.
- A "＋" button in the toolbar to add a new category.
- Swipe-to-delete behavior:
  - If `isSystem` is `true`, show an alert: "This is a system category and cannot be deleted. You can rename it instead."
  - If `isSystem` is `false`, show a confirmation alert before deleting.

### 2. Create `Views/CategoryEditView.swift`
- A sheet/pushed view for editing a single category (or creating a new one).
- Fields:
  - `name: String` (text field)
  - `type: CategoryType` (picker: Income / Expense)
  - `limit: Double` (text field, optional — only shown for expense categories)
  - `color: Color` (grid of preset color swatches to pick from)
  - `icon: String` (a picker or list of common SF Symbols to choose from)
- Save button saves to SwiftData via `modelContext`.
- Cancel button dismisses without saving.

### 3. Connect Settings to Main App
- In `ContentView`, add a gear icon button (`Image(systemName: "gearshape")`) in the toolbar.
- Tapping it presents `SettingsView` as a sheet: `.sheet(isPresented: $showSettings)`.

### 4. Verify Build
- The sheet opens/closes correctly.
- Categories can be added, renamed, and (non-system) deleted.
- The list updates immediately via `@Query`.

## Implementation Guide
(To be filled after Phase 3 implementation.)
