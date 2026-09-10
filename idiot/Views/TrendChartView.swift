import Charts
import SwiftData
import SwiftUI

struct TrendChartView: View {
    @Query private var transactions: [Transaction]
    @State private var selectedCategories = Set<UUID>()
    @State private var hoveredMonth: Date?

    private var expenseCategories: [Category] {
        let categories = transactions.compactMap(\.category).filter { $0.type == .expense }
        return Dictionary(grouping: categories, by: \.id)
            .compactMap { _, categories in categories.first }
            .sorted { $0.name < $1.name }
    }

    private var trendData: [MonthlyCategoryAmount] {
        let visibleCategoryIDs = selectedCategories.isEmpty ? Set(expenseCategories.map(\.id)) : selectedCategories
        let expenseTransactions = transactions.filter {
            guard let category = $0.category else {
                return false
            }

            return category.type == .expense && visibleCategoryIDs.contains(category.id)
        }

        let grouped = Dictionary(grouping: expenseTransactions) { transaction in
            "\(transaction.date.startOfMonth.timeIntervalSince1970)-\(transaction.category?.id.uuidString ?? "")"
        }

        return grouped.compactMap { _, transactions in
            guard let first = transactions.first, let category = first.category else {
                return nil
            }

            return MonthlyCategoryAmount(
                month: first.date.startOfMonth,
                categoryName: category.name,
                categoryColor: category.colorHex,
                amount: transactions.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.month < $1.month }
    }

    private var monthCount: Int {
        Set(trendData.map(\.month)).count
    }

    private var colorDomain: [String] {
        Array(Set(trendData.map(\.categoryName))).sorted()
    }

    private var colorRange: [Color] {
        colorDomain.map { categoryName in
            let hex = trendData.first { $0.categoryName == categoryName }?.categoryColor ?? "#8E8E93"
            return Color(hex: hex)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if expenseCategories.isEmpty {
                ContentUnavailableView("No spending categories yet", systemImage: "chart.line.uptrend.xyaxis")
            } else if monthCount < 2 {
                ContentUnavailableView("Need at least 2 months of data to show trends", systemImage: "chart.line.uptrend.xyaxis")
            } else {
                Chart {
                    ForEach(trendData) { item in
                        LineMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(by: .value("Category", item.categoryName))
                        .symbol(by: .value("Category", item.categoryName))
                        .accessibilityLabel("\(item.categoryName), \(item.month.formatted(.dateTime.month(.wide).year()))")
                        .accessibilityValue(item.amount.formattedCurrency)
                    }

                    if let hoveredMonth {
                        RuleMark(x: .value("Hovered", hoveredMonth, unit: .month))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                }
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
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
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case let .active(location):
                                    guard let plotRect = proxy.plotFrame else {
                                        hoveredMonth = nil
                                        return
                                    }
                                    let plotFrame = geometry[plotRect]
                                    let x = location.x - plotFrame.origin.x
                                    if x >= 0, x <= plotFrame.width, let month: Date = proxy.value(atX: x) {
                                        hoveredMonth = month.startOfMonth
                                    } else {
                                        hoveredMonth = nil
                                    }
                                case .ended:
                                    hoveredMonth = nil
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let month = hoveredMonth {
                        monthTooltip(month)
                            .padding(4)
                    }
                }
                .frame(height: 280)
                .animation(.default, value: trendData.count)
            }

            if !expenseCategories.isEmpty {
                categoryToggles
            }
        }
        .padding()
        .navigationTitle("Spending Trends")
    }

    private func monthTooltip(_ month: Date) -> some View {
        let monthKey = month.startOfMonth
        let items = trendData
            .filter { Calendar.current.isDate($0.month, equalTo: monthKey, toGranularity: .month) }
            .sorted { $0.amount > $1.amount }
        return VStack(alignment: .leading, spacing: 3) {
            Text(monthKey.formatted(.dateTime.month(.wide).year()))
                .font(.caption.weight(.semibold))

            ForEach(items, id: \.categoryName) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: item.categoryColor))
                        .frame(width: 8, height: 8)
                    Text(item.categoryName)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.amount.formattedCurrency)
                        .fontWeight(.semibold)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .fixedSize()
    }

    private var categoryToggles: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)

            ForEach(expenseCategories) { category in
                Toggle(isOn: categoryBinding(category)) {
                    Label(category.name, systemImage: category.iconName)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }
        }
    }

    private func categoryBinding(_ category: Category) -> Binding<Bool> {
        Binding {
            selectedCategories.isEmpty || selectedCategories.contains(category.id)
        } set: { isSelected in
            if selectedCategories.isEmpty {
                selectedCategories = Set(expenseCategories.map(\.id))
            }

            if isSelected {
                selectedCategories.insert(category.id)
            } else {
                selectedCategories.remove(category.id)
            }
        }
    }
}

struct MonthlyCategoryAmount: Identifiable {
    let id = UUID()
    let month: Date
    let categoryName: String
    let categoryColor: String
    let amount: Double
}
