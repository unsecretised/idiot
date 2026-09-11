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
    @Environment(\.modelContext) private var modelContext
    @State private var selectedWeekLabel: String?
    @State private var chartSize: CGSize = .zero
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

    private var titleBlock: some View {
        Text("Weekly Overview")
            .font(.title2.weight(.semibold))
    }

    private func summaryBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(monthlyNet.formattedCurrency)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(monthlyNet >= 0 ? Color.green : .red)
                .contentTransition(.numericText())

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
            .font(.callout.monospacedDigit())

            Text("Balance: \(totalBalance.formattedCurrency)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(balanceColor)
                .accessibilityHint("Includes \(broughtForwardBalance.formattedCurrency) brought forward")
        }
        .animation(.snappy(duration: 0.25), value: monthlyNet)
        .animation(.snappy(duration: 0.25), value: totalBalance)
    }

    // MARK: - Accessibility labels

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
        let txTotal = allTransactions
            .filter { $0.date < start }
            .reduce(0) { $0 + ($1.category?.type == .income ? $1.amount : -$1.amount) }
        return txTotal + OpeningBalance.amount
    }

    private var totalBalance: Double {
        broughtForwardBalance + monthlyNet
    }

    private var recurringTransactions: [Transaction] {
        let start = selectedMonth.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start
        return allTransactions.filter { $0.recurringRuleID != nil && $0.date >= start && $0.date < end }
    }

    private var recurringCount: Int {
        recurringTransactions.count
    }

    private var recurringExpense: Double {
        recurringTransactions.filter { $0.category?.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var recurringIncome: Double {
        recurringTransactions.filter { $0.category?.type == .income }.reduce(0) { $0 + $1.amount }
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

    private var selectedExpensesTotal: Double {
        selectedWeekDetails.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var selectedIncomeTotal: Double {
        selectedWeekDetails.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var selectedNetTotal: Double {
        selectedIncomeTotal - selectedExpensesTotal
    }

    private var selectedWeekNumber: Int? {
        guard let selectedWeekLabel else { return nil }
        return weeklyData.first(where: { $0.weekLabel == selectedWeekLabel })?.week
    }

    private var selectedWeekDetails: [CategoryBreakdown] {
        guard let week = selectedWeekNumber else { return [] }
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: 16)
                    summaryBlock(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 8) {
                    titleBlock
                    summaryBlock(alignment: .leading)
                }
            }

            if recurringCount > 0 {
                Text([
                    "\(recurringCount) recurring",
                    recurringExpense > 0 ? "−\(recurringExpense.formattedCurrency)" : nil,
                    recurringIncome > 0 ? "+\(recurringIncome.formattedCurrency)" : nil,
                ]
                .compactMap { $0 }
                .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        .onTapGesture(coordinateSpace: .local) { location in
                            guard let plotRect = proxy.plotFrame else { return }
                            let plotFrame = geometry[plotRect]
                            let point = CGPoint(
                                x: location.x - plotFrame.origin.x,
                                y: location.y - plotFrame.origin.y
                            )
                            guard point.x >= 0, point.x <= plotFrame.width, point.y >= 0, point.y <= plotFrame.height else {
                                selectedWeekLabel = nil
                                return
                            }
                            if let label: String = proxy.value(atX: point.x) {
                                selectedWeekLabel = selectedWeekLabel == label ? nil : label
                            } else {
                                selectedWeekLabel = nil
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
            #endif

            if selectedWeekNumber != nil, !selectedWeekDetails.isEmpty,
               let label = selectedWeekLabel
            {
                weekDetailCard(label)
            }
        }
        .animation(.snappy(duration: 0.25), value: selectedWeekLabel)
        .padding(16)
        #if os(macOS)
            .background(
                Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        #else
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        #endif
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .onAppear {
                WidgetSnapshotWriter.write(context: modelContext)
            }
            .onChange(of: allTransactions) {
                WidgetSnapshotWriter.write(context: modelContext)
            }
    }

    private func weekDetailCard(_ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                Button {
                    selectedWeekLabel = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                        .frame(minWidth: 20, minHeight: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close detailed view")
            }

            ForEach(selectedWeekDetails, id: \.categoryName) { detail in
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
            if selectedExpensesTotal > 0 {
                HStack {
                    Text("Expenses").font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Text(selectedExpensesTotal.formattedCurrency)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            if selectedIncomeTotal > 0 {
                HStack {
                    Text("Income").font(.caption)
                        .foregroundStyle(.green)
                    Spacer()
                    Text(selectedIncomeTotal.formattedCurrency)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            HStack {
                Text("Net").font(.caption.weight(.bold))
                Spacer()
                Text(selectedNetTotal.formattedCurrency)
                    .font(.caption.weight(.bold))
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
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
