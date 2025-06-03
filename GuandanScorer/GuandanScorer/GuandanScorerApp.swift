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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
