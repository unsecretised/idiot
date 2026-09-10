import Charts
import SwiftUI

struct BalanceChartSection: View {
    let points: [AnalyticsEngine.BalancePoint]
    let openingBalance: Double

    @State private var hoveredDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Balance Over Time")
                    .font(.headline)
                Spacer()
                Text("Opening \(openingBalance.formattedCurrency)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                if points.count < 2 {
                    placeholder
                } else {
                    balanceChart
                }
            }
        }
    }

    private var placeholder: some View {
        Text("Not enough data to plot a balance curve.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }

    private var balanceChart: some View {
        let closing = points.last?.balance ?? 0
        let up = closing >= openingBalance

        return Chart {
            AreaMark(
                x: .value("Date", points.first!.date, unit: .day),
                y: .value("Balance", points.first!.balance)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [Color(hex: "#4F8EF7").opacity(0.25), Color(hex: "#4F8EF7").opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(Color(hex: "#4F8EF7"))
                .interpolationMethod(.catmullRom)
                .accessibilityLabel(point.date.formatted(style: .medium))
                .accessibilityValue(point.balance.formattedCurrency)
            }

            if let hoveredDate {
                RuleMark(x: .value("Hovered", hoveredDate))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
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
        .chartYScale(domain: yDomain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case let .active(location):
                            guard let plotRect = proxy.plotFrame else {
                                hoveredDate = nil
                                return
                            }
                            let plotFrame = geometry[plotRect]
                            let x = location.x - plotFrame.origin.x
                            let y = location.y - plotFrame.origin.y
                            if x >= 0, x <= plotFrame.width, y >= 0, y <= plotFrame.height {
                                hoveredDate = proxy.value(atX: x)
                            } else {
                                hoveredDate = nil
                            }
                        case .ended:
                            hoveredDate = nil
                        }
                    }
            }
        }
        .frame(height: 220)
        .overlay(alignment: .top) {
            if let date = hoveredDate, let point = nearestPoint(to: date) {
                Text("\(date.formatted(style: .medium)) · \(point.balance.formattedCurrency)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(.regularMaterial, in: Capsule())
                    .help("\(date.formatted(style: .medium)) · \(point.balance.formattedCurrency)")
                    .offset(y: 30)
            } else {
                Text("Closing \(closing.formattedCurrency) · \(up ? "+" : "−")\(abs(closing - openingBalance).formattedCurrency)")
                    .font(.caption)
                    .foregroundStyle(up ? .green : .red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(.quaternary.opacity(0.4), in: Capsule())
            }
        }
    }

    private func nearestPoint(to date: Date) -> AnalyticsEngine.BalancePoint? {
        let nearestIndex = points.indices.min {
            abs(points[$0].date.timeIntervalSince(date)) < abs(points[$1].date.timeIntervalSince(date))
        }
        guard let nearestIndex else { return nil }
        return points[nearestIndex]
    }

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.balance)
        let low = min(0, values.min() ?? 0)
        let high = max(0, values.max() ?? 0)
        guard high > low else {
            let pad = abs(high) * 0.2 + 1
            return (low - pad) ... (high + pad)
        }
        let pad = (high - low) * 0.1
        return (low - pad) ... (high + pad)
    }
}
