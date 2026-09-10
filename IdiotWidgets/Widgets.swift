import SwiftUI
import WidgetKit

struct StaticEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StaticProvider: TimelineProvider {
    func placeholder(in _: Context) -> StaticEntry {
        StaticEntry(date: .now, snapshot: WidgetStore.load())
    }

    func getSnapshot(in _: Context, completion: @escaping (StaticEntry) -> Void) {
        completion(StaticEntry(date: .now, snapshot: WidgetStore.load()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<StaticEntry>) -> Void) {
        completion(Timeline(entries: [StaticEntry(date: .now, snapshot: WidgetStore.load())], policy: .never))
    }
}

private var widgetSurfaceBackground: some View {
    #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
            .overlay {
                LinearGradient(
                    colors: [.green.opacity(0.08), .blue.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    #else
        Color(uiColor: .systemBackground)
            .overlay {
                LinearGradient(
                    colors: [.green.opacity(0.08), .blue.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    #endif
}

struct TransactionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TransactionWidget", provider: StaticProvider()) { entry in
            TransactionWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Transactions")
        .description("Shows your balance and most recent transactions.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TransactionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StaticEntry

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumView
            } else {
                largeView
            }
        }
        .widgetURL(URL(string: "idiot://open"))
        .containerBackground(for: .widget) {
            widgetSurfaceBackground
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            balanceHeader
            Divider()
            if entry.snapshot.rows.isEmpty {
                emptyState
            } else {
                ForEach(entry.snapshot.rows.prefix(2)) { row in
                    rowView(row, compact: true)
                }
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            balanceHeader
            Divider()
            if entry.snapshot.rows.isEmpty {
                emptyState
            } else {
                ForEach(entry.snapshot.rows.prefix(5)) { row in
                    rowView(row, compact: false)
                }
            }
        }
    }

    private var balanceHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(entry.snapshot.monthLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("Balance \(entry.snapshot.balance.widgetCurrency)")
                    .font(.headline)
                    .foregroundStyle(entry.snapshot.balance >= 0 ? Color.green : Color.red)
                HStack(spacing: 6) {
                    Text("+\(entry.snapshot.income.widgetCurrency)")
                        .foregroundStyle(.green)
                    Text("−\(entry.snapshot.expense.widgetCurrency)")
                        .foregroundStyle(.red)
                }
                .font(.caption)
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("No transactions yet")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func rowView(_ row: SnapshotRow, compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.iconName)
                .font(.caption2)
                .foregroundStyle(Color(snapshotHex: row.colorHex))
                .frame(width: 18)

            Text(row.title.isEmpty ? "Untitled" : row.title)
                .font(!compact ? .callout : .caption)
                .lineLimit(1)

            Spacer()

            Text("\(row.isIncome ? "+" : "−")\(row.amount.widgetCurrency)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(row.isIncome ? Color.green : Color.red)
        }
    }
}

struct AnalyticsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AnalyticsWidget", provider: StaticProvider()) { entry in
            AnalyticsWidgetView(entry: entry)
        }
        .configurationDisplayName("Analytics")
        .description("Monthly income, expenses, net, and budget alerts.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct AnalyticsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StaticEntry

    private var snapshot: WidgetSnapshot {
        entry.snapshot
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumView
            } else {
                largeView
            }
        }
        .widgetURL(URL(string: "idiot://analytics"))
        .containerBackground(for: .widget) {
            widgetSurfaceBackground
                .overlay {
                    LinearGradient(
                        colors: [.blue.opacity(0.10), .purple.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
        }
    }

    private var mediumView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.monthLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.net.widgetCurrency)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(snapshot.net >= 0 ? Color.green : Color.red)
                Text("Net this month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(snapshot.income.widgetCurrency)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                HStack(spacing: 4) {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(snapshot.expense.widgetCurrency)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if let categoryName = snapshot.topCategoryName {
                    Text("Top: \(categoryName) \(snapshot.topCategoryAmount.widgetCurrency)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(snapshot.monthLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(snapshot.net.widgetCurrency)
                .font(.title2.weight(.bold))
                .foregroundStyle(snapshot.net >= 0 ? Color.green : Color.red)

            HStack(spacing: 12) {
                Text("+\(snapshot.income.widgetCurrency)")
                    .foregroundStyle(.green)
                Text("−\(snapshot.expense.widgetCurrency)")
                    .foregroundStyle(.red)
                Text("Balance \(snapshot.balance.widgetCurrency)")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            if snapshot.overLimitCount > 0 {
                Label("\(snapshot.overLimitCount) categorie(s) over budget", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            if snapshot.rows.isEmpty {
                Text("No transactions this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.rows.prefix(4)) { row in
                    HStack(spacing: 8) {
                        Image(systemName: row.iconName)
                            .font(.caption2)
                            .foregroundStyle(Color(snapshotHex: row.colorHex))
                        Text(row.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("\(row.isIncome ? "+" : "−")\(row.amount.widgetCurrency)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(row.isIncome ? Color.green : Color.red)
                    }
                }
            }
        }
    }
}

struct NewTransactionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NewTransactionWidget", provider: StaticProvider()) { entry in
            NewTransactionWidgetView(entry: entry)
        }
        .configurationDisplayName("New Transaction")
        .description("Tap to add a transaction in the app.")
        .supportedFamilies([.systemSmall])
    }
}

private struct NewTransactionWidgetView: View {
    let entry: StaticEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Add")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "idiot://add"))
        .accessibilityLabel("Add transaction")
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.green.opacity(0.18), .mint.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
