//
//  AllViews.swift
//  Vinted Notifications
//
//  Complete UI Implementation - Split into individual files when importing to Xcode
//  This file contains all Components, Screens, and Navigation
//

import SwiftUI

// MARK: - COMPONENTS

// LoadingView Component - Matches React Native loading screen
struct LoadingView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            Text("Vinted Notifications")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(theme.text)
                .kerning(-1)
                .padding(.bottom, 8)

            // Tagline
            Text("NEVER MISS A DEAL")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textTertiary)
                .kerning(2)
                .padding(.bottom, 48)

            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.5)
                .padding(.bottom, 16)

            // Loading text
            Text("Initializing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

// PageHeader Component - Matches React Native exactly
struct PageHeader: View {
    let title: String
    var showSettings: Bool = true
    var showBack: Bool = false
    var centered: Bool = false
    var rightButton: AnyView? = nil

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack(alignment: .center) {
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
                        .font(.system(size: 34))
                        .foregroundColor(theme.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(theme.background)
    }
}

// StatWidget Component - Matches React Native exactly
struct StatWidget: View {
    let tag: String
    let value: String
    let subheading: String
    let lastUpdated: String
    let icon: String
    let iconColor: Color

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with tag and icon
            HStack {
                Text(tag)
                    .font(.system(size: FontSizes.caption1, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Spacer()

                // Icon in circular container
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.08))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
            }
            .padding(.bottom, Spacing.xs)

            Spacer()

            // Content - Value and subheading
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(theme.text)
                    .kerning(-1)
                    .lineSpacing(52 - 48)

                if !subheading.isEmpty {
                    Text(subheading)
                        .font(.system(size: FontSizes.subheadline, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Spacer()

            // Footer - Last updated
            Text(lastUpdated)
                .font(.system(size: FontSizes.caption2, weight: .medium))
                .foregroundColor(theme.textTertiary)
                .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// CustomToggle Component - Matches React Native exactly (51x31)
struct CustomToggle: View {
    @Binding var isOn: Bool
    let activeColor: Color
    let inactiveColor: Color

    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 15.5)
                    .fill(isOn ? activeColor : inactiveColor)
                    .frame(width: 51, height: 31)

                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.2), radius: 2.5, x: 0, y: 2)
                    .padding(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Dashboard")

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Stats widgets
                        HStack(spacing: Spacing.md) {
                            StatWidget(
                                tag: "Total Items",
                                value: "\(viewModel.stats.totalItems)",
                                subheading: viewModel.stats.totalItems == 0 ? "No items yet" : "\(viewModel.stats.totalItems) cached",
                                lastUpdated: viewModel.stats.lastUpdated,
                                icon: "square.grid.2x2",
                                iconColor: theme.primary
                            )

                            StatWidget(
                                tag: "Items / Day",
                                value: String(format: "%.0f", viewModel.stats.itemsPerDay),
                                subheading: "Last 7 days",
                                lastUpdated: viewModel.stats.lastUpdated,
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

                            if viewModel.recentQueries.isEmpty {
                                Text("No queries saved")
                                    .font(.system(size: FontSizes.subheadline))
                                    .foregroundColor(theme.textTertiary)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.lg)
                            } else {
                                ForEach(viewModel.recentQueries) { query in
                                    QueryCard(
                                        query: query,
                                        onPress: {},
                                        onDelete: {},
                                        onEdit: {}
                                    )
                                }
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
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadDashboard()
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
    }
}

// Log Entry View - Matches React Native (without icons per user request)
struct LogEntryView: View {
    let log: LogEntry
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                // Level badge without icon
                HStack(spacing: 4) {
                    Text(log.level.rawValue)
                        .font(.system(size: FontSizes.caption2, weight: .bold))
                        .foregroundColor(log.level.color)
                }
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 2)
                .background(log.level.color.opacity(0.2))
                .cornerRadius(BorderRadius.sm)

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
                .stroke(theme.separator, lineWidth: 1)
        )
        .overlay(
            // Left border accent
            Rectangle()
                .fill(log.level.color)
                .frame(width: 4)
                .cornerRadius(BorderRadius.lg, corners: [.topLeft, .bottomLeft]),
            alignment: .leading
        )
    }
}

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Queries Screen
struct QueriesView: View {
    @StateObject private var viewModel = QueriesViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Queries")

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
            }
            .navigationBarHidden(true)
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
                // Custom Page Header
                PageHeader(title: "Items")

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    TextField("Search items...", text: $viewModel.searchQuery)
                        .onChange(of: viewModel.searchQuery) {
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
                .padding(.top, Spacing.xs)

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
            .navigationBarHidden(true)
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
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Analytics")

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
            }
            .navigationBarHidden(true)
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
            VStack(spacing: 0) {
                // Custom Page Header with clear button
                PageHeader(
                    title: "Logs",
                    rightButton: viewModel.logs.isEmpty ? nil : AnyView(
                        Button(action: viewModel.clearLogs) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primary)
                        }
                    )
                )

                if viewModel.logs.isEmpty {
                    Spacer()
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
                    Spacer()
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
            .navigationBarHidden(true)
        }
    }
}

// Custom Segmented Control Component
struct CustomSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    Text(options[index])
                        .font(.system(size: FontSizes.subheadline, weight: .semibold))
                        .foregroundColor(selectedIndex == index ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                }
                .background(selectedIndex == index ? theme.primary : Color.clear)
                .cornerRadius(BorderRadius.md)
            }
        }
        .padding(2)
        .background(theme.buttonFill)
        .cornerRadius(BorderRadius.lg)
    }
}

// Settings Row with Toggle - Helper view to avoid complex expressions
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let activeColor: Color
    let inactiveColor: Color

    @Environment(\.theme) var theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: FontSizes.body, weight: .medium))
                    .foregroundColor(theme.text)
                Text(description)
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)
            }
            Spacer()
            CustomToggle(
                isOn: $isOn,
                activeColor: activeColor,
                inactiveColor: inactiveColor
            )
        }
        .padding(Spacing.md)
        .frame(minHeight: 60)
    }
}

// Settings Screen - Custom styling to match React Native
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var showSaveConfirmation = false

    // Helper computed properties to avoid complex expressions
    private var toggleActiveColor: Color { theme.primary }
    private var toggleInactiveColor: Color { theme.buttonFill }
    private var darkModeDescription: String {
        themeManager.isDarkMode ? "Dark mode enabled" : "Light mode enabled"
    }

    // MARK: - Sections
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("App Settings")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.text)

                        Text("Customize the appearance and behavior of the app")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)

                        VStack(spacing: 0) {
                            // Dark Mode Row
                            SettingsToggleRow(
                                title: "Dark Mode",
                                description: darkModeDescription,
                                isOn: $themeManager.isDarkMode,
                                activeColor: toggleActiveColor,
                                inactiveColor: toggleInactiveColor
                            )
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Notification Mode Row
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notification Mode")
                                        .font(.system(size: FontSizes.body, weight: .medium))
                                        .foregroundColor(theme.text)
                                    Text(viewModel.notificationMode == .precise
                                        ? "Precise: Individual notification for each item with details"
                                        : "Compact: Summary notification (e.g., \"5 new items found\")")
                                        .font(.system(size: FontSizes.footnote))
                                        .foregroundColor(theme.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                CustomSegmentedControl(
                                    options: ["Precise", "Compact"],
                                    selectedIndex: Binding(
                                        get: { viewModel.notificationMode == .precise ? 0 : 1 },
                                        set: { viewModel.notificationMode = $0 == 0 ? .precise : .compact }
                                    )
                                )
                            }
                            .padding(Spacing.md)
                        }
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.xl)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.xl)
                                .stroke(theme.separator, lineWidth: 1)
                        )
        }
    }

    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Advanced Settings")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.text)

                        Text("Configure advanced options for power users (leave empty for defaults)")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)

                        VStack(spacing: 0) {
                            // User Agent
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("User Agent")
                                    .font(.system(size: FontSizes.body, weight: .medium))
                                    .foregroundColor(theme.text)
                                Text("Custom user agent for API requests")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                TextEditor(text: $viewModel.userAgent)
                                    .frame(minHeight: 80)
                                    .padding(Spacing.sm)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(Spacing.md)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Default Headers
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Default Headers")
                                    .font(.system(size: FontSizes.body, weight: .medium))
                                    .foregroundColor(theme.text)
                                Text("Custom HTTP headers (JSON format)")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                TextEditor(text: $viewModel.defaultHeaders)
                                    .frame(minHeight: 80)
                                    .padding(Spacing.sm)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(Spacing.md)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Proxy List
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Proxy List")
                                    .font(.system(size: FontSizes.body, weight: .medium))
                                    .foregroundColor(theme.text)
                                Text("Semicolon-separated proxy list (e.g., http://proxy1:port;http://proxy2:port)")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                TextEditor(text: $viewModel.proxyList)
                                    .frame(minHeight: 80)
                                    .padding(Spacing.sm)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(Spacing.md)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Proxy List URL
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Proxy List URL")
                                    .font(.system(size: FontSizes.body, weight: .medium))
                                    .foregroundColor(theme.text)
                                Text("URL to fetch proxy list from (one proxy per line)")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                TextEditor(text: $viewModel.proxyListURL)
                                    .frame(minHeight: 80)
                                    .padding(Spacing.sm)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(Spacing.md)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Check Proxies
                            SettingsToggleRow(
                                title: "Check Proxies",
                                description: "Verify proxies before use (slower but more reliable)",
                                isOn: $viewModel.checkProxies,
                                activeColor: toggleActiveColor,
                                inactiveColor: toggleInactiveColor
                            )
                        }
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.xl)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.xl)
                                .stroke(theme.separator, lineWidth: 1)
                        )
        }
    }

    private var systemSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("System Settings")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.text)

                        Text("Configure monitoring behavior and filtering")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)

                        VStack(spacing: 0) {
                            // Items Per Query
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Items Per Query")
                                        .font(.system(size: FontSizes.body, weight: .medium))
                                        .foregroundColor(theme.text)
                                    Text("Number of items to fetch per search")
                                        .font(.system(size: FontSizes.footnote))
                                        .foregroundColor(theme.textTertiary)
                                }
                                Spacer()
                                TextField("20", value: $viewModel.itemsPerQuery, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                            }
                            .padding(Spacing.md)
                            .frame(minHeight: 60)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Refresh Delay
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Query Refresh Delay")
                                        .font(.system(size: FontSizes.body, weight: .medium))
                                        .foregroundColor(theme.text)
                                    Text("How often to check for new items")
                                        .font(.system(size: FontSizes.footnote))
                                        .foregroundColor(theme.textTertiary)
                                }
                                Spacer()
                                TextField("60", value: $viewModel.refreshDelay, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                Text("sec")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                            }
                            .padding(Spacing.md)
                            .frame(minHeight: 60)
                            .overlay(
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1),
                                alignment: .bottom
                            )

                            // Banned Words
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Banned Words")
                                    .font(.system(size: FontSizes.body, weight: .medium))
                                    .foregroundColor(theme.text)
                                Text("Filter out items containing these words (separate with |||)")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                TextEditor(text: $viewModel.banwords)
                                    .frame(minHeight: 80)
                                    .padding(Spacing.sm)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(Spacing.md)
                        }
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.xl)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.xl)
                                .stroke(theme.separator, lineWidth: 1)
                        )
        }
    }

    private var countryAllowlistSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Country Allowlist")
                                .font(.system(size: FontSizes.title3, weight: .semibold))
                                .foregroundColor(theme.text)
                            Spacer()
                            if !viewModel.allowlist.isEmpty {
                                Button("Clear All") {
                                    viewModel.clearAllowlist()
                                }
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.link)
                            }
                        }

                        Text("Only show items from sellers in these countries (leave empty to allow all)")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)

                        VStack(spacing: Spacing.sm) {
                            HStack {
                                TextField("e.g., US, FR, DE", text: $viewModel.newCountry)
                                    .textCase(.uppercase)
                                    .autocapitalization(.allCharacters)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs + 2)
                                    .background(theme.cardBackground)
                                    .cornerRadius(BorderRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BorderRadius.md)
                                            .stroke(theme.separator, lineWidth: 1)
                                    )

                                Button(action: viewModel.addCountry) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(theme.primary)
                                        .clipShape(Circle())
                                }
                                .disabled(viewModel.newCountry.isEmpty)
                            }

                            if !viewModel.allowlist.isEmpty {
                                // Country tags with wrapping
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: Spacing.xs)], spacing: Spacing.xs) {
                                    ForEach(viewModel.allowlist, id: \.self) { code in
                                        HStack(spacing: 4) {
                                            Text(code)
                                                .font(.system(size: FontSizes.subheadline, weight: .medium))
                                                .foregroundColor(theme.text)

                                            Button(action: { viewModel.removeCountry(code) }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(theme.textSecondary)
                                            }
                                        }
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, 6)
                                        .background(theme.buttonFill)
                                        .cornerRadius(BorderRadius.md)
                                    }
                                }
                            } else {
                                Text("No countries in allowlist")
                                    .font(.system(size: FontSizes.footnote))
                                    .foregroundColor(theme.textTertiary)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                            }
                        }
                        .padding(Spacing.lg)
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.xl)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.xl)
                                .stroke(theme.separator, lineWidth: 1)
                        )
        }
    }

    private var saveButton: some View {
        Button(action: {
                        viewModel.saveSettings()
                        showSaveConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Save Settings")
                                .font(.system(size: FontSizes.headline, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(theme.primary)
                        .cornerRadius(BorderRadius.lg)
        }
    }

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Danger Zone")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.text)

                        Text("Dangerous operations that cannot be undone")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)

                        VStack(spacing: Spacing.sm) {
                            Button(action: viewModel.deleteAllItems) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 20))
                                    Text("Clear All Items")
                                        .font(.system(size: FontSizes.headline, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(theme.error)
                                .cornerRadius(BorderRadius.lg)
                            }

                            Button(action: viewModel.deleteAllQueries) {
                                HStack {
                                    Image(systemName: "magnifyingglass.circle")
                                        .font(.system(size: 20))
                                    Text("Delete All Queries")
                                        .font(.system(size: FontSizes.headline, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(theme.error)
                                .cornerRadius(BorderRadius.lg)
                            }

                            Button(action: viewModel.clearLogs) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 20))
                                    Text("Clear All Logs")
                                        .font(.system(size: FontSizes.headline, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(theme.error)
                                .cornerRadius(BorderRadius.lg)
                            }

                            Button(action: viewModel.resetAllData) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 20))
                                    Text("Reset All Data")
                                        .font(.system(size: FontSizes.headline, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(theme.error)
                                .cornerRadius(BorderRadius.lg)
                            }
                        }
        }
    }

    private var versionFooter: some View {
        VStack(spacing: Spacing.xs / 2) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textTertiary)
                            Text("v1.0.0")
                                .font(.system(size: FontSizes.caption1))
                                .foregroundColor(theme.textTertiary)
                        }
                        Text("by Quaii")
                            .font(.system(size: FontSizes.caption2))
                            .foregroundColor(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Settings", showSettings: false, showBack: true, centered: true)

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    appSettingsSection
                    advancedSettingsSection
                    systemSettingsSection
                    countryAllowlistSection
                    saveButton
                    dangerZoneSection
                    versionFooter

                    Spacer()
                        .frame(height: 100)
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
        }
        .background(theme.groupedBackground)
        .onAppear {
            viewModel.loadSettings()
        }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your settings have been saved successfully.")
        }
    }
}

