# Phase 7: Month Selector & Header Bar

## Goal
Build the top header area: a month/year picker on the left, a settings gear icon on the right, and a summary bar showing income vs expenses (git diff style: `+$X` green, `−$Y` red, net bold).

## Steps

### 1. Create `Views/MonthlyHeaderView.swift`
- A horizontal bar (`HStack`) containing:
  - **Left**: A `Picker` with `Menu` style showing month/year options.
    - Populate with the last 12 months (or dynamically from available transactions).
    - Label displays the selected month: e.g., "July 2026".
    - Changing the picker updates the bound `selectedMonth` date.
  - **Right**: A gear icon button (`Image(systemName: "gearshape")`) that opens `SettingsView` as a sheet.

### 2. Calculate Summary Stats
- Compute for the selected month:
  - `totalIncome: Double` — sum of all transactions whose category type is `.income`.
  - `totalExpense: Double` — sum of all transactions whose category type is `.expense`.
  - `netTotal: Double` = `totalIncome - totalExpense`.
- Use a helper method or a lightweight ViewModel that performs these calculations from the fetched transactions.

### 3. Create Summary Bar UI
- Below the header, a `HStack` showing:
  - `+$X,XXX.XX` in green (income total)
  - `−$Y,YYY.YY` in red (expense total)
  - Net total in bold: green if positive, red if negative, default text color if zero.
- Style: monospace numbers, git-diff inspired look.
- Example layout:
  ```
  +$5,200.00  −$3,450.00  = +$1,750.00
  ```

### 4. Integrate into `ContentView.swift`
- Replace the current placeholder with:
  ```
  VStack(spacing: 0) {
    MonthlyHeaderView(selectedMonth: $selectedMonth, showSettings: $showSettings)
    SummaryBar(month: selectedMonth)
    ...
  }
  ```
- `TransactionListView` now filters by `selectedMonth` using a `Predicate` on `date` within the month's range.
- The floating "+" button should create transactions with the `selectedMonth`'s context (though actual date is user-chosen in the form).

### 5. Update TransactionListView
- Accept `selectedMonth: Date` as a parameter.
- Filter `@Query` using a `Predicate` that checks `date >= month.start && date < month.nextMonth.start`.

### 6. Verify Build
- Month picker works and list updates.
- Summary numbers update when switching months.
- Settings gear opens the sheet.

## Implementation Guide

Implemented Phase 7 with `MonthlyHeaderView` and `SummaryBarView`. The main screen now has a top month picker populated with the last 12 months, a settings gear that opens `SettingsView`, and a git-diff-style monthly summary showing income, expense, and net totals from SwiftData transactions filtered to the selected month.
