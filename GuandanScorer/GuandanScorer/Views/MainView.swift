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
                            get: { 
                                // 总是从gameManager中获取最新的游戏状态
                                if let index = gameManager.games.firstIndex(where: { $0.id == game.id }) {
                                    return gameManager.games[index]
                                }
                                return game
                            },
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
        .onChange(of: gameManager.currentGame) { oldGame, newGame in
            if let game = newGame {
                // 当有新游戏时，切换到首页标签并导航到游戏视图
                selectedTab = 0
                
                // 清除导航栈，避免重复
                path = NavigationPath()
                path.append(game)
                
                NSLog("📱 [MainView] 导航到游戏: \(game.teamA.player1) & \(game.teamA.player2) vs \(game.teamB.player1) & \(game.teamB.player2)")
            } else if oldGame != nil {
                // 当currentGame被设置为nil时，确保清空导航栈
                NSLog("📱 [MainView] 清空currentGame，准备新导航")
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
