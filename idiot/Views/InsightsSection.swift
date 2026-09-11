import SwiftUI

struct InsightsSection: View {
    let insights: [AnalyticsEngine.Insight]

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Insights")
                            .font(.headline)
                        Text("\(insights.count)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Insights, \(insights.count) available")
                .accessibilityHint(isExpanded ? "Collapses insights" : "Expands insights")

                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(insights) { insight in
                            row(insight)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func row(_ insight: AnalyticsEngine.Insight) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.body)
                .foregroundStyle(Color(hex: insight.tintHex))
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            Text(insight.title)
                .font(.callout.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            Text(insight.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
