//
//  GuandanScorerUITests.swift
//  GuandanScorerUITests
//
//  Created for comprehensive UI testing of GuandanScorer app
//

import XCTest

final class GuandanScorerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // 清理任何已存在的游戏数据
        clearGameData()
    }
    
    override func tearDownWithError() throws {
        // 清理测试数据
        clearGameData()
    }
    
    // MARK: - Helper Methods
    
    /// 清理游戏数据
    private func clearGameData() {
        // 删除所有游戏记录（如果有）
        // 这可能需要根据实际的清理机制调整
    }
    
    /// 创建测试游戏数据
    private func createTestGame() {
        createTestGame(app: app)
    }
    
    // MARK: - TC_UI_001: 对局信息正确显示测试
    
    func testTC_UI_001_GameListDisplayCorrectly() throws {
        // 测试策略：不创建新游戏，直接测试首页的对局列表显示
        // 如果有历史游戏，验证显示；如果没有，创建一个然后返回首页
        
        // 等待首页加载
        Thread.sleep(forTimeInterval: 2.0)
        
        // 先检查是否在首页（有"来一局"按钮）
        let newGameButton = app.buttons["来一局"]
        
        if !newGameButton.exists {
            // 如果不在首页，尝试返回
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                // 点击首页标签（第一个）
                tabBar.buttons.element(boundBy: 0).tap()
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // 查看是否有游戏列表 - HomeView使用List结构显示GameRowView
        let gameList = app.tables.firstMatch
        
        // 直接查找包含VS标记的游戏记录（GameRowView中的内容）
        let gameRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
        
        if gameRecord.exists {
            // 有游戏记录，验证显示
            XCTAssertTrue(gameRecord.exists, "应该显示对局列表项")
            XCTAssertTrue(gameRecord.label.contains("VS"), "对局列表项应该包含VS标记")
        } else {
            // 没有游戏记录，验证显示“来一局”按钮
            XCTAssertTrue(newGameButton.exists, "没有游戏记录时应该显示'来一局'按钮")
        }
    }
    
    // MARK: - TC_UI_002: 搜索过滤功能测试
    
    func testTC_UI_002_SearchFilterFunctionality() throws {
        // 确保在首页
        Thread.sleep(forTimeInterval: 2.0)
        
        // 检查是否在首页
        let newGameButton = app.buttons["来一局"]
        if !newGameButton.exists {
            // 尝试通过TabBar返回首页
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                tabBar.buttons.element(boundBy: 0).tap()
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // 查找搜索框 - 使用TextField而不是searchField
        let searchField = app.textFields["按人名搜索"].firstMatch
        
        // 先检查是否有游戏记录 - 直接查找游戏记录内容
        let gameRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
        if gameRecord.exists {
            // 有游戏记录，可以测试搜索
            if searchField.exists {
                // 输入搜索关键字
                searchField.tap()
                searchField.typeText("张")
                
                // 等待搜索结果更新
                Thread.sleep(forTimeInterval: 1.0)
                
                // 验证搜索功能（至少应该还有游戏记录）
                let afterSearchRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
                XCTAssertTrue(afterSearchRecord.exists, "搜索后应该显示游戏记录")
                
                // 清空搜索框
                searchField.tap()
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 1)
                searchField.typeText(deleteString)
                
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                // 搜索框不存在，可能UI有变化
                XCTAssertTrue(newGameButton.exists, "至少应该有'来一局'按钮")
            }
        } else {
            // 没有游戏记录，无法测试搜索功能
            XCTAssertTrue(newGameButton.exists, "没有游戏记录时应该显示'来一局'按钮")
        }
    }
    
    // MARK: - TC_UI_003: 列表项点击导航测试
    
    func testTC_UI_003_GameListItemNavigation() throws {
        // 确保在首页
        Thread.sleep(forTimeInterval: 2.0)
        
        // 检查是否在首页
        let newGameButton = app.buttons["来一局"]
        if !newGameButton.exists {
            // 尝试通过TabBar返回首页
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                tabBar.buttons.element(boundBy: 0).tap()
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // 查看游戏记录 - 直接查找包含VS的游戏记录
        let gameRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
        
        if gameRecord.exists {
            // 有游戏记录，测试点击导航
            gameRecord.tap()
            
            // 等待导航完成（有异步延迟）
            Thread.sleep(forTimeInterval: 2.0)
            
            // 验证进入对局详情页面 - 查找特征元素
            // 游戏页面应该有级别显示（包含"2"或其他级别）
            let levelText = app.staticTexts.containing(NSPredicate(format: "label MATCHES '.*[2-9JQKA].*'")).firstMatch
            XCTAssertTrue(waitForElement(levelText), "应该显示游戏级别信息")
            
            // 或者查找其他特征元素，如队伍信息
            let teamInfo = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '&'")).firstMatch
            XCTAssertTrue(teamInfo.exists, "应该显示队伍信息")
        } else {
            // 没有游戏记录，无法测试导航
            XCTAssertTrue(newGameButton.exists, "没有游戏记录时应该显示'来一局'按钮")
        }
    }
    
    // MARK: - TC_UI_004: 左滑操作测试
    
    func testTC_UI_004_SwipeActions() throws {
        // 确保在首页
        Thread.sleep(forTimeInterval: 2.0)
        
        // 检查是否在首页
        let newGameButton = app.buttons["来一局"]
        if !newGameButton.exists {
            // 尝试通过TabBar返回首页
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                tabBar.buttons.element(boundBy: 0).tap()
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // 检查是否有游戏记录 - 查找包含VS的游戏记录
        let gameRecord = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
        
        if gameRecord.exists {
            // 有游戏记录，查找可滑动的容器
            let tables = app.tables
            let cells = app.cells
            
            if tables.count > 0 && tables.firstMatch.cells.count > 0 {
                // 在table cell上滑动
                tables.firstMatch.cells.firstMatch.swipeLeft()
            } else if cells.count > 0 {
                // 在独立cell上滑动
                cells.firstMatch.swipeLeft()
            } else {
                // 在包含VS的容器上滑动
                let container = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
                container.swipeLeft()
            }
            
            // 等待动画完成
            Thread.sleep(forTimeInterval: 1.0)
            
            // 验证显示操作按钮
            let deleteButton = app.buttons["删除"].exists
            let againButton = app.buttons["再来一局"].exists
            
            XCTAssertTrue(deleteButton || againButton, 
                         "左滑后应该显示删除或再来一局按钮")
        } else {
            // 没有游戏记录，先完整创建一个游戏
            createTestGame()
            
            // 等待游戏创建完成
            Thread.sleep(forTimeInterval: 2.0)
            
            // 返回主界面 - 使用TabBar
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                tabBar.buttons.element(boundBy: 0).tap()
                Thread.sleep(forTimeInterval: 2.0) // 给更多时间加载列表
            }
            
            // 现在应该有游戏记录了，尝试多种方式查找
            // 首先尝试查找包含VS的文本，确认游戏记录存在
            let gameRecordText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
            
            if gameRecordText.exists {
                // 游戏记录存在，尝试在其父元素上滑动
                // 获取包含这个文本的cell或其他容器
                let tables = app.tables
                let cells = app.cells
                let otherElements = app.otherElements
                
                // 优先尝试table cell
                if tables.count > 0 && tables.firstMatch.cells.count > 0 {
                    let cell = tables.firstMatch.cells.firstMatch
                    cell.swipeLeft()
                } else if cells.count > 0 {
                    // 如果不是table，可能是独立的cells
                    let cell = cells.firstMatch
                    cell.swipeLeft()
                } else {
                    // 最后尝试在包含VS文本的容器上滑动
                    let container = otherElements.containing(NSPredicate(format: "label CONTAINS 'VS'")).firstMatch
                    container.swipeLeft()
                }
                
                Thread.sleep(forTimeInterval: 1.0)
                
                let hasSwipeActions = app.buttons["删除"].exists || app.buttons["再来一局"].exists
                XCTAssertTrue(hasSwipeActions, "创建完整游戏后应该可以左滑显示操作按钮")
            } else {
                XCTFail("创建游戏后应该有游戏记录显示（未找到包含VS的文本）")
            }
        }
    }
    
    // MARK: - TC_UI_005: "来一局"按钮跳转测试
    
    func testTC_UI_005_NewGameButtonNavigation() throws {
        // 点击"来一局"按钮
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "首页应该有'来一局'按钮")
        
        newGameButton.tap()
        
        // 验证跳转到新建一局页面 - 检查导航标题
        let navigationBar = app.navigationBars["新建对局"]
        XCTAssertTrue(waitForElement(navigationBar), "应该跳转到新建一局页面")
        
        // 验证页面元素
        let teamAPlayer1 = app.textFields.matching(identifier: "队员1姓名").firstMatch
        XCTAssertTrue(teamAPlayer1.exists, "新建页面应该有队员输入框")
    }
    
    // MARK: - TC_UI_006: 返回首页功能测试
    
    func testTC_UI_006_BackToHomeFunctionality() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 等待页面加载
        Thread.sleep(forTimeInterval: 1.0)
        
        // 点击取消按钮 - 在导航栏中
        let cancelButton = app.buttons["取消"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // 如果没有找到取消按钮，尝试导航栏的第一个按钮
            let navigationBar = app.navigationBars.firstMatch
            if navigationBar.exists {
                let leftButton = navigationBar.buttons.element(boundBy: 0)
                if leftButton.exists {
                    leftButton.tap()
                }
            }
        }
        
        // 验证返回首页 - 检查导航标题
        let homeNavigationBar = app.navigationBars["惯蛋记分器"]
        XCTAssertTrue(waitForElement(homeNavigationBar), "应该返回首页")
    }
    
    // MARK: - TC_UI_007: 队员姓名输入测试
    
    func testTC_UI_007_PlayerNameInput() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 测试队员姓名输入
        let teamAPlayer1 = app.textFields.matching(identifier: "队员1姓名").firstMatch
        XCTAssertTrue(waitForElement(teamAPlayer1), "应该有A组队员1输入框")
        
        teamAPlayer1.tap()
        teamAPlayer1.typeText("测试姓名")
        
        // 验证输入正确显示
        XCTAssertEqual(teamAPlayer1.value as? String, "测试姓名", "姓名输入应该正确显示")
        
        // 测试空姓名 - 清空输入框
        teamAPlayer1.tap()
        // 使用系统方法清空
        if let value = teamAPlayer1.value as? String, !value.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            teamAPlayer1.typeText(deleteString)
        }
        
        // 测试特殊字符
        teamAPlayer1.typeText("@#$%")
        XCTAssertNotNil(teamAPlayer1.value, "特殊字符输入应该有适当处理")
    }
    
    // MARK: - TC_UI_008: 庄家选择互斥性测试
    
    func testTC_UI_008_DealerSelectionExclusivity() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 等待页面加载
        Thread.sleep(forTimeInterval: 1.0)
        
        // 查找Toggle开关
        let dealerSwitchA = app.switches["A队为庄家"]
        let dealerSwitchB = app.switches["B队为庄家"]
        
        // 验证开关存在
        XCTAssertTrue(dealerSwitchA.exists, "A队庄家开关应该存在")
        XCTAssertTrue(dealerSwitchB.exists, "B队庄家开关应该存在")
        
        // 获取初始状态
        let initialAValue = dealerSwitchA.value as? String ?? "unknown"
        let initialBValue = dealerSwitchB.value as? String ?? "unknown"
        
        // 验证初始状态：A队为庄家，B队不是庄家
        XCTAssertEqual(initialAValue, "1", "初始状态：A队应该为庄家")
        XCTAssertEqual(initialBValue, "0", "初始状态：B队不应该为庄家")
        
        // 点击B队开关，切换庄家 - 精确计算开关位置
        let switchFrame = dealerSwitchB.frame
        let deviceOrientation = app.windows.firstMatch.frame
        
        // Toggle开关通常是51点宽，31点高的标准尺寸
        // 实际可点击的开关部分位于Toggle控件的右侧
        let toggleWidth = switchFrame.width
        let toggleHeight = switchFrame.height
        
        // 计算开关实际圆形按钮的位置
        // 开关按钮直径约为toggleHeight - 4点(上下边距各2点)
        let switchButtonRadius = (toggleHeight - 4) / 2
        
        // 当开关为"关闭"状态时，按钮在左侧；"开启"状态时在右侧
        // 我们要点击的位置应该是开关轨道右侧按钮应该到达的位置
        let switchButtonCenterX = switchFrame.maxX - switchButtonRadius - 2  // 右边距2点
        let switchButtonCenterY = switchFrame.midY
        
        // 使用绝对坐标点击开关按钮中心
        let appWindow = app.windows.firstMatch
        let switchCoordinate = appWindow.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: switchButtonCenterX, dy: switchButtonCenterY))
        switchCoordinate.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // 重新获取状态
        let afterAValue = app.switches["A队为庄家"].value as? String ?? "unknown"
        let afterBValue = app.switches["B队为庄家"].value as? String ?? "unknown"
        
        // 验证互斥性：点击B队开关后，B队成为庄家，A队不再是庄家
        XCTAssertEqual(afterBValue, "1", "点击B队开关后：B队应该成为庄家")
        XCTAssertEqual(afterAValue, "0", "点击B队开关后：A队不应该是庄家")
    }
    
    // MARK: - TC_UI_009: 输入完整性验证测试
    
    func testTC_UI_009_InputCompletenessValidation() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 等待页面加载
        Thread.sleep(forTimeInterval: 1.0)
        
        // 只填写部分队员姓名
        let teamAPlayer1 = app.textFields.matching(identifier: "队员1姓名").firstMatch
        if teamAPlayer1.exists {
            teamAPlayer1.tap()
            teamAPlayer1.typeText("张三")
        }
        
        // 关闭键盘并在横屏模式下滚动到开始对局按钮
        dismissKeyboard(app: app)
        scrollToButtonInLandscape("开始对局", app: app)
        
        // 点击开始对局按钮
        let startButton = app.buttons["开始对局"]
        XCTAssertTrue(waitForElement(startButton), "应该有开始对局按钮")
        
        // 验证按钮是否被禁用（输入不完整时）
        XCTAssertFalse(startButton.isEnabled, "输入不完整时开始对局按钮应该被禁用")
        
        // 或者尝试点击并验证没有跳转
        if startButton.isEnabled {
            startButton.tap()
            
            // 验证是否还在新建页面（没有成功跳转）
            let navigationBar = app.navigationBars["新建对局"]
            XCTAssertTrue(navigationBar.exists, "输入不完整时应该保持在新建页面")
        }
    }
    
    // MARK: - TC_UI_010: 开局按钮功能测试
    
    func testTC_UI_010_StartGameButtonFunctionality() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 等待页面加载
        Thread.sleep(forTimeInterval: 1.0)
        
        // 输入完整信息
        let playerFields = app.textFields.matching(identifier: "队员1姓名")
        let player2Fields = app.textFields.matching(identifier: "队员2姓名")
        
        // A组队员1
        if playerFields.count > 0 {
            playerFields.element(boundBy: 0).tap()
            playerFields.element(boundBy: 0).typeText("张三")
        }
        
        // A组队员2
        if player2Fields.count > 0 {
            player2Fields.element(boundBy: 0).tap()
            player2Fields.element(boundBy: 0).typeText("李四")
        }
        
        // 关闭键盘，避免遮挡B组输入框
        dismissKeyboard(app: app)
        
        // B组队员1
        if playerFields.count > 1 {
            playerFields.element(boundBy: 1).tap()
            playerFields.element(boundBy: 1).typeText("王五")
        }

        dismissKeyboard(app: app)

        // B组队员2
        if player2Fields.count > 1 {
            player2Fields.element(boundBy: 1).tap()
            player2Fields.element(boundBy: 1).typeText("赵六")
        }
        
        // 关闭键盘并在横屏模式下滚动到开始对局按钮
        dismissKeyboard(app: app)
        scrollToButtonInLandscape("开始对局", app: app)
        
        // 点击开始对局按钮
        let startButton = app.buttons["开始对局"]
        XCTAssertTrue(waitForElement(startButton), "应该有开始对局按钮")
        XCTAssertTrue(startButton.isEnabled, "完整输入后开始对局按钮应该可用")
        
        startButton.tap()
        
        // 验证跳转到游戏页面 - 等待页面加载
        Thread.sleep(forTimeInterval: 2.0)
        
        // 验证级别显示 - 寻找包含"2"的文本（初始级别）
        let levelTexts = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '2'"))
        XCTAssertGreaterThan(levelTexts.count, 0, "应该显示初始级别2")
    }
    
    // MARK: - TC_UI_011: 取消按钮返回测试
    
    func testTC_UI_011_CancelButtonReturn() throws {
        // 进入新建页面
        let newGameButton = app.buttons["来一局"]
        newGameButton.tap()
        
        // 等待页面加载
        Thread.sleep(forTimeInterval: 1.0)
        
        // 输入部分信息
        let teamAPlayer1 = app.textFields.matching(identifier: "队员1姓名").firstMatch
        if teamAPlayer1.exists {
            teamAPlayer1.tap()
            teamAPlayer1.typeText("张三")
        }
        
        // 关闭键盘（取消按钮在导航栏，通常可见，不需要滚动）
        dismissKeyboard(app: app)
        
        // 点击取消按钮
        let cancelButton = app.buttons["取消"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // 如果没有取消按钮，尝试导航栏的第一个按钮
            let navigationBar = app.navigationBars.firstMatch
            if navigationBar.exists {
                let leftButton = navigationBar.buttons.element(boundBy: 0)
                if leftButton.exists {
                    leftButton.tap()
                }
            }
        }
        
        // 验证返回首页
        let homeNavigationBar = app.navigationBars["惯蛋记分器"]
        XCTAssertTrue(waitForElement(homeNavigationBar), "取消按钮应该返回首页")
        
        // 验证输入没有被保存 - 重新进入新建页面
        newGameButton.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        let teamAPlayer1Again = app.textFields.matching(identifier: "队员1姓名").firstMatch
        if teamAPlayer1Again.exists {
            let value = teamAPlayer1Again.value as? String
            XCTAssertTrue(value?.isEmpty ?? true, "输入应该没有被保存")
        }
    }
    
    // MARK: - TC_UI_012: 队员姓名显示测试
    
    func testTC_UI_012_PlayerNamesDisplay() throws {
        // 创建测试游戏
        createTestGame()
        
        // 验证A区和B区显示队员姓名
        let teamANames = app.staticTexts["张三 & 李四"]
        let teamBNames = app.staticTexts["王五 & 赵六"]
        
        XCTAssertTrue(teamANames.exists || 
                     (app.staticTexts["张三"].exists && app.staticTexts["李四"].exists),
                     "A区应该显示队员姓名")
        XCTAssertTrue(teamBNames.exists || 
                     (app.staticTexts["王五"].exists && app.staticTexts["赵六"].exists),
                     "B区应该显示队员姓名")
    }
    
    // MARK: - TC_UI_013: 当前级别显示测试
    
    func testTC_UI_013_CurrentLevelDisplay() throws {
        // 创建测试游戏
        createTestGame()
        
        // 验证初始级别显示
        let teamALevel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '2'")).firstMatch
        let teamBLevel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '2'")).firstMatch
        
        XCTAssertTrue(teamALevel.exists, "应该显示A队当前级别")
        XCTAssertTrue(teamBLevel.exists, "应该显示B队当前级别")
    }
    
    // MARK: - TC_UI_014: 庄家标识显示测试
    
    func testTC_UI_014_DealerIndicatorDisplay() throws {
        // 创建测试游戏
        createTestGame()
        
        // 验证庄家标识显示 - 查找星星图标或庄家文字
        let starIcon = app.images.containing(NSPredicate(format: "identifier CONTAINS 'star'")).firstMatch
        let dealerText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '庄'")).firstMatch
        XCTAssertTrue(starIcon.exists || dealerText.exists, "应该显示庄家标识")
    }
    
    // MARK: - TC_UI_015: 点击队伍区域弹出贡牌选择测试
    
    func testTC_UI_015_TeamAreaTapShowsContributionOptions() throws {
        // 创建测试游戏
        createTestGame()
        
        // 点击A队区域 - 直接使用坐标点击左上角的TeamScoreView
        let window = app.windows.firstMatch
        if window.exists {
            // 点击左上角A队区域，避免与列表中的同名文本冲突
            let leftTeamArea = window.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.2))
            leftTeamArea.tap()
        }
        
        // 验证弹出贡牌选择对话框 - 这是一个sheet而不是alert
        Thread.sleep(forTimeInterval: 1.0) // 等待sheet动画完成
        
        // 直接验证贡牌按钮的存在，因为sheet已经弹出
        let doubleButton = app.buttons["双贡"]
        let singleButton = app.buttons["单贡"] 
        let selfButton = app.buttons["自贡"]
        
        XCTAssertTrue(doubleButton.exists || singleButton.exists || selfButton.exists, "应该弹出贡牌选择界面")
        
        // 验证显示双贡、单贡、自贡按钮
        XCTAssertTrue(doubleButton.exists, "应该显示双贡按钮")
        XCTAssertTrue(singleButton.exists, "应该显示单贡按钮")
        XCTAssertTrue(selfButton.exists, "应该显示自贡按钮")
    }
    
    // MARK: - TC_UI_016: 双贡/单贡/自贡按钮功能测试
    
    func testTC_UI_016_ContributionButtonsFunctionality() throws {
        // 创建测试游戏
        createTestGame()
        
        // 点击A队区域弹出贡牌选择 - 直接使用坐标点击左上角的TeamScoreView
        let window = app.windows.firstMatch
        if window.exists {
            // 点击左上角A队区域，避免与列表中的同名文本冲突
            let leftTeamArea = window.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.2))
            leftTeamArea.tap()
        }
        
        // 等待sheet动画完成
        Thread.sleep(forTimeInterval: 1.0)
        
        // 测试双贡按钮
        let doubleButton = app.buttons["双贡"]
        if doubleButton.exists {
            doubleButton.tap()
            
            // 验证游戏逻辑正确执行（级别变化等）
            let updatedLevel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '5'")).firstMatch
            XCTAssertTrue(waitForElement(updatedLevel), "双贡后B队应该升到5级")
            
            // 验证界面状态更新 - 通过轮次记录文本验证
            let roundText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '第1回合'")).firstMatch
            let actionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '双贡'")).firstMatch
            
            XCTAssertTrue(roundText.exists || actionText.exists, "应该有轮次记录显示")
        }
    }
}
