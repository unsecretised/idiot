//
//  ContentView.swift
//  idiot
//
//  Created by Umang on 26/7/26.
//

import SwiftData
import SwiftUI

#if os(iOS)
    struct PrivacyShield: View {
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.background)
                LinearGradient(
                    colors: [.green.opacity(0.08), .blue.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Finance data hidden")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
#endif

struct ContentView: View {
    @State private var selectedMonth = Date.now.startOfMonth
    @State private var showSettings = false
    @State private var showAnalytics = false
    #if os(iOS)
        @Environment(\.scenePhase) private var scenePhase
        @State private var isUnlocked = true
    #endif

    @AppStorage("filterHiddenCategoryIDs") private var hiddenCategoryIDsData: String = ""
    @AppStorage("filterMinAmount") private var minAmountText = ""
    @AppStorage("filterMaxAmount") private var maxAmountText = ""
    @AppStorage("filterShowIncome") private var showIncome = true
    @AppStorage("filterShowExpense") private var showExpense = true
    @State private var hiddenCategoryIDs: Set<Category.ID> = []
    @State private var isFilterStateLoaded = false
    @State private var showAddTransaction = false

    private var hiddenCategoryIDsBinding: Binding<Set<Category.ID>> {
        Binding {
            hiddenCategoryIDs
        } set: { newValue in
            hiddenCategoryIDs = newValue
            if isFilterStateLoaded {
                hiddenCategoryIDsData = newValue.map(\.uuidString).sorted().joined(separator: ",")
            }
        }
    }

    private func loadPersistedFilters() {
        let ids = hiddenCategoryIDsData
            .split(separator: ",")
            .compactMap { UUID(uuidString: String($0)) }
        hiddenCategoryIDs = Set(ids)
        isFilterStateLoaded = true
    }

    private var minAmount: Double? {
        let trimmed = minAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var maxAmount: Double? {
        let trimmed = maxAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthlyHeaderView(
                selectedMonth: $selectedMonth,
                showSettings: $showSettings,
                showAnalytics: $showAnalytics
            )
            WeeklyChartView(
                selectedMonth: selectedMonth,
                hiddenCategoryIDs: hiddenCategoryIDs,
                minAmount: minAmount,
                maxAmount: maxAmount,
                showIncome: showIncome,
                showExpense: showExpense
            )
            .padding(.top, 8)

            TransactionListView(
                selectedMonth: selectedMonth,
                showAddTransaction: $showAddTransaction,
                hiddenCategoryIDs: hiddenCategoryIDsBinding,
                minAmountText: $minAmountText,
                maxAmountText: $maxAmountText,
                showIncome: $showIncome,
                showExpense: $showExpense
            )
        }
        .onAppear {
            loadPersistedFilters()
        }
        #if os(macOS)
        .padding(.top, 32)
        #endif
        .textSelection(.enabled)
        #if os(iOS)
            .overlay {
                if !isUnlocked {
                    PrivacyShield()
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isUnlocked = newPhase == .active
                }
            }
        #endif
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
            .onOpenURL { url in
                switch url.host {
                case "add":
                    showAddTransaction = true
                case "analytics":
                    #if os(macOS)
                        openAnalyticsWindow()
                    #else
                        showAnalytics = true
                    #endif
                default:
                    break
                }
            }
    }

    #if os(macOS)
        @Environment(\.openWindow) private var openWindow

        private func openAnalyticsWindow() {
            openWindow(id: "analytics")
        }
    #endif
}
