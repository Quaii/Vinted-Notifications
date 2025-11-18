//
//  SettingsViewModel.swift
//  Vinted Notifications
//

import Foundation

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

    func deleteAllItems() {
        DatabaseService.shared.deleteAllItems()
        LogService.shared.info("All items deleted")
    }

    func deleteAllQueries() {
        DatabaseService.shared.deleteAllQueries()
        LogService.shared.info("All queries deleted")
    }

    func clearLogs() {
        LogService.shared.clearLogs()
        LogService.shared.info("All logs cleared")
    }

    func resetAllData() {
        DatabaseService.shared.deleteAllItems()
        DatabaseService.shared.deleteAllQueries()
        DatabaseService.shared.clearAllowlist()
        LogService.shared.clearLogs()
        LogService.shared.info("All data reset to defaults")
        loadSettings()
    }
}
