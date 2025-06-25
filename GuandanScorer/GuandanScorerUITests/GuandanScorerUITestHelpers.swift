//
//  GuandanScorerUITestHelpers.swift
//  GuandanScorerUITests
//
//  Common helper methods for UI tests
//

import XCTest

extension XCTestCase {
    
    /// 关闭键盘
    func dismissKeyboard(app: XCUIApplication) {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["return"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// 在横屏模式下滚动到指定按钮
    func scrollToButtonInLandscape(_ buttonIdentifier: String, app: XCUIApplication) {
        let window = app.windows.firstMatch
        let isLandscape = window.frame.width > window.frame.height
        
        if isLandscape {
            var attempts = 0
            let maxAttempts = 3
            
            while attempts < maxAttempts {
                let targetButton = app.buttons[buttonIdentifier]
                if targetButton.exists && targetButton.isHittable {
                    break
                }
                
                window.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                attempts += 1
            }
        }
    }
    
    /// 等待元素出现
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// 创建测试游戏数据（共享版本）
    func createTestGame(app: XCUIApplication) {
        let newGameButton = app.buttons["来一局"]
        if newGameButton.exists {
            newGameButton.tap()
            
            // 等待页面加载
            Thread.sleep(forTimeInterval: 1.0)
            
            // 输入队员信息 - 使用placeholder文本匹配
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
            
            dismissKeyboard(app: app)
            
            // B组队员1
            if allPlayer1Fields.count > 1 {
                allPlayer1Fields.element(boundBy: 1).tap()
                allPlayer1Fields.element(boundBy: 1).typeText("王五")
            }
            
            dismissKeyboard(app: app)
            
            // B组队员2
            if allPlayer2Fields.count > 1 {
                allPlayer2Fields.element(boundBy: 1).tap()
                allPlayer2Fields.element(boundBy: 1).typeText("赵六")
            }
            
            // A队默认为庄家，不需要额外操作
            
            dismissKeyboard(app: app)
            
            scrollToButtonInLandscape("开始对局", app: app)
            
            // 开始游戏 - 使用实际的按钮文本
            let startButton = app.buttons["开始对局"]
            if waitForElement(startButton) {
                startButton.tap()
            }
        }
    }
}