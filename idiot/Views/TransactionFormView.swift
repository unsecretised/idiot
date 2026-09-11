import SwiftData
import SwiftUI

struct TransactionFormView: View {
    private let transaction: Transaction?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var date: Date
    @State private var title = ""
    @State private var desc = ""
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var showValidation = false
    @State private var showDatePicker = false
    @FocusState private var titleFocused: Bool

    init(transaction: Transaction? = nil, defaultDate: Date = .now) {
        self.transaction = transaction
        _date = State(initialValue: transaction?.date ?? defaultDate)
        _title = State(initialValue: transaction?.title ?? "")
        _desc = State(initialValue: transaction?.desc ?? "")
        _amount = State(initialValue: transaction.map { String(format: "%.2f", $0.amount) } ?? "")
        _selectedCategory = State(initialValue: transaction?.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    HStack {
                        Text("Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showDatePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .frame(width: 280)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .focused($titleFocused)
                            .submitLabel(.next)
                            .overlay {
                                if showValidation, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.red, lineWidth: 1)
                                }
                            }

                        if showValidation, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Title is required.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    TextField("Description (optional)", text: $desc)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                            .submitLabel(.done)

                        if showValidation, (Double(amount) ?? 0) <= 0 {
                            Text("Amount must be greater than 0.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Category") {
                    if categories.isEmpty {
                        ContentUnavailableView("No categories", systemImage: "tag", description: Text("Add a category in Settings first."))
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select a category").tag(Category?.none)
                            ForEach(categories) { category in
                                Label {
                                    Text("\(category.type.displayName): \(category.name)")
                                } icon: {
                                    Image(systemName: category.iconName)
                                        .foregroundStyle(Color(hex: category.colorHex))
                                }
                                .tag(Category?.some(category))
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    if showValidation, selectedCategory == nil {
                        Text("Choose a category.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Transaction" : "Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            #if os(macOS)
            .frame(minWidth: 460, minHeight: 360)
            #endif
            .onAppear {
                selectedCategory = selectedCategory ?? categories.first
                if transaction == nil {
                    titleFocused = true
                }
            }
        }
    }

    private var isEditing: Bool {
        transaction != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (Double(amount) ?? 0) > 0 &&
            selectedCategory != nil
    }

    private func save() {
        guard canSave, let selectedCategory else {
            showValidation = true
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmount = Double(amount) ?? 0

        if let transaction {
            transaction.title = trimmedTitle
            transaction.desc = trimmedDesc.isEmpty ? nil : trimmedDesc
            transaction.amount = parsedAmount
            transaction.date = date
            transaction.category = selectedCategory
        } else {
            modelContext.insert(Transaction(
                title: trimmedTitle,
                desc: trimmedDesc.isEmpty ? nil : trimmedDesc,
                amount: parsedAmount,
                date: date,
                category: selectedCategory
            ))
        }

        dismiss()
    }
}
