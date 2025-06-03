import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var showingActionSheet = false
    @State private var selectedTeam: GameRecord.TeamType?
    
    var body: some View {
        VStack {
            if let game = gameViewModel.currentGame {
                // 团队显示区域
                HStack(spacing: 0) {
                    // A组
                    TeamView(
                        team: game.teamA,
                        teamType: .teamA,
                        onTap: {
                            selectedTeam = .teamA
                            showingActionSheet = true
                        }
                    )
                    
                    Divider()
                    
                    // B组
                    TeamView(
                        team: game.teamB,
                        teamType: .teamB,
                        onTap: {
                            selectedTeam = .teamB
                            showingActionSheet = true
                        }
                    )
                }
                .frame(maxHeight: .infinity)
                
                // 回退和前进按钮
                HStack(spacing: 40) {
                    Button(action: {
                        gameViewModel.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(gameViewModel.canUndo ? .blue : .gray)
                    }
                    .disabled(!gameViewModel.canUndo)
                    
                    Button(action: {
                        gameViewModel.redo()
                    }) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(gameViewModel.canRedo ? .blue : .gray)
                    }
                    .disabled(!gameViewModel.canRedo)
                }
                .padding()
            }
        }
        .navigationTitle("进行中")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("结束游戏") {
                gameViewModel.currentGame = nil
            }
        )
        .actionSheet(isPresented: $showingActionSheet) {
            actionSheet(for: selectedTeam)
        }
    }
    
    private func actionSheet(for team: GameRecord.TeamType?) -> ActionSheet {
        guard let team = team else {
            return ActionSheet(title: Text("选择操作"))
        }
        
        var buttons: [ActionSheet.Button] = [
            .default(Text("双贡")) {
                gameViewModel.performAction(for: team, action: .doubleContribution)
            },
            .default(Text("单贡")) {
                gameViewModel.performAction(for: team, action: .singleContribution)
            },
            .default(Text("自贡")) {
                gameViewModel.performAction(for: team, action: .selfContribution)
            }
        ]
        
        // 添加胜利按钮（如果满足条件）
        if gameViewModel.canShowVictoryButton(for: team) {
            buttons.append(
                .default(Text("胜利").foregroundColor(.green)) {
                    gameViewModel.performAction(for: team, action: .victory)
                }
            )
        }
        
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text("选择操作"),
            buttons: buttons
        )
    }
}

// 团队视图组件
struct TeamView: View {
    let team: Team
    let teamType: GameRecord.TeamType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                // 团队标识
                Text("\(teamType.rawValue)组")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 玩家姓名
                VStack(spacing: 8) {
                    Text(team.player1)
                        .font(.headline)
                    Text(team.player2)
                        .font(.headline)
                }
                
                // 当前分数
                Text(team.currentScore.rawValue)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.blue)
                
                // 庄家标示
                if team.isDealer {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("庄家")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(15)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GameView()
                .environmentObject(GameViewModel())
        }
    }
} 