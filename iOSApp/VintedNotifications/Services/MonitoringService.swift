//
//  MonitoringService.swift
//  Vinted Notifications
//
//  Monitoring service with foreground and background support
//

import Foundation
import BackgroundTasks
import UIKit

class MonitoringService: ObservableObject {
    static let shared = MonitoringService()

    private let taskIdentifier = "com.vintednotifications.refresh"
    @Published var isMonitoring = false
    @Published var lastCheckTime: Date?

    // Foreground monitoring
    private var monitoringTask: Task<Void, Never>?
    private var isInForeground = true

    private init() {
        LogService.shared.info("[MonitoringService] Initialized")
        setupAppLifecycleObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle Observers

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        isInForeground = false
        stopForegroundMonitoring()
        LogService.shared.info("[MonitoringService] App entered background, stopping foreground monitoring")
    }

    @objc private func appWillEnterForeground() {
        isInForeground = true
        if isMonitoring {
            startForegroundMonitoring()
            LogService.shared.info("[MonitoringService] App entered foreground, starting foreground monitoring")
        }
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

        // Load settings
        var totalNewItems = 0
        let notificationMode = NotificationMode(rawValue: DatabaseService.shared.getParameter("notification_mode")) ?? .precise
        let itemsPerQuery = Int(DatabaseService.shared.getParameter("items_per_query", defaultValue: "\(AppConfig.defaultItemsPerQuery)")) ?? AppConfig.defaultItemsPerQuery
        let allowlist = DatabaseService.shared.getAllowlist()

        for query in queries {
            do {
                // Fetch items with configured items_per_query setting
                let items = try await VintedAPI.shared.search(url: query.vintedUrl, itemsPerQuery: itemsPerQuery)

                LogService.shared.info("[MonitoringService] Query \(query.id ?? 0): Got \(items.count) items")

                // Filter new items
                var newItems: [VintedItem] = []
                for var item in items {
                    // Skip if item already exists
                    if DatabaseService.shared.itemExists(itemId: item.id) {
                        continue
                    }

                    // Check country allowlist
                    if !allowlist.isEmpty {
                        if let userId = item.userId {
                            // Fetch user's country
                            let userCountry = await VintedAPI.shared.getUserCountry(userId: userId, domain: query.domain())
                            item.userCountry = userCountry

                            // Skip if user's country is not in allowlist (XX is unknown/error)
                            if userCountry != "XX" && !allowlist.contains(userCountry) {
                                LogService.shared.info("[MonitoringService] Skipping item (country \(userCountry) not in allowlist): \(item.title)")
                                continue
                            }
                        }
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

    // MARK: - Foreground Monitoring Loop

    private func startForegroundMonitoring() {
        // Cancel any existing monitoring task
        stopForegroundMonitoring()

        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring && isInForeground {
                // Perform fetch
                await performBackgroundFetch()

                // Get refresh delay from settings
                let refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay

                // Wait for the configured delay (in seconds)
                do {
                    try await Task.sleep(nanoseconds: UInt64(refreshDelay) * 1_000_000_000)
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }

        LogService.shared.info("[MonitoringService] Foreground monitoring loop started")
    }

    private func stopForegroundMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        LogService.shared.info("[MonitoringService] Foreground monitoring loop stopped")
    }

    // MARK: - Start/Stop Monitoring

    func startMonitoring() {
        isMonitoring = true
        scheduleBackgroundFetch()

        // Start foreground monitoring if app is in foreground
        if isInForeground {
            startForegroundMonitoring()
        }

        LogService.shared.info("[MonitoringService] Monitoring started (foreground: \(isInForeground))")
    }

    func stopMonitoring() {
        isMonitoring = false
        stopForegroundMonitoring()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        LogService.shared.info("[MonitoringService] Monitoring stopped")
    }
}
