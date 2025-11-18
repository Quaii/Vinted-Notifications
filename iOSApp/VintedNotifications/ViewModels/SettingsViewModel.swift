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
    @Published var proxyListLink: String = ""
    @Published var checkProxies: Bool = false
    @Published var allowlist: [String] = []
    @Published var newCountry: String = ""

    func loadSettings() {
        refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
        itemsPerQuery = Int(DatabaseService.shared.getParameter("items_per_query", defaultValue: "\(AppConfig.defaultItemsPerQuery)")) ?? AppConfig.defaultItemsPerQuery
        banwords = DatabaseService.shared.getParameter("banwords", defaultValue: "")
        notificationMode = NotificationMode(rawValue: DatabaseService.shared.getParameter("notification_mode", defaultValue: NotificationMode.precise.rawValue)) ?? .precise
        userAgent = DatabaseService.shared.getParameter("user_agent", defaultValue: "")
        defaultHeaders = DatabaseService.shared.getParameter("default_headers", defaultValue: "")
        proxyList = DatabaseService.shared.getParameter("proxy_list", defaultValue: "")
        proxyListLink = DatabaseService.shared.getParameter("proxy_list_link", defaultValue: "")
        checkProxies = DatabaseService.shared.getParameter("check_proxies", defaultValue: "False") == "True"
        allowlist = DatabaseService.shared.getAllowlist()
    }

    func saveSettings() {
        DatabaseService.shared.setParameter("query_refresh_delay", value: "\(refreshDelay)")
        DatabaseService.shared.setParameter("items_per_query", value: "\(itemsPerQuery)")
        DatabaseService.shared.setParameter("banwords", value: banwords)
        DatabaseService.shared.setParameter("notification_mode", value: notificationMode.rawValue)
        DatabaseService.shared.setParameter("user_agent", value: userAgent)
        DatabaseService.shared.setParameter("default_headers", value: defaultHeaders)
        DatabaseService.shared.setParameter("proxy_list", value: proxyList)
        DatabaseService.shared.setParameter("proxy_list_link", value: proxyListLink)
        DatabaseService.shared.setParameter("check_proxies", value: checkProxies ? "True" : "False")

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

    func resetAllData() {
        DatabaseService.shared.deleteAllItems()
        DatabaseService.shared.deleteAllQueries()
        DatabaseService.shared.clearAllowlist()
        LogService.shared.clearLogs()
        LogService.shared.info("All data reset to defaults")
        loadSettings()
    }
}
