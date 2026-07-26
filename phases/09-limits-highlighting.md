# Phase 9: Category Limits & Highlighting

## Goal
Add category budget limits with visual progress tracking, over-limit highlighting on transactions, and profit/spend tinting throughout the UI.

## Steps

### 1. Category Limit Progress in Settings
- In `SettingsView` (or `CategoryEditView`), add a progress bar for each expense category showing how much of the month's limit has been used.
- For a given month, compute `totalSpent` per category from transactions.
- Show as a `ProgressView` with percentage text: `$800 / $1,000 (80%)`.
- If over limit (≥100%), the progress bar turns red.

### 2. Over-Limit Highlighting on Rows
- In `TransactionRowView`, check if the transaction's category has exceeded its monthly limit:
  - Fetch the total spent in that category for the same month.
  - If total > limit, apply a stronger red background or a red badge to the row.
- Use `.background(overLimit ? Color.red.opacity(0.1) : Color.clear)`.

### 3. Profit/Spend Tinting
- Consistently apply:
  - Income items: `.foregroundStyle(.green)` for amount text.
  - Expense items: `.foregroundStyle(.red)` for amount text.
  - The darker/more saturated the color, the higher the amount.
- In `TransactionRowView`, bind the foreground color to the category type.

### 4. Category Totals in Summary Bar
- Enhance the summary bar (from Phase 7) to optionally show per-category totals when a chart segment is tapped (Phase 8 interop).
- Add a small label below each category section in the list showing "Category total: $X / $Y limit".

### 5. Verify Build
- Setting a limit in category settings shows the progress bar.
- Adding transactions that exceed the limit triggers red highlighting.
- Income/expense tinting is consistent across all rows.

## Implementation Guide
(To be filled after Phase 9 implementation.)
