//
//  VintedNotificationsApp.swift
//  Vinted Notifications
//
//  Main app entry point - Production Ready
//  iOS 17+ Compatible
//

import SwiftUI
import UIKit

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

        // Load appearance mode immediately
        loadAppearanceMode()
    }

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                // Show onboarding flow on first launch
                OnboardingFlow()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .onAppear {
                        themeManager.refreshSystemColorScheme()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                        // Listen for onboarding completion
                        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Refresh system color scheme when app becomes active
                        themeManager.refreshSystemColorScheme()
                    }
            } else if isReady {
                MainTabView()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .onAppear {
                        themeManager.refreshSystemColorScheme()

                        // Start monitoring if there are queries
                        let queries = DatabaseService.shared.getQueries(activeOnly: true)
                        if !queries.isEmpty {
                            MonitoringService.shared.startMonitoring()
                            LogService.shared.info("Monitoring started (\(queries.count) active queries)")
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Refresh system color scheme when app becomes active
                        themeManager.refreshSystemColorScheme()
                    }
            } else {
                LoadingView()
                    .environmentObject(themeManager)
                    .environment(\.theme, themeManager.currentTheme)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .onAppear {
                        themeManager.refreshSystemColorScheme()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Refresh system color scheme when app becomes active
                        themeManager.refreshSystemColorScheme()
                    }
                    .task {
                        // Simulate initialization delay
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                        LogService.shared.info("App initialization complete")
                        isReady = true
                    }
            }
        }
    }

    private func loadAppearanceMode() {
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            themeManager.setAppearanceMode(mode)
            LogService.shared.info("Loaded appearance mode: \(mode.rawValue)")
        } else {
            // Default to system mode
            themeManager.setAppearanceMode(.system)
            UserDefaults.standard.set(AppearanceMode.system.rawValue, forKey: "appearanceMode")
            LogService.shared.info("Set default appearance mode: system")
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
