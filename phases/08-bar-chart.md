# Phase 8: Weekly Bar Chart (Swift Charts)

## Goal
Add a stacked vertical bar chart showing the selected month's spending broken down by week and colour-coded by category. Each bar represents one week, with stacked segments for each category.

## Steps

### 1. Create `Views/WeeklyChartView.swift`
- Import `Charts`.
- Accept `selectedMonth: Date` and the list of transactions for that month.
- Process transactions into a chart-friendly data structure:
  ```swift
  struct WeeklyCategoryAmount: Identifiable {
    let id = UUID()
    let week: Int         // 1-5
    let categoryName: String
    let categoryColor: String  // hex
    let amount: Double
  }
  ```
- For each transaction, determine its `weekOfMonth` (1-5) and accumulate amounts per week per category.

### 2. Build the Chart
- Use `Chart` with `BarMark`:
  ```swift
  Chart(weeklyData) { item in
    BarMark(
      x: .value("Week", "W\(item.week)"),
      y: .value("Amount", item.amount)
    )
    .foregroundStyle(by: .value("Category", item.categoryName))
  }
  ```
- Custom color mapping: use `.chartForegroundStyleScale` to map category names to their `colorHex`.
- X-axis: week labels ("W1", "W2", "W3", "W4", "W5" if the month spans 5 weeks).
- Y-axis: dollar amounts formatted with `NumberFormatterExtensions`.
- Chart height: ~200-250pt.

### 3. Category Color Mapping
- Create a dictionary `[String: Color]` from the categories list to map names to parsed hex colors.
- Pass this to `chartForegroundStyleScale`.

### 4. Interactive Features
- Make the chart interactive: tapping a bar segment could filter the transaction list below to show only transactions from that week (stretch goal — implement if time permits).
- Add a `.chartOverlay` or use `chartGesture` to show a tooltip on hover showing the category name and amount.

### 5. Integrate into `ContentView.swift`
- Place `WeeklyChartView` between the `SummaryBar` and `TransactionListView`.
- Pass the same `selectedMonth` and the month's transactions.

### 6. Verify Build
- Chart renders with correct weekly bars.
- Colors match category colors from settings.
- Switching months updates the chart.

## Implementation Guide
(To be filled after Phase 8 implementation.)
