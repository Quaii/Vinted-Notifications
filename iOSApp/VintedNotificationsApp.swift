//
//  VintedNotificationsApp.swift
//  Vinted Notifications
//
//  Main app entry point
//

import SwiftUI

@main
struct VintedNotificationsApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        // App initialization will happen here
        // Services will be initialized when implemented:
        // - DatabaseService
        // - NotificationService
        // - MonitoringService
        // - LogService

        print("Vinted Notifications app starting...")
    }

    var body: some Scene {
        WindowGroup {
            // Placeholder view until MainTabView is implemented
            ZStack {
                themeManager.currentTheme.background
                    .ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeManager.currentTheme.primary)

                    Text("Vinted Notifications")
                        .font(.system(size: FontSizes.largeTitle, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.text)

                    Text("Swift/SwiftUI Implementation")
                        .font(.system(size: FontSizes.title3))
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()
                        .frame(height: 40)

                    Text("Architecture Complete")
                        .font(.system(size: FontSizes.headline, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.primary)

                    Text("Ready for full implementation")
                        .font(.system(size: FontSizes.subheadline))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    Spacer()
                        .frame(height: 60)

                    Button(action: {
                        themeManager.toggleTheme()
                    }) {
                        HStack {
                            Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            Text("Toggle \(themeManager.isDarkMode ? "Light" : "Dark") Mode")
                        }
                        .font(.system(size: FontSizes.body, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(themeManager.currentTheme.primary)
                        .cornerRadius(BorderRadius.lg)
                    }
                }
                .padding(Spacing.xl)
            }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)

            // Once implemented, replace with:
            // MainTabView()
            //     .environmentObject(themeManager)
            //     .environment(\.theme, themeManager.currentTheme)
            //     .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}

// Preview
#Preview {
    VintedNotificationsApp()
        .preferredColorScheme(.dark)
}
