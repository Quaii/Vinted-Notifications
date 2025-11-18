//
//  AllViews.swift
//  Vinted Notifications
//
//  Complete UI Implementation - Split into individual files when importing to Xcode
//  This file contains all Components, Screens, and Navigation
//

import SwiftUI

// MARK: - COMPONENTS

// PageHeader Component
struct PageHeader: View {
    let title: String
    var showSettings: Bool = true
    var showBack: Bool = false
    var centered: Bool = false
    var rightButton: AnyView? = nil

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            if showBack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                        Text("Back")
                            .font(.system(size: FontSizes.body))
                    }
                    .foregroundColor(theme.primary)
                }
            }

            if centered {
                Spacer()
            }

            Text(title)
                .font(.system(size: FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)

            Spacer()

            if let button = rightButton {
                button
            } else if showSettings {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: FontSizes.title3))
                        .foregroundColor(theme.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(theme.background)
    }
}

// StatWidget Component
struct StatWidget: View {
    let tag: String
    let value: String
    let subheading: String
    let icon: String
    let iconColor: Color

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)

                Spacer()

                Text(tag)
                    .font(.system(size: FontSizes.caption2, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .textCase(.uppercase)
            }

            Text(value)
                .font(.system(size: FontSizes.title1, weight: .bold))
                .foregroundColor(theme.text)

            Text(subheading)
                .font(.system(size: FontSizes.footnote))
                .foregroundColor(theme.textSecondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// ItemCard Component
struct ItemCard: View {
    let item: VintedItem
    var compact: Bool = false

    @Environment(\.theme) var theme
    @Environment(\.openURL) var openURL

    var body: some View {
        Button(action: {
            if let urlString = item.url, let url = URL(string: urlString) {
                openURL(url)
            }
        }) {
            HStack(spacing: Spacing.md) {
                // Photo
                AsyncImage(url: URL(string: item.photo ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(theme.buttonFill)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(theme.textTertiary)
                        )
                }
                .frame(width: compact ? 60 : 80, height: compact ? 60 : 80)
                .cornerRadius(BorderRadius.md)

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.formattedPrice())
                        .font(.system(size: FontSizes.headline, weight: .bold))
                        .foregroundColor(theme.primary)

                    Text(item.title)
                        .font(.system(size: FontSizes.body, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(compact ? 1 : 2)

                    if let brand = item.brandTitle, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: FontSizes.subheadline))
                            .foregroundColor(theme.textSecondary)
                    }

                    if !compact {
                        Text(item.timeSincePosted())
                            .font(.system(size: FontSizes.caption1))
                            .foregroundColor(theme.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// QueryCard Component
struct QueryCard: View {
    let query: VintedQuery
    let onPress: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        Button(action: onPress) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(query.queryName)
                            .font(.system(size: FontSizes.headline, weight: .semibold))
                            .foregroundColor(theme.text)

                        Text(query.domain())
                            .font(.system(size: FontSizes.subheadline))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: FontSizes.title3))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Text("Last item: \(query.lastItemTime())")
                    .font(.system(size: FontSizes.caption1))
                    .foregroundColor(theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// CustomToggle Component
struct CustomToggle: View {
    @Binding var isOn: Bool
    let activeColor: Color
    let inactiveColor: Color

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: activeColor))
    }
}

// MARK: - NAVIGATION

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

// MARK: - SCREENS

// Dashboard Screen
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Stats widgets
                    HStack(spacing: Spacing.md) {
                        StatWidget(
                            tag: "Total Items",
                            value: "\(viewModel.stats.totalItems)",
                            subheading: viewModel.stats.totalItems == 0 ? "No items yet" : "\(viewModel.stats.totalItems) cached",
                            icon: "square.grid.2x2",
                            iconColor: theme.primary
                        )

                        StatWidget(
                            tag: "Items / Day",
                            value: String(format: "%.0f", viewModel.stats.itemsPerDay),
                            subheading: "Last 7 days",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: theme.primary
                        )
                    }

                    // Last found item
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Last Found Item")
                                .font(.system(size: FontSizes.title3, weight: .semibold))
                                .foregroundColor(theme.text)

                            Spacer()

                            NavigationLink("View All") {
                                ItemsView()
                            }
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                        }

                        if let item = viewModel.lastItem {
                            ItemCard(item: item, compact: true)
                        } else {
                            Text("No items found yet")
                                .font(.system(size: FontSizes.subheadline))
                                .foregroundColor(theme.textTertiary)
                                .italic()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                        }
                    }

                    // Recent queries
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Queries")
                                .font(.system(size: FontSizes.title3, weight: .semibold))
                                .foregroundColor(theme.text)

                            Spacer()

                            NavigationLink("Manage") {
                                QueriesView()
                            }
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                        }

                        ForEach(viewModel.recentQueries) { query in
                            QueryCard(
                                query: query,
                                onPress: {},
                                onDelete: {},
                                onEdit: {}
                            )
                        }
                    }

                    // Recent logs
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Recent Logs")
                                .font(.system(size: FontSizes.title3, weight: .semibold))
                                .foregroundColor(theme.text)

                            Spacer()

                            NavigationLink("View All") {
                                LogsView()
                            }
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                        }

                        ForEach(viewModel.recentLogs) { log in
                            LogEntryView(log: log)
                        }
                    }

                    Spacer()
                        .frame(height: 100) // Tab bar spacing
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await MonitoringService.shared.checkNow()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
    }
}

// Log Entry View
struct LogEntryView: View {
    let log: LogEntry
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: log.level.icon)
                    .foregroundColor(log.level.color)
                Text(log.level.rawValue)
                    .font(.system(size: FontSizes.caption2, weight: .bold))
                    .foregroundColor(log.level.color)

                Spacer()

                Text(log.timestamp, style: .time)
                    .font(.system(size: FontSizes.caption1))
                    .foregroundColor(theme.textTertiary)
            }

            Text(log.message)
                .font(.system(size: FontSizes.subheadline))
                .foregroundColor(theme.text)
                .lineLimit(2)
        }
        .padding(Spacing.md)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(log.level.color.opacity(0.3), lineWidth: 2)
        )
    }
}

// Queries Screen
struct QueriesView: View {
    @StateObject private var viewModel = QueriesViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.queries.isEmpty {
                    // Empty state
                    VStack(spacing: Spacing.xl) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 64))
                            .foregroundColor(theme.textTertiary)

                        Text("No search queries")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.textSecondary)

                        Text("Add a Vinted search URL to start tracking new items")
                            .font(.system(size: FontSizes.subheadline))
                            .foregroundColor(theme.textTertiary)
                            .multilineTextAlignment(.center)

                        Button(action: { viewModel.showAddSheet = true }) {
                            Text("Add Your First Query")
                                .font(.system(size: FontSizes.body, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(theme.primary)
                                .cornerRadius(BorderRadius.lg)
                        }
                    }
                    .padding(Spacing.xl)
                } else {
                    // List of queries
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.queries) { query in
                                QueryCard(
                                    query: query,
                                    onPress: {},
                                    onDelete: { viewModel.deleteQuery(query) },
                                    onEdit: { viewModel.startEditing(query) }
                                )
                            }
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, 100)
                    }
                }

                // FAB button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { viewModel.showAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(theme.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, Spacing.md)
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(theme.groupedBackground)
            .navigationTitle("Queries")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showAddSheet) {
                QuerySheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadQueries()
        }
    }
}

// Query Sheet
struct QuerySheet: View {
    @ObservedObject var viewModel: QueriesViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Vinted Search URL") {
                    TextField("https://www.vinted.com/catalog?...", text: $viewModel.newQueryUrl)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                }

                Section("Custom Name (Optional)") {
                    TextField("e.g., Nike Shoes", text: $viewModel.newQueryName)
                }

                Section {
                    Text("Paste the full URL from a Vinted search. The app will automatically monitor this search and notify you of new items.")
                        .font(.system(size: FontSizes.footnote))
                        .foregroundColor(theme.textTertiary)
                }

                Button(action: {
                    viewModel.addQuery()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }) {
                    Text(viewModel.editingQuery != nil ? "Update Query" : "Add Query")
                        .font(.system(size: FontSizes.headline, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(theme.primary)
                .foregroundColor(.white)
            }
            .navigationTitle(viewModel.editingQuery != nil ? "Edit Query" : "Add Query")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.newQueryUrl = ""
                        viewModel.newQueryName = ""
                        viewModel.editingQuery = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

// Items Screen
struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    TextField("Search items...", text: $viewModel.searchQuery)
                        .onChange(of: viewModel.searchQuery) { _ in
                            viewModel.applyFilters()
                        }
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.applyFilters()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(theme.secondaryGroupedBackground)
                .cornerRadius(BorderRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .stroke(theme.border, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Toolbar
                HStack {
                    Button(action: { viewModel.showSortSheet = true }) {
                        HStack {
                            Text(viewModel.sortBy.rawValue)
                                .font(.system(size: FontSizes.body, weight: .medium))
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(theme.text)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.lg)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Button(action: { viewModel.viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewModel.viewMode == .list ? .white : theme.textSecondary)
                                .padding(Spacing.sm)
                                .background(viewModel.viewMode == .list ? theme.primary : Color.clear)
                                .cornerRadius(BorderRadius.md)
                        }

                        Button(action: { viewModel.viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(viewModel.viewMode == .grid ? .white : theme.textSecondary)
                                .padding(Spacing.sm)
                                .background(viewModel.viewMode == .grid ? theme.primary : Color.clear)
                                .cornerRadius(BorderRadius.md)
                        }
                    }
                    .background(theme.secondaryGroupedBackground)
                    .cornerRadius(BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.lg)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                // Items list/grid
                if viewModel.filteredItems.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textTertiary)
                        Text("No items found")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.filteredItems) { item in
                                ItemCard(item: item)
                            }
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(theme.groupedBackground)
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadItems()
        }
        .refreshable {
            viewModel.loadItems()
        }
        .sheet(isPresented: $viewModel.showSortSheet) {
            SortSheet(viewModel: viewModel)
        }
    }
}

// Sort Sheet
struct SortSheet: View {
    @ObservedObject var viewModel: ItemsViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(ItemSortOption.allCases, id: \.self) { option in
                Button(action: {
                    viewModel.sortBy = option
                    viewModel.applyFilters()
                    dismiss()
                }) {
                    HStack {
                        Text(option.rawValue)
                            .foregroundColor(theme.text)
                        Spacer()
                        if viewModel.sortBy == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primary)
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Analytics Screen
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Overview stats
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.md) {
                            StatsCard(title: "Total Items", value: "\(viewModel.stats.totalItems)", icon: "square.grid.2x2")
                            StatsCard(title: "Avg. Price", value: String(format: "%.2f€", viewModel.stats.avgPrice), icon: "eurosign.circle")
                        }
                        HStack(spacing: Spacing.md) {
                            StatsCard(title: "Today", value: "\(viewModel.stats.itemsToday)", icon: "calendar")
                            StatsCard(title: "This Week", value: "\(viewModel.stats.itemsThisWeek)", icon: "calendar.badge.clock")
                        }
                    }

                    // Charts placeholder
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Items Over Time")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.text)

                        if viewModel.stats.totalItems > 0 {
                            Rectangle()
                                .fill(theme.secondaryGroupedBackground)
                                .frame(height: 220)
                                .cornerRadius(BorderRadius.xl)
                                .overlay(
                                    Text("Chart: \(viewModel.dailyData.count) days of data")
                                        .foregroundColor(theme.textTertiary)
                                )
                        } else {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48))
                                    .foregroundColor(theme.textTertiary)
                                Text("No data available")
                                    .font(.system(size: FontSizes.body))
                                    .foregroundColor(theme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.xl)
                        }
                    }

                    Spacer()
                        .frame(height: 100)
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            viewModel.loadAnalytics()
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.primary)

            Text(value)
                .font(.system(size: FontSizes.title2, weight: .bold))
                .foregroundColor(theme.text)

            Text(title)
                .font(.system(size: FontSizes.caption2, weight: .bold))
                .foregroundColor(theme.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// Logs Screen
struct LogsView: View {
    @StateObject private var viewModel = LogsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            if viewModel.logs.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(theme.textTertiary)
                    Text("No logs yet")
                        .font(.system(size: FontSizes.title2, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    Text("Application events will appear here")
                        .font(.system(size: FontSizes.body))
                        .foregroundColor(theme.textTertiary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.logs) { log in
                            LogEntryView(log: log)
                        }
                    }
                    .padding(Spacing.lg)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(theme.groupedBackground)
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.logs.isEmpty {
                    Button(action: viewModel.clearLogs) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

// Settings Screen
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // App Settings
                Section("App Settings") {
                    HStack {
                        Text("Dark Mode")
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading) {
                        Text("Notification Mode")
                        Picker("Mode", selection: $viewModel.notificationMode) {
                            Text("Precise").tag(NotificationMode.precise)
                            Text("Compact").tag(NotificationMode.compact)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.notificationMode) { _ in
                            DatabaseService.shared.setParameter("notification_mode", value: viewModel.notificationMode.rawValue)
                        }
                    }
                }

                // System Settings
                Section("System Settings") {
                    HStack {
                        Text("Items Per Query")
                        Spacer()
                        TextField("20", value: $viewModel.itemsPerQuery, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Refresh Delay (sec)")
                        Spacer()
                        TextField("60", value: $viewModel.refreshDelay, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                // Country Allowlist
                Section("Country Allowlist") {
                    HStack {
                        TextField("e.g., US, FR, DE", text: $viewModel.newCountry)
                            .textCase(.uppercase)
                            .autocapitalization(.allCharacters)

                        Button(action: viewModel.addCountry) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.primary)
                        }
                        .disabled(viewModel.newCountry.isEmpty)
                    }

                    if !viewModel.allowlist.isEmpty {
                        ForEach(viewModel.allowlist, id: \.self) { code in
                            HStack {
                                Text(code)
                                Spacer()
                                Button(action: { viewModel.removeCountry(code) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                // Danger Zone
                Section("Danger Zone") {
                    Button(action: viewModel.deleteAllItems) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Items")
                        }
                        .foregroundColor(.red)
                    }

                    Button(action: viewModel.deleteAllQueries) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Queries")
                        }
                        .foregroundColor(.red)
                    }

                    Button(action: viewModel.resetAllData) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Reset All Data")
                        }
                        .foregroundColor(.red)
                    }
                }

                // Version
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Vinted Notifications")
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(theme.textTertiary)
                            Text("v1.0.0 by Quaii")
                                .font(.system(size: FontSizes.caption2))
                                .foregroundColor(theme.textTertiary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadSettings()
        }
    }
}
