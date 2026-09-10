import Charts
import SwiftUI

struct SpendPatternsSection: View {
    let weekdaySpend: [AnalyticsEngine.WeekdaySpend]
    let histogram: [AnalyticsEngine.HistogramBucket]
    let periodSuffix: String

    @State private var hoveredWeekday: String?
    @State private var hoveredBucket: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spend Patterns")
                .font(.headline)

            #if os(macOS)
                HStack(alignment: .top, spacing: 12) {
                    weekdayChart
                    histogramChart
                }
            #else
                weekdayChart
                histogramChart
            #endif
        }
    }

    @ViewBuilder
    private var weekdayChart: some View {
        let maxAmount = weekdaySpend.map(\.amount).max() ?? 0
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("Spending by weekday")
                    .font(.subheadline.weight(.semibold))

                if maxAmount <= 0 {
                    Text("No expense data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)
                } else {
                    Chart(weekdaySpend) { item in
                        BarMark(
                            x: .value("Weekday", item.label),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(Color(hex: "#FF9500"))
                        .cornerRadius(3)
                        .accessibilityLabel(item.label)
                        .accessibilityValue(item.amount.formattedCurrency)
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(amount.formattedCurrency)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                }
                            }
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onContinuousHover { phase in
                                    let value = hoverValue(at: phase, proxy: proxy, geometry: geometry)
                                    hoveredWeekday = value
                                }
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if let label = hoveredWeekday, let item = weekdaySpend.first(where: { $0.label == label }) {
                            Text("\(item.label) · \(item.amount.formattedCurrency)")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(.regularMaterial, in: Capsule())
                                .padding(4)
                        }
                    }
                    .frame(height: 170)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var histogramChart: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("Expense size distribution")
                    .font(.subheadline.weight(.semibold))

                if histogram.isEmpty {
                    Text("No expense data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)
                } else {
                    Chart(histogram) { bucket in
                        BarMark(
                            x: .value("Bucket", bucket.label),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(Color(hex: "#4F8EF7"))
                        .cornerRadius(3)
                        .accessibilityLabel(bucket.label)
                        .accessibilityValue("\(bucket.count) transactions, \(bucket.total.formattedCurrency)")
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.caption2)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onContinuousHover { phase in
                                    let value = hoverValue(at: phase, proxy: proxy, geometry: geometry)
                                    hoveredBucket = value
                                }
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if let label = hoveredBucket, let bucket = histogram.first(where: { $0.label == label }) {
                            Text("\(bucket.label) · \(bucket.count) transactions")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(.regularMaterial, in: Capsule())
                                .padding(4)
                        }
                    }
                    .frame(height: 150)

                    Text("Number of transactions per size bucket")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func hoverValue(at phase: HoverPhase, proxy: ChartProxy, geometry: GeometryProxy) -> String? {
        switch phase {
        case let .active(location):
            guard let plotRect = proxy.plotFrame else { return nil }
            let plotFrame = geometry[plotRect]
            let x = location.x - plotFrame.origin.x
            let y = location.y - plotFrame.origin.y
            guard x >= 0, x <= plotFrame.width, y >= 0, y <= plotFrame.height else { return nil }
            return proxy.value(atX: x)
        case .ended:
            return nil
        }
    }
}
