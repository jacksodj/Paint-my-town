//
//  Logger.swift
//  PaintMyTown
//
//  Created on 2025-10-23.
//

import Foundation
import OSLog

/// Centralized logging utility wrapping OSLog for structured logging
struct Logger {
    // MARK: - Properties

    private let subsystem = "com.paintmytown.app"
    private let category: LogCategory

    // MARK: - Initialization

    init(category: LogCategory = .general) {
        self.category = category
    }

    // MARK: - Logging Methods

    /// Log a debug message (used during development)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    /// Log an informational message
    func info(_ message: String, category: LogCategory? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let targetCategory = category ?? self.category
        logToOS(level: .info, message: message, category: targetCategory, file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(_ message: String, category: LogCategory? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let targetCategory = category ?? self.category
        logToOS(level: .default, message: message, category: targetCategory, file: file, function: function, line: line)
    }

    /// Log an error message
    func error(_ message: String, error: Error? = nil, category: LogCategory? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let targetCategory = category ?? self.category
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        logToOS(level: .error, message: fullMessage, category: targetCategory, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private func log(level: OSLogType, message: String, file: String, function: String, line: Int) {
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: logger, type: level, formattedMessage)
    }

    private func logToOS(level: OSLogType, message: String, category: LogCategory, file: String, function: String, line: Int) {
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        let fileName = (file as NSString).lastPathComponent

        #if DEBUG
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: logger, type: level, formattedMessage)
        #else
        os_log("%{public}@", log: logger, type: level, message)
        #endif
    }
}

// MARK: - Log Category

/// Available log categories for organizing logs
enum LogCategory: String {
    case network = "Network"
    case database = "Database"
    case location = "Location"
    case ui = "UI"
    case general = "General"
    case workout = "Workout"
    case permissions = "Permissions"
    case coverage = "Coverage"

    var logger: Logger {
        Logger(category: self)
    }
}

// MARK: - Global Logger Extension

extension Logger {
    /// Shared logger instance for general purpose logging
    static let shared = Logger(category: .general)
}
