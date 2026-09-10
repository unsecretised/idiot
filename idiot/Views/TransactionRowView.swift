import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let isOverLimit: Bool
    let lockPastMonths: Bool

    private var category: Category? {
        transaction.category
    }

    private var isIncome: Bool {
        category?.type == .income
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(isIncome ? "+" : "−")
                    .font(.headline.monospaced())
                    .foregroundStyle(isIncome ? .green : .red)

                Circle()
                    .fill(Color(hex: category?.colorHex ?? "#8E8E93"))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.title)
                        .fontWeight(.medium)

                    if let category {
                        Label(category.name, systemImage: category.iconName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(transaction.amount.formattedCurrency)
                        .fontWeight(.semibold)
                        .foregroundStyle(isIncome ? .green : .red)

                    Text(transaction.date.formatted(style: .medium))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isOverLimit, let limit = category?.limit {
                Text("Category over limit: \(limit.formattedCurrency)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, isOverLimit ? 8 : 0)
        .background(isOverLimit ? Color.red.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .opacity(lockPastMonths && transaction.date.isInPastMonth ? 0.5 : 1)
        #if os(macOS)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        #else
            .background(Color(uiColor: .systemBackground))
        #endif
    }
}
