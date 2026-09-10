import SwiftData
import SwiftUI

struct ForecastSection: View {
    let forecast: AnalyticsEngine.ForecastResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cash-Flow Forecast")
                    .font(.headline)
                Spacer()
                Text("\(forecast.daysElapsed) of \(forecast.daysInMonth) days elapsed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    projectionRow
                    committedRow

                    if !forecast.upcoming.isEmpty {
                        Divider()
                        upcomingList
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var projectionRow: some View {
        let projectedUp = forecast.projectedNet >= 0
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Projected end-of-month net")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(projectedUp ? "+" : "−")\(abs(forecast.projectedNet).formattedCurrency)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(projectedUp ? .green : .red)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Projected closing balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(forecast.projectedClosingBalance.formattedCurrency)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(forecast.projectedClosingBalance >= 0 ? Color.primary : Color.red)
            }
        }
    }

    private var committedRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Committed so far")
                    .font(.callout)
                Spacer()
                Text("\(forecast.committedSoFarNet.formattedCurrency)")
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)

            HStack {
                Text("Still committed before month end")
                    .font(.callout)
                Spacer()
                Text("+ \(abs(forecast.committedRemainingNet).formattedCurrency)")
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
        }
    }

    private var upcomingList: some View {
        let visible = Array(forecast.upcoming.prefix(4))
        return VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming recurring")
                .font(.callout.weight(.semibold))

            ForEach(visible) { occurrence in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: occurrence.colorHex))
                        .frame(width: 8, height: 8)
                    Text(occurrence.title)
                        .lineLimit(1)
                    Spacer()
                    Text(occurrence.date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(occurrence.amount < 0 ? "−" : "+")\(abs(occurrence.amount).formattedCurrency)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(occurrence.amount < 0 ? .red : .green)
                }
                .font(.caption)
            }

            if forecast.upcoming.count > visible.count {
                Text("+ \(forecast.upcoming.count - visible.count) more occurrence(s) later this month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
