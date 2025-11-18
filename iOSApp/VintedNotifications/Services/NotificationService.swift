//
//  NotificationService.swift
//  Vinted Notifications
//
//  Local notifications using UserNotifications framework
//

import Foundation
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            LogService.shared.info("[NotificationService] Authorization granted: \(granted)")
            return granted
        } catch {
            LogService.shared.error("[NotificationService] Authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleNotification(for item: VintedItem, mode: NotificationMode = .precise) async {
        guard authorizationStatus == .authorized else {
            LogService.shared.warning("[NotificationService] Not authorized to send notifications")
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

        case .compact:
            // Summary notification
            content.title = "New Items Found"
            content.body = "Tap to view new Vinted items"
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
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogService.shared.info("[NotificationService] Notification scheduled for item: \(item.id)")
        } catch {
            LogService.shared.error("[NotificationService] Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    func scheduleCompactNotification(itemCount: Int) async {
        guard authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Items Found"
        content.body = "\(itemCount) new item\(itemCount == 1 ? "" : "s") found on Vinted"
        content.sound = .default
        content.categoryIdentifier = AppConfig.notificationCategoryId

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogService.shared.info("[NotificationService] Compact notification scheduled for \(itemCount) items")
        } catch {
            LogService.shared.error("[NotificationService] Failed to schedule compact notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        LogService.shared.info("[NotificationService] All notifications cleared")
    }
}
