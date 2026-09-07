//
//  idiotApp.swift
//  idiot
//
//  Created by Umang on 26/7/26.
//

import SwiftData
import SwiftUI

@main
struct idiotApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Category.self, Transaction.self)
            DefaultCategories.seed(context: ModelContext(container))
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 750, idealWidth: 750, maxWidth: 750)
                .frame(idealHeight: 600)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .modelContainer(container)
        .commands {
            AnalyticsCommands()
        }

        Window("Analytics", id: "analytics") {
            AnalyticsView()
        }
        .defaultSize(width: 880, height: 700)
        .modelContainer(container)
    }
}

struct AnalyticsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("View") {
            Button("Analytics") {
                openWindow(id: "analytics")
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
        }
    }
}
