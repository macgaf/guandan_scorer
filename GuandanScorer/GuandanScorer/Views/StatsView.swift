import SwiftUI

struct StatsView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("胜率排名")) {
                    ForEach(Array(teamStats.enumerated()), id: \.element.id) { index, stat in
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(stat.teamName)
                                    .font(.headline)
                                
                                HStack {
                                    Text("胜率: \(String(format: "%.1f%%", stat.winRate * 100))")
                                        .foregroundColor(.blue)
                                    
                                    Text("总盘数: \(stat.totalGames)")
                                        .foregroundColor(.gray)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("统计数据")
        }
    }
    
    // 计算每个队伍组合的胜率
    private var teamStats: [TeamStat] {
        // 收集所有组合
        var teamStatDict: [String: TeamStat] = [:]
        
        // 遍历所有已完成的游戏
        for game in gameManager.games.filter({ $0.isCompleted }) {
            // A队组合
            let teamAName = "\(game.teamA.player1) & \(game.teamA.player2)"
            let teamAKey = teamAName
            
            // B队组合
            let teamBName = "\(game.teamB.player1) & \(game.teamB.player2)"
            let teamBKey = teamBName
            
            // 更新A队统计
            var teamAStat = teamStatDict[teamAKey] ?? TeamStat(id: UUID(), teamName: teamAName)
            teamAStat.totalGames += 1
            if game.teamA.isWinner {
                teamAStat.wins += 1
            }
            teamStatDict[teamAKey] = teamAStat
            
            // 更新B队统计
            var teamBStat = teamStatDict[teamBKey] ?? TeamStat(id: UUID(), teamName: teamBName)
            teamBStat.totalGames += 1
            if game.teamB.isWinner {
                teamBStat.wins += 1
            }
            teamStatDict[teamBKey] = teamBStat
        }
        
        // 转换为数组并按胜率排序
        return teamStatDict.values.sorted { $0.winRate > $1.winRate }
    }
}

// 队伍统计数据模型
struct TeamStat: Identifiable {
    var id: UUID
    let teamName: String
    var wins: Int = 0
    var totalGames: Int = 0
    
    var winRate: Double {
        totalGames > 0 ? Double(wins) / Double(totalGames) : 0
    }
}

#Preview {
    StatsView()
        .environmentObject(GameManager())
}
