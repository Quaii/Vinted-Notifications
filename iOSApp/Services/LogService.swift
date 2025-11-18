//
//  LogService.swift
//  Vinted Notifications
//
//  In-memory logging service with circular buffer
//

import Foundation
import SwiftUI

enum LogLevel: String, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

    var color: Color {
        switch self {
        case .info:
            return Color(hex: "6A7A8C")
        case .warning:
            return Color(hex: "F59E0B")
        case .error:
            return Color(hex: "EF4444")
        }
    }

    var icon: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String

    init(id: UUID = UUID(), timestamp: Date = Date(), level: LogLevel, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}

class LogService: ObservableObject {
    static let shared = LogService()

    @Published private(set) var logs: [LogEntry] = []
    private let maxLogs = 100

    private init() {
        log("LogService initialized", level: .info)
    }

    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.insert(entry, at: 0)

            // Maintain circular buffer
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
        }

        // Also print to console
        print("[\(level.rawValue)] \(message)")
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func warning(_ message: String) {
        log(message, level: .warning)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }

    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.log("Logs cleared", level: .info)
        }
    }

    func getLogs(limit: Int? = nil) -> [LogEntry] {
        if let limit = limit {
            return Array(logs.prefix(limit))
        }
        return logs
    }
}
