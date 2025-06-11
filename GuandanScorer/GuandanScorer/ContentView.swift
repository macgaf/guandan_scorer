//
//  ContentView.swift
//  GuandanScorer
//
//  Created by 徐添 on 3/6/25.
//

import SwiftUI

// 简化的ContentView，因为应用现在使用MainView作为主视图
struct ContentView: View {
    var body: some View {
        Text("应用使用MainView作为主视图")
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
