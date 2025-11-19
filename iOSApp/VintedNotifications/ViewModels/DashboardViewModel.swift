//
//  DashboardViewModel.swift
//  Vinted Notifications
//

import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var stats = Stats()
    @Published var lastItem: VintedItem?
    @Published var recentQueries: [VintedQuery] = []
    @Published var recentLogs: [LogEntry] = []
    @Published var isLoading = false
    @Published var showEditSheet = false
    @Published var editingQuery: VintedQuery?
    @Published var newQueryUrl = ""
    @Published var newQueryName = ""
    @Published var errorMessage: String?

    struct Stats {
        var totalItems: Int = 0
        var itemsPerDay: Double = 0
        var lastItemTime: Date?

        var lastUpdated: String {
            if let time = lastItemTime {
                let interval = Date().timeIntervalSince(time)
                let minutes = Int(interval / 60)
                let hours = Int(interval / 3600)
                let days = Int(interval / 86400)

                if minutes < 1 {
                    return "Just now"
                } else if minutes < 60 {
                    return "\(minutes)m ago"
                } else if hours < 24 {
                    return "\(hours)h ago"
                } else {
                    return "\(days)d ago"
                }
            } else {
                return "No data yet"
            }
        }
    }

    func loadDashboard() async {
        await MainActor.run { isLoading = true }

        // Load items
        let items = DatabaseService.shared.getItems(limit: 1000)

        // Calculate stats
        let totalItems = items.count
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let weekAgoMs = Int64(weekAgo.timeIntervalSince1970 * 1000)
        let recentItems = items.filter { $0.createdAtTs >= weekAgoMs }
        let itemsPerDay = recentItems.count > 0 ? Double(recentItems.count) / 7.0 : 0
        let lastItemTime = items.first.map { Date(timeIntervalSince1970: Double($0.createdAtTs) / 1000.0) }

        // Load queries - limit to 1 query (most recently added)
        let queries = DatabaseService.shared.getQueries(activeOnly: true)

        // Load logs
        let logs = LogService.shared.getLogs(limit: 3)

        await MainActor.run {
            self.stats = Stats(
                totalItems: totalItems,
                itemsPerDay: itemsPerDay,
                lastItemTime: lastItemTime
            )
            self.lastItem = items.first
            self.recentQueries = Array(queries.prefix(1))
            self.recentLogs = logs
            self.isLoading = false
        }
    }

    func deleteQuery(_ query: VintedQuery) {
        DatabaseService.shared.deleteQuery(id: query.id ?? 0)
        LogService.shared.info("[Dashboard] Query deleted: \(query.queryName)")
        Task {
            await loadDashboard()
        }
    }

    func startEditing(_ query: VintedQuery) {
        editingQuery = query
        newQueryUrl = query.vintedUrl
        newQueryName = query.queryName
        errorMessage = nil
        showEditSheet = true
    }

    func updateQuery() {
        guard let query = editingQuery, let id = query.id else { return }

        // Validate URL
        guard !newQueryUrl.isEmpty else {
            errorMessage = "URL cannot be empty"
            return
        }

        guard newQueryUrl.contains("vinted.") else {
            errorMessage = "Please enter a valid Vinted URL"
            return
        }

        // Update query
        var updatedQuery = query
        updatedQuery.vintedUrl = newQueryUrl
        updatedQuery.queryName = newQueryName.isEmpty ? "Custom Search" : newQueryName

        DatabaseService.shared.updateQuery(updatedQuery)
        LogService.shared.info("[Dashboard] Query updated: \(updatedQuery.queryName)")

        // Clear form and reload
        newQueryUrl = ""
        newQueryName = ""
        editingQuery = nil
        errorMessage = nil

        Task {
            await loadDashboard()
        }
    }

}
