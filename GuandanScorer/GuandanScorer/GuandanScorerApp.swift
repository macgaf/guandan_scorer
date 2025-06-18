//
//  GuandanScorerApp.swift
//  GuandanScorer
//
//  Created by 徐添 on 3/6/25.
//

import SwiftUI

@main
struct GuandanScorerApp: App {
    // 移除CoreData依赖
    @StateObject private var gameManager = GameManager()

    init() {
        NSLog(" GuandanScorerApp ")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(gameManager)
                .onAppear {
                    NSLog(" MainView ")
                }
        }
    }
}
