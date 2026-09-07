import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    enum BreakdownTab: String, CaseIterable, Identifiable {
        case transactions
        case categories

        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .transactions: "Transactions"
            case .categories: "Categories"
            }
        }
    }

    private struct AnalyticsPoint: Identifiable {
        let id = UUID()
        let bucket: Date
        let categoryName: String
        let colorHex: String
        let type: CategoryType
        let amount: Double
    }

    private struct CategoryStat: Identifiable {
        let id: String
        let name: String
        let colorHex: String
        let iconName: String
        let type: CategoryType
        let total: Double
        let transactionCount: Int
        let avgPerTransaction: Double
        let avgPerPeriod: Double
        let percent: Double
    }

    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var fromDate = (Calendar.current.date(byAdding: .month, value: -6, to: .now) ?? .now).startOfMonth
    @State private var toDate = Date.now
    @State private var granularity: Granularity = .monthly
    @State private var showIncome = true
    @State private var showExpense = true
    @State private var minAmountText = ""
    @State private var maxAmountText = ""
    @State private var selectedCategoryIDs: Set<Category.ID> = []
    @State private var sortAscending = false
    @State private var breakdownTab: BreakdownTab = .transactions
    @State private var showFilters = false
    @State private var hoveredBucket: Date?
    @State private var hoveredLocation: CGPoint?
    @State private var chartSize: CGSize = .zero
    @State private var tooltipSize: CGSize = .zero

    private var minAmount: Double? {
        let trimmed = minAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var maxAmount: Double? {
        let trimmed = maxAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var hasActiveFilters: Bool {
        !showIncome || !showExpense || !minAmountText.isEmpty || !maxAmountText.isEmpty || !selectedCategoryIDs.isEmpty
    }

    private var rangeStart: Date {
        min(fromDate, toDate).startOfDay
    }

    private var rangeEnd: Date {
        max(fromDate, toDate).endOfDay
    }

    private var filteredTransactions: [Transaction] {
        allTransactions.filter { tx in
            guard tx.date >= rangeStart, tx.date <= rangeEnd else { return false }
            let type = tx.category?.type ?? .expense
            if type == .income, !showIncome {
                return false
            }
            if type == .expense, !showExpense {
                return false
            }
            if let minVal = minAmount, tx.amount < minVal {
                return false
            }
            if let maxVal = maxAmount, tx.amount > maxVal {
                return false
            }
            if !selectedCategoryIDs.isEmpty {
                guard let category = tx.category, selectedCategoryIDs.contains(category.id) else {
                    return false
                }
            }
            return true
        }
    }

    private var sortedTransactions: [Transaction] {
        filteredTransactions.sorted { lhs, rhs in
            if lhs.amount != rhs.amount {
                return sortAscending ? lhs.amount < rhs.amount : lhs.amount > rhs.amount
            }
            return sortAscending ? lhs.date < rhs.date : lhs.date > rhs.date
        }
    }

    private var chartData: [AnalyticsPoint] {
        Dictionary(grouping: filteredTransactions) { tx in
            BucketKey(bucket: tx.date.start(of: granularity), name: tx.category?.name ?? "Uncategorized")
        }
        .compactMap { _, txs -> AnalyticsPoint? in
            guard let first = txs.first else { return nil }
            let type = first.category?.type ?? .expense
            let total = txs.reduce(0) { $0 + $1.amount }
            return AnalyticsPoint(
                bucket: first.date.start(of: granularity),
                categoryName: first.category?.name ?? "Uncategorized",
                colorHex: first.category?.colorHex ?? "#8E8E93",
                type: type,
                amount: type == .expense ? -total : total
            )
        }
        .sorted {
            if $0.bucket != $1.bucket {
                return $0.bucket < $1.bucket
            }
            return $0.amount > $1.amount
        }
    }

    private var colorDomain: [String] {
        Array(Set(chartData.map(\.categoryName))).sorted()
    }

    private var colorRange: [Color] {
        colorDomain.map { name in
            let hex = chartData.first { $0.categoryName == name }?.colorHex ?? "#8E8E93"
            return Color(hex: hex)
        }
    }

    private var incomeTotal: Double {
        filteredTransactions.filter { ($0.category?.type ?? .expense) == .income }.reduce(0) { $0 + $1.amount }
    }

    private var expenseTotal: Double {
        filteredTransactions.filter { ($0.category?.type ?? .expense) == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netTotal: Double {
        incomeTotal - expenseTotal
    }

    private var categoryStats: [CategoryStat] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.category?.name ?? "Uncategorized" }
        let periods = periodCount
        return grouped.compactMap { name, txs -> CategoryStat? in
            guard let first = txs.first else { return nil }
            let type = first.category?.type ?? .expense
            let total = txs.reduce(0) { $0 + $1.amount }
            let typeTotal = type == .income ? incomeTotal : expenseTotal
            return CategoryStat(
                id: first.category?.id.uuidString ?? name,
                name: name,
                colorHex: first.category?.colorHex ?? "#8E8E93",
                iconName: first.category?.iconName ?? "questionmark.circle",
                type: type,
                total: total,
                transactionCount: txs.count,
                avgPerTransaction: txs.isEmpty ? 0 : total / Double(txs.count),
                avgPerPeriod: total / Double(periods),
                percent: typeTotal > 0 ? total / typeTotal * 100 : 0
            )
        }
        .sorted {
            if $0.type != $1.type {
                return $0.type == .expense
            }
            if $0.total != $1.total {
                return $0.total > $1.total
            }
            return $0.name < $1.name
        }
    }

    private var periodCount: Int {
        let component: Calendar.Component
        switch granularity {
        case .daily: component = .day
        case .weekly: component = .weekOfMonth
        case .monthly: component = .month
        case .yearly: component = .year
        }
        let difference = Calendar.current.dateComponents([component], from: rangeStart, to: rangeEnd).value(for: component) ?? 0
        return max(1, difference + 1)
    }

    private var periodSuffix: String {
        switch granularity {
        case .daily: "day"
        case .weekly: "wk"
        case .monthly: "mo"
        case .yearly: "yr"
        }
    }

    private var hoveredExpenseTotal: Double {
        hoveredDetails.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var hoveredIncomeTotal: Double {
        hoveredDetails.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var hoveredNetTotal: Double {
        hoveredIncomeTotal - hoveredExpenseTotal
    }

    private var hoveredDetails: [CategoryBreakdown] {
        guard let hoveredBucket else { return [] }
        let bucketTxs = filteredTransactions.filter { $0.date.start(of: granularity) == hoveredBucket }
        let grouped = Dictionary(grouping: bucketTxs) { $0.category?.name ?? "Uncategorized" }

        return grouped.compactMap { name, txs -> CategoryBreakdown? in
            guard let first = txs.first else { return nil }
            return CategoryBreakdown(
                categoryName: name,
                colorHex: first.category?.colorHex ?? "#8E8E93",
                amount: txs.reduce(0) { $0 + $1.amount },
                type: first.category?.type ?? .expense
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                toolbarRow
                summaryHeader
                chart
                breakdownSection
            }
            .padding()
        }
        .frame(minWidth: 780, minHeight: 640)
        .navigationTitle("Analytics")
    }

    private var toolbarRow: some View {
        HStack(spacing: 12) {
            Button {
                showFilters = true
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease")
                    .foregroundStyle(hasActiveFilters ? Color.accentColor : .primary)
            }
            .popover(isPresented: $showFilters, arrowEdge: .bottom) {
                filtersPopover
            }
            .accessibilityLabel("Filters")

            Text("\(rangeStart.formatted(style: .medium)) – \(rangeEnd.formatted(style: .medium))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Group by", selection: $granularity) {
                ForEach(Granularity.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .accessibilityLabel("Group by")
        }
    }

    private var filtersPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
                Button("Reset All") {
                    resetFilters()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.tint)
                .disabled(!hasActiveFilters)
            }

            DatePicker("From", selection: $fromDate)
            DatePicker("To", selection: $toDate)

            HStack(spacing: 12) {
                Toggle(isOn: $showIncome) {
                    Text("Income")
                        .foregroundStyle(.green)
                }
                .fixedSize()

                Toggle(isOn: $showExpense) {
                    Text("Expenses")
                        .foregroundStyle(.red)
                }
                .fixedSize()

                Spacer()

                HStack(spacing: 6) {
                    Text("Min")
                        .foregroundStyle(.secondary)
                    TextField("None", text: $minAmountText)
                        .frame(width: 70)
                    Text("Max")
                        .foregroundStyle(.secondary)
                    TextField("None", text: $maxAmountText)
                        .frame(width: 70)
                }
            }

            Divider()

            categoryToggles
        }
        .padding(16)
        .frame(width: 430)
    }

    private var summaryHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(granularity.label) view")
                    .font(.title2.weight(.semibold))
                Text("\(filteredTransactions.count) transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(netTotal.formattedCurrency)
                    .font(.title2.weight(.bold))
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("+")
                        Text(incomeTotal.formattedCurrency)
                    }
                    .foregroundStyle(.green)

                    HStack(spacing: 4) {
                        Text("−")
                        Text(expenseTotal.formattedCurrency)
                    }
                    .foregroundStyle(.red)
                }
                .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        if filteredTransactions.isEmpty {
            ContentUnavailableView(
                "No transactions in this range",
                systemImage: "chart.bar.xaxis",
                description: Text("Try widening the date range or relaxing filters.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            dataChart
        }
    }

    private var dataChart: some View {
        Chart(chartData) { item in
            BarMark(
                x: .value("Period", item.bucket, unit: granularity.calendarComponent),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(by: .value("Category", item.categoryName))
            .accessibilityLabel("\(item.categoryName), \(item.bucket.periodLabel(for: granularity))")
            .accessibilityValue(item.amount.formattedCurrency)
        }
        .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
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
                                hoveredBucket = nil
                                hoveredLocation = nil
                                return
                            }
                            let plotFrame = geometry[plotRect]
                            let x = location.x - plotFrame.origin.x
                            let y = location.y - plotFrame.origin.y
                            if x >= 0, x <= plotFrame.width, y >= 0, y <= plotFrame.height {
                                hoveredBucket = proxy.value(atX: x)
                                hoveredLocation = location
                            } else {
                                hoveredBucket = nil
                                hoveredLocation = nil
                            }
                        case .ended:
                            hoveredBucket = nil
                            hoveredLocation = nil
                        }
                    }
            }
        }
        .frame(height: 320)
        .overlay(alignment: .topLeading) {
            if let location = hoveredLocation, !hoveredDetails.isEmpty, let bucket = hoveredBucket {
                tooltip(for: bucket)
                    .offset(
                        x: tooltipOffset(location, tooltipSize: tooltipSize).x,
                        y: tooltipOffset(location, tooltipSize: tooltipSize).y
                    )
            }
        }
        .onPreferenceChange(SizePreferenceKey.self) { tooltipSize = $0 }
    }

    private func tooltip(for bucket: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bucket.periodLabel(for: granularity))
                .font(.caption.weight(.semibold))

            ForEach(hoveredDetails, id: \.categoryName) { detail in
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
                Text("Total income")
                    .foregroundStyle(.green)
                Spacer()
                Text(hoveredIncomeTotal.formattedCurrency)
                    .foregroundStyle(.green)
            }
            HStack {
                Text("Total expenses")
                    .foregroundStyle(.red)
                Spacer()
                Text(hoveredExpenseTotal.formattedCurrency)
                    .foregroundStyle(.red)
            }
            HStack {
                Text("Net")
                    .fontWeight(.bold)
                Spacer()
                Text(hoveredNetTotal.formattedCurrency)
                    .fontWeight(.bold)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .fixedSize()
        .background(GeometryReader { geo in
            Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
        })
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Breakdown", selection: $breakdownTab) {
                    ForEach(BreakdownTab.allCases) { tab in
                        Text(tab.label).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .labelsHidden()
                .accessibilityLabel("Breakdown view")

                Spacer()

                if breakdownTab == .transactions {
                    Button {
                        sortAscending.toggle()
                    } label: {
                        Label(sortAscending ? "Ascending" : "Descending", systemImage: sortAscending ? "arrow.up" : "arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .help("Toggle sort order")
                    .accessibilityLabel("Toggle sort order")
                }
            }

            GroupBox {
                switch breakdownTab {
                case .transactions:
                    transactionsList
                case .categories:
                    categoriesList
                }
            }
        }
    }

    @ViewBuilder
    private var transactionsList: some View {
        if sortedTransactions.isEmpty {
            Text("No transactions for the selected filters.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 8) {
                ForEach(sortedTransactions) { tx in
                    transactionRow(tx)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var categoriesList: some View {
        if categoryStats.isEmpty {
            Text("No data for the selected filters.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                categoryGroup("Expenses", stats: categoryStats.filter { $0.type == .expense })
                categoryGroup("Income", stats: categoryStats.filter { $0.type == .income })
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryGroup(_ title: String, stats: [CategoryStat]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(title == "Income" ? Color.green : Color.red)

            if stats.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats) { stat in
                    categoryRow(stat)
                }
            }
        }
    }

    private func categoryRow(_ stat: CategoryStat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: stat.colorHex))
                    .frame(width: 8, height: 8)

                Image(systemName: stat.iconName)
                    .frame(width: 16)
                    .foregroundStyle(Color(hex: stat.colorHex))

                Text(stat.name)
                    .lineLimit(1)

                Spacer()

                Text(stat.total.formattedCurrency)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(stat.type == .income ? .green : .red)

                Text(String(format: "%.0f%%", stat.percent))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }

            ProgressView(value: min(stat.percent, 100) / 100)
                .tint(Color(hex: stat.colorHex))

            Text("\(stat.transactionCount) transactions · \(stat.avgPerTransaction.formattedCurrency) avg/tx · \(stat.avgPerPeriod.formattedCurrency) avg/\(periodSuffix)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .help("\(String(format: "%.1f", stat.percent))% of total \(stat.type == .income ? "income" : "expenses")")
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        let type = tx.category?.type ?? .expense
        let colorHex = tx.category?.colorHex ?? "#8E8E93"
        return HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 8, height: 8)

            Image(systemName: tx.category?.iconName ?? "questionmark.circle")
                .frame(width: 16)
                .foregroundStyle(Color(hex: colorHex))

            VStack(alignment: .leading, spacing: 1) {
                Text(tx.title.isEmpty ? "Untitled" : tx.title)
                    .lineLimit(1)
                Text("\(tx.category?.name ?? "Uncategorized") · \(tx.date.formatted(style: .medium))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(type == .income ? "+" : "−")\(tx.amount.formattedCurrency)")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(type == .income ? .green : .red)
        }
        .font(.callout)
    }

    private var categoryToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Categories")
                    .font(.headline)
                Spacer()
                if !selectedCategoryIDs.isEmpty {
                    Button("Show all") {
                        selectedCategoryIDs = []
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.tint)
                }
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(categories) { category in
                    Toggle(isOn: categoryBinding(category)) {
                        Label(category.name, systemImage: category.iconName)
                            .foregroundStyle(Color(hex: category.colorHex))
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
    }

    private func categoryBinding(_ category: Category) -> Binding<Bool> {
        Binding {
            selectedCategoryIDs.isEmpty || selectedCategoryIDs.contains(category.id)
        } set: { isSelected in
            if selectedCategoryIDs.isEmpty {
                selectedCategoryIDs = Set(categories.map(\.id))
            }

            if isSelected {
                selectedCategoryIDs.insert(category.id)
            } else {
                selectedCategoryIDs.remove(category.id)
            }
        }
    }

    private func resetFilters() {
        fromDate = (Calendar.current.date(byAdding: .month, value: -6, to: .now) ?? .now).startOfMonth
        toDate = .now
        showIncome = true
        showExpense = true
        minAmountText = ""
        maxAmountText = ""
        selectedCategoryIDs = []
    }

    private func tooltipOffset(_ location: CGPoint, tooltipSize: CGSize) -> CGPoint {
        let gap: CGFloat = 12

        let fitsRight = location.x + gap + tooltipSize.width <= chartSize.width
        let offsetX = fitsRight ? location.x + gap : max(gap, location.x - tooltipSize.width - gap)

        let fitsAbove = location.y - gap >= tooltipSize.height
        let offsetY = fitsAbove ? location.y - gap - tooltipSize.height : min(chartSize.height - tooltipSize.height - gap, location.y + gap)

        return CGPoint(x: offsetX, y: max(gap, offsetY))
    }
}

private struct BucketKey: Hashable {
    let bucket: Date
    let name: String
}
