# Phase 12 — Analytics Suite Expansion

## Goal

Expand `AnalyticsView` beyond the base bar chart + breakdowns with an insight layer, deeper visualizations, forecasting, and data export — all conforming to the existing filter pipeline and cross-platform (macOS 14 / iOS 17).

## Features

1. **Insights cards** — auto-generated takeaways (savings rate, net trend, biggest category, category swings vs previous period, outlier transactions ≥3× category average, largest single expense, budget pressure).
2. **Balance over time** — cumulative running-balance line chart with opening balance from brought-forward math.
3. **Daily/weekly spend heatmap** — GitHub-style horizontal calendar (weekday rows, weeks scrolling left to right with month labels); auto-switches to weekly columns when the selected range exceeds ~210 days.
4. **Cash-flow forecast** — current-month only: discretionary daily pace + committed recurring occurrences (via `RecurringRule` frequencies) → projected end-of-month net and closing balance.
5. **Period comparison** — base month vs previous month / same month last year, per-category delta table with favorable direction coloring (income up = green, expense up = red).
6. **Recurring vs discretionary** — SectorMark donut of expense split + top recurring rules in range.
7. **Spend patterns** — spending-by-weekday bar chart + expense-size distribution histogram.
8. **Help page** (`Views/HelpView.swift`) — usage & savings guide; CSV export was built and then removed at user request (both platforms).

## Implementation Guide

### Architecture

- `Helpers/AnalyticsEngine.swift` — pure, `static` computations. Accepts pre-filtered `[Transaction]` arrays; no `@Query` inside. Exposes:
  - Totals: `incomeTotal`, `expenseTotal`, `netTotal`, `savingsRate`, `percentDelta`, `periodCount`, `broughtForward`
  - Series: `cumulativeBalanceSeries` → `[BalancePoint]`, `dailyExpenseTotals` / `weeklyExpenseTotals` → `[DailyAmount]`
  - Comparison: `categoryDeltas(current:previous:categories:)` → `[CategoryDelta]`
  - Insights: `generateInsights(...)` → `[Insight]` (tint as hex string; views map via `Color(hex:)`)
  - Forecast: `upcomingOccurrences(rules:until:after:)`, `forecast(month:monthTxs:allTx:rules:)` → `ForecastResult?`
  - Recurring: `recurringExpenseShare`, `recurringRuleSpend` → `[RuleSpend]`
  - Patterns: `spendByWeekday` → `[WeekdaySpend]` (ordered from locale `firstWeekday`), `expenseHistogram` → `[HistogramBucket]`
- Section views in `Views/`: `InsightsSection`, `BalanceChartSection`, `HeatmapSection`, `ForecastSection`, `PeriodComparisonSection` (owns its `@Query` + month/mode state), `RecurringSplitSection`, `SpendPatternsSection`.
- `AnalyticsView` feeds sections computed engine values from the filtered pipeline (`filteredTransactions`, `previousTransactions`, `categories`); forecast intentionally ignores analytics filters and uses the real current month.
- Recurring detection: `Transaction.recurringRuleID != nil`. Monthly normalization: `RecurringRule.monthlyNormalizedCost` (amount × `RecurrenceFrequency.perMonthEstimateMultiplier`).

### Integration points

- **Tabs**: the summary header, insights cards, and the main stacked bar chart are **always visible** at the top. A dropdown (menu `Picker`) in the toolbar switches the lower content (`AnalyticsTab` enum: `transactions`, `categories`, `balance`, `forecast`, `comparison`, `patterns`, each with an SF Symbol label). Contents:
  - **Transactions**: sortable transactions list with top-expense flags
  - **Categories**: category stats with progress bars
  - **Balance & Heatmap**: cumulative balance line + daily/weekly heatmap
  - **Forecast & Budgets**: end-of-month projection (placeholder when no current-month data) + budget board
  - **Comparison & Recurring**: month-vs-month delta table + committed/discretionary donut
  - **Spend Patterns**: weekday chart + expense-size histogram
- All tabs share the global filter pipeline (`filteredTransactions`, previous period) and the granularity picker.
- iOS toolbar: two stacked rows (filters + date range, then tab dropdown + granularity) so the pickers never overlap the charts at small widths; macOS keeps the single-row layout.
- Heatmap levels use p50/p90/max of nonzero totals; zero days render as neutral gray. Mac-only tooltips via `.help`; legend shows Less → More.
- Forecast math: `committedSoFarNet + committedRemainingNet + (discretionaryNetSoFar / daysElapsed) × daysInMonth`. Upcoming occurrences derive from `RecurrenceFrequency.nextDate(after:dayNumber:)` guarded by `endDate` and a loop cap.

### Conventions observed

- No comments; swiftformat via `make build`.
- Git-diff color language kept: `+`/green income, `−`/red expenses, favorable deltas green.
- Empty states use plain secondary text or placeholders; sections hide when empty (e.g. insights, recurring split, forecast).
- Period comparability: budget-pressure insight only when `granularity == .monthly`.

## Follow-up — Help & Savings Guide (`Views/HelpView.swift`)

- Static List-based page grouped into sections (Quick Start, Main Screen, one per analytics tab, a 6-step savings routine, Budgets/Categories/Subscriptions, Data/Export/Sync), each row an icon + title + actionable explanation tied to in-app insights.
- Entry points: `questionmark.circle` button in `MonthlyHeaderView` (own sheet, `Done` button on iOS) and a "Help & Savings Guide" `NavigationLink` in `SettingsView`.
