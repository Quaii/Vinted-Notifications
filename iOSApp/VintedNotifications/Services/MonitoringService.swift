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

    private let refreshTaskIdentifier = "com.vintednotifications.refresh"
    private let processingTaskIdentifier = "com.vintednotifications.processing"
    @Published var isMonitoring = false
    @Published var lastCheckTime: Date?

    // Foreground monitoring
    private var monitoringTask: Task<Void, Never>?
    private var isInForeground = true
    
    // Background monitoring - uses background-safe timer
    private var backgroundMonitoringTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid

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
        
        // CRITICAL FIX: Start background monitoring immediately
        // Don't rely solely on iOS background tasks which are unreliable
        if isMonitoring {
            // Schedule background tasks as backup
            scheduleBackgroundFetch()
            
            // Start background-safe monitoring with extended background time
            startBackgroundMonitoring()
            
            LogService.shared.info("[MonitoringService] App entered background - started active background monitoring")
        }
        
        LogService.shared.info("[MonitoringService] App entered background, switched to background monitoring mode")
    }

    @objc private func appWillEnterForeground() {
        isInForeground = true
        
        // CRITICAL FIX: Stop background monitoring when returning to foreground
        stopBackgroundMonitoring()
        
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
            LogService.shared.info("[MonitoringService] App entered foreground, switched to foreground monitoring")
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
        // Register BGAppRefreshTask (for quick refreshes)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefreshTask(task as! BGAppRefreshTask)
        }
        
        // Register BGProcessingTask (more reliable, can run longer)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { task in
            self.handleBackgroundProcessingTask(task as! BGProcessingTask)
        }
        
        LogService.shared.info("[MonitoringService] Background tasks registered (refresh + processing)")
    }

    // MARK: - Schedule Background Fetch

    func scheduleBackgroundFetch() {
        // Get refresh delay from settings (user preference, default 30 minutes)
        let refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
        let interval = TimeInterval(refreshDelay * 60) // Convert to seconds
        
        // Schedule BGAppRefreshTask (quick refresh)
        scheduleRefreshTask(interval: interval)
        
        // Schedule BGProcessingTask (more reliable, runs longer)
        scheduleProcessingTask(interval: interval)
    }
    
    private func scheduleRefreshTask(interval: TimeInterval) {
        // Cancel any existing scheduled refresh tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            let nextDate = request.earliestBeginDate ?? Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            LogService.shared.info("[MonitoringService] ✅ Refresh task scheduled for: \(formatter.string(from: nextDate)) (in \(Int(interval/60)) minutes)")
        } catch {
            LogService.shared.error("[MonitoringService] ❌ Failed to schedule refresh task: \(error.localizedDescription)")
        }
    }
    
    private func scheduleProcessingTask(interval: TimeInterval) {
        // Cancel any existing scheduled processing tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskIdentifier)

        let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        // Processing tasks can require network access
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
            let nextDate = request.earliestBeginDate ?? Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            LogService.shared.info("[MonitoringService] ✅ Processing task scheduled for: \(formatter.string(from: nextDate)) (in \(Int(interval/60)) minutes)")
            
            // Log pending tasks for debugging
            BGTaskScheduler.shared.getPendingTaskRequests { requests in
                let refreshCount = requests.filter { $0.identifier == self.refreshTaskIdentifier }.count
                let processingCount = requests.filter { $0.identifier == self.processingTaskIdentifier }.count
                LogService.shared.info("[MonitoringService] Pending tasks - Refresh: \(refreshCount), Processing: \(processingCount)")
            }
        } catch {
            LogService.shared.error("[MonitoringService] ❌ Failed to schedule processing task: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Background Tasks

    private func handleBackgroundRefreshTask(_ task: BGAppRefreshTask) {
        let startTime = Date()
        LogService.shared.info("[MonitoringService] 🎯 Background REFRESH task STARTED at \(DateFormatter.localizedString(from: startTime, dateStyle: .none, timeStyle: .medium))")

        // Schedule next fetch BEFORE performing current fetch
        // This ensures we always have a task scheduled
        scheduleBackgroundFetch()

        Task {
            let success = await performBackgroundFetch()
            task.setTaskCompleted(success: success)
            let duration = Date().timeIntervalSince(startTime)
            LogService.shared.info("[MonitoringService] ✅ Background REFRESH task COMPLETED in \(String(format: "%.1f", duration))s")
        }

        // Set expiration handler
        task.expirationHandler = {
            LogService.shared.warning("[MonitoringService] ⚠️ Background REFRESH task EXPIRED - task took too long")
            task.setTaskCompleted(success: false)
        }
    }
    
    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        let startTime = Date()
        LogService.shared.info("[MonitoringService] 🎯 Background PROCESSING task STARTED at \(DateFormatter.localizedString(from: startTime, dateStyle: .none, timeStyle: .medium))")

        // Schedule next fetch BEFORE performing current fetch
        // This ensures we always have a task scheduled
        scheduleBackgroundFetch()

        Task {
            let success = await performBackgroundFetch()
            task.setTaskCompleted(success: success)
            let duration = Date().timeIntervalSince(startTime)
            LogService.shared.info("[MonitoringService] ✅ Background PROCESSING task COMPLETED in \(String(format: "%.1f", duration))s")
        }

        // Set expiration handler (processing tasks have longer timeout)
        task.expirationHandler = {
            LogService.shared.warning("[MonitoringService] ⚠️ Background PROCESSING task EXPIRED - task took too long")
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

    // MARK: - Background Monitoring (iOS Background-Safe)
    
    private func startBackgroundMonitoring() {
        LogService.shared.info("[MonitoringService] Starting background monitoring...")
        
        // Begin background task to get extended execution time
        beginBackgroundTask()
        
        // Get refresh delay from settings
        let refreshDelay = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
        let interval = TimeInterval(refreshDelay)
        
        // Perform immediate check when entering background
        Task {
            await performBackgroundFetch()
            
            // After first check, schedule repeating timer on main thread
            await MainActor.run {
                // Create timer that fires periodically while app is backgrounded
                // This works during the extended background execution time
                self.backgroundMonitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    guard let self = self, !self.isInForeground, self.isMonitoring else {
                        return
                    }
                    
                    // Renew background task before each check
                    self.beginBackgroundTask()
                    
                    Task {
                        await self.performBackgroundFetch()
                    }
                }
                
                // Ensure timer runs in background
                RunLoop.main.add(self.backgroundMonitoringTimer!, forMode: .common)
                
                LogService.shared.info("[MonitoringService] Background monitoring timer started (interval: \(interval)s)")
            }
        }
    }
    
    private func stopBackgroundMonitoring() {
        backgroundMonitoringTimer?.invalidate()
        backgroundMonitoringTimer = nil
        endBackgroundTask()
        LogService.shared.info("[MonitoringService] Background monitoring stopped")
    }
    
    private func beginBackgroundTask() {
        // End previous background task if exists
        endBackgroundTask()
        
        // Request extended background execution time
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask { [weak self] in
            // Called when time expires - cleanup
            LogService.shared.warning("[MonitoringService] Background task time expired")
            self?.endBackgroundTask()
        }
        
        if backgroundTaskIdentifier != .invalid {
            LogService.shared.info("[MonitoringService] Background task started (ID: \(backgroundTaskIdentifier.rawValue))")
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            LogService.shared.info("[MonitoringService] Ending background task (ID: \(backgroundTaskIdentifier.rawValue))")
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
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
        
        // Check and log background refresh status
        let refreshStatus = checkBackgroundRefreshStatus()
        LogService.shared.info("[MonitoringService] Background Refresh Status: \(refreshStatus)")
        
        if refreshStatus != "Enabled" {
            LogService.shared.warning("[MonitoringService] ⚠️ WARNING: Background App Refresh is not enabled!")
            LogService.shared.warning("[MonitoringService] To enable: Settings > General > Background App Refresh > Vinted Notifications")
        }
        
        LogService.shared.info("[MonitoringService] ⚠️ IMPORTANT: iOS controls when background tasks run.")
        LogService.shared.info("[MonitoringService] Using dual-task approach (Refresh + Processing) for better reliability.")
        let refreshDelayMinutes = Int(DatabaseService.shared.getParameter("query_refresh_delay", defaultValue: "\(AppConfig.defaultRefreshDelay)")) ?? AppConfig.defaultRefreshDelay
        LogService.shared.info("[MonitoringService] Tasks scheduled every \(refreshDelayMinutes) minutes.")
        LogService.shared.info("[MonitoringService] The app will reschedule tasks when you open it to improve reliability.")
    }

    func stopMonitoring() {
        isMonitoring = false
        stopForegroundMonitoring()
        stopBackgroundMonitoring()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskIdentifier)
        LogService.shared.info("[MonitoringService] Monitoring stopped (all modes cancelled)")
    }
    
    // MARK: - Background Refresh Status
    
    func checkBackgroundRefreshStatus() -> String {
        // Check if background app refresh is enabled for this app
        // Note: This is a system-level setting that users can disable
        let status = UIApplication.shared.backgroundRefreshStatus
        switch status {
        case .available:
            return "Enabled"
        case .restricted:
            return "Restricted (parental controls)"
        case .denied:
            return "Disabled (check Settings > General > Background App Refresh)"
        @unknown default:
            return "Unknown"
        }
    }
}
