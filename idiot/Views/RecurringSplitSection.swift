import Charts
import SwiftUI

struct RecurringSplitSection: View {
    let committed: Double
    let discretionary: Double
    let ruleSpend: [AnalyticsEngine.RuleSpend]

    var body: some View {
        let total = committed + discretionary
        if total <= 0 {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recurring vs Discretionary")
                        .font(.headline)
                    Spacer()
                    Text("Committed \(String(format: "%.0f", committed / total * 100))% of expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GroupBox {
                    HStack(alignment: .center, spacing: 20) {
                        donut(total: total)
                            .frame(width: 140, height: 140)

                        VStack(alignment: .leading, spacing: 8) {
                            legendRow(label: "Committed", amount: committed, total: total, color: Color(hex: "#5AC8FA"))
                            legendRow(label: "Discretionary", amount: discretionary, total: total, color: .gray.opacity(0.55))
                        }

                        if !ruleSpend.isEmpty {
                            Divider()
                            topRules
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func donut(total: Double) -> some View {
        let data: [(String, Double, Color)] = [
            ("Committed", committed, Color(hex: "#5AC8FA")),
            ("Discretionary", discretionary, Color.gray.opacity(0.55)),
        ]
        return Chart(data, id: \.0) { item in
            SectorMark(
                angle: .value("Total", max(item.1, 0.0001)),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(item.2)
            .annotation(position: .overlay) {
                Text("\(String(format: "%.0f", item.1 / total * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(item.0)
            .accessibilityValue(item.1.formattedCurrency)
        }
        .help("Committed \(committed.formattedCurrency) · Discretionary \(discretionary.formattedCurrency)")
    }

    private var topRules: some View {
        let visible = Array(ruleSpend.prefix(5))
        return VStack(alignment: .leading, spacing: 6) {
            Text("Top recurring")
                .font(.callout.weight(.semibold))

            ForEach(visible) { rule in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: rule.colorHex))
                            .frame(width: 8, height: 8)
                        Text(rule.title)
                            .lineLimit(1)
                        Spacer()
                        Text(rule.total.formattedCurrency)
                            .monospacedDigit()
                            .fontWeight(.semibold)
                    }
                    Text("\(rule.count) transactions in range")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if ruleSpend.count > visible.count {
                Text("+ \(ruleSpend.count - visible.count) other rule(s)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func legendRow(label: String, amount: Double, total: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.callout)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(amount.formattedCurrency)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text("\(String(format: "%.0f", amount / total * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}
