//
//  OnboardingViews.swift
//  Vinted Notifications
//
//  Onboarding Flow Views
//

import SwiftUI

// MARK: - Onboarding State
enum OnboardingStep {
    case welcome
    case permissionExplanation
    case permissionGranted
    case permissionDenied
}

// MARK: - Onboarding ViewModel
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete = false

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    init() {
        // Check if user has already completed onboarding
        isOnboardingComplete = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .permissionExplanation
        case .permissionExplanation:
            // Will trigger permission request
            break
        case .permissionGranted, .permissionDenied:
            completeOnboarding()
        }
    }

    func requestNotificationPermission() async {
        let granted = await NotificationService.shared.requestAuthorization()

        if granted {
            currentStep = .permissionGranted
            LogService.shared.info("[Onboarding] Notification permission granted")
        } else {
            currentStep = .permissionDenied
            LogService.shared.info("[Onboarding] Notification permission denied")
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
        isOnboardingComplete = true
        LogService.shared.info("[Onboarding] Onboarding completed")
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
            LogService.shared.info("[Onboarding] Opening Settings app")
        }
    }
}

// MARK: - Onboarding Flow
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

// MARK: - Welcome Screen
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

// MARK: - Permission Explanation Screen
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

// MARK: - Permission Granted Screen
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

// MARK: - Permission Denied Screen
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
