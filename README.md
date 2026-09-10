# idiot

A fully native, 100% free and open source (FOSS) finance tracker for macOS and iOS.

Track income and expenses across customizable categories, visualize spending with Swift Charts, enforce category budgets, manage recurring transactions, and sync everything privately through iCloud.

## Highlights

- **Native** — Built entirely with SwiftUI + SwiftData + Swift Charts. No Electron, no web views, no tracking.
- **FOSS** — 100% open source. No ads, no accounts, no telemetry, no data collection.
- **Income + Expense tracking** — Log both sides of your money with per-category colors and icons.
- **Budget limits** — Set monthly spending caps per expense category, with over-limit highlighting.
- **Swift Charts analytics** — Weekly stacked bar charts, multi-month trend lines, and a full analytics suite: insights, cumulative balance, daily/weekly heatmap, end-of-month forecast, month-vs-month comparison, recurring vs. discretionary spend split, and spend-pattern breakdowns (weekday chart + size histogram).
- **Recurring transactions** — Define rules (subscriptions, rent, salary) that auto-detect upcoming occurrences.
- **iCloud sync** — CloudKit-backed SwiftData sync between your Mac and iPhone.
- **Widgets** — Home screen widgets via `WidgetSnapshotWriter` snapshots.
- **Past-month immutability** — Transactions in past months are locked from editing; the current month stays fully editable.
- **Git-diff-style summary** — Monthly header shows `+$X` in green, `−$Y` in red, with bold net.

## Requirements

| | |
|---|---|
| macOS | 14.0+ |
| iOS | 17.0+ |
| Xcode | 26.5+ |
| SwiftFormat | 0.55.5 (installed automatically via `make install`) |

## Build & Run

```bash
make install   # install SwiftFormat
make build     # format + build (macOS)
make run       # format + build + launch the app
make build-ios # build for iOS Simulator (iPhone 17 Pro)
make run-ios   # build + install + launch on the simulator
make run-device DEVICE_NAME="iPhone"  # build + install on a physical iPhone
make clean     # remove build artifacts
```

## Tech Stack

- **SwiftUI** — declarative UI for both macOS and iOS
- **SwiftData** — local persistence with CloudKit (iCloud) sync
- **Swift Charts** — all visualizations
- **SwiftFormat** — enforced formatting on every build (`swiftformat .`)

## Project Structure

```
idiot/
├── Models/          # SwiftData models (Transaction, Category, RecurringRule, ...)
├── ViewModels/      # CloudSyncMonitor
├── Views/           # SwiftUI views (list, forms, charts, analytics, settings)
├── Helpers/         # Pure logic: AnalyticsEngine, RecurringEngine, formatters, extensions
└── phases/          # Development phase documents
```

## License

This project is free software: you can redistribute it and/or modify it under the terms of your choice of open source license. See [LICENSE](LICENSE) for details.
