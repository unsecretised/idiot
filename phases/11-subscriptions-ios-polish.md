# Phase 11 — Subscriptions, Auto Salary, Analytics Upgrades & iPhone Fixes

## Overview
- Rec recurring transactions via a new `RecurringRule` model powering **Subscriptions** (expenses) and **Auto Salary** (income). A `RecurringEngine` auto-generates real `Transaction` records on launch and after rule edits, only for dates through today (rule choice: no future pre-generation).
- Analytics gained: budget board, month-over-month deltas, savings-rate tile, biggest-expense callout with TOP badge and avg line.
- iPhone UI fixes: removed macOS-only top padding from `ContentView`; normalized `TransactionRowView` row insets/backgrounds; analytics filters now render full-width in a sheet on iOS (popover stays on macOS); toolbar controls are width-flexible.

## Data model
- `RecurringRule` (`Models/RecurringRule.swift`): `id, title, amount, frequencyRaw, dayNumber (1–28), category relationship, startDate, endDate?, isActive, lastGeneratedDate?, syncStamp`.
- `RecurrenceFrequency` enum: weekly / monthly / yearly with `nextDate(after:dayNumber:)` and a per-month cost multiplier for estimates.
- `Transaction` gained `recurringRuleID: UUID?` so generated rows link back to their rule (used for deleting history and idempotency).

## Engine
- `RecurringEngine.materialize(context:)` — idempotent; inserts a transaction per due date from the rule's start (or lastGeneratedDate) through today, skipping duplicates by (ruleID, day). Runs at app startup and after each rule save.
- `RecurringEngine.nextDueDate(for:)` — powers "Next due" labels.

## UI
- `RecurringFormView` — add/edit rules; mode `.subscription` or `.salary` (filters income/expense categories accordingly).
- `RecurringListView` — rule rows with next-due, monthly estimate footers, pause badge, delete alert with "keep past transactions" vs "delete rule + generated transactions".
- Entry points in Settings via NavigationLinks; recurring summary chip shown in WeeklyChartView header when the selected month contains recurring items.
