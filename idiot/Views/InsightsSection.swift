import SwiftUI

struct InsightsSection: View {
    let insights: [AnalyticsEngine.Insight]

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Insights")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 250, maximum: 420), alignment: .topLeading)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(insights) { insight in
                        card(insight)
                    }
                }
            }
        }
    }

    private func card(_ insight: AnalyticsEngine.Insight) -> some View {
        let tint = Color(hex: insight.tintHex)
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.icon)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
