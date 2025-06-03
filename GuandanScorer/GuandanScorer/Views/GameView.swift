import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var game: Game
    @State private var showTeamAActions = false
    @State private var showTeamBActions = false
    @State private var historyIndex = 0 // 用于回退和前进
    
    var body: some View {
        VStack {
            // 第一排 - 队伍信息和分数
            HStack(spacing: 0) {
                // A队信息
                TeamScoreView(team: $game.teamA)
                    .frame(maxWidth: .infinity)
                    .background(game.teamA.isDealer ? Color.yellow.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        showTeamAActions = true
                    }
                    .sheet(isPresented: $showTeamAActions) {
                        TeamActionsView(
                            isPresented: $showTeamAActions,
                            actingTeam: $game.teamA,
                            opposingTeam: $game.teamB,
                            game: $game
                        )
                    }
                
                // 分隔线
                Rectangle()
                    .frame(width: 2, height: 100)
                    .foregroundColor(.gray.opacity(0.5))
                
                // B队信息
                TeamScoreView(team: $game.teamB)
                    .frame(maxWidth: .infinity)
                    .background(game.teamB.isDealer ? Color.yellow.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        showTeamBActions = true
                    }
                    .sheet(isPresented: $showTeamBActions) {
                        TeamActionsView(
                            isPresented: $showTeamBActions,
                            actingTeam: $game.teamB,
                            opposingTeam: $game.teamA,
                            game: $game
                        )
                    }
            }
            .frame(height: 150)
            .cornerRadius(10)
            .padding()
            
            // 回合历史记录列表
            List {
                ForEach(Array(game.rounds.enumerated().reversed()), id: \.element.id) { index, round in
                    RoundHistoryRow(round: round, roundNumber: game.rounds.count - index)
                }
            }
            .listStyle(PlainListStyle())
            
            // 第二排 - 回退和前进按钮
            HStack {
                // 回退按钮
                Button(action: {
                    if historyIndex < game.rounds.count - 1 {
                        historyIndex += 1
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title)
                        .padding()
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .disabled(historyIndex >= game.rounds.count - 1)
                
                Spacer()
                
                // 前进按钮
                Button(action: {
                    if historyIndex > 0 {
                        historyIndex -= 1
                    }
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title)
                        .padding()
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .disabled(historyIndex <= 0)
            }
            .padding()
        }
        .navigationTitle("对局")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 队伍分数视图
struct TeamScoreView: View {
    @Binding var team: TeamStatus
    
    var body: some View {
        VStack(spacing: 10) {
            // 队员名称
            Text("\(team.player1) & \(team.player2)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 当前分数
            Text(team.currentLevel.rawValue)
                .font(.system(size: 48, weight: .bold))
            
            // 庄家标识
            if team.isDealer {
                Text("庄家")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
            
            // 赢家标识
            if team.isWinner {
                Text("胜利")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// 回合历史行
struct RoundHistoryRow: View {
    let round: Round
    let roundNumber: Int
    
    var body: some View {
        HStack {
            // 回合编号
            Text("#\(roundNumber)")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            
            // A队状态
            HStack {
                if round.teamA.isDealer {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Text(round.teamA.currentLevel.rawValue)
                    .font(.headline)
                
                if round.teamA.isWinner {
                    Text("(胜)")
                        .foregroundColor(.green)
                }
            }
            
            Text("vs")
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // B队状态
            HStack {
                if round.teamB.isWinner {
                    Text("(胜)")
                        .foregroundColor(.green)
                }
                
                Text(round.teamB.currentLevel.rawValue)
                    .font(.headline)
                
                if round.teamB.isDealer {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // 时间
            Text(formatDate(round.timestamp))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// 队伍操作视图
struct TeamActionsView: View {
    @Binding var isPresented: Bool
    @Binding var actingTeam: TeamStatus
    @Binding var opposingTeam: TeamStatus
    @Binding var game: Game
    
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
                    actingTeam = tempActing
                    opposingTeam = tempOpposing
                    isPresented = false
                }
                
                // 单贡按钮
                ActionButton(title: "单贡", systemImage: "arrow.up", color: .orange) {
                    var tempActing = actingTeam
                    var tempOpposing = opposingTeam
                    game.singleContribution(fromTeam: &tempActing, toTeam: &tempOpposing)
                    actingTeam = tempActing
                    opposingTeam = tempOpposing
                    isPresented = false
                }
                
                // 自贡按钮
                ActionButton(title: "自贡", systemImage: "arrow.uturn.up", color: .blue) {
                    var tempActing = actingTeam
                    game.selfContribution(team: &tempActing)
                    actingTeam = tempActing
                    isPresented = false
                }
                
                // 胜利按钮 (当A级别时或对方A3时显示)
                if actingTeam.currentLevel.rawValue.hasPrefix("A") || 
                   opposingTeam.currentLevel == .aceThree {
                    ActionButton(title: "胜利", systemImage: "crown", color: .green) {
                        var tempActing = actingTeam
                        game.winGame(team: &tempActing)
                        actingTeam = tempActing
                        isPresented = false
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

#Preview {
    NavigationView {
        GameView(
            game: .constant(
                Game(
                    teamA: TeamStatus(
                        player1: "张三",
                        player2: "李四",
                        currentLevel: .five,
                        isDealer: true
                    ),
                    teamB: TeamStatus(
                        player1: "王五",
                        player2: "赵六",
                        currentLevel: .jack,
                        isDealer: false
                    ),
                    startTime: Date()
                )
            )
        )
        .environmentObject(GameManager())
    }
}
