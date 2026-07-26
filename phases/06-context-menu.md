# Phase 6: Context Menu & Immutability

## Goal
Add right-click context menus to transaction rows with Edit, Copy, and Delete actions. Enforce immutability for past months: edit and delete are disabled for any transaction belonging to a month before the current month.

## Steps

### 1. Add Context Menu to `TransactionRowView`
- Attach `.contextMenu` modifier to the row's content.
- Menu items:
  - **Edit**: Disabled if transaction is in a past month. Opens `TransactionFormView` with the transaction pre-filled.
  - **Copy**: Always enabled. Creates a duplicate with a new `UUID`, same values but `date` set to today, `createdAt` set to now. Insert into `modelContext`.
  - **Delete**: Disabled if transaction is in a past month. Shows confirmation alert before deleting.

### 2. Immutability Check Helper
- Add a computed property / helper function:
  ```swift
  var isEditable: Bool {
    Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
  }
  ```
- Or a helper on `Transaction` (or in a ViewModel):
  ```swift
  func isInPastMonth() -> Bool {
    let calendar = Calendar.current
    let transactionMonth = calendar.dateInterval(of: .month, for: date)!
    let currentMonth = calendar.dateInterval(of: .month, for: Date())!
    return transactionMonth.end < currentMonth.start!
  }
  ```

### 3. Wire Edit Action
- When "Edit" is tapped, set a `@State editingTransaction` in `TransactionListView` and present `TransactionFormView(transaction: editingTransaction)` as a sheet.

### 4. Wire Delete Action
- Show `.alert` with "Delete Transaction?" confirmation.
- On confirm, call `modelContext.delete(transaction)`.

### 5. Visual Dimming
- In `TransactionRowView`, if `!isEditable`, apply `.opacity(0.5)` to the entire row.

### 6. Verify Build
- Right-click a transaction — all three options appear.
- Past-month transactions: Edit and Delete are greyed out or removed (use `Divider()` + conditional visibility).
- Copy creates an identical transaction with today's date.
- Delete removes the transaction after confirmation.

## Implementation Guide

Implemented Phase 6 by adding a context menu to transaction rows from `TransactionListView`. Edit opens `TransactionFormView` with the selected transaction, Copy duplicates the transaction with today's date and a fresh SwiftData object, Delete uses a confirmation alert, and both Edit/Delete are disabled for transactions whose date is in a past month. Existing row dimming continues to use the shared `Date.isInPastMonth` helper.
