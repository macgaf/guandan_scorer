import SwiftUI

struct MainView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var path = NavigationPath()
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页标签
            NavigationStack(path: $path) {
                HomeView()
                    .navigationDestination(for: Game.self) { game in
                        GameView(game: Binding(
                            get: { game },
                            set: { newGame in
                                if let index = gameManager.games.firstIndex(where: { $0.id == newGame.id }) {
                                    gameManager.games[index] = newGame
                                    gameManager.saveGames()
                                }
                            }
                        ))
                    }
            }
            .tabItem {
                Label("首页", systemImage: "house")
            }
            .tag(0)
            
            // 统计标签
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
                .tag(1)
        }
        .onChange(of: gameManager.currentGame) { _, newGame in
            if let game = newGame {
                // 当有新游戏时，切换到首页标签
                selectedTab = 0
                path.append(game)
            }
        }
        // 使用系统默认的颜色方案
        .preferredColorScheme(nil)
        // 横屏模式支持
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // 横屏模式逻辑可以根据需要添加
        }
    }
}

#Preview {
    MainView()
        .environmentObject(GameManager())
}
