import SwiftUI
import os

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var game: Game
    @State private var showTeamAActions = false
    @State private var showTeamBActions = false
    @State private var historyIndex = 0 // 用于回退和前进
    @State private var displayedGame: Game // 用于显示当前状态
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(game: Binding<Game>) {
        self._game = game
        self._displayedGame = State(initialValue: game.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: horizontalSizeClass == .compact ? 10 : 20) {
            // 第一排 - 队伍信息和分数
            HStack(spacing: 0) {
                // A队信息
                TeamScoreView(team: $displayedGame.teamA, game: displayedGame)
                    .frame(maxWidth: .infinity)
                    .background(displayedGame.teamA.isDealer ? Color.orange.opacity(0.15) : Color.clear)
                    .onTapGesture {
                        // 记录点击事件
                        OSLogger.logInputEvent("点击 - 目标: A队(\(displayedGame.teamA.player1) & \(displayedGame.teamA.player2)) - 详情: 当前级别: \(displayedGame.teamA.currentLevel.rawValue)")
                        
                        // 只有当没有回退且本局没有出现获胜方时才允许操作
                        if historyIndex == 0 && !game.isCompleted {
                            showTeamAActions = true
                        }
                    }
                    .sheet(isPresented: $showTeamAActions) {
                        TeamActionsView(
                            isPresented: $showTeamAActions,
                            actingTeam: .constant(game.teamA),
                            opposingTeam: .constant(game.teamB),
                            game: $game,
                            onActionComplete: { 
                                // 更新显示的游戏状态
                                displayedGame = game
                                
                                // 将更新后的游戏保存到GameManager
                                gameManager.updateCurrentGame(game: game)
                                
                                // 确保UI更新
                                OSLogger.logUIAction("[视图-操作完成后] displayedGame.teamA: \(displayedGame.teamA.currentLevel.rawValue), displayedGame.teamB: \(displayedGame.teamB.currentLevel.rawValue)")
                            }
                        )
                    }
                
                // 分隔线
                Rectangle()
                    .frame(width: 2, height: 100)
                    .foregroundColor(.secondary.opacity(0.5))
                
                // B队信息
                TeamScoreView(team: $displayedGame.teamB, game: displayedGame)
                    .frame(maxWidth: .infinity)
                    .background(displayedGame.teamB.isDealer ? Color.orange.opacity(0.15) : Color.clear)
                    .onTapGesture {
                        // 记录点击事件
                        OSLogger.logInputEvent("点击 - 目标: B队(\(displayedGame.teamB.player1) & \(displayedGame.teamB.player2)) - 详情: 当前级别: \(displayedGame.teamB.currentLevel.rawValue)")
                        
                        // 只有当没有回退且本局没有出现获胜方时才允许操作
                        if historyIndex == 0 && !game.isCompleted {
                            showTeamBActions = true
                        }
                    }
                    .sheet(isPresented: $showTeamBActions) {
                        TeamActionsView(
                            isPresented: $showTeamBActions,
                            actingTeam: .constant(game.teamB),
                            opposingTeam: .constant(game.teamA),
                            game: $game,
                            onActionComplete: {
                                // 更新显示的游戏状态
                                displayedGame = game
                                
                                // 将更新后的游戏保存到GameManager
                                gameManager.updateCurrentGame(game: game)
                                
                                // 确保UI更新
                                OSLogger.logUIAction("[视图-操作完成后] displayedGame.teamA: \(displayedGame.teamA.currentLevel.rawValue), displayedGame.teamB: \(displayedGame.teamB.currentLevel.rawValue)")
                            }
                        )
                    }
            }
            .frame(height: 150)
            
            // 第二排 - 回合历史记录列表（可上下滚动）
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(displayedGame.rounds.enumerated()), id: \.element.id) { index, round in
                        RoundHistoryRow(round: round, roundNumber: index + 1, game: displayedGame)
                            .id(round.id)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // 只有在最后一轮且没有回退时才能删除
                                if index == displayedGame.rounds.count - 1 && historyIndex == 0 {
                                    Button(role: .destructive) {
                                        deleteLastRound()
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: displayedGame.rounds.count) { oldCount, newCount in
                    // 新增回合时自动滚动到底部
                    if newCount > oldCount, let lastRound = displayedGame.rounds.last {
                        withAnimation {
                            proxy.scrollTo(lastRound.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // 第三排 - 回退和前进按钮
            HStack {
                // 回退按钮
                Button(action: {
                    // 记录按钮点击事件
                    OSLogger.logInputEvent("点击 - 目标: 回退按钮 - 详情: 当前历史索引: \(historyIndex)")
                    
                    if historyIndex < game.rounds.count {
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
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.2)))
                }
                .disabled(historyIndex >= game.rounds.count)
                
                Spacer()
                
                // 前进按钮
                Button(action: {
                    // 记录按钮点击事件
                    OSLogger.logInputEvent("点击 - 目标: 前进按钮 - 详情: 当前历史索引: \(historyIndex)")
                    
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
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.2)))
                }
                .disabled(historyIndex <= 0)
            }
            .padding()
        }
        .navigationTitle("对局")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // 记录界面初始化事件
            OSLogger.logInputEvent("点击 - 目标: GameView界面 - 详情: 界面初始化 - A队: \(game.teamA.player1) & \(game.teamA.player2) (\(game.teamA.currentLevel.rawValue)), B队: \(game.teamB.player1) & \(game.teamB.player2) (\(game.teamB.currentLevel.rawValue))")
            
            // 初始化显示状态
            displayedGame = game
            OSLogger.logUIAction("[GameView-onAppear] 初始化 displayedGame - teamA: \(displayedGame.teamA.currentLevel.rawValue), teamB: \(displayedGame.teamB.currentLevel.rawValue)")
        }
        .onDisappear {
            // 记录界面切换事件
            OSLogger.logInputEvent("点击 - 目标: GameView界面 - 详情: 界面切换 - 离开对局界面")
            
            // 不在这里清空currentGame，避免导航冲突
            OSLogger.logUIAction("[GameView-onDisappear] 视图即将消失")
        }
    }
    
    // 根据历史索引更新显示的游戏状态
    private func updateDisplayedGame() {
        if historyIndex == 0 {
            // 如果索引为0，显示当前状态
            displayedGame = game
        } else if historyIndex <= game.rounds.count {
            // 创建一个游戏副本，只包含到指定历史点的回合
            var historicalGame = game
            let roundsToShow = max(0, game.rounds.count - historyIndex)
            historicalGame.rounds = Array(game.rounds.prefix(roundsToShow))
            
            if historicalGame.rounds.isEmpty {
                // 重置到初始状态
                historicalGame.teamA.currentLevel = .two
                historicalGame.teamB.currentLevel = .two
                historicalGame.teamA.isWinner = false
                historicalGame.teamB.isWinner = false
                historicalGame.isCompleted = false
                // 保持初始庄家状态
                if let firstRound = game.rounds.first {
                    historicalGame.teamA.isDealer = firstRound.teamA.isDealer
                    historicalGame.teamB.isDealer = firstRound.teamB.isDealer
                }
            } else if let lastRound = historicalGame.rounds.last {
                // 从最后一轮获取队伍状态
                historicalGame.teamA = lastRound.teamA
                historicalGame.teamB = lastRound.teamB
            }
            
            displayedGame = historicalGame
        }
    }
    
    // 删除最后一轮
    private func deleteLastRound() {
        // 只有在没有回退（即显示最新状态）时才能删除
        guard game.rounds.count > 0 && historyIndex == 0 else { return }
        
        // 记录删除操作
        OSLogger.logInputEvent("滑动 - 目标: 最后一轮记录 - 详情: 删除第\(game.rounds.count)轮")
        
        // 删除最后一轮
        game.rounds.removeLast()
        
        // 更新队伍状态到上一轮的状态
        if let lastRound = game.rounds.last {
            game.teamA = lastRound.teamA
            game.teamB = lastRound.teamB
            // 重置游戏完成状态和获胜标记
            game.isCompleted = false
            game.teamA.isWinner = false
            game.teamB.isWinner = false
        } else {
            // 如果没有回合了，重置到初始状态
            game.teamA.currentLevel = .two
            game.teamB.currentLevel = .two
            game.teamA.isWinner = false
            game.teamB.isWinner = false
            game.isCompleted = false
        }
        
        // 更新显示的游戏
        displayedGame = game
        
        // 保存更改
        gameManager.updateCurrentGame(game: game)
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
            
            // 庄家标记
            if team.isDealer {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("庄家")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
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
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第\(roundNumber)回合")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 显示时间
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 显示队伍信息 - 左边A队，右边B队
            HStack(alignment: .top) {
                // A队信息（左边）
                VStack(alignment: .leading) {
                    Text("\(round.teamA.player1) & \(round.teamA.player2)")
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // B队信息（右边）
                VStack(alignment: .trailing) {
                    Text("\(round.teamB.player1) & \(round.teamB.player2)")
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // 回合操作结果 - 根据操作方决定位置
            HStack {
                if isActingTeamA {
                    // A队操作，结果靠左
                    Text(actionDescription)
                        .font(.callout)
                        .padding(6)
                        .background(actionColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                } else {
                    // B队操作，结果靠右
                    Spacer()
                    
                    Text(actionDescription)
                        .font(.callout)
                        .padding(6)
                        .background(actionColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            // 回合结束后的比分和庄家信息
            HStack {
                // A队比分和庄家
                HStack(spacing: 4) {
                    Text(round.teamA.currentLevel.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if round.teamA.isDealer {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(":")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // B队比分和庄家
                HStack(spacing: 4) {
                    if round.teamB.isDealer {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Text(round.teamB.currentLevel.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(8)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    // 判断是否是A队的操作
    private var isActingTeamA: Bool {
        // 根据操作团队名称判断
        return round.actingTeamName == "\(round.teamA.player1) & \(round.teamA.player2)"
    }
    
    // 格式化时间
    private var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: round.timestamp)
    }
    
    // 回合操作描述
    private var actionDescription: String {
        switch round.actionType {
        case .doubleContribute:
            return "\(round.actingTeamName) 双贡"
        case .singleContribute:
            return "\(round.actingTeamName) 单贡"
        case .selfContribute:
            return "\(round.actingTeamName) 自贡"
        case .win:
            return "\(round.actingTeamName) 获胜"
        }
    }
    
    // 根据操作类型返回不同颜色
    private var actionColor: Color {
        switch round.actionType {
        case .doubleContribute:
            return .red
        case .singleContribute:
            return .orange
        case .selfContribute:
            return .blue
        case .win:
            return .green
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
                ActionButton(title: "双贡", systemImage: "arrow.up.2", color: .red) {
                    // 记录按钮点击事件
                    OSLogger.logInputEvent("点击 - 目标: 双贡按钮 - 详情: 操作队伍: \(actingTeam.player1) & \(actingTeam.player2)")
                    
                    OSLogger.logUIAction("[视图-双贡按钮点击] actingTeam: \(actingTeam.player1)&\(actingTeam.player2), opposingTeam: \(opposingTeam.player1)&\(opposingTeam.player2)")
                    OSLogger.logUIAction("[视图-双贡前] game.teamA: \(game.teamA.currentLevel.rawValue), game.teamB: \(game.teamB.currentLevel.rawValue)")
                    
                    // 使用新的简化API
                    game.doubleContribution(fromTeamId: actingTeam.id)
                    OSLogger.logUIAction("[视图-双贡完成] game.teamA: \(game.teamA.currentLevel.rawValue), game.teamB: \(game.teamB.currentLevel.rawValue)")
                    
                    isPresented = false
                    onActionComplete?()
                }
                
                // 单贡按钮
                ActionButton(title: "单贡", systemImage: "arrow.up", color: .orange) {
                    // 直接使用game的引用进行操作
                    if actingTeam.id == game.teamA.id {
                        // A队单贡
                        var fromTeam = game.teamA
                        var toTeam = game.teamB
                        game.singleContribution(fromTeam: &fromTeam, toTeam: &toTeam)
                    } else {
                        // B队单贡
                        var fromTeam = game.teamB
                        var toTeam = game.teamA
                        game.singleContribution(fromTeam: &fromTeam, toTeam: &toTeam)
                    }
                    
                    isPresented = false
                    onActionComplete?()
                }
                
                // 自贡按钮
                ActionButton(title: "自贡", systemImage: "arrow.uturn.up", color: .blue) {
                    // 直接使用game的引用进行操作
                    if actingTeam.id == game.teamA.id {
                        // A队自贡
                        var team = game.teamA
                        game.selfContribution(team: &team)
                    } else {
                        // B队自贡
                        var team = game.teamB
                        game.selfContribution(team: &team)
                    }
                    
                    isPresented = false
                    onActionComplete?()
                }
                
                // 胜利按钮 (当A级别时或对方A3时显示)
                if actingTeam.currentLevel.rawValue.hasPrefix("A") || 
                   opposingTeam.currentLevel == .aceThree {
                    ActionButton(title: "胜利", systemImage: "crown", color: .green) {
                        // 直接使用game的引用进行操作
                        if actingTeam.id == game.teamA.id {
                            // A队胜利
                            var team = game.teamA
                            game.winGame(team: &team)
                        } else {
                            // B队胜利
                            var team = game.teamB
                            game.winGame(team: &team)
                        }
                        
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
