import SwiftUI

struct MonthlyHeaderView: View {
    #if os(macOS)
        @Environment(\.openWindow) private var openWindow
    #endif
    @Binding var selectedMonth: Date
    @Binding var showSettings: Bool
    @Binding var showAnalytics: Bool

    @State private var showHelp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var monthLabel: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date.now.startOfMonth, toGranularity: .month)
    }

    private var recentMonths: [Date] {
        let calendar = Calendar.current
        let current = Date.now.startOfMonth
        return (0 ..< 12).compactMap { calendar.date(byAdding: .month, value: -$0, to: current) }
    }

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                Section {
                    Button("Previous Month") {
                        moveMonth(by: -1)
                    }
                    Button("Next Month") {
                        moveMonth(by: 1)
                    }

                    if !isCurrentMonth {
                        Button("Jump to Today") {
                            setSelectedMonth(Date.now.startOfMonth)
                        }
                    }
                }

                Section("Months") {
                    ForEach(recentMonths, id: \.self) { month in
                        if month == selectedMonth {
                            Label(month.formatted(.dateTime.month(.wide).year()), systemImage: "checkmark")
                        } else {
                            Button(month.formatted(.dateTime.month(.wide).year())) {
                                setSelectedMonth(month)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(monthLabel)
                        .font(.headline.monospacedDigit())
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary.opacity(0.3), in: Capsule())
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Selected month")
            .accessibilityHint("Opens navigation and month selection")

            Spacer()

            Menu {
                Button {
                    #if os(macOS)
                        openWindow(id: "analytics")
                    #else
                        showAnalytics = true
                    #endif
                } label: {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }

                Divider()

                Button {
                    showHelp = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More options")
            .help("Analytics, Help and Settings")
        }
        .padding(.horizontal)
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                HelpView()
                #if os(iOS)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showHelp = false
                            }
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                #endif
            }
        }
    }

    private func moveMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) else { return }
        setSelectedMonth(newDate)
    }

    private func setSelectedMonth(_ month: Date) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            selectedMonth = month
        }
    }
}
