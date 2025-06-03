import Foundation

// 分数等级
enum ScoreLevel: String, CaseIterable {
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "J"
    case queen = "Q"
    case king = "K"
    case a1 = "A1"
    case a2 = "A2"
    case a3 = "A3"
    
    var next: ScoreLevel? {
        guard let index = ScoreLevel.allCases.firstIndex(of: self),
              index < ScoreLevel.allCases.count - 1 else { return nil }
        return ScoreLevel.allCases[index + 1]
    }
    
    func advance(by levels: Int) -> ScoreLevel {
        guard let index = ScoreLevel.allCases.firstIndex(of: self) else { return self }
        let newIndex = min(index + levels, ScoreLevel.allCases.count - 1)
        return ScoreLevel.allCases[newIndex]
    }
}

// 团队
struct Team: Identifiable, Codable {
    let id = UUID()
    var player1: String
    var player2: String
    var currentScore: ScoreLevel = .two
    var isDealer: Bool = false
    
    var displayName: String {
        "\(player1)、\(player2)"
    }
}

// 游戏记录
struct GameRecord: Identifiable, Codable {
    let id = UUID()
    var teamA: Team
    var teamB: Team
    var winner: TeamType?
    var createdAt: Date = Date()
    
    enum TeamType: String, Codable {
        case teamA = "A"
        case teamB = "B"
    }
    
    var displayResult: String {
        if let winner = winner {
            let winnerTeam = winner == .teamA ? teamA : teamB
            let loserTeam = winner == .teamA ? teamB : teamA
            return "\(winnerTeam.currentScore.rawValue)（胜）：\(loserTeam.currentScore.rawValue)"
        } else {
            return "\(teamA.currentScore.rawValue)：\(teamB.currentScore.rawValue)"
        }
    }
}

// 游戏动作
enum GameAction {
    case doubleContribution  // 双贡
    case singleContribution // 单贡
    case selfContribution   // 自贡
    case victory           // 胜利
} 