//
//  SettingsViewModel.swift
//  Vinted Notifications
//

import Foundation

enum DangerZoneAction {
    case deleteAllItems
    case deleteAllQueries
    case clearLogs
    case resetAllData
}

class SettingsViewModel: ObservableObject {
    @Published var refreshDelay: Int = AppConfig.defaultRefreshDelay
    @Published var itemsPerQuery: Int = AppConfig.defaultItemsPerQuery
    @Published var banwords: String = ""
    @Published var notificationMode: NotificationMode = .precise
    @Published var userAgent: String = ""
    @Published var defaultHeaders: String = ""
    @Published var proxyList: String = ""
    @Published var proxyListURL: String = ""
    @Published var checkProxies: Bool = false
    @Published var allowlist: [String] = []
    @Published var newCountry: String = ""
    @Published var showDangerZoneConfirmation = false
    @Published var pendingDangerZoneAction: DangerZoneAction?

    func loadSettings() {
        refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
        itemsPerQuery = Int(DatabaseService.shared.getParameter("items_per_query", defaultValue: "\(AppConfig.defaultItemsPerQuery)")) ?? AppConfig.defaultItemsPerQuery
        banwords = DatabaseService.shared.getParameter("banwords", defaultValue: "")
        notificationMode = NotificationMode(rawValue: DatabaseService.shared.getParameter("notification_mode", defaultValue: NotificationMode.precise.rawValue)) ?? .precise

        // Load and pretty-print user agents
        let userAgentsJSON = DatabaseService.shared.getParameter("user_agents", defaultValue: "[]")
        userAgent = prettyPrintJSON(userAgentsJSON) ?? userAgentsJSON

        // Load and pretty-print default headers
        let defaultHeadersJSON = DatabaseService.shared.getParameter("default_headers", defaultValue: "{}")
        defaultHeaders = prettyPrintJSON(defaultHeadersJSON) ?? defaultHeadersJSON

        proxyList = DatabaseService.shared.getParameter("proxy_list", defaultValue: "")
        proxyListURL = DatabaseService.shared.getParameter("proxy_list_link", defaultValue: "")
        checkProxies = DatabaseService.shared.getParameter("check_proxies", defaultValue: "0") == "1"
        allowlist = DatabaseService.shared.getAllowlist()
    }

    private func prettyPrintJSON(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }

    private func compactJSON(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let compactData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
              let compactString = String(data: compactData, encoding: .utf8) else {
            return nil
        }
        return compactString
    }

    func saveSettings() {
        DatabaseService.shared.setParameter("query_refresh_delay", value: "\(refreshDelay)")
        DatabaseService.shared.setParameter("items_per_query", value: "\(itemsPerQuery)")
        DatabaseService.shared.setParameter("banwords", value: banwords)
        DatabaseService.shared.setParameter("notification_mode", value: notificationMode.rawValue)

        // Compact JSON before saving
        let compactUserAgents = compactJSON(userAgent) ?? userAgent
        let compactHeaders = compactJSON(defaultHeaders) ?? defaultHeaders

        DatabaseService.shared.setParameter("user_agents", value: compactUserAgents)
        DatabaseService.shared.setParameter("default_headers", value: compactHeaders)
        DatabaseService.shared.setParameter("proxy_list", value: proxyList)
        DatabaseService.shared.setParameter("proxy_list_link", value: proxyListURL)
        DatabaseService.shared.setParameter("check_proxies", value: checkProxies ? "1" : "0")

        // Reload VintedAPI settings to apply changes
        VintedAPI.shared.reloadSettings()

        LogService.shared.info("Settings saved successfully")
    }

    func addCountry() {
        let code = newCountry.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty, code.count == 2 else { return }

        DatabaseService.shared.addToAllowlist(code)
        newCountry = ""
        loadSettings()
    }

    func removeCountry(_ code: String) {
        DatabaseService.shared.removeFromAllowlist(code)
        loadSettings()
    }

    func clearAllowlist() {
        DatabaseService.shared.clearAllowlist()
        loadSettings()
    }

    func requestDeleteAllItems() {
        pendingDangerZoneAction = .deleteAllItems
        showDangerZoneConfirmation = true
    }

    func requestDeleteAllQueries() {
        pendingDangerZoneAction = .deleteAllQueries
        showDangerZoneConfirmation = true
    }

    func requestClearLogs() {
        pendingDangerZoneAction = .clearLogs
        showDangerZoneConfirmation = true
    }

    func requestResetAllData() {
        pendingDangerZoneAction = .resetAllData
        showDangerZoneConfirmation = true
    }

    func executeDangerZoneAction() {
        guard let action = pendingDangerZoneAction else { return }

        switch action {
        case .deleteAllItems:
            DatabaseService.shared.deleteAllItems()
            LogService.shared.info("All items deleted")
        case .deleteAllQueries:
            DatabaseService.shared.deleteAllQueries()
            LogService.shared.info("All queries deleted")
        case .clearLogs:
            LogService.shared.clearLogs()
            LogService.shared.info("All logs cleared")
        case .resetAllData:
            DatabaseService.shared.deleteAllItems()
            DatabaseService.shared.deleteAllQueries()
            DatabaseService.shared.clearAllowlist()
            LogService.shared.clearLogs()
            LogService.shared.info("All data reset to defaults")
            loadSettings()
        }

        pendingDangerZoneAction = nil
    }

    func getConfirmationMessage() -> (title: String, message: String) {
        guard let action = pendingDangerZoneAction else {
            return ("", "")
        }

        switch action {
        case .deleteAllItems:
            return ("Clear All Items?", "This will permanently delete all cached items. This action cannot be undone.")
        case .deleteAllQueries:
            return ("Delete All Queries?", "This will permanently delete all saved search queries. This action cannot be undone.")
        case .clearLogs:
            return ("Clear All Logs?", "This will permanently delete all application logs. This action cannot be undone.")
        case .resetAllData:
            return ("Reset All Data?", "This will permanently delete ALL items, queries, logs, and settings. This action cannot be undone.")
        }
    }

    #if DEBUG
    @Published var debugTapCount = 0
    @Published var showDebugCountdown = false
    @Published var debugCountdownMessage = ""
    @Published var debugModeEnabled = false

    func handleDebugTap() {
        // If already enabled, don't allow re-enabling until app restart
        if debugModeEnabled {
            return
        }

        debugTapCount += 1

        if debugTapCount >= 2 && debugTapCount < 5 {
            let remaining = 5 - debugTapCount
            debugCountdownMessage = "You are \(remaining) click\(remaining == 1 ? "" : "s") away from enabling Developer mode"
            showDebugCountdown = true

            // Hide message after 1.5 seconds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if showDebugCountdown {
                    showDebugCountdown = false
                }
            }
        } else if debugTapCount >= 5 {
            // Enable debug mode (one-time per app session)
            debugModeEnabled = true
            debugTapCount = 0
            showDebugCountdown = false
            LogService.shared.info("[Debug] Developer mode enabled")
        }

        // Reset tap count after 3 seconds of inactivity
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if debugTapCount < 5 {
                debugTapCount = 0
            }
        }
    }

    func sendTestNotification() {
        Task {
            let testItem = VintedItem(
                id: Int64(Date().timeIntervalSince1970 * 1000),
                title: "Debug Test Notification",
                brandTitle: "Debug Brand",
                sizeTitle: "L",
                price: "99.99",
                currency: "€",
                photo: nil,
                url: "https://www.vinted.com",
                buyUrl: "https://www.vinted.com/transaction/buy/new?source_screen=item",
                createdAtTs: Int64(Date().timeIntervalSince1970 * 1000),
                rawTimestamp: nil,
                queryId: nil,
                notified: false,
                userId: nil,
                userCountry: nil
            )

            await NotificationService.shared.scheduleNotification(for: testItem, mode: notificationMode)
            LogService.shared.info("[Debug] Test notification sent")
        }
    }

    func sendMultipleNotifications(count: Int) {
        Task {
            for i in 1...count {
                let testItem = VintedItem(
                    id: Int64(Date().timeIntervalSince1970 * 1000) + Int64(i),
                    title: "Test Item #\(i)",
                    brandTitle: "Brand \(i)",
                    sizeTitle: "M",
                    price: "\(i * 10).00",
                    currency: "€",
                    photo: nil,
                    url: "https://www.vinted.com",
                    buyUrl: "https://www.vinted.com/transaction/buy/new?source_screen=item",
                    createdAtTs: Int64(Date().timeIntervalSince1970 * 1000),
                    rawTimestamp: nil,
                    queryId: nil,
                    notified: false,
                    userId: nil,
                    userCountry: nil
                )

                await NotificationService.shared.scheduleNotification(for: testItem, mode: .precise)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            LogService.shared.info("[Debug] Sent \(count) test notifications")
        }
    }

    func triggerManualFetch() {
        Task {
            LogService.shared.info("[Debug] Manual fetch triggered")
            await MonitoringService.shared.checkNow()
        }
    }

    func clearAllDebugNotifications() {
        Task { @MainActor in
            NotificationService.shared.clearAllNotifications()
            LogService.shared.info("[Debug] All notifications cleared")
        }
    }

    func checkDebugAuthorizationStatus() {
        Task { @MainActor in
            NotificationService.shared.checkAuthorizationStatus()
            LogService.shared.info("[Debug] Notification authorization check requested")
        }
    }
    #endif
}
