# Phase 4: Transaction List View

## Goal
Build the main transaction list showing all transactions for the selected month, with `+` / `−` prefix indicators, color-coded by income/expense, and a floating "＋" button to add new transactions.

## Steps

### 1. Create `Views/TransactionRowView.swift`
- Displays a single transaction in a `HStack`.
- Layout (left to right):
  - Prefix indicator: green `+` for income, red `−` for expense (use `Text("+")` / `Text("−")` with `.foregroundStyle(.green)` / `.foregroundStyle(.red)`).
  - Category color dot (small circle filled with category's `colorHex`).
  - Title (`.fontWeight(.medium)`)
  - Spacer
  - Amount (formatted as currency, green for income, red for expense).
  - Date (short format, e.g., "12 Jul").
- If the transaction's month is before the current month, the row is dimmed (`.opacity(0.5)`).

### 2. Create `Views/TransactionListView.swift`
- A `List` (or `ScrollView` with `LazyVStack`) that fetches `Transaction` objects for the selected month using a `@Query` with a `Predicate` filtering by date range.
- Pass in the selected month as a `@Binding` or use `@State` in the parent.
- Sort by `date` descending (most recent first).
- Each row is a `TransactionRowView`.
- Overlay a floating "＋" button at the bottom-right using `.overlay(alignment: .bottomTrailing)`.

### 3. Create `Views/TransactionFormView.swift` (Add Only — Edit Will Be Phase 5)
- For now, create a simple form for adding new transactions:
  - Date picker (defaults to today)
  - Title text field (mandatory)
  - Description text field (optional)
  - Amount text field (numeric)
  - Category picker (filtered by selected type? Or show all categories)
- Save button creates a new `Transaction` and inserts into `modelContext`.
- Dismiss on save.

### 4. Wire Up in `ContentView.swift`
- Replace the "Hello, world!" placeholder with `TransactionListView`.
- Set up a `@State selectedMonth: Date` (defaults to current month).
- Pass `selectedMonth` to `TransactionListView`.
- Placeholder for the header and chart (to be added in later phases).
- The floating "+" button presents `TransactionFormView` as a sheet.

### 5. Verify Build
- Transactions appear in the list when added.
- Income shows green `+`, expense shows red `−`.
- Rows are properly sorted by date.

## Implementation Guide
(To be filled after Phase 4 implementation.)
