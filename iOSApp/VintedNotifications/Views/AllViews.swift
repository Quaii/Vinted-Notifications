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
                .font(.system(size: centered ? FontSizes.title1 : FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)

            Spacer()

            if let button = rightButton {
                button
            } else if showSettings {
                NavigationLink(destination: SettingsView()) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, centered ? Spacing.xs : Spacing.sm)
        .padding(.bottom, centered ? Spacing.sm : Spacing.md)
        .background(theme.background)
    }
}

// MARK: - ONBOARDING VIEWS

// Onboarding Flow - First launch experience
struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                WelcomeScreen(viewModel: viewModel)
            case .permissionExplanation:
                PermissionExplanationScreen(viewModel: viewModel)
            case .permissionGranted:
                PermissionGrantedScreen(viewModel: viewModel)
            case .permissionDenied:
                PermissionDeniedScreen(viewModel: viewModel)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
}

// Welcome Screen - First screen on app launch
struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and branding
            VStack(spacing: Spacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(theme.primary)
                    .padding(.bottom, Spacing.lg)

                Text("Welcome to")
                    .font(.system(size: FontSizes.title2, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                Text("Vinted Notifications")
                    .font(.system(size: FontSizes.largeTitle, weight: .bold))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)

                Text("NEVER MISS A DEAL")
                    .font(.system(size: FontSizes.footnote, weight: .medium))
                    .foregroundColor(theme.textTertiary)
                    .kerning(2)
                    .padding(.top, Spacing.xs)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            // Thank you message
            VStack(spacing: Spacing.md) {
                Text("Thank you for downloading!")
                    .font(.system(size: FontSizes.title3, weight: .semibold))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)

                Text("Get instant notifications when new items matching your saved searches appear on Vinted.")
                    .font(.system(size: FontSizes.body))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxl)

            // Next button
            Button(action: viewModel.nextStep) {
                Text("Next")
                    .font(.system(size: FontSizes.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md + 2)
                    .background(theme.primary)
                    .cornerRadius(BorderRadius.xl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// Permission Explanation Screen
struct PermissionExplanationScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.primary)
                .padding(.bottom, Spacing.xl)

            // Title
            Text("Enable Notifications")
                .font(.system(size: FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.md)

            // Explanation
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "Instant Alerts",
                    description: "Get notified immediately when new items matching your searches appear"
                )

                FeatureRow(
                    icon: "star.fill",
                    title: "Never Miss Deals",
                    description: "Be the first to see great deals before they're gone"
                )

                FeatureRow(
                    icon: "shield.fill",
                    title: "Privacy First",
                    description: "Notifications are sent locally on your device only"
                )
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            // Information note
            Text("You can change this permission anytime in Settings")
                .font(.system(size: FontSizes.caption1))
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)

            // Allow button
            Button(action: {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }) {
                Text("Allow Notifications")
                    .font(.system(size: FontSizes.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md + 2)
                    .background(theme.primary)
                    .cornerRadius(BorderRadius.xl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// Feature Row Component for permission screen
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(title)
                    .font(.system(size: FontSizes.body, weight: .semibold))
                    .foregroundColor(theme.text)

                Text(description)
                    .font(.system(size: FontSizes.subheadline))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Permission Granted Screen - Success
struct PermissionGrantedScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(theme.primary)
            }
            .padding(.bottom, Spacing.xl)

            // Title
            Text("You're All Set!")
                .font(.system(size: FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.md)

            // Message
            Text("Thank you for enabling notifications. You'll now receive instant alerts when new items matching your searches appear on Vinted.")
                .font(.system(size: FontSizes.body))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Spacer()

            // Get Started button
            Button(action: viewModel.completeOnboarding) {
                Text("Get Started")
                    .font(.system(size: FontSizes.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md + 2)
                    .background(theme.primary)
                    .cornerRadius(BorderRadius.xl)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// Permission Denied Screen - Guide to enable manually
struct PermissionDeniedScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, Spacing.xl)

            // Title
            Text("Notifications Required")
                .font(.system(size: FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.md)

            // Explanation
            Text("This app requires notification permissions to alert you when new Vinted items matching your searches become available.")
                .font(.system(size: FontSizes.body))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.xl)

            // Instructions
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("To enable notifications:")
                    .font(.system(size: FontSizes.body, weight: .semibold))
                    .foregroundColor(theme.text)

                InstructionStep(number: 1, text: "Tap 'Open Settings' below")
                InstructionStep(number: 2, text: "Find 'Vinted Notifications' in the list")
                InstructionStep(number: 3, text: "Tap on 'Notifications'")
                InstructionStep(number: 4, text: "Enable 'Allow Notifications'")
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            VStack(spacing: Spacing.md) {
                // Open Settings button
                Button(action: viewModel.openSettings) {
                    Text("Open Settings")
                        .font(.system(size: FontSizes.headline, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md + 2)
                        .background(theme.primary)
                        .cornerRadius(BorderRadius.xl)
                }

                // Continue anyway button
                Button(action: viewModel.completeOnboarding) {
                    Text("Continue Without Notifications")
                        .font(.system(size: FontSizes.body, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.vertical, Spacing.sm)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// Instruction Step Component
struct InstructionStep: View {
    let number: Int
    let text: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: FontSizes.footnote, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            Text(text)
                .font(.system(size: FontSizes.subheadline))
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                // Photo - Larger size for better visibility
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
                .frame(width: compact ? 80 : 100, height: compact ? 80 : 100)
                .cornerRadius(BorderRadius.md)

                // Content - Title, brand, and time on the left
                VStack(alignment: .leading, spacing: Spacing.xs) {
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

                // Price on the right side
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(item.formattedPrice())
                        .font(.system(size: FontSizes.headline, weight: .bold))
                        .foregroundColor(theme.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: FontSizes.footnote))
                        .foregroundColor(theme.textTertiary)
                }
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

// ItemGridCard Component - for grid view
struct ItemGridCard: View {
    let item: VintedItem

    @Environment(\.theme) var theme
    @Environment(\.openURL) var openURL

    var body: some View {
        Button(action: {
            if let urlString = item.url, let url = URL(string: urlString) {
                openURL(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
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
                .frame(height: 160)
                .clipped()

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.formattedPrice())
                        .font(.system(size: FontSizes.headline, weight: .bold))
                        .foregroundColor(theme.primary)

                    Text(item.title)
                        .font(.system(size: FontSizes.subheadline, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(2)

                    if let brand = item.brandTitle, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: FontSizes.caption1))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(Spacing.sm)
            }
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

    @Environment(\.theme) var theme

    var body: some View {
        Button(action: onPress) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(query.queryName)
                        .font(.system(size: FontSizes.headline, weight: .semibold))
                        .foregroundColor(theme.text)

                    Text(query.domain())
                        .font(.system(size: FontSizes.subheadline))
                        .foregroundColor(theme.textSecondary)
                }

                Text("Last item: \(query.lastItemTime())")
                    .font(.system(size: FontSizes.caption1))
                    .foregroundColor(theme.textTertiary)
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
                                List {
                                    ForEach(viewModel.recentQueries) { query in
                                        QueryCard(
                                            query: query,
                                            onPress: {}
                                        )
                                        .listRowInsets(EdgeInsets(top: Spacing.sm, leading: 0, bottom: Spacing.sm, trailing: 0))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.deleteQuery(query)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }

                                            Button {
                                                viewModel.startEditing(query)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: CGFloat(viewModel.recentQueries.count) * 100)
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
                .scrollIndicators(.hidden)
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
        .sheet(isPresented: $viewModel.showEditSheet) {
            DashboardQueryEditSheet(viewModel: viewModel)
        }
    }
}

// Dashboard Query Edit Sheet
struct DashboardQueryEditSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: {
                    viewModel.newQueryUrl = ""
                    viewModel.newQueryName = ""
                    viewModel.editingQuery = nil
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: FontSizes.body))
                        .foregroundColor(theme.primary)
                }

                Spacer()

                Text("Edit Query")
                    .font(.system(size: FontSizes.headline, weight: .bold))
                    .foregroundColor(theme.text)

                Spacer()

                Button(action: {
                    viewModel.updateQuery()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }) {
                    Text("Update")
                        .font(.system(size: FontSizes.body, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(theme.background)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // URL Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vinted Search URL")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("https://www.vinted.com/catalog?...", text: $viewModel.newQueryUrl)
                            .font(.system(size: FontSizes.body))
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Name Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Custom Name (Optional)")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("e.g., Nike Shoes", text: $viewModel.newQueryName)
                            .font(.system(size: FontSizes.body))
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(.red)

                            Text(error)
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(BorderRadius.lg)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
        }
        .background(theme.groupedBackground)
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

            Text(log.message.removingEmojis())
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
                        List {
                            ForEach(viewModel.queries) { query in
                                QueryCard(
                                    query: query,
                                    onPress: {}
                                )
                                .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteQuery(query)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.startEditing(query)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(theme.groupedBackground)
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
                            .padding(.bottom, 50)
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
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: {
                    viewModel.newQueryUrl = ""
                    viewModel.newQueryName = ""
                    viewModel.editingQuery = nil
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: FontSizes.body))
                        .foregroundColor(theme.primary)
                }

                Spacer()

                Text(viewModel.editingQuery != nil ? "Edit Query" : "Add Query")
                    .font(.system(size: FontSizes.headline, weight: .bold))
                    .foregroundColor(theme.text)

                Spacer()

                Button(action: {
                    viewModel.addQuery()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }) {
                    Text(viewModel.editingQuery != nil ? "Update" : "Add")
                        .font(.system(size: FontSizes.body, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(theme.background)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // URL Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vinted Search URL")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("https://www.vinted.com/catalog?...", text: $viewModel.newQueryUrl)
                            .font(.system(size: FontSizes.body))
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Name Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Custom Name (Optional)")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("e.g., Nike Shoes", text: $viewModel.newQueryName)
                            .font(.system(size: FontSizes.body))
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Info Section
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "info.circle")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(theme.primary)

                            Text("Paste the full URL from a Vinted search. The app will automatically monitor this search and notify you of new items.")
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .background(theme.primary.opacity(0.1))
                        .cornerRadius(BorderRadius.lg)
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(.red)

                            Text(error)
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(BorderRadius.lg)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
        }
        .background(theme.groupedBackground)
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
                HStack(spacing: Spacing.sm) {
                    Button(action: { viewModel.showSortSheet = true }) {
                        HStack {
                            Text(viewModel.sortBy.rawValue)
                                .font(.system(size: FontSizes.body, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: FontSizes.subheadline))
                        }
                        .foregroundColor(theme.text)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.lg)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }

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
                        if viewModel.viewMode == .list {
                            LazyVStack(spacing: Spacing.md) {
                                ForEach(viewModel.filteredItems) { item in
                                    ItemCard(item: item)
                                }
                            }
                            .padding(Spacing.lg)
                            .padding(.bottom, 100)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)
                            ], spacing: Spacing.md) {
                                ForEach(viewModel.filteredItems) { item in
                                    ItemGridCard(item: item)
                                }
                            }
                            .padding(Spacing.lg)
                            .padding(.bottom, 100)
                        }
                    }
                    .scrollIndicators(.hidden)
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

                    // Items Over Time Chart
                    ItemsOverTimeChart(viewModel: viewModel)

                    // Items by Day of Week Chart
                    ItemsByDayChart(viewModel: viewModel)

                    // Price Distribution Chart
                    PriceDistributionChart(viewModel: viewModel)

                    // Cumulative Growth Chart
                    CumulativeGrowthChart(viewModel: viewModel)

                    Spacer()
                        .frame(height: 100)
                }
                .padding(Spacing.lg)
                }
                .scrollIndicators(.hidden)
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
        HStack(alignment: .center, spacing: 0) {
            // Left side - Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: FontSizes.caption2, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: FontSizes.title2, weight: .bold))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - Icon in circular background
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(theme.primary)
            }
        }
        .padding(Spacing.md)
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// Chart Components for Analytics
struct ItemsOverTimeChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Items Over Time")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Last 30 days")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.dailyData.isEmpty {
                    SimpleLineChart(data: viewModel.dailyData, color: theme.primary)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.line.uptrend.xyaxis")
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
}

struct ItemsByDayChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Items by Day of Week")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Weekly distribution")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.weeklyData.isEmpty {
                    SimpleBarChart(data: viewModel.weeklyData, color: theme.primary)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.bar")
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
}

struct PriceDistributionChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Price Distribution")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Items grouped by price range")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.priceDistribution.isEmpty {
                    SimplePriceDistribution(data: viewModel.priceDistribution, theme: theme)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.pie")
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
}

struct CumulativeGrowthChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var cumulativeData: [Int] {
        var cumulative: [Int] = []
        var sum = 0
        for value in viewModel.dailyData {
            sum += value
            cumulative.append(sum)
        }
        return cumulative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Cumulative Growth")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Total items accumulated over last 30 days")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.dailyData.isEmpty {
                    SimpleLineChart(data: cumulativeData, color: theme.primary, filled: true)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.line.uptrend.xyaxis")
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
}

// Simple chart implementations
struct SimpleLineChart: View {
    let data: [Int]
    let color: Color
    var filled: Bool = false

    @Environment(\.theme) var theme

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = max(maxValue - minValue, 1)

            ZStack(alignment: .bottomLeading) {
                // Background grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(theme.separator.opacity(0.3))
                            .frame(height: 1)
                        Spacer()
                    }
                }

                // Line path
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
                        let y = geometry.size.height * (1 - normalizedValue)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)

                // Filled area
                if filled {
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                            let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
                            let y = geometry.size.height * (1 - normalizedValue)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: geometry.size.height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    }
}

struct SimpleBarChart: View {
    let data: [String: Int]
    let color: Color

    @Environment(\.theme) var theme

    var sortedData: [(String, Int)] {
        let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayOrder.compactMap { day in
            if let count = data[day] {
                return (day, count)
            }
            return nil
        }
    }

    var body: some View {
        let maxValue = data.values.max() ?? 1

        HStack(alignment: .bottom, spacing: 8) {
            ForEach(sortedData, id: \.0) { day, count in
                VStack(spacing: 4) {
                    Spacer()

                    let height = CGFloat(count) / CGFloat(maxValue)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: max(height * 180, count > 0 ? 4 : 0))

                    Text(day)
                        .font(.system(size: FontSizes.caption2, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, Spacing.md)
    }
}

struct SimplePriceDistribution: View {
    let data: [AnalyticsViewModel.PriceRange]
    let theme: AppColors

    var body: some View {
        let sortedData = data.sorted { $0.name < $1.name }
        let total = data.reduce(0) { $0 + $1.count }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(sortedData) { range in
                HStack {
                    Text(range.name)
                        .font(.system(size: FontSizes.footnote, weight: .medium))
                        .foregroundColor(theme.text)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geometry in
                        let percentage = total > 0 ? CGFloat(range.count) / CGFloat(total) : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.primary)
                            .frame(width: geometry.size.width * percentage)
                    }

                    Text("\(range.count)")
                        .font(.system(size: FontSizes.footnote, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .frame(height: 24)
            }
        }
        .padding(.vertical, Spacing.md)
    }
}

struct EmptyChartView: View {
    let icon: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(theme.textTertiary)
            Text("No information available at this point in time")
                .font(.system(size: FontSizes.body))
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
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
                    .scrollIndicators(.hidden)
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
                                // Country tags with horizontal wrapping
                                HStack(alignment: .top, spacing: 0) {
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 6),
                                        alignment: .leading,
                                        spacing: Spacing.xs
                                    ) {
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
                                    Spacer()
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
                            Button(action: viewModel.requestDeleteAllItems) {
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

                            Button(action: viewModel.requestDeleteAllQueries) {
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

                            Button(action: viewModel.requestClearLogs) {
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

                            Button(action: viewModel.requestResetAllData) {
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

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                Text("Developer Mode")
                    .font(.system(size: FontSizes.title3, weight: .semibold))
                    .foregroundColor(theme.text)
            }

            Text("Debugging and testing tools. Only available in DEBUG builds.")
                .font(.system(size: FontSizes.footnote))
                .foregroundColor(theme.textTertiary)

            VStack(spacing: Spacing.sm) {
                // Notification mode selector
                HStack {
                    Text("Notification Mode:")
                        .font(.system(size: FontSizes.subheadline, weight: .medium))
                        .foregroundColor(theme.text)
                    Spacer()
                    CustomSegmentedControl(
                        options: ["Precise", "Compact"],
                        selectedIndex: Binding(
                            get: { viewModel.notificationMode == .precise ? 0 : 1 },
                            set: { viewModel.notificationMode = $0 == 0 ? .precise : .compact }
                        )
                    )
                    .frame(width: 180)
                }
                .padding(.bottom, Spacing.xs)

                Button(action: viewModel.sendTestNotification) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 18))
                        Text("Send Test Notification")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(theme.primary)
                    .cornerRadius(BorderRadius.lg)
                }

                Button(action: { viewModel.sendMultipleNotifications(count: 3) }) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18))
                        Text("Send 3 Test Notifications")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(theme.primary)
                    .cornerRadius(BorderRadius.lg)
                }

                Button(action: viewModel.triggerManualFetch) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                        Text("Trigger Manual Fetch")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                    }
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(theme.secondaryGroupedBackground)
                    .cornerRadius(BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.lg)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }

                Button(action: viewModel.clearAllDebugNotifications) {
                    HStack {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 18))
                        Text("Clear All Notifications")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                    }
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(theme.secondaryGroupedBackground)
                    .cornerRadius(BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.lg)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }

                Button(action: viewModel.checkDebugAuthorizationStatus) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 18))
                        Text("Check Authorization Status")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                    }
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(theme.secondaryGroupedBackground)
                    .cornerRadius(BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.lg)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
            }
        }
    }
    #endif

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
        #if DEBUG
        .onTapGesture {
            viewModel.handleDebugTap()
        }
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    appSettingsSection
                    systemSettingsSection
                    countryAllowlistSection
                    advancedSettingsSection
                    saveButton
                    dangerZoneSection

                    #if DEBUG
                    if viewModel.debugModeEnabled {
                        debugSection
                    }
                    #endif

                    versionFooter
                }
                .padding(Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(theme.groupedBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadSettings()
        }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your settings have been saved successfully.")
        }
        .alert(viewModel.getConfirmationMessage().title, isPresented: $viewModel.showDangerZoneConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.pendingDangerZoneAction = nil
            }
            Button("Confirm", role: .destructive) {
                viewModel.executeDangerZoneAction()
            }
        } message: {
            Text(viewModel.getConfirmationMessage().message)
        }
        #if DEBUG
        .overlay(
            Group {
                if viewModel.showDebugCountdown {
                    VStack {
                        Spacer()
                        Text(viewModel.debugCountdownMessage)
                            .font(.system(size: FontSizes.subheadline, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(BorderRadius.lg)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showDebugCountdown)
                }
            }
        )
        #endif
    }
}

// String extension to remove emojis from log messages
extension String {
    func removingEmojis() -> String {
        return self.filter { character in
            !character.isEmoji
        }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

