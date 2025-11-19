//
//  AnalyticsView.swift
//  Vinted Notifications
//
//  Analytics Screen with Charts
//

import SwiftUI

// MARK: - Analytics Screen
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Analytics")

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Overview stats
                        VStack(spacing: Spacing.md) {
                            HStack(spacing: Spacing.md) {
                                StatsCard(title: "Total Items", value: "\(viewModel.stats.totalItems)", icon: "square.grid.2x2")
                                StatsCard(title: "Avg. Price", value: String(format: "%.2f€", viewModel.stats.avgPrice), icon: "eurosign.circle")
                            }
                            HStack(spacing: Spacing.md) {
                                StatsCard(title: "Today", value: "\(viewModel.stats.itemsToday)", icon: "calendar")
                                StatsCard(title: "This Week", value: "\(viewModel.stats.itemsThisWeek)", icon: "calendar.badge.clock")
                            }
                        }

                        // Items Over Time Chart
                        ItemsOverTimeChart(viewModel: viewModel)

                        // Items by Day of Week Chart
                        ItemsByDayChart(viewModel: viewModel)

                        // Price Distribution Chart
                        PriceDistributionChart(viewModel: viewModel)

                        // Cumulative Growth Chart
                        CumulativeGrowthChart(viewModel: viewModel)

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(Spacing.lg)
                }
                .scrollIndicators(.hidden)
                .background(theme.groupedBackground)
            }
            .navigationBarHidden(true)
        }
        .task {
            viewModel.loadAnalytics()
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side - Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: FontSizes.caption2, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: FontSizes.title2, weight: .bold))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - Icon in circular background
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(theme.primary)
            }
        }
        .padding(Spacing.md)
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Chart Components
struct ItemsOverTimeChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Items Over Time")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Last 30 days")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.dailyData.isEmpty {
                    SimpleLineChart(data: viewModel.dailyData, color: theme.primary)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.line.uptrend.xyaxis")
                }
            }
            .padding(Spacing.lg)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.separator, lineWidth: 1)
            )
        }
    }
}

struct ItemsByDayChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Items by Day of Week")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Weekly distribution")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.weeklyData.isEmpty {
                    SimpleBarChart(data: viewModel.weeklyData, color: theme.primary)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.bar")
                }
            }
            .padding(Spacing.lg)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.separator, lineWidth: 1)
            )
        }
    }
}

struct PriceDistributionChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Price Distribution")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Items grouped by price range")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.priceDistribution.isEmpty {
                    SimplePriceDistribution(data: viewModel.priceDistribution, theme: theme)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.pie")
                }
            }
            .padding(Spacing.lg)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.separator, lineWidth: 1)
            )
        }
    }
}

struct CumulativeGrowthChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.theme) var theme

    var cumulativeData: [Int] {
        var cumulative: [Int] = []
        var sum = 0
        for value in viewModel.dailyData {
            sum += value
            cumulative.append(sum)
        }
        return cumulative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Cumulative Growth")
                .font(.system(size: FontSizes.title3, weight: .semibold))
                .foregroundColor(theme.text)

            VStack(spacing: Spacing.sm) {
                Text("Total items accumulated over last 30 days")
                    .font(.system(size: FontSizes.footnote))
                    .foregroundColor(theme.textTertiary)

                if viewModel.stats.totalItems > 0 && !viewModel.dailyData.isEmpty {
                    SimpleLineChart(data: cumulativeData, color: theme.primary, filled: true)
                        .frame(height: 220)
                } else {
                    EmptyChartView(icon: "chart.line.uptrend.xyaxis")
                }
            }
            .padding(Spacing.lg)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.separator, lineWidth: 1)
            )
        }
    }
}

// MARK: - Simple Chart Implementations
struct SimpleLineChart: View {
    let data: [Int]
    let color: Color
    var filled: Bool = false

    @Environment(\.theme) var theme

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = max(maxValue - minValue, 1)

            ZStack(alignment: .bottomLeading) {
                // Background grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(theme.separator.opacity(0.3))
                            .frame(height: 1)
                        Spacer()
                    }
                }

                // Line path
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
                        let y = geometry.size.height * (1 - normalizedValue)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)

                // Filled area
                if filled {
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                            let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
                            let y = geometry.size.height * (1 - normalizedValue)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: geometry.size.height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    }
}

struct SimpleBarChart: View {
    let data: [String: Int]
    let color: Color

    @Environment(\.theme) var theme

    var sortedData: [(String, Int)] {
        let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayOrder.compactMap { day in
            if let count = data[day] {
                return (day, count)
            }
            return nil
        }
    }

    var body: some View {
        let maxValue = data.values.max() ?? 1

        HStack(alignment: .bottom, spacing: 8) {
            ForEach(sortedData, id: \.0) { day, count in
                VStack(spacing: 4) {
                    Spacer()

                    let height = CGFloat(count) / CGFloat(maxValue)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: max(height * 180, count > 0 ? 4 : 0))

                    Text(day)
                        .font(.system(size: FontSizes.caption2, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, Spacing.md)
    }
}

struct SimplePriceDistribution: View {
    let data: [AnalyticsViewModel.PriceRange]
    let theme: AppColors

    var body: some View {
        let sortedData = data.sorted { $0.name < $1.name }
        let total = data.reduce(0) { $0 + $1.count }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(sortedData) { range in
                HStack {
                    Text(range.name)
                        .font(.system(size: FontSizes.footnote, weight: .medium))
                        .foregroundColor(theme.text)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geometry in
                        let percentage = total > 0 ? CGFloat(range.count) / CGFloat(total) : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.primary)
                            .frame(width: geometry.size.width * percentage)
                    }

                    Text("\(range.count)")
                        .font(.system(size: FontSizes.footnote, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .frame(height: 24)
            }
        }
        .padding(.vertical, Spacing.md)
    }
}

struct EmptyChartView: View {
    let icon: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(theme.textTertiary)
            Text("No information available at this point in time")
                .font(.system(size: FontSizes.body))
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}
