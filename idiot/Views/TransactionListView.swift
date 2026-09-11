import SwiftData
import SwiftUI

struct TransactionListView: View {
    let selectedMonth: Date
    @Binding var showAddTransaction: Bool
    @Binding var hiddenCategoryIDs: Set<Category.ID>
    @Binding var minAmountText: String
    @Binding var maxAmountText: String
    @Binding var showIncome: Bool
    @Binding var showExpense: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("lockPastMonths") private var lockPastMonths = true
    @State private var editingTransaction: Transaction?
    @State private var pendingDeleteTransaction: Transaction?
    @State private var selectedTransactionIDs: Set<Transaction.ID> = []
    #if os(iOS)
        @State private var editMode: EditMode = .inactive
        private var isSelectMode: Bool {
            editMode == .active
        }

        private var allSelected: Bool {
            selectedTransactionIDs.count >= filteredTransactions.count && !filteredTransactions.isEmpty
        }
    #endif
    @State private var showBatchDeleteAlert = false
    @State private var showFilterPopover = false

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
        !hiddenCategoryIDs.isEmpty || minAmountFilter != nil || maxAmountFilter != nil || !showIncome || !showExpense
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            if let category = transaction.category {
                if hiddenCategoryIDs.contains(category.id) {
                    return false
                }
                if !showIncome, category.type == .income {
                    return false
                }
                if !showExpense, category.type == .expense {
                    return false
                }
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
                let isSelected = selectedTransactionIDs.contains(transaction.id)
                let row = TransactionRowView(
                    transaction: transaction,
                    isOverLimit: isOverLimit(transaction),
                    lockPastMonths: lockPastMonths,
                    isSelected: isSelected
                )
                row
                    .listRowBackground(row.rowBackground(isSelected: isSelected))
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
                #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeleteTransaction = transaction
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(lockPastMonths && transaction.date.isInPastMonth)

                        Button {
                            editingTransaction = transaction
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.accentColor)
                        .disabled(lockPastMonths && transaction.date.isInPastMonth)
                    }
                #endif
                    .listRowSeparator(.hidden)
                    .simultaneousGesture(TapGesture().onEnded {
                        #if os(iOS)
                            if isSelectMode {
                                return
                            }
                        #endif
                        if isSelected {
                            selectedTransactionIDs.remove(transaction.id)
                        } else {
                            selectedTransactionIDs.insert(transaction.id)
                        }
                    })
            }
            #if os(iOS)
            .environment(\.editMode, $editMode)
            #endif
            #if os(macOS)
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            #else
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            #endif
            .overlay {
                if filteredTransactions.isEmpty {
                    ContentUnavailableView("No transactions yet", systemImage: "tray", description: Text("Tap + to add one."))
                }
            }
            .animation(.default, value: filteredTransactions.count)
            #if os(macOS)
                .onDeleteCommand {
                    deleteSelected()
                }
            #endif
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
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.snappy(duration: 0.2), value: hasActiveFilters)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .foregroundStyle(hasActiveFilters ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filters")
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
                #if os(iOS)
                    .opacity(isSelectMode ? 0 : 1)
                    .disabled(isSelectMode)
                    .accessibilityHidden(isSelectMode)
                #endif
                    .keyboardShortcut("n", modifiers: .command)
            }
            .padding()
            .animation(.default, value: selectedTransactionIDs.isEmpty)
        }
        #if os(iOS)
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        if isSelectMode {
                            selectedTransactionIDs = []
                            editMode = .inactive
                        } else {
                            editMode = .active
                        }
                    }
                } label: {
                    Label(isSelectMode ? "Done" : "Select", systemImage: isSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .padding(10)
                        .background(.regularMaterial, in: Capsule())
                        .foregroundStyle(isSelectMode ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
                .animation(.snappy(duration: 0.2), value: isSelectMode)

                if isSelectMode {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            selectedTransactionIDs = allSelected ? [] : Set(filteredTransactions.map(\.id))
                        }
                    } label: {
                        Label(allSelected ? "Deselect All" : "Select All", systemImage: allSelected ? "circle" : "checkmark.circle")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.semibold))
                            .padding(10)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding()
            .animation(.snappy(duration: 0.25), value: isSelectMode)
        }
        #endif
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

    private var amountRangeCaption: String {
        let bounds = ClosedRange.amountBounds(for: transactions.map(\.amount))
        let suffix = " (\(Int(bounds.lowerBound))–\(Int(bounds.upperBound)))"
        switch (minAmountText.isEmpty, maxAmountText.isEmpty) {
        case (true, true):
            return "Showing all amounts" + suffix
        case (false, true):
            if let minAmountDouble {
                return "From \(Int(minAmountDouble)) and up"
            }
            return "From any amount"
        case (true, false):
            return "Up to \(maxAmountText)"
        default:
            return "\(minAmountText) – \(maxAmountText)"
        }
    }

    private var minAmountDouble: Double? {
        Double(minAmountText)
    }

    private var filterPopoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Filters")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Toggle("Income", isOn: $showIncome)
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                Toggle("Expense", isOn: $showExpense)
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
            }

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
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Amount Range")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                AmountRangeSlider(
                    bounds: .amountBounds(for: transactions.map(\.amount)),
                    lowText: $minAmountText,
                    highText: $maxAmountText
                )

                Text(amountRangeCaption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Reset") {
                    hiddenCategoryIDs = []
                    minAmountText = ""
                    maxAmountText = ""
                    showIncome = true
                    showExpense = true
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
