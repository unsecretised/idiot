import SwiftData
import SwiftUI

struct CategoryEditView: View {
    private let category: Category?
    private let colorOptions = ["#4F8EF7", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#FFCC00", "#FF2D55", "#5AC8FA"]
    private let iconOptions = ["tag.fill", "briefcase.fill", "bolt.fill", "fork.knife", "basket.fill", "car.fill", "desktopcomputer", "person.fill", "dollarsign.circle.fill", "bag.fill", "house.fill", "heart.fill"]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name: String
    @State private var type: CategoryType
    @State private var limit: String
    @State private var colorHex: String
    @State private var iconName: String
    @State private var showValidation = false

    init(category: Category? = nil) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _type = State(initialValue: category?.type ?? .expense)
        _limit = State(initialValue: category?.limit.map { String(format: "%.2f", $0) } ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? "#4F8EF7")
        _iconName = State(initialValue: category?.iconName ?? "tag.fill")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(CategoryType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if type == .expense {
                        TextField("Monthly limit (optional)", text: $limit)
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(34)), count: 8), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { option in
                            Button {
                                colorHex = option
                            } label: {
                                Circle()
                                    .fill(Color(hex: option))
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        if colorHex == option {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    Picker("Icon", selection: $iconName) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Label(icon, systemImage: icon).tag(icon)
                        }
                    }
                }

                if showValidation, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Name is required.")
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
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
            .frame(minWidth: 420, minHeight: 420)
            #endif
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidation = true
            return
        }

        let parsedLimit = Double(limit.trimmingCharacters(in: .whitespacesAndNewlines))
        let resolvedLimit = type == .expense ? parsedLimit : nil

        if let category {
            category.name = trimmedName
            category.type = type
            category.limit = resolvedLimit
            category.colorHex = colorHex
            category.iconName = iconName
        } else {
            let nextSortOrder = (categories.filter { $0.type == type }.map(\.sortOrder).max() ?? 0) + 1
            modelContext.insert(Category(
                name: trimmedName,
                type: type,
                limit: resolvedLimit,
                colorHex: colorHex,
                iconName: iconName,
                sortOrder: nextSortOrder
            ))
        }

        dismiss()
    }
}
