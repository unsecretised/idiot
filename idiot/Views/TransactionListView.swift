import SwiftData
import SwiftUI

struct TransactionListView: View {
    let selectedMonth: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("lockPastMonths") private var lockPastMonths = true
    @State private var showAddTransaction = false
    @State private var editingTransaction: Transaction?
    @State private var pendingDeleteTransaction: Transaction?
    @State private var hiddenCategoryIDs: Set<Category.ID> = []
    @State private var selectedTransactionIDs: Set<Transaction.ID> = []
    @State private var showBatchDeleteAlert = false
    @State private var showFilterPopover = false
    @State private var minAmountText = ""
    @State private var maxAmountText = ""

    private var transactions: [Transaction] {
        let start = selectedMonth.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? selectedMonth.endOfMonth
        return allTransactions.filter { $0.date >= start && $0.date < end }
    }

    private var minAmountFilter: Double? {
        let trimmed = minAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var maxAmountFilter: Double? {
        let trimmed = maxAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var hasActiveFilters: Bool {
        !hiddenCategoryIDs.isEmpty || minAmountFilter != nil || maxAmountFilter != nil
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            if let category = transaction.category, hiddenCategoryIDs.contains(category.id) {
                return false
            }
            if let minVal = minAmountFilter, transaction.amount < minVal {
                return false
            }
            if let maxVal = maxAmountFilter, transaction.amount > maxVal {
                return false
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(filteredTransactions, selection: $selectedTransactionIDs) { transaction in
                TransactionRowView(
                    transaction: transaction,
                    isOverLimit: isOverLimit(transaction),
                    lockPastMonths: lockPastMonths
                )
                .contextMenu {
                    Button("Edit") {
                        editingTransaction = transaction
                    }
                    .disabled(lockPastMonths && transaction.date.isInPastMonth)

                    Button("Copy") {
                        copy(transaction)
                    }

                    Divider()

                    Button("Delete", role: .destructive) {
                        pendingDeleteTransaction = transaction
                    }
                    .disabled(lockPastMonths && transaction.date.isInPastMonth)
                }
            }
            .overlay {
                if filteredTransactions.isEmpty {
                    ContentUnavailableView("No transactions yet", systemImage: "tray", description: Text("Tap + to add one."))
                }
            }
            .animation(.default, value: filteredTransactions.count)
            .onDeleteCommand {
                deleteSelected()
            }
            .onKeyPress(.return) {
                editSelectedTransaction()
                return .handled
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 8) {
                if !selectedTransactionIDs.isEmpty {
                    Button(role: .destructive) {
                        showBatchDeleteAlert = true
                    } label: {
                        Label("Delete (\(selectedTransactionIDs.count))", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    showFilterPopover = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(hasActiveFilters ? ".fill" : "")")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .foregroundStyle(hasActiveFilters ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                    filterPopoverContent
                }

                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(width: 48, height: 48)
                        .background(.tint, in: Circle())
                        .foregroundStyle(.white)
                        .shadow(radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding()
            .animation(.default, value: selectedTransactionIDs.isEmpty)
        }
        .alert("Delete selected transactions?", isPresented: $showBatchDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let editable = selectedTransactionIDs.filter { id in
                !lockPastMonths || filteredTransactions.first { $0.id == id }?.date.isInPastMonth == false
            }
            let skipped = selectedTransactionIDs.count - editable.count
            if skipped > 0 {
                Text("\(editable.count) transaction(s) will be deleted. \(skipped) past-month transaction(s) are skipped.")
            } else {
                Text("\(editable.count) transaction(s) will be deleted.")
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            TransactionFormView(transaction: nil, defaultDate: selectedMonth)
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionFormView(transaction: transaction)
        }
        .alert("Delete Transaction?", isPresented: deleteConfirmationBinding) {
            Button("Delete", role: .destructive) {
                if let pendingDeleteTransaction {
                    modelContext.delete(pendingDeleteTransaction)
                }
                pendingDeleteTransaction = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteTransaction = nil
            }
        } message: {
            Text("This transaction will be removed from the current month.")
        }
    }

    private var filterPopoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Filters")
                .font(.headline)

            if !categories.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Categories")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(categories) { category in
                        Toggle(isOn: Binding(
                            get: { !hiddenCategoryIDs.contains(category.id) },
                            set: { isVisible in
                                if isVisible {
                                    hiddenCategoryIDs.remove(category.id)
                                } else {
                                    hiddenCategoryIDs.insert(category.id)
                                }
                            }
                        )) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(category.name)
                                    .font(.caption)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Amount Range")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField("Min", text: $minAmountText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("—")
                        .foregroundStyle(.secondary)
                    TextField("Max", text: $maxAmountText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            HStack {
                Spacer()
                Button("Reset") {
                    hiddenCategoryIDs = []
                    minAmountText = ""
                    maxAmountText = ""
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .frame(width: 240)
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            pendingDeleteTransaction != nil
        } set: { isPresented in
            if !isPresented {
                pendingDeleteTransaction = nil
            }
        }
    }

    private func deleteSelected() {
        let toDelete = filteredTransactions.filter { transaction in
            selectedTransactionIDs.contains(transaction.id) && (!lockPastMonths || !transaction.date.isInPastMonth)
        }
        for transaction in toDelete {
            modelContext.delete(transaction)
        }
        selectedTransactionIDs = []
    }

    private func copy(_ transaction: Transaction) {
        modelContext.insert(Transaction(
            title: transaction.title,
            desc: transaction.desc,
            amount: transaction.amount,
            date: .now,
            category: transaction.category
        ))
    }

    private func editSelectedTransaction() {
        guard let id = selectedTransactionIDs.first,
              let transaction = filteredTransactions.first(where: { $0.id == id }),
              !lockPastMonths || !transaction.date.isInPastMonth
        else { return }
        editingTransaction = transaction
    }

    private func isOverLimit(_ transaction: Transaction) -> Bool {
        guard let category = transaction.category,
              category.type == .expense,
              let limit = category.limit
        else {
            return false
        }

        let total = transactions
            .filter { $0.category?.id == category.id }
            .reduce(0) { $0 + $1.amount }

        return total > limit
    }
}
