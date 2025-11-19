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
    @State private var isReady = false
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    init() {
        // Initialize services
        LogService.shared.info("Vinted Notifications app starting...")

        // Register background tasks
        MonitoringService.shared.registerBackgroundTasks()
        LogService.shared.info("Background tasks registered")
    }

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                // Show onboarding flow on first launch
                OnboardingFlow()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                    .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                        // Listen for onboarding completion
                        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    }
            } else if isReady {
                MainTabView()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                    .onAppear {
                        // Start monitoring if there are queries
                        let queries = DatabaseService.shared.getQueries(activeOnly: true)
                        if !queries.isEmpty {
                            MonitoringService.shared.startMonitoring()
                            LogService.shared.info("Monitoring started (\(queries.count) active queries)")
                        }
                    }
            } else {
                LoadingView()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                    .task {
                        // Simulate initialization delay
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                        LogService.shared.info("App initialization complete")
                        isReady = true
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
