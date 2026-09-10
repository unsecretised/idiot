import SwiftData
import SwiftUI

struct PeriodComparisonSection: View {
    enum ComparisonMode: String, CaseIterable, Identifiable {
        case previousMonth
        case sameMonthLastYear

        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .previousMonth: "Previous month"
            case .sameMonthLastYear: "Same month last year"
            }
        }
    }

    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var baseMonth = Date.now.startOfMonth
    @State private var comparisonMode: ComparisonMode = .previousMonth

    private var baseStart: Date {
        baseMonth.startOfMonth
    }

    private var baseEnd: Date {
        baseMonth.endOfMonth
    }

    private var comparisonMonth: Date {
        switch comparisonMode {
        case .previousMonth:
            Calendar.current.date(byAdding: .month, value: -1, to: baseStart) ?? baseStart
        case .sameMonthLastYear:
            Calendar.current.date(byAdding: .year, value: -1, to: baseStart) ?? baseStart
        }
    }

    private var currentTxs: [Transaction] {
        allTransactions.filter { $0.date >= baseStart && $0.date <= baseEnd }
    }

    private var comparisonTxs: [Transaction] {
        let start = comparisonMonth.startOfMonth
        let end = comparisonMonth.endOfMonth
        return allTransactions.filter { $0.date >= start && $0.date <= end }
    }

    private var deltas: [AnalyticsEngine.CategoryDelta] {
        AnalyticsEngine.categoryDeltas(current: currentTxs, previous: comparisonTxs, categories: categories)
    }

    private var currentNet: Double {
        AnalyticsEngine.netTotal(currentTxs)
    }

    private var comparisonNet: Double {
        AnalyticsEngine.netTotal(comparisonTxs)
    }

    private var netDelta: Double? {
        AnalyticsEngine.percentDelta(current: currentNet, previous: comparisonNet)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                DatePicker(
                    "Month",
                    selection: $baseMonth,
                    displayedComponents: .date
                )
                .labelsHidden()

                Picker("Compare with", selection: $comparisonMode) {
                    ForEach(ComparisonMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)

                Spacer()
            }

            comparisonSummary

            GroupBox {
                comparisonRows
            }
        }
    }

    private var comparisonSummary: some View {
        HStack(spacing: 14) {
            Text("\(baseMonth.formatted(.dateTime.month(.abbreviated).year())) net \(currentNet.formattedCurrency)")
            Text("vs")
                .foregroundStyle(.secondary)
            Text("\(comparisonMonth.formatted(.dateTime.month(.abbreviated).year())) net \(comparisonNet.formattedCurrency)")

            if let delta = netDelta {
                let improved = delta > 0
                HStack(spacing: 3) {
                    Image(systemName: improved ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text("\(String(format: "%.0f", abs(delta)))%")
                }
                .foregroundStyle(improved ? .green : .red)
                .help("Net change vs \(comparisonMonth.formatted(.dateTime.month(.abbreviated).year()))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    @ViewBuilder
    private var comparisonRows: some View {
        let expense = deltas.filter { $0.type == .expense }
        let income = deltas.filter { $0.type == .income }
        if expense.isEmpty && income.isEmpty {
            Text("No activity in either month.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                comparisonGroup("Expenses", deltas: expense)
                comparisonGroup("Income", deltas: income)
            }
            .padding(.vertical, 2)
        }
    }

    private func comparisonGroup(_ title: String, deltas: [AnalyticsEngine.CategoryDelta]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(title == "Income" ? Color.green : Color.red)

            ForEach(deltas) { delta in
                comparisonRow(delta)
            }
        }
    }

    private func comparisonRow(_ delta: AnalyticsEngine.CategoryDelta) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: delta.colorHex))
                .frame(width: 8, height: 8)

            Image(systemName: delta.iconName)
                .frame(width: 16)
                .foregroundStyle(Color(hex: delta.colorHex))

            Text(delta.name)
                .lineLimit(1)

            if delta.previous == 0, delta.current > 0 {
                Text("new")
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.green.opacity(0.2), in: Capsule())
                    .foregroundStyle(.green)
            } else if delta.current == 0 {
                Text("stopped")
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary.opacity(0.5), in: Capsule())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(delta.previous.formattedCurrency)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Text("→")
                .foregroundStyle(.secondary.opacity(0.6))

            Text(delta.current.formattedCurrency)
                .monospacedDigit()
                .fontWeight(.semibold)

            if let percent = delta.percent, percent.isFinite {
                deltaBadge(percent: percent, type: delta.type)
            }
        }
        .font(.callout)
    }

    @ViewBuilder
    private func deltaBadge(percent: Double, type: CategoryType) -> some View {
        let up = percent > 0
        let favorable = type == .income ? up : !up
        Text("\(up ? "+" : "−")\(String(format: "%.0f", abs(percent)))%")
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(favorable ? .green : .red)
            .frame(width: 52, alignment: .trailing)
    }
}
