//
//  NotificationService.swift
//  Vinted Notifications
//
//  Local notifications using UserNotifications framework
//

import Foundation
import UserNotifications

@MainActor
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        // Set self as delegate to receive notifications while app is in foreground
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - UNUserNotificationCenterDelegate

    // This method is called when a notification is delivered while the app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // This method is called when user taps on a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification tap
        if let urlString = userInfo["url"] as? String, let _ = URL(string: urlString) {
            Task { @MainActor in
                // Open URL if needed
                LogService.shared.info("[NotificationService] User tapped notification with URL: \(urlString)")
            }
        }

        completionHandler()
    }

    // MARK: - Authorization

    nonisolated func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                checkAuthorizationStatus()
            }
            LogService.shared.info("[NotificationService] Authorization granted: \(granted)")
            return granted
        } catch {
            LogService.shared.error("[NotificationService] Authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleNotification(for item: VintedItem, mode: NotificationMode = .precise) async {
        // Re-check authorization status before scheduling
        checkAuthorizationStatus()

        // Small delay to ensure status is updated
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        LogService.shared.info("[NotificationService] Attempting to schedule notification. Auth status: \(authorizationStatus.rawValue)")

        guard authorizationStatus == .authorized else {
            LogService.shared.warning("[NotificationService] Not authorized to send notifications. Status: \(authorizationStatus.rawValue)")
            return
        }

        let content = UNMutableNotificationContent()

        switch mode {
        case .precise:
            // Individual notification with item details
            content.title = "New Item Found!"
            var body = item.title
            if let brand = item.brandTitle, !brand.isEmpty {
                body += " - \(brand)"
            }
            if !item.price.isEmpty {
                body += " · \(item.formattedPrice())"
            }
            content.body = body
            LogService.shared.info("[NotificationService] Precise notification: \(content.title) - \(content.body)")

        case .compact:
            // Summary notification
            content.title = "New Items Found"
            content.body = "Tap to view new Vinted items"
            LogService.shared.info("[NotificationService] Compact notification: \(content.title)")
        }

        content.sound = .default
        content.categoryIdentifier = AppConfig.notificationCategoryId

        // Add custom data
        content.userInfo = [
            "item_id": item.id,
            "url": item.url ?? "",
            "buy_url": item.buyUrl ?? ""
        ]

        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)

        // Create request with unique identifier
        let identifier = "vinted-item-\(item.id)-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogService.shared.info("[NotificationService] ✅ Notification scheduled successfully for item: \(item.id) with identifier: \(identifier)")

            // Verify it was added
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            LogService.shared.info("[NotificationService] Total pending notifications: \(pending.count)")
        } catch {
            LogService.shared.error("[NotificationService] ❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    func scheduleCompactNotification(itemCount: Int) async {
        // Re-check authorization status before scheduling
        checkAuthorizationStatus()

        // Small delay to ensure status is updated
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        LogService.shared.info("[NotificationService] Attempting to schedule compact notification for \(itemCount) items. Auth status: \(authorizationStatus.rawValue)")

        guard authorizationStatus == .authorized else {
            LogService.shared.warning("[NotificationService] Not authorized to send compact notification. Status: \(authorizationStatus.rawValue)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "New Items Found"
        content.body = "\(itemCount) new item\(itemCount == 1 ? "" : "s") found on Vinted"
        content.sound = .default
        content.categoryIdentifier = AppConfig.notificationCategoryId

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let identifier = "vinted-compact-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogService.shared.info("[NotificationService] ✅ Compact notification scheduled for \(itemCount) items with identifier: \(identifier)")

            // Verify it was added
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            LogService.shared.info("[NotificationService] Total pending notifications: \(pending.count)")
        } catch {
            LogService.shared.error("[NotificationService] ❌ Failed to schedule compact notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        LogService.shared.info("[NotificationService] All notifications cleared")
    }
}
