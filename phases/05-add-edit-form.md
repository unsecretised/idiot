# Phase 5: Add/Edit Transaction Sheet

## Goal
Refine the transaction form from Phase 4 into a full-featured sheet that handles both adding new transactions and editing existing ones, with proper validation.

## Steps

### 1. Refactor `TransactionFormView.swift`
- Accept an optional `Transaction?` parameter. If non-nil, pre-fill the form (edit mode). If nil, create new (add mode).
- Add a `isEditing: Bool` computed property based on the transaction parameter.
- Form fields:
  - **Date**: `DatePicker` with `.field` style.
  - **Title**: `TextField` with "Title" placeholder, `@State private var title: String`.
  - **Description**: `TextField` with "Description (optional)" placeholder, `@State private var desc: String`.
  - **Amount**: `TextField` with numeric keypad / validation — format as currency on focus out.
  - **Category**: `Picker` with all categories, grouped by type if desired.
- Validation:
  - Title must not be empty — show a red border / error message.
  - Amount must be > 0.
  - Category must be selected.
- Save logic:
  - **Add mode**: Create new `Transaction`, set all properties, call `modelContext.insert(object:)`.
  - **Edit mode**: Update properties on the existing transaction.
- Dismiss on successful save (call `dismiss()`).

### 2. Update `TransactionListView.swift` to Support Edit
- In the floating "+" button, present `TransactionFormView(transaction: nil)`.
- For future context menu edit (Phase 6), we'll present `TransactionFormView(transaction: selectedTransaction)`.

### 3. Add Validation UI
- When the user taps "Save" with invalid data, show inline error messages (red text below fields) rather than an alert.
- Highlight the title field border in red if empty.

### 4. Verify Build
- Adding a new transaction works with validation.
- Editing will be tested in Phase 6 when context menu is added.
- Form dismisses correctly.

## Implementation Guide
(To be filled after Phase 5 implementation.)
