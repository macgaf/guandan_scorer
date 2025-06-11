import Foundation

// 惯蛋级别
enum GuandanLevel: String, CaseIterable, Identifiable, Codable {
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
    case aceOne = "A1"
    case aceTwo = "A2"
    case aceThree = "A3"
    
    var id: String { self.rawValue }
    
    // 获取下一级别
    func nextLevel() -> GuandanLevel? {
        switch self {
        case .two: return .three
        case .three: return .four
        case .four: return .five
        case .five: return .six
        case .six: return .seven
        case .seven: return .eight
        case .eight: return .nine
        case .nine: return .ten
        case .ten: return .jack
        case .jack: return .queen
        case .queen: return .king
        case .king: return .aceOne
        case .aceOne: return .aceTwo
        case .aceTwo: return .aceThree
        case .aceThree: return nil  // 已经是最高级别
        }
    }
    
    // 升级两级
    func levelUpByTwo() -> GuandanLevel? {
        if let next = self.nextLevel(), let nextNext = next.nextLevel() {
            return nextNext
        }
        return nil
    }
    
    // 升级三级
    func levelUpByThree() -> GuandanLevel? {
        if let next = self.nextLevel(), 
           let nextNext = next.nextLevel(),
           let nextNextNext = nextNext.nextLevel() {
            return nextNextNext
        }
        return nil
    }
}

// 队伍状态
struct TeamStatus: Codable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var player1: String
    var player2: String
    var currentLevel: GuandanLevel
    var isDealer: Bool
    var isWinner: Bool = false
    var score: Int = 0
    
    // 显示名称
    var displayName: String {
        return "\(player1) & \(player2)"
    }
}

// 回合记录
// 回合操作类型
enum RoundActionType: String, Codable {
    case doubleContribute = "双贡"
    case singleContribute = "单贡"
    case selfContribute = "自贡"
    case win = "获胜"
}

struct Round: Codable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var teamA: TeamStatus
    var teamB: TeamStatus
    var timestamp: Date = Date()
    var notes: String = ""
    
    // 新增属性
    var actionType: RoundActionType = .doubleContribute
    var actingTeamName: String = ""
    var level: GuandanLevel = .two
    
    // 初始化方法
    init(teamA: TeamStatus, teamB: TeamStatus) {
        self.teamA = teamA
        self.teamB = teamB
    }
    
    // 兼容旧的初始化方法
    init(teamA: TeamStatus, teamB: TeamStatus, timestamp: Date) {
        self.teamA = teamA
        self.teamB = teamB
        self.timestamp = timestamp
    }
    
    // 获取赢家
    var winner: TeamStatus? {
        if teamA.isWinner {
            return teamA
        } else if teamB.isWinner {
            return teamB
        }
        return nil
    }
}

// 新游戏设置
struct NewGameSetup {
    var teamAPlayer1: String
    var teamAPlayer2: String
    var teamBPlayer1: String
    var teamBPlayer2: String
}

// 对局
struct Game: Codable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var teamA: TeamStatus
    var teamB: TeamStatus
    var rounds: [Round] = []
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    
    // 当前回合
    var currentRound: Round? {
        rounds.last
    }
    
    // 双贡操作 - A队双下，B队升3级
    mutating func doubleContribution(fromTeam: inout TeamStatus, toTeam: inout TeamStatus) {
        if let newLevel = toTeam.currentLevel.levelUpByThree() {
            toTeam.currentLevel = newLevel
            toTeam.isDealer = true
            fromTeam.isDealer = false
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .doubleContribute
            newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
            newRound.level = toTeam.currentLevel
            rounds.append(newRound)
        }
    }
    
    // 单贡操作 - 一方单下，另一方升2级
    mutating func singleContribution(fromTeam: inout TeamStatus, toTeam: inout TeamStatus) {
        if let newLevel = toTeam.currentLevel.levelUpByTwo() {
            toTeam.currentLevel = newLevel
            toTeam.isDealer = true
            fromTeam.isDealer = false
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .singleContribute
            newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
            newRound.level = toTeam.currentLevel
            rounds.append(newRound)
        }
    }
    
    // 自贡操作 - 升1级
    mutating func selfContribution(team: inout TeamStatus) {
        if let newLevel = team.currentLevel.nextLevel() {
            team.currentLevel = newLevel
            // 自贡不改变庄家
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .selfContribute
            newRound.actingTeamName = "\(team.player1) & \(team.player2)"
            newRound.level = team.currentLevel
            rounds.append(newRound)
        }
    }
    
    // 胜利操作
    mutating func winGame(team: inout TeamStatus) {
        team.isWinner = true
        isCompleted = true
        endTime = Date()
        
        var updatedTeamA = teamA
        var updatedTeamB = teamB
        
        if team.id == teamA.id {
            updatedTeamA.isWinner = true
        } else {
            updatedTeamB.isWinner = true
        }
        
        var finalRound = Round(teamA: updatedTeamA, teamB: updatedTeamB)
        finalRound.actionType = .win
        finalRound.actingTeamName = "\(team.player1) & \(team.player2)"
        finalRound.level = team.currentLevel
        rounds.append(finalRound)
    }
}

// 游戏管理器
class GameManager: ObservableObject {
    @Published var games: [Game] = []
    @Published var currentGame: Game?
    @Published var newGameSetup: NewGameSetup?
    
    // 过滤游戏列表
    func filteredGames(searchText: String) -> [Game] {
        if searchText.isEmpty {
            return games
        }
        
        return games.filter { game in
            let teamAPlayers = "\(game.teamA.player1) \(game.teamA.player2)"
            let teamBPlayers = "\(game.teamB.player1) \(game.teamB.player2)"
            return teamAPlayers.contains(searchText) || teamBPlayers.contains(searchText)
        }
    }
    
    // 新建游戏
    func createNewGame(teamA: TeamStatus, teamB: TeamStatus) -> Game {
        let newGame = Game(
            teamA: teamA,
            teamB: teamB,
            startTime: Date()
        )
        games.append(newGame)
        currentGame = newGame
        saveGames()
        return newGame
    }
    
    // 结束游戏
    // 删除游戏
    func deleteGame(game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games.remove(at: index)
            saveGames()
        }
    }
    
    // 准备新游戏（来自现有游戏）
    func prepareNewGame(from game: Game) {
        newGameSetup = NewGameSetup(
            teamAPlayer1: game.teamA.player1,
            teamAPlayer2: game.teamA.player2,
            teamBPlayer1: game.teamB.player1,
            teamBPlayer2: game.teamB.player2
        )
    }
    
    func endGame(game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index].isCompleted = true
            games[index].endTime = Date()
            saveGames()
        }
    }
    
    // 存储游戏
    func saveGames() {
        // 这里使用UserDefaults临时存储数据
        // 在实际应用中，应该使用CoreData
        if let encoded = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(encoded, forKey: "SavedGames")
        }
    }
    
    // 加载游戏
    func loadGames() {
        if let savedGames = UserDefaults.standard.data(forKey: "SavedGames") {
            if let decodedGames = try? JSONDecoder().decode([Game].self, from: savedGames) {
                games = decodedGames
            }
        }
    }
    
    init() {
        loadGames()
    }
}
