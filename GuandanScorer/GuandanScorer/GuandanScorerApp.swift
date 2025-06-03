//
//  GuandanScorerApp.swift
//  GuandanScorer
//
//  Created by 徐添 on 3/6/25.
//

import SwiftUI

@main
struct GuandanScorerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var gameManager = GameManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(gameManager)
        }
    }
}
