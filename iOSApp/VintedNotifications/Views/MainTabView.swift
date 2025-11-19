//
//  MainTabView.swift
//  Vinted Notifications
//
//  Main Navigation Tab View
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            QueriesView()
                .tabItem {
                    Label("Queries", systemImage: "magnifyingglass")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
                .tag(2)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)

            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.fill")
                }
                .tag(4)
        }
        .accentColor(themeManager.currentTheme.primary)
    }
}
