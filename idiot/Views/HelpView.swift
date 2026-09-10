import SwiftUI

struct HelpView: View {
    struct HelpRow: Identifiable {
        let id = UUID()
        let icon: String
        let tintHex: String
        let title: String
        let detail: String
    }

    struct HelpGroup: Identifiable {
        let id = UUID()
        let title: String
        let items: [HelpRow]
    }

    private static let blue = "#4F8EF7"
    private static let green = "#34C759"
    private static let orange = "#FF9500"
    private static let red = "#FF3B30"
    private static let purple = "#AF52DE"
    private static let teal = "#5AC8FA"

    private static let groups: [HelpGroup] = [
        HelpGroup(title: "Quick Start", items: [
            HelpRow(icon: "plus.circle", tintHex: blue, title: "Adding transactions", detail: "Use the floating + button (or idiot://add) to record income and expenses. Pick a category, enter an amount, and save. "
                + "Accurate, complete data is what makes every other feature useful."),
            HelpRow(icon: "lock", tintHex: orange, title: "Past months are locked", detail: "Months before the current one are read-only to protect your history. "
                + "Review them freely — edit the current month only."),
            HelpRow(icon: "calendar", tintHex: blue, title: "Navigating months", detail: "Use the arrows or the month dropdown in the header to jump between months. "
                + "Brought forward shows the balance carried into the month."),
        ]),
        HelpGroup(title: "Main Screen", items: [
            HelpRow(icon: "text.justify.left", tintHex: blue, title: "Summary bar", detail: "+ is income, − is expenses, and the bold number is your net for the month. "
                + "Below it you can see the opening (brought-forward) balance and your running balance. Aim for a positive net every month."),
            HelpRow(icon: "chart.bar.xaxis", tintHex: orange, title: "Weekly overview", detail: "Each bar is one week of the month, stacked by category. Expenses push bars down, income pulls them up. "
                + "Tall downward bars = heavy weeks. Use the zoom controls to inspect unusual weeks."),
            HelpRow(icon: "repeat", tintHex: purple, title: "Recurring ribbon", detail: "Shows how much of the month is already committed by repeating rules. High committed amounts mean less room to adjust."),
        ]),
        HelpGroup(title: "Analytics — Overview & Insights", items: [
            HelpRow(icon: "line.3.horizontal.decrease", tintHex: blue, title: "Filters", detail: "Filter by date range, granularity, income/expense, transaction size, and categories. "
                + "Everything on the page responds to the same filters."),
            HelpRow(icon: "sparkles", tintHex: purple, title: "Insights cards", detail: "Auto-generated takeaways: savings rate, net trend vs the previous period, biggest expense category, "
                + "+20%/-20% category swings, outlier purchases (3x your usual per-transaction spend), and budget pressure. "
                + "Read them first — each one is a concrete place to save."),
            HelpRow(icon: "crown", tintHex: orange, title: "Biggest expense", detail: "Your largest category share. Trimming even 10–20% off your #1 category usually beats many small cuts."),
            HelpRow(icon: "gauge", tintHex: red, title: "Budget pressure", detail: "Appears when a category's average exceeds its monthly limit. Raise the limit if it is realistic, or treat it as a cut target."),
        ]),
        HelpGroup(title: "Analytics — Transactions & Categories", items: [
            HelpRow(icon: "list.bullet.rectangle", tintHex: blue, title: "Transactions tab", detail: "Every transaction in the filtered range, sorted by amount. "
                + "The TOP badge marks your biggest expenses. Scan for one-off larger purchases you don't need to repeat."),
            HelpRow(icon: "tag.circle", tintHex: green, title: "Categories tab", detail: "Each category shows its total, share %, average per transaction, and average per period. "
                + "A high average per transaction is a sign of bulk purchases that could be planned or reduced."),
        ]),
        HelpGroup(title: "Analytics — Balance & Heatmap", items: [
            HelpRow(icon: "chart.line.uptrend.xyaxis", tintHex: blue, title: "Balance over time", detail: "Your running balance across the range. A slope downward for an extended stretch means you are consistently outspending income. "
                + "The goal is a flat-or-rising curve."),
            HelpRow(icon: "calendar.badge.exclamationmark", tintHex: orange, title: "Spend heatmap", detail: "Darker green squares are heavier spending days. Clusters show patterns like weekend splurges or end-of-month panic spending. "
                + "For longer ranges it switches to weekly squares."),
        ]),
        HelpGroup(title: "Analytics — Forecast & Budgets", items: [
            HelpRow(icon: "wand.and.stars", tintHex: purple, title: "Cash-flow forecast", detail: "Projects this month's end using your discretionary pace plus committed recurring items still due. "
                + "If the projected net is red, reduce discretionary spending now — you already know what is fixed."),
            HelpRow(icon: "gauge.with.dots.needle.50percent", tintHex: red, title: "Budget board", detail: "Average monthly spend vs each budget limit, and how many months you went over. "
                + "Anything consistently red is your best savings lever."),
        ]),
        HelpGroup(title: "Analytics — Comparison & Recurring", items: [
            HelpRow(icon: "arrow.left.arrow.right.square", tintHex: blue, title: "Period comparison", detail: "Month vs previous month or the same month last year. Items marked 'new' appeared this month; 'stopped' items vanished. "
                + "New recurring-looking items are worth auditing before they become permanent."),
            HelpRow(icon: "circle.grid.cross", tintHex: teal, title: "Recurring vs discretionary", detail: "How much of your spending is committed vs chosen. "
                + "The higher the committed slice, the harder it is to redirect money to savings — cull dormant subscriptions here."),
        ]),
        HelpGroup(title: "Analytics — Spend Patterns", items: [
            HelpRow(icon: "sun.haze", tintHex: orange, title: "Weekday chart", detail: "Which days cost you the most. If weekends dominate, try setting a light weekly spending plan."),
            HelpRow(icon: "chart.histogram", tintHex: blue, title: "Size distribution", detail: "How many transactions fall in each price bucket. A long tail of small purchases adds up; a few large ones are usually the bigger lever."),
        ]),
        HelpGroup(title: "Growing Your Savings — a simple routine", items: [
            HelpRow(icon: "target", tintHex: green, title: "1. Set targets", detail: "Open Settings and give every expense category a monthly limit that is at least 10% below last quarter's average. Limits drive the budget board and pressure insights."),
            HelpRow(icon: "eye", tintHex: green, title: "2. Weekly check-in", detail: "Open Analytics and glance at the Insights cards and Balance chart. Spending on pace for a negative net? Cut discretionary purchases immediately — forecasts give you weeks of warning."),
            HelpRow(icon: "cut", tintHex: green, title: "3. Kill the fixed waste", detail: "Each month, visit Comparison & Recurring, find rules you no longer value, and delete them in Settings > Subscriptions. Recurring cuts pay you back indefinitely."),
            HelpRow(icon: "sparkle", tintHex: green, title: "4. Attack the top category", detail: "The insights card names your biggest category. A 15% reduction there usually beats trimming five small ones."),
            HelpRow(icon: "repeat", tintHex: green, title: "5. Automate your income", detail: "Set up Auto Salary and other repeating income so your savings rate is computed without gaps, and track it from the summary header each month."),
            HelpRow(icon: "checkmark.seal", tintHex: green, title: "6. Monthly review", detail: "Run the month-vs-month comparison. Falling category costs and a rising balance curve over 2-3 months means the plan is working."),
        ]),
        HelpGroup(title: "Budgets, Categories & Subscriptions", items: [
            HelpRow(icon: "slider.horizontal.3", tintHex: blue, title: "Category limits", detail: "In Settings, edit any expense category to set a monthly limit. Over-limit spending is highlighted red throughout the app."),
            HelpRow(icon: "repeat", tintHex: purple, title: "Recurring rules", detail: "Rules auto-generate transactions on schedule (weekly/monthly/yearly). Weekly and yearly rules are normalized to a monthly cost so committed totals stay comparable."),
        ]),
        HelpGroup(title: "Data, Export & Sync", items: [
            HelpRow(icon: "icloud", tintHex: blue, title: "iCloud sync", detail: "Data syncs across your Mac and iPhone. Force a push from Settings if a device looks stale, and watch the sync status indicator."),
            HelpRow(icon: "square.grid.3x1.folder.badge.plus", tintHex: blue, title: "Widgets", detail: "Home-screen widgets show recent transactions, your analytics snapshot, and a quick Add button."),
        ]),
    ]

    var body: some View {
        List {
            Section {
                Text("Savings rate — the share of income you keep after expenses — is the single best health metric in the app. Everything below is how to move it up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Self.groups) { group in
                Section(group.title) {
                    ForEach(group.items) { row in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: row.icon)
                                .foregroundStyle(Color(hex: row.tintHex))
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.title)
                                    .font(.callout.weight(.semibold))
                                Text(row.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
        .navigationTitle("Help")
    }
}
