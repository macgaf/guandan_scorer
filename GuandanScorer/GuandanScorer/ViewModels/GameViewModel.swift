import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var gameRecords: [GameRecord] = []
    @Published var currentGame: GameRecord?
    @Published var searchText: String = ""
    
    // 游戏历史记录（用于回退和前进）
    private var gameHistory: [GameRecord] = []
    private var historyIndex: Int = -1
    
    var filteredGameRecords: [GameRecord] {
        if searchText.isEmpty {
            return gameRecords
        } else {
            return gameRecords.filter { record in
                record.teamA.player1.contains(searchText) ||
                record.teamA.player2.contains(searchText) ||
                record.teamB.player1.contains(searchText) ||
                record.teamB.player2.contains(searchText)
            }
        }
    }
    
    var canUndo: Bool {
        historyIndex > 0
    }
    
    var canRedo: Bool {
        historyIndex < gameHistory.count - 1
    }
    
    init() {
        loadGameRecords()
    }
    
    // 创建新游戏
    func createNewGame(teamA: Team, teamB: Team) {
        var newTeamA = teamA
        var newTeamB = teamB
        
        // 确保只有一个团队是庄家
        if !newTeamA.isDealer && !newTeamB.isDealer {
            newTeamA.isDealer = true
        }
        
        let newGame = GameRecord(teamA: newTeamA, teamB: newTeamB)
        currentGame = newGame
        gameHistory = [newGame]
        historyIndex = 0
    }
    
    // 执行游戏动作
    func performAction(for team: GameRecord.TeamType, action: GameAction) {
        guard var game = currentGame else { return }
        
        switch action {
        case .doubleContribution:
            // 双贡：对方升3级，对方打庄
            if team == .teamA {
                game.teamB.currentScore = game.teamB.currentScore.advance(by: 3)
                game.teamB.isDealer = true
                game.teamA.isDealer = false
            } else {
                game.teamA.currentScore = game.teamA.currentScore.advance(by: 3)
                game.teamA.isDealer = true
                game.teamB.isDealer = false
            }
            
        case .singleContribution:
            // 单贡：对方升2级，对方打庄
            if team == .teamA {
                game.teamB.currentScore = game.teamB.currentScore.advance(by: 2)
                game.teamB.isDealer = true
                game.teamA.isDealer = false
            } else {
                game.teamA.currentScore = game.teamA.currentScore.advance(by: 2)
                game.teamA.isDealer = true
                game.teamB.isDealer = false
            }
            
        case .selfContribution:
            // 自贡：本队升1级，还是本队打庄
            if team == .teamA {
                game.teamA.currentScore = game.teamA.currentScore.advance(by: 1)
            } else {
                game.teamB.currentScore = game.teamB.currentScore.advance(by: 1)
            }
            
        case .victory:
            // 胜利
            game.winner = team
            saveGameRecord(game)
            currentGame = nil
            return
        }
        
        // 更新游戏状态并添加到历史
        currentGame = game
        addToHistory(game)
    }
    
    // 添加到历史记录
    private func addToHistory(_ game: GameRecord) {
        // 如果不在历史记录末尾，删除后面的记录
        if historyIndex < gameHistory.count - 1 {
            gameHistory = Array(gameHistory.prefix(historyIndex + 1))
        }
        gameHistory.append(game)
        historyIndex = gameHistory.count - 1
    }
    
    // 回退
    func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        currentGame = gameHistory[historyIndex]
    }
    
    // 前进
    func redo() {
        guard historyIndex < gameHistory.count - 1 else { return }
        historyIndex += 1
        currentGame = gameHistory[historyIndex]
    }
    
    // 检查是否可以显示胜利按钮
    func canShowVictoryButton(for team: GameRecord.TeamType) -> Bool {
        guard let game = currentGame else { return false }
        
        if team == .teamA {
            // A队打Ax或B队打A3
            return game.teamA.currentScore.rawValue.hasPrefix("A") || game.teamB.currentScore == .a3
        } else {
            // B队打Ax或A队打A3
            return game.teamB.currentScore.rawValue.hasPrefix("A") || game.teamA.currentScore == .a3
        }
    }
    
    // 保存游戏记录
    private func saveGameRecord(_ record: GameRecord) {
        gameRecords.append(record)
        saveGameRecords()
    }
    
    // 持久化存储
    private func saveGameRecords() {
        if let encoded = try? JSONEncoder().encode(gameRecords) {
            UserDefaults.standard.set(encoded, forKey: "gameRecords")
        }
    }
    
    private func loadGameRecords() {
        if let data = UserDefaults.standard.data(forKey: "gameRecords"),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
            gameRecords = decoded
        }
    }
} 