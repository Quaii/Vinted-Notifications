//
//  AnalyticsViewModel.swift
//  Vinted Notifications
//

import Foundation

class AnalyticsViewModel: ObservableObject {
    @Published var stats = Stats()
    @Published var dailyData: [Int] = []
    @Published var weeklyData: [String: Int] = [:]
    @Published var priceDistribution: [PriceRange] = []

    struct Stats {
        var totalItems: Int = 0
        var avgPrice: Double = 0
        var itemsToday: Int = 0
        var itemsThisWeek: Int = 0
    }

    struct PriceRange: Identifiable {
        let id = UUID()
        let name: String
        var count: Int
    }

    func loadAnalytics() {
        let items = DatabaseService.shared.getItems(limit: 10000)

        // Calculate total and average price
        let totalItems = items.count
        let totalPrice = items.reduce(0.0) { sum, item in
            sum + (Double(item.price) ?? 0)
        }
        let avgPrice = totalItems > 0 ? totalPrice / Double(totalItems) : 0

        // Calculate items today
        let today = Calendar.current.startOfDay(for: Date())
        let todayMs = Int64(today.timeIntervalSince1970 * 1000)
        let itemsToday = items.filter { $0.createdAtTs >= todayMs }.count

        // Calculate items this week
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let weekAgoMs = Int64(weekAgo.timeIntervalSince1970 * 1000)
        let itemsThisWeek = items.filter { $0.createdAtTs >= weekAgoMs }.count

        // Daily data (last 30 days)
        var dailyCounts: [String: Int] = [:]
        let calendar = Calendar.current
        for i in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dateKey = calendar.startOfDay(for: date).timeIntervalSince1970
                dailyCounts[String(Int(dateKey))] = 0
            }
        }

        for item in items {
            let itemDate = Date(timeIntervalSince1970: Double(item.createdAtTs) / 1000.0)
            let dateKey = calendar.startOfDay(for: itemDate).timeIntervalSince1970
            let key = String(Int(dateKey))
            dailyCounts[key, default: 0] += 1
        }

        let sortedDailyData = dailyCounts.sorted { $0.key < $1.key }.map { $0.value }

        // Weekly distribution
        var weeklyDataDict: [String: Int] = [
            "Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0
        ]
        let dayMapping = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for item in items {
            let itemDate = Date(timeIntervalSince1970: Double(item.createdAtTs) / 1000.0)
            let dayOfWeek = calendar.component(.weekday, from: itemDate)
            let dayName = dayMapping[dayOfWeek - 1]
            weeklyDataDict[dayName, default: 0] += 1
        }

        // Price distribution
        var priceRanges: [String: Int] = [
            "0-10€": 0, "10-25€": 0, "25-50€": 0, "50-100€": 0, "100+€": 0
        ]

        for item in items {
            let price = Double(item.price) ?? 0
            if price < 10 { priceRanges["0-10€"]! += 1 }
            else if price < 25 { priceRanges["10-25€"]! += 1 }
            else if price < 50 { priceRanges["25-50€"]! += 1 }
            else if price < 100 { priceRanges["50-100€"]! += 1 }
            else { priceRanges["100+€"]! += 1 }
        }

        let priceDistArray = priceRanges.map { PriceRange(name: $0.key, count: $0.value) }

        // Update published properties
        DispatchQueue.main.async {
            self.stats = Stats(
                totalItems: totalItems,
                avgPrice: avgPrice,
                itemsToday: itemsToday,
                itemsThisWeek: itemsThisWeek
            )
            self.dailyData = sortedDailyData
            self.weeklyData = weeklyDataDict
            self.priceDistribution = priceDistArray
        }
    }
}
