//
//  AIchatbotApp.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI
import SwiftData

@main
struct AIchatbotApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Keep old models for migration
            ChatSession.self,
            ChatMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("itelo") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
        }
        .modelContainer(sharedModelContainer)
    }
}
