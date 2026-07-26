# Phase 10: Spending Habits Line Chart & Final Polish

## Goal
Add a multi-month trend line chart (accessible from Settings) showing spending per category over time. Finish with final polish: error states, empty states, animations, and accessibility.

## Steps

### 1. Create `Views/TrendChartView.swift`
- Import `Charts`.
- Place this inside `SettingsView` as a navigation destination or a button that opens a sub-sheet.
- Data structure:
  ```swift
  struct MonthlyCategoryAmount: Identifiable {
    let id = UUID()
    let month: Date
    let categoryName: String
    let categoryColor: String
    let amount: Double
  }
  ```
- Fetch all transactions, group by `(yearMonth, category)`, sum amounts.
- Filter by selected categories (user can toggle which categories to show via checkboxes or a legend).
- Build a line chart:
  ```swift
  Chart(trendData) { item in
    LineMark(
      x: .value("Month", item.month, unit: .month),
      y: .value("Amount", item.amount)
    )
    .foregroundStyle(by: .value("Category", item.categoryName))
  }
  ```
- X-axis: month labels (e.g., "Jan", "Feb", ...).
- Y-axis: dollar amounts.
- Add `.chartForegroundStyleScale` for consistent colors.
- If there are fewer than 2 months of data, show a message: "Need at least 2 months of data to show trends."

### 2. Add Trend Chart Access in Settings
- In `SettingsView`, add a row/button: **"View Spending Trends"** that navigates to or presents `TrendChartView`.
- Since Settings is a sheet, the trends view could be a `NavigationStack` push or another sheet.

### 3. Empty States
- **No transactions**: When the selected month has no data, show a centered message: "No transactions yet. Tap + to add one." with a faded icon.
- **No categories**: If all categories are deleted (shouldn't happen with system categories, but handle gracefully), show a message to add categories in Settings.

### 4. Error States
- Wrap SwiftData operations in `do/try/catch` and show user-friendly error alerts.
- For chart rendering issues (rare with Swift Charts), show a generic "Could not load chart data" message.

### 5. Animations
- Add `.animation(.default, value: transactions)` on the list to animate list changes.
- Add `.chartYScale(domain:)` with animation for chart transitions when switching months.
- Use `matchedGeometryEffect` or smooth transitions for the floating "+" button.

### 6. Keyboard Shortcuts (macOS)
- `Cmd+N` — opens add transaction sheet.
- `Cmd+,` — opens Settings.
- `Cmd+F` — focus on month picker.
- Implement using `.keyboardShortcut` on buttons or via `.commands` in the SwiftUI scene.

### 7. Accessibility
- Add `accessibilityLabel` to all interactive elements.
- Add `accessibilityValue` to progress bars and chart elements.
- Ensure chart data points are accessible via `Chart`'s built-in accessibility.

### 8. Final Verification
- Run `make format` — no formatting errors.
- Run `make build` — builds with zero warnings.
- Run the app and manually test:
  - Add income and expense transactions.
  - Switch months and verify data changes.
  - Check immutability on past months.
  - Set a category limit and exceed it.
  - View bar chart and trend chart.
  - Use keyboard shortcuts.

## Implementation Guide

Implemented Phase 10 with `TrendChartView`, accessible from Settings through a "View Spending Trends" navigation row. The trend chart groups expense transactions by month and category, supports category toggles, shows empty/insufficient-data states, and uses category colors consistently. Added empty states for the transaction list and no-category form case, list/chart animations, keyboard shortcuts for new transaction (`Cmd+N`) and settings (`Cmd+,`), and accessibility labels/values on chart and budget elements.
