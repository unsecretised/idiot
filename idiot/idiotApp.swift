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
                .frame(minWidth: 500, idealWidth: 500, maxWidth: 500)
                .frame(idealHeight: 600)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .modelContainer(container)
    }
}
