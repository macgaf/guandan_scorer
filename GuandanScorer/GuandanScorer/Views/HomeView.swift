import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var searchText = ""
    @State private var showNewGameSheet = false
    
    var body: some View {
        VStack {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("按人名搜索", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // 对局列表
            List {
                ForEach(gameManager.filteredGames(searchText: searchText)) { game in
                    GameRowView(game: game)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            gameManager.currentGame = game
                        }
                        .swipeActions(edge: .trailing) {
                            // 删除按钮
                            Button(role: .destructive) {
                                withAnimation {
                                    gameManager.deleteGame(game: game)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            // 再来一局按钮
                            Button {
                                showNewGameSheet = true
                                gameManager.prepareNewGame(from: game)
                            } label: {
                                Label("再来一局", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                }
            }
            .listStyle(PlainListStyle())
            
            // 来一局按钮
            Button(action: {
                showNewGameSheet = true
            }) {
                Text("来一局")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("惯蛋记分器")
        .sheet(isPresented: $showNewGameSheet) {
            NewGameView(
                teamAPlayer1: gameManager.newGameSetup?.teamAPlayer1 ?? "",
                teamAPlayer2: gameManager.newGameSetup?.teamAPlayer2 ?? "",
                teamBPlayer1: gameManager.newGameSetup?.teamBPlayer1 ?? "",
                teamBPlayer2: gameManager.newGameSetup?.teamBPlayer2 ?? ""
            )
        }
    }
}

struct GameRowView: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManager
    @State private var showNewGameSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 队伍信息
            HStack {
                Text("\(game.teamA.player1) & \(game.teamA.player2)")
                    .font(.headline)
                
                Spacer()
                
                Text("VS")
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(game.teamB.player1) & \(game.teamB.player2)")
                    .font(.headline)
            }
            
            // 成绩信息
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(game.teamA.currentLevel.rawValue)
                            .font(.title2)
                            .bold()
                        
                        if game.teamA.isWinner {
                            Text("(胜)")
                                .foregroundColor(.green)
                        }
                        
                        if let lastRound = game.rounds.last, lastRound.dealerTeamId == game.teamA.id {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        if let lastRound = game.rounds.last, lastRound.dealerTeamId == game.teamB.id {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        if game.teamB.isWinner {
                            Text("(胜)")
                                .foregroundColor(.green)
                        }
                        
                        Text(game.teamB.currentLevel.rawValue)
                            .font(.title2)
                            .bold()
                    }
                }
            }
            
            // 再来一局按钮
            Button(action: {
                showNewGameSheet = true
            }) {
                Text("再来一局")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(5)
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameView(
                    teamAPlayer1: game.teamA.player1,
                    teamAPlayer2: game.teamA.player2,
                    teamBPlayer1: game.teamB.player1,
                    teamBPlayer2: game.teamB.player2
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    HomeView()
        .environmentObject(GameManager())
}
