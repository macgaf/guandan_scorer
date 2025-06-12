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
    
    // 判断是否为A级别
    var isALevel: Bool {
        return self == .aceOne || self == .aceTwo || self == .aceThree
    }
    
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
        // 如果当前级别是K或以下，最多只能升到A1
        if self == .king {
            return .aceOne
        }
        
        if let next = self.nextLevel(), 
           let nextNext = next.nextLevel(),
           let nextNextNext = nextNext.nextLevel() {
            return nextNextNext
        }
        return nil
    }
    
    // 根据规则限制升级，最多只能升到A1
    func limitedLevelUp(by levels: Int) -> GuandanLevel {
        var result = self
        var remainingLevels = levels
        
        while remainingLevels > 0 && result != .aceThree {
            if result == .king && remainingLevels >= 1 {
                // 如果当前是K，无论还要升几级，最多只能升到A1
                return .aceOne
            }
            
            if let next = result.nextLevel() {
                result = next
                remainingLevels -= 1
            } else {
                break
            }
        }
        
        return result
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
    
    // 指定需要编码/解码的属性
    private enum CodingKeys: String, CodingKey {
        case  player1, player2, currentLevel, isDealer, isWinner
    }
    
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
    var dealerTeamId: UUID? // 当前回合的庄家队伍ID
    
    // 指定需要编码/解码的属性
    private enum CodingKeys: String, CodingKey {
        case teamA, teamB, timestamp, notes, actionType, actingTeamName, level, dealerTeamId
    }
    
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
    
    // 指定需要编码/解码的属性
    private enum CodingKeys: String, CodingKey {
        case teamA, teamB, rounds, startTime, endTime, isCompleted
    }
    
    // 当前回合
    var currentRound: Round? {
        rounds.last
    }
    
    // 双贡操作 - A队双下，B队升3级
    mutating func doubleContribution(fromTeam: inout TeamStatus, toTeam: inout TeamStatus) {
        // 根据规则，对方双贡，本方升3级，但最多只能升到A1
        let newLevel = toTeam.currentLevel.limitedLevelUp(by: 3)
        toTeam.currentLevel = newLevel
        
        // 只有当前庄家没有取胜时，才会转换庄家
        if fromTeam.isDealer {
            toTeam.isDealer = true
            fromTeam.isDealer = false
        }
        
        // 如果对方是A级别且是庄家，则本方获胜
        if fromTeam.isDealer && toTeam.currentLevel.isALevel {
            toTeam.isWinner = true
            isCompleted = true
            endTime = Date()
        }
        
        // 记录回合
        var newRound = Round(teamA: teamA, teamB: teamB)
        newRound.actionType = .doubleContribute
        newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
        newRound.level = toTeam.currentLevel
        newRound.dealerTeamId = toTeam.id // 双贡后对方打庄
        
        // 更新队伍状态
        if fromTeam.id == teamA.id {
            newRound.teamA = fromTeam
            newRound.teamB = toTeam
        } else {
            newRound.teamA = toTeam
            newRound.teamB = fromTeam
        }
        
        rounds.append(newRound)
    }
    
    // 单贡操作 - 一方单下，另一方升2级
    mutating func singleContribution(fromTeam: inout TeamStatus, toTeam: inout TeamStatus) {
        // 根据规则，对方单贡，本方升2级，但最多只能升到A1
        let newLevel = toTeam.currentLevel.limitedLevelUp(by: 2)
        toTeam.currentLevel = newLevel
        
        // 只有当前庄家没有取胜时，才会转换庄家
        if fromTeam.isDealer {
            toTeam.isDealer = true
            fromTeam.isDealer = false
        }
        
        // 如果对方是A级别且是庄家，则本方获胜
        if fromTeam.isDealer && toTeam.currentLevel.isALevel {
            toTeam.isWinner = true
            isCompleted = true
            endTime = Date()
        }
        
        // 记录回合
        var newRound = Round(teamA: teamA, teamB: teamB)
        newRound.actionType = .singleContribute
        newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
        newRound.level = toTeam.currentLevel
        newRound.dealerTeamId = toTeam.id // 单贡后对方打庄
        
        // 更新队伍状态
        if fromTeam.id == teamA.id {
            newRound.teamA = fromTeam
            newRound.teamB = toTeam
        } else {
            newRound.teamA = toTeam
            newRound.teamB = fromTeam
        }
        
        rounds.append(newRound)
    }
    
    // 自贡操作 - 升1级
    mutating func selfContribution(team: inout TeamStatus) {
        // 如果当前是A3级别且是庄家，则失败，对方获胜
        if team.currentLevel == .aceThree && team.isDealer {
            // 找到对方
            var opposingTeam: TeamStatus
            if team.id == teamA.id {
                opposingTeam = teamB
                opposingTeam.isWinner = true
                teamB = opposingTeam
            } else {
                opposingTeam = teamA
                opposingTeam.isWinner = true
                teamA = opposingTeam
            }
            
            isCompleted = true
            endTime = Date()
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .selfContribute
            newRound.actingTeamName = "\(team.player1) & \(team.player2)"
            newRound.level = team.currentLevel
            newRound.dealerTeamId = team.id // 自贡后自己还是庄家
            rounds.append(newRound)
            return
        }
        
        // 如果是A1或A2级别，可以继续升级
        // 如果是其他级别，正常升1级
        if let newLevel = team.currentLevel.nextLevel() {
            team.currentLevel = newLevel
            // 自贡不改变庄家
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .selfContribute
            newRound.actingTeamName = "\(team.player1) & \(team.player2)"
            newRound.level = team.currentLevel
            newRound.dealerTeamId = team.id // 自贡后自己还是庄家
            
            // 更新队伍状态
            if team.id == teamA.id {
                newRound.teamA = team
                newRound.teamB = teamB
            } else {
                newRound.teamA = teamA
                newRound.teamB = team
            }
            
            rounds.append(newRound)
        }
    }
    
    // 胜利操作
    mutating func winGame(team: inout TeamStatus) {
        // 只有当庄家在A级别时，才能直接获胜
        if team.isDealer && team.currentLevel.isALevel {
            team.isWinner = true
            isCompleted = true
            endTime = Date()
            
            // 更新队伍状态
            if team.id == teamA.id {
                teamA.isWinner = true
            } else {
                teamB.isWinner = true
            }
            
            var finalRound = Round(teamA: teamA, teamB: teamB)
            finalRound.actionType = .win
            finalRound.actingTeamName = "\(team.player1) & \(team.player2)"
            finalRound.level = team.currentLevel
            finalRound.dealerTeamId = team.id // 获胜方应该是庄家
            rounds.append(finalRound)
        }
    }
}

// 游戏管理器
class GameManager: ObservableObject {
    @Published var games: [Game] = []
    @Published var currentGame: Game?
    @Published var newGameSetup: NewGameSetup?
    @Published var historyIndex: Int = 0 // 用于回退和前进功能
    
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
        
        // 创建初始回合记录
        var initialGame = newGame
        let initialRound = Round(teamA: teamA, teamB: teamB)
        initialGame.rounds = [initialRound]
        
        games.append(initialGame)
        currentGame = initialGame
        historyIndex = 0 // 重置历史索引
        saveGames()
        return initialGame
    }
    
    // 更新当前游戏
    func updateCurrentGame(game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
            currentGame = game
            historyIndex = 0 // 重置历史索引
            saveGames()
        }
    }
    
    // 删除游戏
    func deleteGame(game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games.remove(at: index)
            if currentGame?.id == game.id {
                currentGame = nil
            }
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
    
    // 结束游戏
    func endGame(game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index].isCompleted = true
            games[index].endTime = Date()
            if currentGame?.id == game.id {
                currentGame = games[index]
            }
            saveGames()
        }
    }
    
    // 回退操作
    func stepBack() -> Game? {
        guard let game = currentGame, !game.rounds.isEmpty, historyIndex < game.rounds.count - 1 else {
            return nil
        }
        
        historyIndex += 1
        return getHistoricalGameState(game: game, historyIndex: historyIndex)
    }
    
    // 前进操作
    func stepForward() -> Game? {
        guard let game = currentGame, historyIndex > 0 else {
            return nil
        }
        
        historyIndex -= 1
        return getHistoricalGameState(game: game, historyIndex: historyIndex)
    }
    
    // 获取历史游戏状态
    func getHistoricalGameState(game: Game, historyIndex: Int) -> Game {
        if historyIndex == 0 || game.rounds.isEmpty {
            return game
        }
        
        // 创建一个游戏副本，只包含到指定历史点的回合
        var historicalGame = game
        let roundsToInclude = max(0, game.rounds.count - historyIndex)
        historicalGame.rounds = Array(game.rounds.prefix(roundsToInclude))
        
        // 从最后一轮获取队伍状态
        if let lastRound = historicalGame.rounds.last {
            historicalGame.teamA = lastRound.teamA
            historicalGame.teamB = lastRound.teamB
        }
        
        return historicalGame
    }
    
    // 存储游戏
    func saveGames() {
        // 这里使用UserDefaults临时存储数据
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
