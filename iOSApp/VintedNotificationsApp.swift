//
//  VintedNotificationsApp.swift
//  Vinted Notifications
//
//  Main app entry point - Production Ready
//  iOS 17+ Compatible
//

import SwiftUI

@main
struct VintedNotificationsApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        // Initialize services
        LogService.shared.info("🚀 Vinted Notifications app starting...")

        // Register background tasks
        MonitoringService.shared.registerBackgroundTasks()
        LogService.shared.info("✅ Background tasks registered")

        // Request notification permissions
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            LogService.shared.info("📱 Notification permission: \(granted)")
        }

        LogService.shared.info("✨ App initialization complete")
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environment(\.theme, themeManager.currentTheme)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    // Start monitoring if there are queries
                    let queries = DatabaseService.shared.getQueries(activeOnly: true)
                    if !queries.isEmpty {
                        MonitoringService.shared.startMonitoring()
                        LogService.shared.info("🔄 Monitoring started (\(queries.count) active queries)")
                    }
                }
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    let themeManager = ThemeManager()
    themeManager.isDarkMode = false

    return MainTabView()
        .environmentObject(themeManager)
        .environment(\.theme, themeManager.currentTheme)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    let themeManager = ThemeManager()
    themeManager.isDarkMode = true

    return MainTabView()
        .environmentObject(themeManager)
        .environment(\.theme, themeManager.currentTheme)
        .preferredColorScheme(.dark)
}
