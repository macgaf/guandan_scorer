//
//  GuandanScorerApp.swift
//  GuandanScorer
//
//  Created by 徐添 on 3/6/25.
//

import SwiftUI
import os

@main
struct GuandanScorerApp: App {
    // 移除CoreData依赖
    @StateObject private var gameManager = GameManager()

    init() {
        OSLogger.logInitialization("GuandanScorerApp 应用初始化")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(gameManager)
                .onAppear {
                    OSLogger.logUIAction("MainView 主界面显示")
                }
        }
    }
}
