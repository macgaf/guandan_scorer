//
//  GuandanScorerUITestsExtended.swift
//  GuandanScorerUITests
//
//  Extended UI tests for game interface and integration scenarios
//

import XCTest

final class GuandanScorerUITestsExtended: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // 等待应用完全加载
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    override func tearDownWithError() throws {
        // 清理测试数据
    }
    
    // MARK: - Helper Methods
    
    
    /// 执行一轮游戏操作
    private func performGameRound(team: String, action: String) {
        // 在GameView中，需要点击队伍区域来触发贡牌选择
        // 直接使用坐标点击，避免与轮次历史列表中的同名文本冲突
        
        let window = app.windows.firstMatch
        if window.exists {
            // 点击屏幕上方的队伍区域：左边是A队，右边是B队
            let normalizedPoint = team == "A" 
                ? CGVector(dx: 0.25, dy: 0.2)  // 左上角A队区域
                : CGVector(dx: 0.75, dy: 0.2)  // 右上角B队区域
            window.coordinate(withNormalizedOffset: normalizedPoint).tap()
        }
        
        // 等待弹出框出现
        Thread.sleep(forTimeInterval: 1.0)
        
        // 查找并点击动作按钮
        let actionButton = app.buttons[action]
        if waitForElement(actionButton) {
            actionButton.tap()
        } else {
            // 如果是弹出框中的按钮，可能在alerts中
            let alert = app.alerts.firstMatch
            if alert.exists {
                let alertButton = alert.buttons[action]
                if alertButton.exists {
                    alertButton.tap()
                }
            }
        }
    }
    
    
    // MARK: - TC_UI_017: 游戏结束时界面状态测试
    
    func testTC_UI_017_GameEndState() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 执行导致游戏结束的操作序列
        // 让B队升到A1级别，然后A队双贡导致B队获胜
        
        // 多轮操作让B队升到A级别
        for _ in 0..<4 {
            performGameRound(team: "A", action: "双贡")
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // 最后一轮A队双贡，应该导致B队获胜
        performGameRound(team: "A", action: "双贡")
        
        // 验证游戏结束状态 - 查找皇冠图标
        let crownIcon = app.images.containing(NSPredicate(format: "identifier CONTAINS 'crown'")).firstMatch
        XCTAssertTrue(waitForElement(crownIcon), "应该显示获胜者皇冠图标")
        
        // 验证无法继续进行操作 - 通过坐标点击左上角的TeamScoreView
        let window = app.windows.firstMatch
        if window.exists {
            // 点击左上角A队区域，避免与列表中的同名文本冲突
            let leftTeamArea = window.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.2))
            leftTeamArea.tap()
        }
        
        // 验证不再弹出贡牌选择
        Thread.sleep(forTimeInterval: 1.0)
        let contributionDialog = app.buttons["双贡"].exists || app.buttons["单贡"].exists || app.buttons["自贡"].exists
        XCTAssertFalse(contributionDialog, "游戏结束后不应该弹出贡牌选择")
    }
    
    // MARK: - TC_UI_018: 轮次历史列表测试
    
    func testTC_UI_018_RoundHistoryList() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行多轮游戏
        let actions = ["双贡", "单贡", "自贡"]
        for (index, action) in actions.enumerated() {
            let team = index % 2 == 0 ? "A" : "B"
            performGameRound(team: team, action: action)
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // 验证轮次历史列表 - 通过文本内容验证
        let roundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
        let actionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '双贡'")).firstMatch
        XCTAssertTrue(roundText.exists || actionText.exists, "应该显示轮次历史列表")
        
        // 验证轮次记录包含完整信息 - 验证多个轮次的操作记录
        let doubleContribText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '双贡'")).firstMatch
        let singleContribText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '单贡'")).firstMatch
        let selfContribText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '自贡'")).firstMatch
        
        XCTAssertTrue(doubleContribText.exists && singleContribText.exists && selfContribText.exists,
                     "轮次记录应该包含各种操作信息")
    }
    
    // MARK: - TC_UI_019: 滚动到最新记录测试
    
    func testTC_UI_019_ScrollToLatestRecord() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行多轮游戏以产生足够的记录
        for i in 0..<8 {
            let team = i % 2 == 0 ? "A" : "B"
            let action = ["双贡", "单贡", "自贡"][i % 3]
            performGameRound(team: team, action: action)
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        // 执行新的游戏操作
        performGameRound(team: "A", action: "单贡")
        
        // 验证列表自动滚动到最新记录 - 通过文本内容验证
        let latestRoundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第9回合'")).firstMatch
        let latestActionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '单贡'")).firstMatch
        XCTAssertTrue(latestRoundText.exists || latestActionText.exists, "最新记录应该在可视区域内")
    }
    
    // MARK: - TC_UI_020: 删除最后一轮功能测试
    
    func testTC_UI_020_DeleteLastRoundFunction() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行几轮游戏
        performGameRound(team: "A", action: "双贡")
        performGameRound(team: "B", action: "单贡")
        
        // 记录删除前的状态 - 通过文本内容验证
        let initialRoundExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第2回合'")).firstMatch.exists
        
        // 查找并左滑最后一轮记录
        // 先确认第2回合记录存在
        let lastRoundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第2回合'")).firstMatch
        if lastRoundText.exists {
            // 查找可滑动的容器
            let tables = app.tables
            let cells = app.cells
            
            if tables.count > 0 {
                // 尝试找到包含"第2回合"的cell
                let cellsContainingRound = tables.firstMatch.cells.containing(NSPredicate(format: "label CONTAINS '第2回合'"))
                if cellsContainingRound.count > 0 {
                    cellsContainingRound.firstMatch.swipeLeft()
                } else if tables.firstMatch.cells.count > 0 {
                    // 如果找不到特定的cell，滑动最后一个cell（通常是最新的记录）
                    let lastIndex = tables.firstMatch.cells.count - 1
                    tables.firstMatch.cells.element(boundBy: lastIndex).swipeLeft()
                }
            } else if cells.count > 0 {
                // 如果不是table，尝试独立的cells
                let cellsContainingRound = cells.containing(NSPredicate(format: "label CONTAINS '第2回合'"))
                if cellsContainingRound.count > 0 {
                    cellsContainingRound.firstMatch.swipeLeft()
                }
            } else {
                // 最后尝试在包含第2回合的容器上滑动
                let container = app.otherElements.containing(NSPredicate(format: "label CONTAINS '第2回合'")).firstMatch
                container.swipeLeft()
            }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            // 点击删除按钮
            let deleteButton = app.buttons["删除"]
            if deleteButton.exists {
                deleteButton.tap()
                
                // 验证记录被删除 - 通过文本内容验证
                Thread.sleep(forTimeInterval: 1.0)
                let afterDeleteRoundExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第2回合'")).firstMatch.exists
                XCTAssertTrue(initialRoundExists && !afterDeleteRoundExists, "第2回合记录应该被删除")
                
                // 验证游戏状态正确回退 - 检查第1回合是否还存在
                let firstRoundExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch.exists
                XCTAssertTrue(firstRoundExists, "第1回合记录应该仍然存在")
                
                // 验证级别正确回退 - 删除第2回合后，应该回到第1回合结束时的状态
                // 第1回合是A队双贡，所以B队级别应该是5
                let teamBLevelCorrect = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '5'")).firstMatch.exists
                XCTAssertTrue(teamBLevelCorrect, "删除最后一轮后，B队级别应该回退到5（第1回合双贡后的级别）")
            }
        }
    }
    
    // MARK: - TC_UI_021: 回退按钮功能测试
    
    func testTC_UI_021_UndoButtonFunction() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行多轮游戏
        performGameRound(team: "A", action: "双贡")
        performGameRound(team: "A", action: "单贡")
        
        // 记录当前状态
        let currentLevel = getCurrentTeamLevel("B")
        
        // 点击回退按钮
        let undoButton = app.buttons["回退"]
        if undoButton.exists {
            undoButton.tap()
            
            // 验证游戏状态回到上一轮
            let previousLevel = getCurrentTeamLevel("B")
            XCTAssertNotEqual(currentLevel, previousLevel, "回退后级别应该发生变化")
            
            // 验证界面显示正确更新 - 通过文本内容验证
            let remainingRoundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
            XCTAssertTrue(remainingRoundText.exists, "轮次列表应该仍然存在")
        }
    }
    
    // MARK: - TC_UI_021b: 单轮回退到空状态测试
    
    func testTC_UI_021b_UndoToEmptyState() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行一轮游戏
        performGameRound(team: "A", action: "双贡")
        
        // 验证有回合记录
        let roundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
        XCTAssertTrue(roundText.exists, "应该有第1回合记录")
        
        // 点击回退按钮
        let undoButton = app.buttons["回退"]
        XCTAssertTrue(undoButton.exists && undoButton.isEnabled, "回退按钮应该可用")
        
        undoButton.tap()
        
        // 验证回退到空状态
        Thread.sleep(forTimeInterval: 1.0)
        let emptyRoundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
        XCTAssertFalse(emptyRoundText.exists, "应该没有回合记录")
        
        // 验证级别重置为初始状态 - 检查A队和B队都是级别2
        let levelA = getCurrentTeamLevel("A")
        let levelB = getCurrentTeamLevel("B")
        XCTAssertEqual(levelA, "2", "A队应该重置为初始级别2")
        XCTAssertEqual(levelB, "2", "B队应该重置为初始级别2")
        
        // 验证前进按钮可用
        let redoButton = app.buttons["前进"]
        XCTAssertTrue(redoButton.exists && redoButton.isEnabled, "前进按钮应该可用")
    }
    
    // MARK: - TC_UI_022: 前进按钮功能测试
    
    func testTC_UI_022_RedoButtonFunction() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行游戏操作
        performGameRound(team: "A", action: "双贡")
        
        // 执行回退
        let undoButton = app.buttons["回退"]
        if undoButton.exists {
            undoButton.tap()
            
            // 记录回退后状态
            let undoLevel = getCurrentTeamLevel("B")
            
            // 点击前进按钮
            let redoButton = app.buttons["前进"]
            if redoButton.exists {
                redoButton.tap()
                
                // 验证游戏状态前进到下一轮
                let redoLevel = getCurrentTeamLevel("B")
                XCTAssertNotEqual(undoLevel, redoLevel, "前进后级别应该恢复")
                
                // 验证界面显示正确更新
                let levelDisplay = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(redoLevel)'")).firstMatch
                XCTAssertTrue(levelDisplay.exists, "级别显示应该正确更新")
            }
        }
    }
    
    // MARK: - Integration Tests (TC_IT_001-008)
    
    // MARK: - TC_IT_001: 完整游戏流程测试
    
    func testTC_IT_001_CompleteGameFlow() throws {
        // 新建游戏
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "应该有'来一局'按钮")
        newGameButton.tap()
        
        // 输入队员信息 - 使用正确的标识符
        let allPlayer1Fields = app.textFields.matching(identifier: "队员1姓名")
        let allPlayer2Fields = app.textFields.matching(identifier: "队员2姓名")
        
        // A组队员1
        if allPlayer1Fields.count > 0 {
            allPlayer1Fields.element(boundBy: 0).tap()
            allPlayer1Fields.element(boundBy: 0).typeText("张三")
        }
        
        // A组队员2
        if allPlayer2Fields.count > 0 {
            allPlayer2Fields.element(boundBy: 0).tap()
            allPlayer2Fields.element(boundBy: 0).typeText("李四")
        }
        
        // B组队员1
        if allPlayer1Fields.count > 1 {
            allPlayer1Fields.element(boundBy: 1).tap()
            allPlayer1Fields.element(boundBy: 1).typeText("王五")
        }
        
        // B组队员2
        if allPlayer2Fields.count > 1 {
            allPlayer2Fields.element(boundBy: 1).tap()
            allPlayer2Fields.element(boundBy: 1).typeText("赵六")
        }
        
        // A队默认为庄家，直接开始游戏
        let startButton = app.buttons["开始对局"]
        startButton.tap()
        
        // 进行多轮游戏操作，让某队达到A级别以获胜
        // 需要让某队升级到A级别（从2开始，经过3-K后到A）
        let gameActions = [
            ("A", "双贡"),  // B队: 2->5
            ("B", "双贡"),  // A队: 2->5
            ("A", "双贡"),  // B队: 5->8
            ("B", "双贡"),  // A队: 5->8
            ("A", "双贡"),  // B队: 8->J
            ("B", "双贡"),  // A队: 8->J
            ("A", "双贡"),  // B队: J->A1 (达到A级别，B队获胜)
            ("A", "双贡")  // B队: A1->获胜
        ]
        
        for (team, action) in gameActions {
            performGameRound(team: team, action: action)
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // 返回首页查看记录
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // 应用应该自动定位到新创建的游戏记录，不需要手动滑动
        // 验证完整游戏流程数据传递正确 - 直接查找游戏记录
        let playerInfo = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '张三'")).firstMatch
        XCTAssertTrue(waitForElement(playerInfo), "应该自动显示新创建的游戏记录（包含张三）")
        
        // 验证游戏记录包含VS标记
        let vsInfo = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
        XCTAssertTrue(vsInfo.exists, "游戏记录应该包含VS标记")
        
        // 验证显示了胜利信息
        let victorInfo = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '胜'")).firstMatch
        XCTAssertTrue(victorInfo.exists, "应该显示获胜者皇冠图标")
    }
    
    // MARK: - TC_IT_002: 数据在各界面间传递测试
    
    func testTC_IT_002_DataTransferBetweenViews() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 进行游戏操作
        performGameRound(team: "A", action: "双贡")
        
        // 记录游戏状态
        let gameLevel = getCurrentTeamLevel("B")
        
        // 返回首页
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
            
            // 等待首页加载
            Thread.sleep(forTimeInterval: 2.0)
            
            // 验证首页信息 - 查找游戏记录容器而不是文本
            let gameRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
            
            // 重新进入游戏详情 - 点击List中的Cell而不是文本
            if waitForElement(gameRecord) {
                // 在List中查找包含游戏记录的Cell并点击
                let gameList = app.tables.firstMatch
                if gameList.exists && gameList.cells.count > 0 {
                    // 点击第一个cell（最新的游戏记录）
                    gameList.cells.element(boundBy: 0).tap()
                } else {
                    // 备用方案：使用坐标点击游戏记录区域
                    let window = app.windows.firstMatch
                    let gameArea = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                    gameArea.tap()
                }
                
                // 验证数据一致性
                let currentLevel = getCurrentTeamLevel("B")
                XCTAssertEqual(gameLevel, currentLevel, "界面间数据应该保持一致")
            }
        }
    }
    
    // MARK: - TC_IT_003: 状态变化同步更新测试
    
    func testTC_IT_003_StateChangeSynchronization() throws {
        // 创建测试游戏
        createTestGame(app: app)
        
        // 记录初始状态
        let initialLevel = getCurrentTeamLevel("B")
        
        // 执行游戏操作
        performGameRound(team: "A", action: "双贡")
        
        // 验证所有相关界面元素同步更新
        let updatedLevel = getCurrentTeamLevel("B")
        XCTAssertNotEqual(initialLevel, updatedLevel, "级别应该发生变化")
        
        // 验证轮次记录更新 - 通过文本内容验证
        let roundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
        let actionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '双贡'")).firstMatch
        XCTAssertTrue(roundText.exists || actionText.exists, "轮次记录应该存在")
        
        // 验证庄家标识更新（如果适用） - 查找星星图标或庄家文字
        let starIcon = app.images.containing(NSPredicate(format: "identifier CONTAINS 'star'")).firstMatch
        let dealerText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '庄'")).firstMatch
        XCTAssertTrue(starIcon.exists || dealerText.exists, "庄家标识应该正确显示")
    }
    
    // MARK: - Helper Method for Level Detection
    
    private func getCurrentTeamLevel(_ team: String) -> String {
        // 根据团队获取当前级别
        // 在TeamScoreView中，级别显示在队员名字下方
        
        // 定义有效的级别值
        let validLevels = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A1", "A2", "A3"]
        
        // 获取屏幕尺寸以判断左右位置
        let window = app.windows.firstMatch
        let screenWidth = window.frame.width
        let midX = screenWidth / 2
        
        // 在屏幕上方的TeamScoreView区域查找所有级别
        let allTexts = app.staticTexts.allElementsBoundByIndex
        
        // 根据屏幕位置查找对应队伍的级别
        // A队在左边，B队在右边
        for element in allTexts {
            let text = element.label
            if validLevels.contains(text) && element.exists {
                let frame = element.frame
                // 只查找屏幕上方的级别（TeamScoreView区域）
                if frame.minY < 400 {
                    // A队在左半边
                    if team == "A" && frame.midX < midX {
                        return text
                    }
                    // B队在右半边
                    else if team == "B" && frame.midX > midX {
                        return text
                    }
                }
            }
        }
        
        // 备选方案：如果没有找到，返回默认值
        return "2" // 默认返回初始级别
    }
}

// MARK: - Performance and Device Tests

final class GuandanScorerUITestsPerformance: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    // MARK: - TC_PT_001: 应用启动性能测试
    
    func testTC_PT_001_AppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    // MARK: - TC_PT_002: 界面响应时间测试
    
    func testTC_PT_002_UIResponseTime() throws {
        // 等待应用完全加载
        Thread.sleep(forTimeInterval: 2.0)
        
        measure(metrics: [XCTClockMetric()]) {
            // 测试按钮点击响应时间
            let newGameButton = app.buttons["来一局"]
            if newGameButton.exists {
                // 不使用tap()来避免滚动问题，改为coordinate点击
                let bounds = newGameButton.frame
                let centerPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
                    .withOffset(CGVector(dx: bounds.midX, dy: bounds.midY))
                centerPoint.tap()
            }
            
            // 等待页面加载
            let navigationBar = app.navigationBars["新建对局"]
            _ = navigationBar.waitForExistence(timeout: 3.0)
            
            // 返回首页以便重复测试
            let cancelButton = app.buttons["取消"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }
    
    // MARK: - Device Adaptation Tests
    
    func testTC_UI_023_iPhoneAdaptation() throws {
        app.launch()
        
        // 验证在不同iPhone尺寸上的界面适配
        let bounds = app.windows.firstMatch.frame
        XCTAssertGreaterThan(bounds.width, 0, "应用应该适应屏幕宽度")
        XCTAssertGreaterThan(bounds.height, 0, "应用应该适应屏幕高度")
        
        // 验证关键界面元素可见
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "主要按钮应该可见")
        XCTAssertTrue(newGameButton.isHittable, "主要按钮应该可点击")
    }
    
    func testTC_UI_024_DarkModeSupport() throws {
        app.launch()
        
        // 验证在当前模式下UI元素可见
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "来一局按钮应该存在")
        XCTAssertTrue(newGameButton.isHittable, "来一局按钮应该可点击")
        
        // 进入新建游戏界面验证适应性颜色
        newGameButton.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        let startButton = app.buttons["开始对局"]
        
        // 如果按钮不可点击，可能需要滑动
        if !startButton.isHittable {
            // 直接在主窗口上滑动
            let window = app.windows.firstMatch
            window.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertTrue(startButton.exists, "开始对局按钮应该存在")
        
        // 验证文本字段在深色模式下可读
        let textField = app.textFields.matching(identifier: "队员1姓名").firstMatch
        XCTAssertTrue(textField.exists, "文本字段应该可见")
    }
    
    func testTC_UI_025_LandscapeMode() throws {
        app.launch()
        
        // 旋转到横屏模式
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // 等待界面调整
        Thread.sleep(forTimeInterval: 2.0)
        
        // 验证界面布局适应横屏
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "横屏模式下按钮应该存在")
        XCTAssertTrue(newGameButton.isHittable, "横屏模式下按钮应该可点击")
        
        // 进入新建游戏页面测试横屏适配
        newGameButton.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // 在横屏模式下，可能需要滑动才能看到"开始对局"按钮
        let startButton = app.buttons["开始对局"]
        if !startButton.isHittable {
            // 向上滑动以显示开始对局按钮
            let window = app.windows.firstMatch
            window.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // 验证开始对局按钮在滑动后可见
        XCTAssertTrue(startButton.exists, "横屏模式下开始对局按钮应该存在")
        XCTAssertTrue(startButton.isHittable, "横屏模式下开始对局按钮应该可点击")
        
        // 恢复竖屏
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testTC_UI_026_iPadAdaptation() throws {
        app.launch()
        
        // 验证适应性布局
        let window = app.windows.firstMatch
        let isLargeScreen = window.frame.width > 768
        
        // 验证基本功能在大屏幕上正常
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "来一局按钮应该存在")
        
        if isLargeScreen {
            // 在大屏幕设备上测试横屏
            XCUIDevice.shared.orientation = .landscapeLeft
            Thread.sleep(forTimeInterval: 1.0)
            
            // 验证横屏下的适应性布局
            XCTAssertTrue(newGameButton.isHittable, "大屏幕横屏模式下按钮应该可点击")
            
            // 测试新建游戏的适应性布局
            newGameButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // 验证在大屏幕上的表单布局
            let textFields = app.textFields.matching(identifier: "队员1姓名")
            XCTAssertGreaterThan(textFields.count, 0, "应该有队员输入字段")
            
            XCUIDevice.shared.orientation = .portrait
        }
    }
    
    func testTC_UI_027_TextInputStress() throws {
        app.launch()
        
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 快速文本输入以触发潜在的NaN错误
        let textField = app.textFields.matching(identifier: "队员1姓名").firstMatch
        if textField.exists {
            textField.tap()
            
            // 快速输入
            for char in "TestPlayer123" {
                textField.typeText(String(char))
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            // 验证没有崩溃
            XCTAssertTrue(textField.exists, "文本字段应该仍然存在")
            
            // 验证可以删除文本
            textField.tap()
            for _ in 0..<14 {
                app.keys["delete"].tap()
            }
        }
    }
}
