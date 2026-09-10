import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var transactions: [Transaction]

    @AppStorage("lockPastMonths") private var lockPastMonths = true
    @State private var showAddCategory = false
    @State private var editingCategory: Category?
    @State private var pendingDeleteCategory: Category?
    @State private var showSystemCategoryAlert = false
    @State private var isPushing = false
    @State private var pushError: String?
    private let syncMonitor = CloudSyncMonitor.shared

    private var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var incomeCategories: [Category] {
        categories.filter { $0.type == .income }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        TrendChartView()
                    } label: {
                        Label("View Spending Trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section {
                    NavigationLink {
                        RecurringListView(type: .expense)
                    } label: {
                        Label("Subscriptions", systemImage: "repeat")
                    }
                    .accessibilityLabel("Manage Subscriptions")

                    NavigationLink {
                        RecurringListView(type: .income)
                    } label: {
                        Label("Auto Salary", systemImage: "dollarsign.circle")
                    }
                    .accessibilityLabel("Manage Auto Salary")
                }

                Section {
                    Toggle("Lock past months from editing", isOn: $lockPastMonths)
                } footer: {
                    Text("When enabled, transactions in previous months cannot be edited, copied, or deleted.")
                }

                Section {
                    LabeledContent("Status") {
                        Text(syncMonitor.statusText)
                            .foregroundStyle(syncMonitor.showsError ? .red : .secondary)
                            .monospacedDigit()
                    }

                    Button {
                        forcePush()
                    } label: {
                        HStack {
                            Label("Force Push to iCloud", systemImage: "icloud.and.arrow.up")
                            if isPushing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isPushing)
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text("Changes sync automatically. Use Force Push if a device seems out of date — it re-uploads all local data to your private iCloud database.")
                }

                categorySection("Expense", categories: expenseCategories)
                categorySection("Income", categories: incomeCategories)
            }
            .navigationTitle("Settings")
            .task {
                await syncMonitor.refreshAccountStatus()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Category")
                }
            }
            .sheet(isPresented: $showAddCategory) {
                CategoryEditView()
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category)
            }
            .alert("System Category", isPresented: $showSystemCategoryAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This is a system category and cannot be deleted. You can rename it instead.")
            }
            .alert("Delete Category?", isPresented: deleteConfirmationBinding) {
                Button("Delete", role: .destructive) {
                    if let pendingDeleteCategory {
                        modelContext.delete(pendingDeleteCategory)
                    }
                    pendingDeleteCategory = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteCategory = nil
                }
            } message: {
                Text("This will remove the category from your tracker.")
            }
            .alert("Force Push Failed", isPresented: pushErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pushError ?? "Unknown error.")
            }
            #if os(macOS)
            .frame(minWidth: 520, minHeight: 520)
            #endif
        }
    }

    private func forcePush() {
        guard !isPushing else { return }
        isPushing = true
        pushError = nil

        Task {
            do {
                let now = Date()
                for transaction in try modelContext.fetch(FetchDescriptor<Transaction>()) {
                    transaction.syncStamp = now
                }
                for category in try modelContext.fetch(FetchDescriptor<Category>()) {
                    category.syncStamp = now
                }
                try modelContext.save()
            } catch {
                pushError = error.localizedDescription
            }
            isPushing = false
        }
    }

    private var pushErrorBinding: Binding<Bool> {
        Binding {
            pushError != nil
        } set: { isPresented in
            if !isPresented {
                pushError = nil
            }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            pendingDeleteCategory != nil
        } set: { isPresented in
            if !isPresented {
                pendingDeleteCategory = nil
            }
        }
    }

    private func categorySection(_ title: String, categories: [Category]) -> some View {
        Section(title) {
            if categories.isEmpty {
                Text("No \(title.lowercased()) categories yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categories) { category in
                    categoryRow(category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                        .contextMenu {
                            Button("Edit") {
                                editingCategory = category
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                requestDelete(category)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                requestDelete(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 10, height: 10)

                Image(systemName: category.iconName)
                    .frame(width: 22)
                    .foregroundStyle(Color(hex: category.colorHex))

                Text(category.name)

                Spacer()

                if category.type == .expense, let limit = category.limit {
                    Text(limit.formattedCurrency)
                        .foregroundStyle(.secondary)
                }
            }

            if category.type == .expense, let limit = category.limit {
                let spent = currentMonthSpent(for: category)
                let progress = limit > 0 ? min(spent / limit, 1) : 0

                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(spent >= limit ? .red : Color(hex: category.colorHex))
                        .accessibilityLabel("\(category.name) budget")
                        .accessibilityValue("\(spent.formattedCurrency) of \(limit.formattedCurrency)")

                    Text("\(spent.formattedCurrency) / \(limit.formattedCurrency) (\(Int((limit > 0 ? spent / limit : 0) * 100))%)")
                        .font(.caption)
                        .foregroundStyle(spent >= limit ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func currentMonthSpent(for category: Category) -> Double {
        let start = Date.now.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? Date.now.endOfMonth

        return transactions
            .filter { transaction in
                transaction.category?.id == category.id &&
                    transaction.date >= start &&
                    transaction.date < end
            }
            .reduce(0) { $0 + $1.amount }
    }

    private func requestDelete(_ category: Category) {
        if category.isSystem {
            showSystemCategoryAlert = true
        } else {
            pendingDeleteCategory = category
        }
    }
}
