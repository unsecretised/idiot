import SwiftUI

struct MonthlyHeaderView: View {
    #if os(macOS)
        @Environment(\.openWindow) private var openWindow
    #endif
    @Binding var selectedMonth: Date
    @Binding var showSettings: Bool
    @Binding var showAnalytics: Bool

    @State private var showMonthPicker = false
    @State private var showHelp = false

    private var monthLabel: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date.now.startOfMonth, toGranularity: .month)
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous month")

                Button {
                    showMonthPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(monthLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .monospacedDigit()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Selected month")
                .popover(isPresented: $showMonthPicker, arrowEdge: .bottom) {
                    monthGridPopover
                }

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next month")

                if !isCurrentMonth {
                    Button("Today") {
                        withAnimation { selectedMonth = Date.now.startOfMonth }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .padding(.leading, 8)
                }
            }

            Spacer()

            Button {
                #if os(macOS)
                    openWindow(id: "analytics")
                #else
                    showAnalytics = true
                #endif
            } label: {
                Image(systemName: "chart.bar.xaxis")
            }
            .accessibilityLabel("Analytics")
            .help("Open Analytics")
            .padding(.trailing, 8)

            Button {
                showHelp = true
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .accessibilityLabel("Help")
            .help("How to use this app")
            .padding(.trailing, 8)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)
            .accessibilityLabel("Settings")
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
        selectedMonth = newDate
    }

    private var monthGridPopover: some View {
        let calendar = Calendar.current
        let current = Date.now.startOfMonth
        let months = (0 ..< 12).compactMap { calendar.date(byAdding: .month, value: -$0, to: current) }

        return VStack(spacing: 0) {
            ForEach(Array(months.chunked(into: 3)), id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { month in
                        Button {
                            selectedMonth = month
                            showMonthPicker = false
                        } label: {
                            Text(month.formatted(.dateTime.month(.abbreviated).year()))
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(month == selectedMonth ? Color.accentColor.opacity(0.15) : Color.clear)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Divider()
            }
        }
        .padding(6)
        .frame(width: 220)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
