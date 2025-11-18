//
//  MonitoringService.swift
//  Vinted Notifications
//
//  Background monitoring service using BGTaskScheduler
//

import Foundation
import BackgroundTasks

class MonitoringService: ObservableObject {
    static let shared = MonitoringService()

    private let taskIdentifier = "com.vintednotifications.refresh"
    @Published var isMonitoring = false
    @Published var lastCheckTime: Date?

    private init() {
        LogService.shared.info("[MonitoringService] Initialized")
    }

    // MARK: - Banwords Filtering

    private func containsBanwords(_ title: String) -> Bool {
        let banwordsStr = DatabaseService.shared.getParameter("banwords", defaultValue: "")
        guard !banwordsStr.isEmpty else { return false }

        // Split by ||| delimiter
        let banwords = banwordsStr.split(separator: "|||").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard !banwords.isEmpty else { return false }

        let titleLower = title.lowercased()
        return banwords.contains { word in
            !word.isEmpty && titleLower.contains(word)
        }
    }

    // MARK: - Register Background Tasks

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
        LogService.shared.info("[MonitoringService] Background tasks registered")
    }

    // MARK: - Schedule Background Fetch

    func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: AppConfig.backgroundFetchInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            LogService.shared.info("[MonitoringService] Background fetch scheduled")
        } catch {
            LogService.shared.error("[MonitoringService] Failed to schedule background fetch: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Background Task

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        LogService.shared.info("[MonitoringService] Background task started")

        // Schedule next fetch
        scheduleBackgroundFetch()

        Task {
            await performBackgroundFetch()
            task.setTaskCompleted(success: true)
        }

        // Set expiration handler
        task.expirationHandler = {
            LogService.shared.warning("[MonitoringService] Background task expired")
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Perform Background Fetch

    func performBackgroundFetch() async {
        LogService.shared.info("[MonitoringService] Starting background fetch...")

        let queries = DatabaseService.shared.getQueries(activeOnly: true)

        guard !queries.isEmpty else {
            LogService.shared.info("[MonitoringService] No active queries, skipping")
            return
        }

        LogService.shared.info("[MonitoringService] Checking \(queries.count) queries")

        var totalNewItems = 0
        let notificationMode = NotificationMode(rawValue: DatabaseService.shared.getParameter("notification_mode")) ?? .precise

        for query in queries {
            do {
                // Fetch items
                let items = try await VintedAPI.shared.search(url: query.vintedUrl)

                LogService.shared.info("[MonitoringService] Query \(query.id ?? 0): Got \(items.count) items")

                // Filter new items
                var newItems: [VintedItem] = []
                for item in items {
                    // Skip if item already exists
                    if DatabaseService.shared.itemExists(itemId: item.id) {
                        continue
                    }

                    // Skip if title contains banwords
                    if containsBanwords(item.title) {
                        LogService.shared.info("[MonitoringService] Skipping item (banword match): \(item.title)")
                        continue
                    }

                    // Add item to database and notification queue
                    var itemWithQuery = item
                    itemWithQuery.queryId = query.id
                    DatabaseService.shared.addItem(itemWithQuery)
                    newItems.append(itemWithQuery)
                }

                if !newItems.isEmpty {
                    LogService.shared.info("[MonitoringService] Found \(newItems.count) new items for query \(query.id ?? 0)")
                    totalNewItems += newItems.count

                    // Update query last item timestamp
                    if let lastItem = newItems.first {
                        DatabaseService.shared.updateQueryLastItem(queryId: query.id ?? 0, timestamp: lastItem.createdAtTs)
                    }

                    // Send notifications
                    switch notificationMode {
                    case .precise:
                        for item in newItems {
                            await NotificationService.shared.scheduleNotification(for: item, mode: .precise)
                        }
                    case .compact:
                        // Will send one compact notification after all queries
                        break
                    }
                }

            } catch {
                LogService.shared.error("[MonitoringService] Error checking query \(query.id ?? 0): \(error.localizedDescription)")
            }
        }

        // Send compact notification if mode is compact
        if totalNewItems > 0 && notificationMode == .compact {
            await NotificationService.shared.scheduleCompactNotification(itemCount: totalNewItems)
        }

        await MainActor.run {
            lastCheckTime = Date()
        }

        LogService.shared.info("[MonitoringService] Background fetch complete. Total new items: \(totalNewItems)")
    }

    // MARK: - Manual Check

    func checkNow() async {
        await performBackgroundFetch()
    }

    // MARK: - Start/Stop Monitoring

    func startMonitoring() {
        isMonitoring = true
        scheduleBackgroundFetch()
        LogService.shared.info("[MonitoringService] Monitoring started")
    }

    func stopMonitoring() {
        isMonitoring = false
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        LogService.shared.info("[MonitoringService] Monitoring stopped")
    }
}
