import SwiftUI

struct MainView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Game.self) { game in
                    GameView(game: Binding(
                        get: { game },
                        set: { newGame in
                            if let index = gameManager.games.firstIndex(where: { $0.id == newGame.id }) {
                                gameManager.games[index] = newGame
                            }
                        }
                    ))
                }
        }
        .onChange(of: gameManager.currentGame) { _, newGame in
            if let game = newGame {
                path.append(game)
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(GameManager())
}
