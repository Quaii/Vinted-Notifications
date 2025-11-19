//
//  DebugViewModel.swift
//  Vinted Notifications
//
//  Debug mode for development builds only
//

#if DEBUG
import Foundation

class DebugViewModel: ObservableObject {
    @Published var showDebugMenu = false
    @Published var notificationMode: NotificationMode = .precise

    func sendTestNotification() {
        Task {
            // Create a test item with correct parameter order
            let testItem = VintedItem(
                id: Int64(Date().timeIntervalSince1970 * 1000),
                title: "🧪 Debug Test Notification",
                brandTitle: "Debug Brand",
                sizeTitle: "L",
                price: "99.99",
                currency: "€",
                photo: nil,
                url: "https://www.vinted.com",
                buyUrl: "https://www.vinted.com/transaction/buy/new?source_screen=item",
                createdAtTs: Int64(Date().timeIntervalSince1970 * 1000),
                rawTimestamp: nil,
                queryId: nil,
                notified: false,
                userId: nil,
                userCountry: nil
            )

            await NotificationService.shared.scheduleNotification(for: testItem, mode: notificationMode)
            LogService.shared.info("[Debug] Test notification sent")
        }
    }

    func sendMultipleNotifications(count: Int) {
        Task {
            for i in 1...count {
                let testItem = VintedItem(
                    id: Int64(Date().timeIntervalSince1970 * 1000) + Int64(i),
                    title: "Test Item #\(i)",
                    brandTitle: "Brand \(i)",
                    sizeTitle: "M",
                    price: "\(i * 10).00",
                    currency: "€",
                    photo: nil,
                    url: "https://www.vinted.com",
                    buyUrl: "https://www.vinted.com/transaction/buy/new?source_screen=item",
                    createdAtTs: Int64(Date().timeIntervalSince1970 * 1000),
                    rawTimestamp: nil,
                    queryId: nil,
                    notified: false,
                    userId: nil,
                    userCountry: nil
                )

                await NotificationService.shared.scheduleNotification(for: testItem, mode: .precise)
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s delay between notifications
            }
            LogService.shared.info("[Debug] Sent \(count) test notifications")
        }
    }

    func triggerManualFetch() {
        Task {
            LogService.shared.info("[Debug] Manual fetch triggered")
            await MonitoringService.shared.checkNow()
        }
    }

    func clearAllNotifications() {
        NotificationService.shared.clearAllNotifications()
        LogService.shared.info("[Debug] All notifications cleared")
    }

    func checkAuthorizationStatus() {
        NotificationService.shared.checkAuthorizationStatus()
        LogService.shared.info("[Debug] Notification authorization check requested")
    }
}
#endif
