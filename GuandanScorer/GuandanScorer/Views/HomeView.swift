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
            ScrollViewReader { proxy in
                List {
                    ForEach(gameManager.filteredGames(searchText: searchText)) { game in
                        GameRowView(game: game)
                            .id(game.id)  // 添加id以支持滚动定位
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // 记录游戏选择事件
                                OSLogger.logInputEvent("点击 - 目标: 游戏列表项 - 详情: 选择游戏: \(game.teamA.player1) & \(game.teamA.player2) vs \(game.teamB.player1) & \(game.teamB.player2)")
                                
                                // 先清除currentGame，然后设置新的游戏，确保onChange被触发
                                DispatchQueue.main.async {
                                    gameManager.currentGame = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                        gameManager.currentGame = game
                                    }
                                }
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
                .onChange(of: gameManager.games.count) { oldCount, newCount in
                    // 当游戏数量增加时（创建新游戏），自动滚动到最新的游戏
                    if newCount > oldCount, let latestGame = gameManager.games.first {
                        withAnimation {
                            proxy.scrollTo(latestGame.id, anchor: .top)
                        }
                    }
                }
                .onAppear {
                    // 首次显示时，如果有当前游戏，滚动到它
                    if let currentGame = gameManager.currentGame {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(currentGame.id, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            // 来一局按钮
            Button(action: {
                // 记录新建游戏按钮点击
                OSLogger.logInputEvent("点击 - 目标: 来一局按钮 - 详情: 点击新建游戏")
                
                showNewGameSheet = true
            }) {
                Text("来一局")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("惯蛋记分器")
        .onAppear {
            // 记录主界面初始化
            OSLogger.logInputEvent("点击 - 目标: HomeView界面 - 详情: 界面初始化 - 游戏列表 (\(gameManager.games.count) 个游戏)")
        }
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
                        
                        if game.teamA.isDealer {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("庄")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        if game.teamB.isDealer {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("庄")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
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