//
//  OnboardingViewModel.swift
//  Vinted Notifications
//
//  Manages the first-launch onboarding flow
//

import Foundation
import UserNotifications

enum OnboardingStep {
    case welcome
    case permissionExplanation
    case permissionGranted
    case permissionDenied
}

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
