//
//  Financial_programApp.swift
//  Financial program
//
//  Created by Ivan Cheglakov on 2026-04-29.
//

import SwiftUI
import SwiftData

@main
struct Financial_programApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Account.self, Transaction.self, Category.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { seedCategoriesIfNeeded() }
#if os(macOS)
                .frame(minWidth: 720, minHeight: 750)
#endif
        }
        .modelContainer(sharedModelContainer)
#if os(macOS)
        .defaultSize(width: 900, height: 820)
#endif
    }

    private func seedCategoriesIfNeeded() {
        let context = sharedModelContainer.mainContext
        let existing = try? context.fetch(FetchDescriptor<Category>())
        guard existing?.isEmpty ?? true else { return }
        for cat in Category.defaultCategories() {
            context.insert(cat)
        }
        try? context.save()
    }
}
