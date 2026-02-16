//
//  LittleBlackBookApp.swift
//  LittleBlackBook
//
//  Created by Maxwell Ludden on 2/15/26.
//

import SwiftUI
import SwiftData

@main
struct LittleBlackBookApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Contact.self,
            Event.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

