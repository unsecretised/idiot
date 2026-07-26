import Charts
import SwiftData
import SwiftUI

struct TrendChartView: View {
    @Query private var transactions: [Transaction]
    @State private var selectedCategories = Set<UUID>()

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
                Chart(trendData) { item in
                    LineMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(by: .value("Category", item.categoryName))
                    .symbol(by: .value("Category", item.categoryName))
                    .accessibilityLabel("\(item.categoryName), \(item.month.formatted(.dateTime.month(.wide).year()))")
                    .accessibilityValue(item.amount.formattedCurrency)
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
