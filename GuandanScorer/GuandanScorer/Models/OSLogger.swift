import Foundation
import os

/// 统一日志管理器，使用Apple的Logger系统
struct OSLogger {
    // MARK: - 日志子系统和分类
    private static let subsystem = "com.ossware.GuandanScorer"
    
    // MARK: - Logger实例
    private static let game = Logger(subsystem: subsystem, category: "Game")
    private static let ui = Logger(subsystem: subsystem, category: "UI")
    private static let data = Logger(subsystem: subsystem, category: "Data")
    private static let input = Logger(subsystem: subsystem, category: "Input")
    
    // MARK: - 便捷方法
    static func logGameAction(_ message: String) {
        game.info("🎯 \(message)")
    }
    
    static func logUIAction(_ message: String) {
        ui.info("📱 \(message)")
    }
    
    static func logDataOperation(_ message: String) {
        data.info("💾 \(message)")
    }
    
    static func logInitialization(_ message: String) {
        data.info("🔍 \(message)")
    }
    
    static func logInputEvent(_ message: String) {
        input.info("🖱️ \(message)")
    }
    
    static func logKeyboardEvent(_ message: String) {
        input.info("⌨️ \(message)")
    }
    
    static func logTextInput(_ message: String) {
        input.info("📝 \(message)")
    }
}