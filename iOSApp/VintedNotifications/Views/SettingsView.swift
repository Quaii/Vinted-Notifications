//
//  SettingsView.swift
//  Vinted Notifications
//
//  Settings Screen
//

import SwiftUI

// MARK: - Settings Toggle Row
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

// MARK: - Settings Screen
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var showSaveConfirmation = false

    // Helper computed properties to avoid complex expressions
    private var toggleActiveColor: Color { theme.primary }
    private var toggleInactiveColor: Color { theme.buttonFill }

    private func getAppearanceModeDescription() -> String {
        switch themeManager.appearanceMode {
        case .system:
            return "Automatically match system appearance"
        case .light:
            return "Light mode enabled"
        case .dark:
            return "Dark mode enabled"
        }
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
                // Appearance Mode Row
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .font(.system(size: FontSizes.body, weight: .medium))
                            .foregroundColor(theme.text)
                        Text(getAppearanceModeDescription())
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    CustomSegmentedControl(
                        options: AppearanceMode.allCases.map { $0.displayName },
                        selectedIndex: Binding(
                            get: {
                                AppearanceMode.allCases.firstIndex(of: themeManager.appearanceMode) ?? 0
                            },
                            set: { newIndex in
                                let newMode = AppearanceMode.allCases[newIndex]
                                themeManager.setAppearanceMode(newMode)
                                UserDefaults.standard.set(newMode.rawValue, forKey: "appearanceMode")
                                LogService.shared.info("Appearance mode changed to: \(newMode.rawValue)")
                            }
                        )
                    )
                }
                .padding(Spacing.md)
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
                .overlay(
                    Rectangle()
                        .fill(theme.separator)
                        .frame(height: 1),
                    alignment: .bottom
                )

                // Show Foreground Notifications Row
                SettingsToggleRow(
                    title: "Foreground Notifications",
                    description: viewModel.showForegroundNotifications
                        ? "Show notifications when app is open"
                        : "Hide notifications when app is open",
                    isOn: $viewModel.showForegroundNotifications,
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.subheadline))
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.subheadline))
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.subheadline))
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.subheadline))
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.body))
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.body))
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
                    Text("Filter out items containing these words (separate with /)")
                        .font(.system(size: FontSizes.footnote))
                        .foregroundColor(theme.textTertiary)

                    ZStack(alignment: .topLeading) {
                        // Placeholder text
                        if viewModel.banwords.isEmpty {
                            Text("e.g., fake / replica / damaged")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(theme.placeholder)
                                .padding(.horizontal, Spacing.sm + 4)
                                .padding(.vertical, Spacing.sm + 8)
                        }

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
                            .foregroundColor(theme.text)
                            .font(.system(size: FontSizes.body))
                    }
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
                        .foregroundColor(theme.text)
                        .font(.system(size: FontSizes.body))

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
