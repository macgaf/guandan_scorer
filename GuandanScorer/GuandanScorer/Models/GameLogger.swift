import Foundation
import UIKit

// 输入事件类型
enum InputEventType: String {
    case tap = "点击"
    case swipe = "滑动"
    case longPress = "长按"
    case drag = "拖拽"
    case keyPress = "按键"
    case textInput = "文本输入"
}

// 日志管理器
class GameLogger {
    static let shared = GameLogger()
    private let logFileName = "guandan_game_log.txt"
    private let logDirName = "logs"
    
    private var logFileURL: URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // 创建Logs目录
        let logsDirectory = documentsDirectory.appendingPathComponent(logDirName)
        if !fileManager.fileExists(atPath: logsDirectory.path) {
            try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
        
        return logsDirectory.appendingPathComponent(logFileName)
    }
    
    // 写入日志到文件
    func writeLog(_ message: String) {
        guard let fileURL = logFileURL else {
            print("无法获取日志文件路径")
            return
        }
        
        let logMessage = message + "\n"
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // 文件已存在，追加内容
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // 文件不存在，创建新文件
            try? logMessage.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
    }
    
    // 获取日志文件路径
    func getLogFilePath() -> String? {
        return logFileURL?.path
    }
    
    // 清除日志文件
    func clearLogFile() {
        guard let fileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // 记录输入事件
    func logInputEvent(type: InputEventType, target: String, location: CGPoint? = nil, details: String? = nil) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        var logMessage = "[\(timestamp)] 输入事件: \(type.rawValue) - 目标: \(target)"
        
        if let location = location {
            logMessage += " - 位置: (\(Int(location.x)), \(Int(location.y)))"
        }
        
        if let details = details {
            logMessage += " - 详情: \(details)"
        }
        
        writeLog(logMessage)
        NSLog("🖱️ \(logMessage)")
    }
    
    // 记录按键事件
    func logKeyboardEvent(key: String, action: String = "按下") {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] 键盘事件: \(action) '\(key)'"
        
        writeLog(logMessage)
        NSLog("⌨️ \(logMessage)")
    }
    
    // 记录文本输入事件
    func logTextInput(field: String, text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] 文本输入: 字段'\(field)' - 内容: '\(text)'"
        
        writeLog(logMessage)
        NSLog("📝 \(logMessage)")
    }
}
