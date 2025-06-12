import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var game: Game
    @State private var showTeamAActions = false
    @State private var showTeamBActions = false
    @State private var historyIndex = 0 // 用于回退和前进
    @State private var displayedGame: Game // 用于显示当前状态
    
    init(game: Binding<Game>) {
        self._game = game
        self._displayedGame = State(initialValue: game.wrappedValue)
    }
    
    var body: some View {
        VStack {
            // 第一排 - 队伍信息和分数
            HStack(spacing: 0) {
                // A队信息
                TeamScoreView(team: $displayedGame.teamA, game: displayedGame)
                    .frame(maxWidth: .infinity)
                    .background(displayedGame.teamA.isDealer ? Color.yellow.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        // 只有当没有回退时才允许操作
                        if historyIndex == 0 {
                            showTeamAActions = true
                        }
                    }
                    .sheet(isPresented: $showTeamAActions) {
                        TeamActionsView(
                            isPresented: $showTeamAActions,
                            actingTeam: $game.teamA,
                            opposingTeam: $game.teamB,
                            game: $game,
                            onActionComplete: { 
                                // 更新显示的游戏状态
                                displayedGame = game
                                // 将更新后的游戏保存到GameManager
                                gameManager.updateCurrentGame(game: game)
                            }
                        )
                    }
                
                // 分隔线
                Rectangle()
                    .frame(width: 2, height: 100)
                    .foregroundColor(.gray.opacity(0.5))
                
                // B队信息
                TeamScoreView(team: $displayedGame.teamB, game: displayedGame)
                    .frame(maxWidth: .infinity)
                    .background(displayedGame.teamB.isDealer ? Color.yellow.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        // 只有当没有回退时才允许操作
                        if historyIndex == 0 {
                            showTeamBActions = true
                        }
                    }
                    .sheet(isPresented: $showTeamBActions) {
                        TeamActionsView(
                            isPresented: $showTeamBActions,
                            actingTeam: $game.teamB,
                            opposingTeam: $game.teamA,
                            game: $game,
                            onActionComplete: {
                                // 更新显示的游戏状态
                                displayedGame = game
                                // 将更新后的游戏保存到GameManager
                                gameManager.updateCurrentGame(game: game)
                            }
                        )
                    }
            }
            .frame(height: 150)
            
            // 回合历史记录列表
            List {
                ForEach(Array(displayedGame.rounds.enumerated().reversed()), id: \.element.id) { index, round in
                    RoundHistoryRow(round: round, roundNumber: displayedGame.rounds.count - index)
                }
            }
            .listStyle(PlainListStyle())
            
            // 第二排 - 回退和前进按钮
            HStack {
                // 回退按钮
                Button(action: {
                    if historyIndex < game.rounds.count - 1 {
                        historyIndex += 1
                        // 更新显示的游戏状态
                        updateDisplayedGame()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title2)
                        Text("回退")
                            .font(.headline)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.2)))
                }
                .disabled(historyIndex >= game.rounds.count - 1)
                
                Spacer()
                
                // 前进按钮
                Button(action: {
                    if historyIndex > 0 {
                        historyIndex -= 1
                        // 更新显示的游戏状态
                        updateDisplayedGame()
                    }
                }) {
                    HStack {
                        Text("前进")
                            .font(.headline)
                        Image(systemName: "arrow.uturn.forward")
                            .font(.title2)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.2)))
                }
                .disabled(historyIndex <= 0)
            }
            .padding()
        }
        .navigationTitle("对局")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 初始化显示状态
            displayedGame = game
        }
    }
    
    // 根据历史索引更新显示的游戏状态
    private func updateDisplayedGame() {
        if historyIndex == 0 {
            // 如果索引为0，显示当前状态
            displayedGame = game
        } else if game.rounds.count >= historyIndex {
            // 创建一个游戏副本，只包含到指定历史点的回合
            var historicalGame = game
            historicalGame.rounds = Array(game.rounds.prefix(game.rounds.count - historyIndex))
            
            // 从最后一轮获取队伍状态
            if let lastRound = historicalGame.rounds.last {
                historicalGame.teamA = lastRound.teamA
                historicalGame.teamB = lastRound.teamB
            }
            
            displayedGame = historicalGame
        }
    }
}

// 队伍分数视图
struct TeamScoreView: View {
    @Binding var team: TeamStatus
    var game: Game // 添加game参数以访问rounds信息
    
    var body: some View {
        VStack(spacing: 5) {
            // 胜利标记
            if team.isWinner {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .padding(.bottom, 2)
            }
            
            // 玩家名称
            Text("\(team.player1) & \(team.player2)")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // 庄家标记 - 只有在最后一轮本队是庄家时才显示
            if game.rounds.last?.dealerTeamId == team.id {
                Text("(庄)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            // 空白间隔
            Spacer()
                .frame(height: 5)
            
            // 显示级别值
            Text("\(team.currentLevel.rawValue)")
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.vertical)
    }
}

// 回合历史行
struct RoundHistoryRow: View {
    let round: Round
    let roundNumber: Int
    
    var body: some View {
        HStack {
            Text("第\(roundNumber)回合")
                .font(.headline)
            
            Spacer()
            
            // 显示这一回合的操作
            Text(actionDescription(round: round))
                .font(.body)
        }
        .padding(.vertical, 5)
    }
    
    private func actionDescription(round: Round) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: round.timestamp)
        
        if round.actionType == .doubleContribute {
            return "[\(timeString)] \(round.actingTeamName) 双贡 \(round.level.rawValue)"
        } else if round.actionType == .singleContribute {
            return "[\(timeString)] \(round.actingTeamName) 单贡 \(round.level.rawValue)"
        } else if round.actionType == .selfContribute {
            return "[\(timeString)] \(round.actingTeamName) 自贡 \(round.level.rawValue)"
        } else if round.actionType == .win {
            return "[\(timeString)] \(round.actingTeamName) 获胜"
        } else {
            return "[\(timeString)] 未知操作"
        }
    }
}

// 队伍操作视图
struct TeamActionsView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    @Binding var actingTeam: TeamStatus
    @Binding var opposingTeam: TeamStatus
    @Binding var game: Game
    var onActionComplete: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("\(actingTeam.player1) & \(actingTeam.player2)")
                    .font(.headline)
                
                // 显示当前级别
                Text("当前级别: \(actingTeam.currentLevel.rawValue)")
                    .font(.title)
                
                Divider()
                
                // 双贡按钮
                ActionButton(title: "双贡", systemImage: "arrow.up.arrow.up", color: .red) {
                    var tempActing = actingTeam
                    var tempOpposing = opposingTeam
                    game.doubleContribution(fromTeam: &tempActing, toTeam: &tempOpposing)
                    // 确保仅有一方是庄家
                    if tempOpposing.isDealer {
                        tempActing.isDealer = false
                    }
                    // 保存全局的状态变化
                    if actingTeam.id == game.teamA.id {
                        game.teamA = tempActing
                        game.teamB = tempOpposing
                    } else {
                        game.teamA = tempOpposing
                        game.teamB = tempActing
                    }
                    actingTeam = tempActing
                    opposingTeam = tempOpposing
                    isPresented = false
                    onActionComplete?()
                }
                
                // 单贡按钮
                ActionButton(title: "单贡", systemImage: "arrow.up", color: .orange) {
                    var tempActing = actingTeam
                    var tempOpposing = opposingTeam
                    game.singleContribution(fromTeam: &tempActing, toTeam: &tempOpposing)
                    // 确保仅有一方是庄家
                    if tempOpposing.isDealer {
                        tempActing.isDealer = false
                    }
                    // 保存全局的状态变化
                    if actingTeam.id == game.teamA.id {
                        game.teamA = tempActing
                        game.teamB = tempOpposing
                    } else {
                        game.teamA = tempOpposing
                        game.teamB = tempActing
                    }
                    actingTeam = tempActing
                    opposingTeam = tempOpposing
                    isPresented = false
                    onActionComplete?()
                }
                
                // 自贡按钮
                ActionButton(title: "自贡", systemImage: "arrow.uturn.up", color: .blue) {
                    var tempActing = actingTeam
                    game.selfContribution(team: &tempActing)
                    // 保存全局的状态变化
                    if actingTeam.id == game.teamA.id {
                        game.teamA = tempActing
                    } else {
                        game.teamB = tempActing
                    }
                    actingTeam = tempActing
                    isPresented = false
                    onActionComplete?()
                }
                
                // 胜利按钮 (当A级别时或对方A3时显示)
                if actingTeam.currentLevel.rawValue.hasPrefix("A") || 
                   opposingTeam.currentLevel == .aceThree {
                    ActionButton(title: "胜利", systemImage: "crown", color: .green) {
                        var tempActing = actingTeam
                        game.winGame(team: &tempActing)
                        // 保存全局的状态变化
                        if actingTeam.id == game.teamA.id {
                            game.teamA = tempActing
                        } else {
                            game.teamB = tempActing
                        }
                        actingTeam = tempActing
                        isPresented = false
                        onActionComplete?()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("队伍操作")
            .navigationBarItems(trailing: Button("关闭") {
                isPresented = false
            })
        }
    }
}

// 操作按钮
struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
