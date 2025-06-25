import Foundation
import os

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
    var id = UUID()
    var player1: String
    var player2: String
    var currentLevel: GuandanLevel
    var isDealer: Bool
    var isWinner: Bool = false
    
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
    var id = UUID()
    var teamA: TeamStatus
    var teamB: TeamStatus
    var timestamp: Date = Date()
    var notes: String = ""
    
    // 新增属性
    var actionType: RoundActionType = .doubleContribute
    var actingTeamName: String = ""
    var level: GuandanLevel = .two
    var dealerTeamId: UUID? // 当前回合的庄家队伍ID
    var logMessage: String = "" // 回合日志信息
    
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
    
    // 生成回合日志信息
    mutating func generateLogMessage() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = dateFormatter.string(from: timestamp)
        
        // 对阵信息（包含比分）
        let teamAInfo = "\(teamA.player1) & \(teamA.player2) [\(teamA.currentLevel.rawValue)\(teamA.isDealer ? "(庄)" : "")]"
        let teamBInfo = "\(teamB.player1) & \(teamB.player2) [\(teamB.currentLevel.rawValue)\(teamB.isDealer ? "(庄)" : "")]"
        
        // 操作信息
        var actionInfo = ""
        switch actionType {
        case .doubleContribute:
            actionInfo = "\(actingTeamName) 双贡 \(level.rawValue)"
        case .singleContribute:
            actionInfo = "\(actingTeamName) 单贡 \(level.rawValue)"
        case .selfContribute:
            actionInfo = "\(actingTeamName) 自贡 \(level.rawValue)"
        case .win:
            actionInfo = "\(actingTeamName) 获胜"
        }
        
        // 详细比分信息
        let teamALevel = teamA.currentLevel.rawValue
        let teamBLevel = teamB.currentLevel.rawValue
        let dealerMark = teamA.isDealer ? "A队庄" : "B队庄"
        let scoreInfo = "比分：A队[\(teamALevel)] vs B队[\(teamBLevel)] | \(dealerMark)"
        
        // 结果信息
        var resultInfo = ""
        if let winner = self.winner {
            let winnerTeam = winner.id == teamA.id ? "A队" : "B队"
            let loserTeam = winner.id == teamA.id ? "B队" : "A队"
            let winnerLevel = winner.id == teamA.id ? teamA.currentLevel.rawValue : teamB.currentLevel.rawValue
            let loserLevel = winner.id == teamA.id ? teamB.currentLevel.rawValue : teamA.currentLevel.rawValue
            resultInfo = "游戏结束，\(winnerTeam)(\(winner.displayName)) \(winnerLevel) : \(loserLevel) \(loserTeam) 获胜！"
        }
        
        // 组合日志信息
        logMessage = "[\(timeString)] \(teamAInfo) VS \(teamBInfo) | \(actionInfo) | \(scoreInfo) | \(resultInfo)"
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
    var id = UUID()
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
    mutating func doubleContribution(fromTeamId: UUID) {
        // 确定操作的队伍
        var fromTeam: TeamStatus
        var toTeam: TeamStatus
        
        if fromTeamId == teamA.id {
            fromTeam = teamA
            toTeam = teamB
        } else {
            fromTeam = teamB
            toTeam = teamA
        }
        
        OSLogger.logGameAction("[双贡开始] fromTeam: \(fromTeam.player1)&\(fromTeam.player2)(\(fromTeam.currentLevel.rawValue)), toTeam: \(toTeam.player1)&\(toTeam.player2)(\(toTeam.currentLevel.rawValue))")
        OSLogger.logGameAction("[双贡前庄家] fromTeam.isDealer: \(fromTeam.isDealer), toTeam.isDealer: \(toTeam.isDealer)")
        
        let oldLevel = toTeam.currentLevel
        
        // 根据新规则：如果对方当前是A1~A3，对方获得本局的最终胜利
        if toTeam.currentLevel.isALevel {
            toTeam.isWinner = true
            isCompleted = true
            endTime = Date()
            OSLogger.logGameAction("[双贡胜利] \(toTeam.player1)&\(toTeam.player2) 在A级别时接受双贡，直接获胜")
        } else {
            // 如果对方当前是2~K，对方升3级，最多升级到A1
            let newLevel = toTeam.currentLevel.limitedLevelUp(by: 3)
            toTeam.currentLevel = newLevel
            OSLogger.logGameAction("[双贡升级] \(toTeam.player1)&\(toTeam.player2): \(oldLevel.rawValue) -> \(newLevel.rawValue)")
            
            // 转换庄家到受贡方
            if fromTeam.isDealer {
                toTeam.isDealer = true
                fromTeam.isDealer = false
                OSLogger.logGameAction("[双贡庄家转换] 庄家从 \(fromTeam.player1)&\(fromTeam.player2) 转到 \(toTeam.player1)&\(toTeam.player2)")
            }
        }
        
        // 更新游戏中的队伍状态
        OSLogger.logGameAction("[双贡前游戏状态] teamA: \(teamA.player1)&\(teamA.player2)(\(teamA.currentLevel.rawValue)), teamB: \(teamB.player1)&\(teamB.player2)(\(teamB.currentLevel.rawValue))")
        if fromTeamId == teamA.id {
            teamA = fromTeam
            teamB = toTeam
            OSLogger.logGameAction("[双贡更新游戏] teamA=fromTeam, teamB=toTeam")
        } else {
            teamA = toTeam
            teamB = fromTeam
            OSLogger.logGameAction("[双贡更新游戏] teamA=toTeam, teamB=fromTeam")
        }
        OSLogger.logGameAction("[双贡后游戏状态] teamA: \(teamA.player1)&\(teamA.player2)(\(teamA.currentLevel.rawValue)), teamB: \(teamB.player1)&\(teamB.player2)(\(teamB.currentLevel.rawValue))")
        
        // 记录回合
        var newRound = Round(teamA: teamA, teamB: teamB)
        newRound.actionType = .doubleContribute
        newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
        newRound.level = toTeam.currentLevel
        newRound.dealerTeamId = toTeam.id // 双贡后对方打庄
        
        // 生成日志信息
        newRound.generateLogMessage()
        OSLogger.logGameAction("回合日志: \(newRound.logMessage)")
        OSLogger.logGameAction("[回合日志写入] \(newRound.logMessage)")
        
        rounds.append(newRound)
    }
    
    // 单贡操作 - 一方单下，另一方升级
    mutating func singleContribution(fromTeam: inout TeamStatus, toTeam: inout TeamStatus) {
        let oldLevel = toTeam.currentLevel
        
        // 根据新规则处理不同情况
        if toTeam.currentLevel.isALevel {
            // 如果对方当前是A1~A3，对方获得本局的胜利，结束本局
            toTeam.isWinner = true
            isCompleted = true
            endTime = Date()
            OSLogger.logGameAction("[单贡胜利] \(toTeam.player1)&\(toTeam.player2) 在A级别时接受单贡，直接获胜")
        } else {
            // 如果对方当前是2~K，对方升2级，最多升级到A1
            let newLevel = toTeam.currentLevel.limitedLevelUp(by: 2)
            toTeam.currentLevel = newLevel
            OSLogger.logGameAction("[单贡升级] \(toTeam.player1)&\(toTeam.player2): \(oldLevel.rawValue) -> \(newLevel.rawValue)")
            
            // 转换庄家到受贡方
            if fromTeam.isDealer {
                toTeam.isDealer = true
                fromTeam.isDealer = false
            }
        }
        
        // 更新游戏中的队伍状态
        if fromTeam.id == teamA.id {
            teamA = fromTeam
            teamB = toTeam
        } else {
            teamA = toTeam
            teamB = fromTeam
        }
        
        // 确保inout参数与游戏状态同步
        if fromTeam.id == teamA.id {
            fromTeam = teamA
            toTeam = teamB
        } else {
            fromTeam = teamB
            toTeam = teamA
        }
        
        // 记录回合
        var newRound = Round(teamA: teamA, teamB: teamB)
        newRound.actionType = .singleContribute
        newRound.actingTeamName = "\(fromTeam.player1) & \(fromTeam.player2)"
        newRound.level = toTeam.currentLevel
        newRound.dealerTeamId = toTeam.id // 单贡后对方打庄
        
        // 生成日志信息
        newRound.generateLogMessage()
        OSLogger.logGameAction("回合日志: \(newRound.logMessage)")
        OSLogger.logGameAction("[回合日志写入] \(newRound.logMessage)")
        
        rounds.append(newRound)
    }
    
    // 自贡操作 - 升1级
    mutating func selfContribution(team: inout TeamStatus) {
        // 根据新规则：如果本队当前是A3，本队3次A不过，本队本局失败，对方获得本局的胜利
        if team.currentLevel == .aceThree {
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
            // 生成日志信息
            newRound.generateLogMessage()
            OSLogger.logGameAction("回合日志: \(newRound.logMessage)")
            OSLogger.logGameAction("[回合日志写入] \(newRound.logMessage)")
            
            rounds.append(newRound)
            return
        }
        
        // 根据新规则：如果本队当前是2~A2，本队升1级，还是本队打庄
        // (即除了A3的所有情况)
        if let newLevel = team.currentLevel.nextLevel() {
            team.currentLevel = newLevel
            
            // 自贡后，自贡方应该是庄家
            if !team.isDealer {
                // 如果自贡方不是庄家，需要转换庄家
                team.isDealer = true
                
                // 对方失去庄家身份
                if team.id == teamA.id {
                    teamB.isDealer = false
                } else {
                    teamA.isDealer = false
                }
            }
            
            // 更新游戏中的队伍状态
            if team.id == teamA.id {
                teamA = team
                // 确保inout参数与游戏状态同步
                team = teamA
            } else {
                teamB = team
                // 确保inout参数与游戏状态同步  
                team = teamB
            }
            
            var newRound = Round(teamA: teamA, teamB: teamB)
            newRound.actionType = .selfContribute
            newRound.actingTeamName = "\(team.player1) & \(team.player2)"
            newRound.level = team.currentLevel
            newRound.dealerTeamId = team.id // 自贡后自己还是庄家
            
            // 生成日志信息
            newRound.generateLogMessage()
            OSLogger.logGameAction("回合日志: \(newRound.logMessage)")
            OSLogger.logGameAction("[回合日志写入] \(newRound.logMessage)")
            
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
            // 生成日志信息
            finalRound.generateLogMessage()
            OSLogger.logGameAction("回合日志: \(finalRound.logMessage)")
            OSLogger.logGameAction("[回合日志写入] \(finalRound.logMessage)")
            
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
        
        // 不创建初始回合记录，让游戏从空白状态开始
        games.append(newGame)
        currentGame = newGame
        historyIndex = 0 // 重置历史索引
        saveGames()
        OSLogger.logInitialization("创建新游戏: \(teamA.player1) & \(teamA.player2) vs \(teamB.player1) & \(teamB.player2)")
        return newGame
    }
    
    // 更新当前游戏
    func updateCurrentGame(game: Game) {
        OSLogger.logDataOperation("[GameManager-更新游戏] 开始更新游戏 ID: \(game.id)")
        OSLogger.logDataOperation("[GameManager-更新前] teamA: \(game.teamA.currentLevel.rawValue), teamB: \(game.teamB.currentLevel.rawValue)")
        
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            OSLogger.logDataOperation("[GameManager-找到游戏] 在索引 \(index)")
            OSLogger.logDataOperation("[GameManager-旧游戏状态] teamA: \(games[index].teamA.currentLevel.rawValue), teamB: \(games[index].teamB.currentLevel.rawValue)")
            
            games[index] = game
            currentGame = game
            historyIndex = 0 // 重置历史索引
            
            OSLogger.logDataOperation("[GameManager-更新后] teamA: \(games[index].teamA.currentLevel.rawValue), teamB: \(games[index].teamB.currentLevel.rawValue)")
            OSLogger.logDataOperation("[GameManager-currentGame] teamA: \(currentGame?.teamA.currentLevel.rawValue ?? "nil"), teamB: \(currentGame?.teamB.currentLevel.rawValue ?? "nil")")
            
            saveGames()
            OSLogger.logDataOperation("[GameManager-保存完成]")
        } else {
            OSLogger.logDataOperation("[GameManager-错误] 未找到游戏 ID: \(game.id)")
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
        // 使用JSON文件存储替代UserDefaults
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            OSLogger.logDataOperation("无法获取文档目录")
            return
        }
        
        let gameDataURL = documentsDirectory.appendingPathComponent("games.json")
        
        do {
            let encoded = try JSONEncoder().encode(games)
            try encoded.write(to: gameDataURL)
            OSLogger.logDataOperation("游戏数据已保存到: \(gameDataURL.path)")
        } catch {
            OSLogger.logDataOperation("保存游戏数据失败: \(error)")
        }
    }
    
    // 加载游戏
    func loadGames() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            OSLogger.logDataOperation("无法获取文档目录")
            return
        }
        
        let gameDataURL = documentsDirectory.appendingPathComponent("games.json")
        OSLogger.logDataOperation("尝试从以下路径加载游戏数据: \(gameDataURL.path)")
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: gameDataURL.path) else {
            OSLogger.logDataOperation("游戏数据文件不存在，使用空数据")
            OSLogger.logDataOperation("当前games数组大小: \(games.count)")
            return
        }
        
        do {
            let data = try Data(contentsOf: gameDataURL)
            let decodedGames = try JSONDecoder().decode([Game].self, from: data)
            games = decodedGames
            OSLogger.logDataOperation("已加载 \(games.count) 个游戏记录")
        } catch {
            OSLogger.logDataOperation("加载游戏数据失败: \(error)")
            OSLogger.logDataOperation("当前games数组大小: \(games.count)")
        }
    }
    
    // 清除所有数据
    func clearAllData() {
        // 清除内存中的数据
        games = []
        currentGame = nil
        newGameSetup = nil
        historyIndex = 0
        
        // 清除文件中的数据
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            OSLogger.logDataOperation("无法获取文档目录")
            return
        }
        
        let gameDataURL = documentsDirectory.appendingPathComponent("games.json")
        
        // 删除文件
        do {
            try fileManager.removeItem(at: gameDataURL)
        } catch {
            OSLogger.logDataOperation("删除游戏数据文件失败: \(error)")
        }
        
        OSLogger.logDataOperation("所有数据已清除")
    }
    
    // 清除当前游戏的所有回合数据
    func clearCurrentGameRounds() {
        guard let currentGame = currentGame else { return }
        
        // 找到当前游戏在数组中的索引
        if let gameIndex = games.firstIndex(where: { $0.id == currentGame.id }) {
            // 清除回合数据，重置队伍状态
            var clearedGame = games[gameIndex]
            clearedGame.rounds = []
            
            // 重置队伍级别和状态
            clearedGame.teamA.currentLevel = .two
            clearedGame.teamB.currentLevel = .two
            clearedGame.teamA.isWinner = false
            clearedGame.teamB.isWinner = false
            clearedGame.isCompleted = false
            
            // 更新游戏数组和当前游戏
            games[gameIndex] = clearedGame
            self.currentGame = clearedGame
            historyIndex = 0
            
            saveGames()
            OSLogger.logInitialization("已清除游戏回合数据: \(clearedGame.teamA.player1) & \(clearedGame.teamA.player2) vs \(clearedGame.teamB.player1) & \(clearedGame.teamB.player2)")
        }
    }
    
    init() {
        OSLogger.logInitialization("GameManager初始化开始")
        
        // 测试文件系统访问
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            OSLogger.logInitialization("Documents目录: \(documentsDirectory.path)")
        } else {
            OSLogger.logInitialization("无法获取Documents目录")
        }
        
        loadGames()
        OSLogger.logInitialization("GameManager初始化完成，games数量: \(games.count)")
        if !games.isEmpty {
            OSLogger.logInitialization("现有游戏:")
            for (index, game) in games.enumerated() {
                OSLogger.logInitialization("  游戏\(index + 1): \(game.teamA.player1) & \(game.teamA.player2) vs \(game.teamB.player1) & \(game.teamB.player2)")
            }
        } else {
            OSLogger.logInitialization("没有现有游戏")
        }
    }
}
