//
//  SimpleGameTests.swift
//  GuandanScorerTests
//
//  Created for testing game logic
//

import Testing
import Foundation
@testable import GuandanScorer

struct SimpleGameTests {
    
    @Test("简单双贡测试")
    func testSimpleDoubleContribution() async throws {
        // 创建简单的测试场景
        let teamA = TeamStatus(
            player1: "张三",
            player2: "李四",
            currentLevel: .two,
            isDealer: true
        )
        
        let teamB = TeamStatus(
            player1: "王五",
            player2: "赵六",
            currentLevel: .two,
            isDealer: false
        )
        
        var game = Game(teamA: teamA, teamB: teamB, startTime: Date())
        
        print("🧪 [简单测试开始] A队双贡，B队从2升到5")
        print("🧪 [测试前] teamA: \(game.teamA.currentLevel.rawValue), teamB: \(game.teamB.currentLevel.rawValue)")
        
        // 执行双贡操作 - A队双贡
        game.doubleContribution(fromTeamId: game.teamA.id)
        
        print("🧪 [测试后] game.teamA: \(game.teamA.currentLevel.rawValue), game.teamB: \(game.teamB.currentLevel.rawValue)")
        
        // 验证游戏状态是否正确更新
        #expect(game.teamB.currentLevel == .five, "游戏中的B队应该从2升到5")
        #expect(game.teamA.isDealer == false, "游戏中的A队应该不再是庄家")
        #expect(game.teamB.isDealer == true, "游戏中的B队应该成为庄家")
        
        // 验证回合记录
        #expect(game.rounds.count == 1, "应该有一个回合记录")
        
        print("🧪 [简单测试完成] 双贡功能测试通过")
    }
    
    @Test("级别升级方法独立测试")
    func testLevelUpMethod() async throws {
        print("🧪 [级别测试开始]")
        
        // 测试从2升3级到5
        let result1 = GuandanLevel.two.limitedLevelUp(by: 3)
        print("🧪 从2升3级结果: \(result1.rawValue)")
        #expect(result1 == .five, "从2升3级应该到5")
        
        // 测试从K升3级（应该限制到A1）
        let result2 = GuandanLevel.king.limitedLevelUp(by: 3)
        print("🧪 从K升3级结果: \(result2.rawValue)")
        #expect(result2 == .aceOne, "从K升3级应该限制到A1")
        
        print("🧪 [级别测试完成] 所有级别升级测试通过")
    }
}