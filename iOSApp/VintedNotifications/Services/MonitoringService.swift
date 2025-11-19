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
        
        // Ensure background task is scheduled when going to background
        if isMonitoring {
            scheduleBackgroundFetch()
            LogService.shared.info("[MonitoringService] App entered background - ensured background task is scheduled")
        }
        
        LogService.shared.info("[MonitoringService] App entered background, stopping foreground monitoring")
    }

    @objc private func appWillEnterForeground() {
        isInForeground = true
        if isMonitoring {
            // CRITICAL: Reschedule background tasks every time app enters foreground
            // iOS may not run background tasks for hours/days, so we need to reschedule
            scheduleBackgroundFetch()
            LogService.shared.info("[MonitoringService] App entered foreground - rescheduled background tasks")
            
            // Perform immediate catch-up check if it's been a while since last check
            // This helps recover from missed background task executions
            if let lastCheck = lastCheckTime {
                let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
                let refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
                
                // If it's been more than 2x the refresh delay, do an immediate check
                if timeSinceLastCheck > Double(refreshDelay * 2) {
                    LogService.shared.info("[MonitoringService] Last check was \(Int(timeSinceLastCheck/60)) minutes ago - performing catch-up check")
                    Task {
                        await performBackgroundFetch()
                    }
                }
            } else {
                // No previous check, do one now
                LogService.shared.info("[MonitoringService] No previous check found - performing initial check")
                Task {
                    await performBackgroundFetch()
                }
            }
            
            startForegroundMonitoring()
            LogService.shared.info("[MonitoringService] App entered foreground, starting foreground monitoring")
        }
    }

    // MARK: - Banwords Filtering

    private func containsBanwords(_ title: String) -> Bool {
        let banwordsStr = DatabaseService.shared.getParameter("banwords", defaultValue: "")
        guard !banwordsStr.isEmpty else { return false }

        // Split by / delimiter
        let banwords = banwordsStr.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
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
        // Cancel any existing scheduled tasks first
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Use a shorter interval to increase chances of execution
        // iOS controls when tasks actually run, but shorter intervals help
        let interval = min(AppConfig.backgroundFetchInterval, 15 * 60) // Max 15 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            let nextDate = request.earliestBeginDate ?? Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            LogService.shared.info("[MonitoringService] ✅ Background fetch scheduled for: \(formatter.string(from: nextDate)) (in \(Int(interval/60)) minutes)")
            
            // Log pending tasks for debugging
            BGTaskScheduler.shared.getPendingTaskRequests { requests in
                let pendingCount = requests.filter { $0.identifier == self.taskIdentifier }.count
                LogService.shared.info("[MonitoringService] Pending background tasks: \(pendingCount)")
            }
        } catch {
            LogService.shared.error("[MonitoringService] ❌ Failed to schedule background fetch: \(error.localizedDescription)")

            // If scheduling fails, try again with a shorter time
            let retryRequest = BGAppRefreshTaskRequest(identifier: taskIdentifier)
            retryRequest.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // Try in 5 minutes
            do {
                try BGTaskScheduler.shared.submit(retryRequest)
                LogService.shared.info("[MonitoringService] ✅ Retry: Background fetch scheduled for 5 minutes")
            } catch {
                LogService.shared.error("[MonitoringService] ❌ Retry also failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Handle Background Task

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        let startTime = Date()
        LogService.shared.info("[MonitoringService] 🎯 Background task STARTED at \(DateFormatter.localizedString(from: startTime, dateStyle: .none, timeStyle: .medium))")

        // Schedule next fetch BEFORE performing current fetch
        // This ensures we always have a task scheduled
        scheduleBackgroundFetch()

        Task {
            let success = await performBackgroundFetch()
            task.setTaskCompleted(success: success)
            let duration = Date().timeIntervalSince(startTime)
            LogService.shared.info("[MonitoringService] ✅ Background task COMPLETED in \(String(format: "%.1f", duration))s")
        }

        // Set expiration handler
        task.expirationHandler = {
            LogService.shared.warning("[MonitoringService] ⚠️ Background task EXPIRED - task took too long")
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Perform Background Fetch

    func performBackgroundFetch() async -> Bool {
        LogService.shared.info("[MonitoringService] Starting background fetch...")

        let queries = DatabaseService.shared.getQueries(activeOnly: true)

        guard !queries.isEmpty else {
            LogService.shared.info("[MonitoringService] No active queries, skipping")
            return true
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
        return true
    }

    // MARK: - Manual Check

    func checkNow() async {
        _ = await performBackgroundFetch()
    }

    // MARK: - Foreground Monitoring Loop

    private func startForegroundMonitoring() {
        // Cancel any existing monitoring task
        stopForegroundMonitoring()

        monitoringTask = Task {
            // Small initial delay to ensure database is ready
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

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
        guard !isMonitoring else {
            LogService.shared.info("[MonitoringService] Monitoring already active")
            return
        }

        isMonitoring = true

        // Schedule background fetch for when app is in background
        scheduleBackgroundFetch()

        // Start foreground monitoring if app is in foreground
        if isInForeground {
            startForegroundMonitoring()
        }

        LogService.shared.info("[MonitoringService] Monitoring started (foreground: \(isInForeground))")
        LogService.shared.info("[MonitoringService] ⚠️ IMPORTANT: iOS controls when background tasks run.")
        LogService.shared.info("[MonitoringService] Background tasks may be delayed by hours or days if:")
        LogService.shared.info("[MonitoringService] - App is not used frequently")
        LogService.shared.info("[MonitoringService] - Device is in low power mode")
        LogService.shared.info("[MonitoringService] - System decides app doesn't need background refresh")
        LogService.shared.info("[MonitoringService] The app will reschedule tasks when you open it to improve reliability.")
    }

    func stopMonitoring() {
        isMonitoring = false
        stopForegroundMonitoring()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        LogService.shared.info("[MonitoringService] Monitoring stopped")
    }
}
