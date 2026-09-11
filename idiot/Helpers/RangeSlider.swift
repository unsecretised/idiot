import SwiftUI

struct RangeSlider: View {
    let bounds: ClosedRange<Double>
    @Binding var low: Double
    @Binding var high: Double

    private let handleSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let span = max(bounds.upperBound - bounds.lowerBound, 1)
            let lowX = CGFloat((low - bounds.lowerBound) / span) * width
            let highX = CGFloat((high - bounds.lowerBound) / span) * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 4)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(highX - lowX, 4), height: 4)
                    .offset(x: lowX)

                thumb(x: lowX)
                    .gesture(snapGesture(width: width, span: span) { value in
                        low = min(high, value)
                    })

                thumb(x: highX)
                    .gesture(snapGesture(width: width, span: span) { value in
                        high = max(low, value)
                    })
            }
            .frame(width: geo.size.width, alignment: .leading)
        }
        .frame(height: 32)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amount range")
        .accessibilityValue("\(low.formatted(.number.precision(.fractionLength(0)))) – \(high.formatted(.number.precision(.fractionLength(0))))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                low = max(bounds.lowerBound, min(high, low + 1))
            case .decrement:
                high = max(low, min(bounds.upperBound, high - 1))
            @unknown default:
                break
            }
        }
    }

    private func snapGesture(width: CGFloat, span: Double, update: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let fraction = min(1, max(0, Double(value.location.x / width)))
                let raw = bounds.lowerBound + fraction * span
                update(raw.rounded())
            }
    }

    private func thumb(x: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .overlay(
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            )
            .offset(x: x - handleSize / 2)
    }
}

struct AmountRangeSlider: View {
    let bounds: ClosedRange<Double>
    @Binding var lowText: String
    @Binding var highText: String

    var body: some View {
        RangeSlider(
            bounds: bounds,
            low: Binding(
                get: { Double(lowText) ?? bounds.lowerBound },
                set: { lowText = $0 <= bounds.lowerBound ? "" : String(Int($0)) }
            ),
            high: Binding(
                get: { Double(highText) ?? bounds.upperBound },
                set: { highText = $0 >= bounds.upperBound ? "" : String(Int($0)) }
            )
        )
    }
}

extension ClosedRange where Bound == Double {
    /// Bounds for an amount filter slider: floor/ceil over the given amounts, or a sensible default when empty.
    static func amountBounds(for amounts: [Double]) -> ClosedRange<Double> {
        guard let min = amounts.min(), let max = amounts.max() else { return 0 ... 100 }
        return ClosedRange(uncheckedBounds: (floor(min), Swift.max(ceil(max), floor(min) + 1)))
    }
}
