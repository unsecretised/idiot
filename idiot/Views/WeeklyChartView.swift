import Charts
import SwiftData
import SwiftUI

struct WeeklyChartView: View {
    let selectedMonth: Date
    let hiddenCategoryIDs: Set<Category.ID>
    let minAmount: Double?
    let maxAmount: Double?
    let showIncome: Bool
    let showExpense: Bool

    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @State private var hoveredWeekLabel: String?
    @State private var hoveredLocation: CGPoint?
    @State private var chartSize: CGSize = .zero
    @State private var tooltipSize: CGSize = .zero
    @State private var yZoom: CGFloat = 1.0
    @State private var yPan: Double = 0.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var lastPan: Double = 0.0

    private var transactions: [Transaction] {
        let start = selectedMonth.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? selectedMonth.endOfMonth
        return allTransactions.filter { tx in
            guard tx.date >= start, tx.date < end else { return false }
            if let cat = tx.category {
                if hiddenCategoryIDs.contains(cat.id) {
                    return false
                }
                if !showIncome, cat.type == .income {
                    return false
                }
                if !showExpense, cat.type == .expense {
                    return false
                }
            }
            if let minVal = minAmount, tx.amount < minVal {
                return false
            }
            if let maxVal = maxAmount, tx.amount > maxVal {
                return false
            }
            return true
        }
    }

    private var weeklyData: [WeeklyCategoryAmount] {
        let weekRange = Calendar.current.range(of: .weekOfMonth, in: .month, for: selectedMonth) ?? 1 ..< 1
        var result: [WeeklyCategoryAmount] = []

        for week in weekRange {
            let weekTxs = transactions.filter { $0.date.weekOfMonth == week }
            let label = Date.weekDateRangeLabel(weekNumber: week, in: selectedMonth)
            let grouped = Dictionary(grouping: weekTxs) { $0.category?.name ?? "Uncategorized" }

            for (name, txs) in grouped {
                guard let category = txs.first?.category else { continue }
                let amount = txs.reduce(0) { $0 + $1.amount }
                result.append(WeeklyCategoryAmount(
                    week: week,
                    weekLabel: label,
                    categoryName: name,
                    categoryColor: category.colorHex,
                    amount: category.type == .expense ? amount : -amount
                ))
            }
        }

        return result.sorted {
            if $0.week != $1.week {
                return $0.week < $1.week
            }
            if $0.amount >= 0, $1.amount < 0 {
                return true
            }
            if $0.amount < 0, $1.amount >= 0 {
                return false
            }
            if $0.amount < 0, $1.amount < 0 {
                return $0.amount < $1.amount
            }
            return $0.amount > $1.amount
        }
    }

    private var colorDomain: [String] {
        Array(Set(weeklyData.map(\.categoryName))).sorted()
    }

    private var colorRange: [Color] {
        colorDomain.map { name in
            let hex = weeklyData.first { $0.categoryName == name }?.categoryColor ?? "#8E8E93"
            return Color(hex: hex)
        }
    }

    private var maxAbsoluteAmount: Double {
        let positive = Dictionary(grouping: weeklyData.filter { $0.amount > 0 }, by: \.week)
            .mapValues { items in items.reduce(0) { $0 + $1.amount } }
        let negative = Dictionary(grouping: weeklyData.filter { $0.amount < 0 }, by: \.week)
            .mapValues { items in abs(items.reduce(0) { $0 + $1.amount }) }
        let maxVal = max(positive.values.max() ?? 0, negative.values.max() ?? 0)
        guard maxVal > 0 else { return 1 }
        return maxVal * 1.15
    }

    private var yAxisDomain: ClosedRange<Double> {
        let range = maxAbsoluteAmount / Double(yZoom)
        return (-range + yPan) ... (range + yPan)
    }

    private var monthlyIncome: Double {
        transactions.filter { $0.category?.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyExpenses: Double {
        transactions.filter { $0.category?.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyNet: Double {
        monthlyIncome - monthlyExpenses
    }

    private var broughtForwardBalance: Double {
        let start = selectedMonth.startOfMonth
        return allTransactions
            .filter { $0.date < start }
            .reduce(0) { $0 + ($1.category?.type == .income ? $1.amount : -$1.amount) }
    }

    private var totalBalance: Double {
        broughtForwardBalance + monthlyNet
    }

    private var balanceColor: Color {
        if totalBalance > 0 {
            return .green
        }

        if totalBalance < 0 {
            return .red
        }

        return .primary
    }

    private var hoveredExpensesTotal: Double {
        hoveredWeekDetails.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var hoveredIncomeTotal: Double {
        hoveredWeekDetails.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var hoveredNetTotal: Double {
        hoveredIncomeTotal - hoveredExpensesTotal
    }

    private var hoveredWeekNumber: Int? {
        guard let hoveredWeekLabel else { return nil }
        return weeklyData.first(where: { $0.weekLabel == hoveredWeekLabel })?.week
    }

    private var hoveredWeekDetails: [CategoryBreakdown] {
        guard let week = hoveredWeekNumber else { return [] }
        let weekTxs = transactions.filter { $0.date.weekOfMonth == week }
        let grouped = Dictionary(grouping: weekTxs) { $0.category?.name ?? "Uncategorized" }

        return grouped.compactMap { name, txs in
            guard let category = txs.first?.category else { return nil }
            return CategoryBreakdown(
                categoryName: name,
                colorHex: category.colorHex,
                amount: txs.reduce(0) { $0 + $1.amount },
                type: category.type
            )
        }
        .sorted { lhs, rhs in
            if lhs.type != rhs.type {
                return lhs.type == .expense
            }
            if lhs.type == .expense {
                return lhs.amount > rhs.amount
            }
            return lhs.amount < rhs.amount
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Weekly Overview")
                    .font(.title2.weight(.semibold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(monthlyNet.formattedCurrency)
                        .font(.title2.weight(.bold))
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("+")
                                .foregroundStyle(.green)
                            Text(monthlyIncome.formattedCurrency)
                                .foregroundStyle(.green)
                        }
                        HStack(spacing: 4) {
                            Text("−")
                                .foregroundStyle(.red)
                            Text(monthlyExpenses.formattedCurrency)
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.callout)

                    HStack(spacing: 4) {
                        Text("Brought forward:")
                            .foregroundStyle(.secondary)
                        Text(broughtForwardBalance.formattedCurrency)
                    }
                    .font(.caption)

                    HStack(spacing: 4) {
                        Text("Balance:")
                            .foregroundStyle(.secondary)
                        Text(totalBalance.formattedCurrency)
                            .foregroundStyle(balanceColor)
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            Chart(weeklyData) { item in
                BarMark(
                    x: .value("Week", item.weekLabel),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(by: .value("Category", item.categoryName))
                .accessibilityLabel("\(item.categoryName), week \(item.week)")
                .accessibilityValue(item.amount.formattedCurrency)
            }
            .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
            .chartYScale(domain: yAxisDomain)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(abs(amount).formattedCurrency)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onAppear { chartSize = geometry.size }
                        .onChange(of: geometry.size) { chartSize = $1 }
                        .onContinuousHover { phase in
                            switch phase {
                            case let .active(location):
                                guard let plotRect = proxy.plotFrame else {
                                    hoveredWeekLabel = nil
                                    hoveredLocation = nil
                                    return
                                }
                                let plotFrame = geometry[plotRect]
                                let x = location.x - plotFrame.origin.x
                                let y = location.y - plotFrame.origin.y
                                if x >= 0, x <= plotFrame.width, y >= 0, y <= plotFrame.height {
                                    if let weekLabel: String = proxy.value(atX: x) {
                                        hoveredWeekLabel = weekLabel
                                    } else {
                                        hoveredWeekLabel = nil
                                    }
                                    hoveredLocation = location
                                } else {
                                    hoveredWeekLabel = nil
                                    hoveredLocation = nil
                                }
                            case .ended:
                                hoveredWeekLabel = nil
                                hoveredLocation = nil
                            }
                        }
                }
            }
            .frame(height: 320)
            .clipped()
            #if os(macOS)
                .background(ScrollWheelHandler { delta in
                    let factor = exp(delta * 0.02)
                    yZoom = max(1.0, yZoom * factor)
                    lastZoom = yZoom
                })
            #endif
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            yZoom = max(1.0, lastZoom * value)
                        }
                        .onEnded { _ in
                            lastZoom = yZoom
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            let range = maxAbsoluteAmount / Double(yZoom)
                            let chartH = max(chartSize.height, 320)
                            yPan = lastPan - Double(value.translation.height) / Double(chartH) * 2 * range
                        }
                        .onEnded { _ in
                            lastPan = yPan
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded { resetYZoom() }
                )
                .overlay(alignment: .topTrailing) {
                    if yZoom > 1.01 || abs(yPan) > 0.01 {
                        Button {
                            resetYZoom()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(6)
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Reset zoom")
                        .padding(6)
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let location = hoveredLocation, !hoveredWeekDetails.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hoveredWeekLabel ?? "")
                                .font(.caption.weight(.semibold))
                            ForEach(hoveredWeekDetails, id: \.categoryName) { detail in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: detail.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(detail.categoryName)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(detail.amount.formattedCurrency)
                                        .fontWeight(.semibold)
                                }
                                .font(.caption)
                            }

                            Divider()
                            HStack {
                                Text("Total expenses")
                                    .foregroundStyle(.red)
                                Spacer()
                                Text(hoveredExpensesTotal.formattedCurrency)
                                    .foregroundStyle(.red)
                            }
                            HStack {
                                Text("Total income")
                                    .foregroundStyle(.green)
                                Spacer()
                                Text(hoveredIncomeTotal.formattedCurrency)
                                    .foregroundStyle(.green)
                            }
                            HStack {
                                Text("Net")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(hoveredNetTotal.formattedCurrency)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .fixedSize()
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
                        })
                        .offset(
                            x: tooltipOffset(location, tooltipSize: tooltipSize).x,
                            y: tooltipOffset(location, tooltipSize: tooltipSize).y
                        )
                    }
                }
                .onPreferenceChange(SizePreferenceKey.self) { tooltipSize = $0 }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private func tooltipOffset(_ location: CGPoint, tooltipSize: CGSize) -> CGPoint {
        let gap: CGFloat = 12

        let fitsRight = location.x + gap + tooltipSize.width <= chartSize.width
        let offsetX = fitsRight ? location.x + gap : max(gap, location.x - tooltipSize.width - gap)

        let fitsAbove = location.y - gap >= tooltipSize.height
        let offsetY = fitsAbove ? location.y - gap - tooltipSize.height : min(chartSize.height - tooltipSize.height - gap, location.y + gap)

        return CGPoint(x: offsetX, y: max(gap, offsetY))
    }

    private func resetYZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            yZoom = 1.0
            yPan = 0.0
            lastZoom = 1.0
            lastPan = 0.0
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct WeeklyCategoryAmount: Identifiable {
    let id = UUID()
    let week: Int
    let weekLabel: String
    let categoryName: String
    let categoryColor: String
    let amount: Double
}

struct CategoryBreakdown {
    let categoryName: String
    let colorHex: String
    let amount: Double
    let type: CategoryType
}

#if os(macOS)
    struct ScrollWheelHandler: NSViewRepresentable {
        let onScroll: (CGFloat) -> Void

        func makeNSView(context _: Context) -> NSView {
            let view = _ScrollWheelView()
            view.onScroll = onScroll
            return view
        }

        func updateNSView(_ nsView: NSView, context _: Context) {
            (nsView as? _ScrollWheelView)?.onScroll = onScroll
        }
    }

    final class _ScrollWheelView: NSView {
        var onScroll: ((CGFloat) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            wantsRestingTouches = true
        }

        override func scrollWheel(with event: NSEvent) {
            onScroll?(event.scrollingDeltaY)
        }
    }
#endif
