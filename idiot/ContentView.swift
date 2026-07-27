//
//  ContentView.swift
//  idiot
//
//  Created by Umang on 26/7/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedMonth = Date.now.startOfMonth
    @State private var showSettings = false

    @State private var hiddenCategoryIDs: Set<Category.ID> = []
    @State private var minAmountText = ""
    @State private var maxAmountText = ""
    @State private var showIncome = true
    @State private var showExpense = true

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
            MonthlyHeaderView(selectedMonth: $selectedMonth, showSettings: $showSettings)
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
                hiddenCategoryIDs: $hiddenCategoryIDs,
                minAmountText: $minAmountText,
                maxAmountText: $maxAmountText,
                showIncome: $showIncome,
                showExpense: $showExpense
            )
        }
        .padding(.top, 32)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
