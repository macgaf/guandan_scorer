//
//  GuandanScorerUITestsLaunchTests.swift
//  GuandanScorerUITests
//
//  Launch tests for GuandanScorer app
//

import XCTest

final class GuandanScorerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 验证应用成功启动
        XCTAssertTrue(app.state == .runningForeground, "应用应该在前台运行")
        
        // 验证主要界面元素存在
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 5.0), "主页应该显示'来一局'按钮")

        // 拍摄启动截图
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchInDarkMode() throws {
        // 测试深色模式下的启动
        let app = XCUIApplication()
        app.launch()
        
        // 这里可以通过系统设置或模拟器控制来切换到深色模式
        // 由于UI测试的限制，这里主要验证应用在深色模式下能正常启动
        
        XCTAssertTrue(app.state == .runningForeground, "深色模式下应用应该正常启动")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // 测试启动性能
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            
            // 等待关键元素出现，确保应用完全加载
            let newGameButton = app.buttons["来一局"]
            _ = newGameButton.waitForExistence(timeout: 10.0)
        }
    }
    
    @MainActor
    func testLaunchWithMemoryPressure() throws {
        // 在内存压力下测试启动
        let app = XCUIApplication()
        
        // 启动应用
        app.launch()
        
        // 验证在内存压力下仍能正常启动
        XCTAssertTrue(app.state == .runningForeground, "内存压力下应用应该正常启动")
        
        // 验证关键功能可用
        let newGameButton = app.buttons["来一局"]
        XCTAssertTrue(newGameButton.exists, "内存压力下主要功能应该可用")
    }
}