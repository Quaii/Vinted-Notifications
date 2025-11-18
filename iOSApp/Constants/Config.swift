//
//  Config.swift
//  Vinted Notifications
//
//  App configuration constants
//

import Foundation

struct AppConfig {
    // Default settings
    static let defaultRefreshDelay: Int = 60 // seconds
    static let defaultItemsPerQuery: Int = 20
    static let defaultTimeWindow: Int = 1200 // 20 minutes in seconds

    // Database
    static let dbName: String = "vinted_notifications.db"
    static let dbVersion: String = "1.0"

    // API
    static let apiMaxRetries: Int = 3
    static let apiTimeout: TimeInterval = 30.0 // 30 seconds

    // Notification
    static let notificationIdentifier: String = "vinted_notifications"
    static let notificationCategoryId: String = "VINTED_ITEM"

    // Background fetch
    static let backgroundFetchInterval: TimeInterval = 15 * 60 // 15 minutes
}

// Vinted domains
let vintedDomains: [String] = [
    "vinted.fr",
    "vinted.de",
    "vinted.co.uk",
    "vinted.com",
    "vinted.es",
    "vinted.it",
    "vinted.pl",
    "vinted.be",
    "vinted.nl",
    "vinted.lt",
    "vinted.cz",
    "vinted.se",
    "vinted.at",
    "vinted.pt",
    "vinted.lu"
]

// Default message template
let defaultMessageTemplate: String = """
Title: {title}
Price: {price}
Brand: {brand}
Size: {size}
"""

// Notification modes
enum NotificationMode: String, CaseIterable {
    case precise = "precise"  // Individual notification for each item
    case compact = "compact"  // Summary notification

    var description: String {
        switch self {
        case .precise:
            return "Precise: Individual notification for each item with details"
        case .compact:
            return "Compact: Summary notification (e.g., \"5 new items found\")"
        }
    }
}

// User Agents for rotation
let userAgents: [String] = [
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1"
]

// Default headers for API requests
let defaultHeaders: [String: String] = [
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Content-Type": "application/json"
]
