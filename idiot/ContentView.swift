//
//  ContentView.swift
//  idiot
//
//  Created by Umang on 26/7/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedMonth = Date.now.startOfMonth
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            MonthlyHeaderView(selectedMonth: $selectedMonth, showSettings: $showSettings)
            WeeklyChartView(selectedMonth: selectedMonth)
                .padding(.top, 8)

            TransactionListView(selectedMonth: selectedMonth)
        }
        .padding(.top, 32)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
