//
//  LogsView.swift
//  Vinted Notifications
//
//  Logs Screen
//

import SwiftUI

// MARK: - Log Entry View
struct LogEntryView: View {
    let log: LogEntry
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                // Level badge without icon
                HStack(spacing: 4) {
                    Text(log.level.rawValue)
                        .font(.system(size: FontSizes.caption2, weight: .bold))
                        .foregroundColor(log.level.color)
                }
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 2)
                .background(log.level.color.opacity(0.2))
                .cornerRadius(BorderRadius.sm)

                Spacer()

                Text(log.timestamp, style: .time)
                    .font(.system(size: FontSizes.caption1))
                    .foregroundColor(theme.textTertiary)
            }

            Text(log.message.removingEmojis())
                .font(.system(size: FontSizes.subheadline))
                .foregroundColor(theme.text)
                .lineLimit(2)
        }
        .padding(Spacing.md)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .stroke(theme.separator, lineWidth: 1)
        )
    }
}

// MARK: - Logs Screen
struct LogsView: View {
    @StateObject private var viewModel = LogsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header with clear button
                PageHeader(
                    title: "Logs",
                    rightButton: viewModel.logs.isEmpty ? nil : AnyView(
                        Button(action: viewModel.clearLogs) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primary)
                        }
                    )
                )

                if viewModel.logs.isEmpty {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundColor(theme.textTertiary)
                        Text("No logs yet")
                            .font(.system(size: FontSizes.title2, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                        Text("Application events will appear here")
                            .font(.system(size: FontSizes.body))
                            .foregroundColor(theme.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.logs) { log in
                                LogEntryView(log: log)
                            }
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(theme.groupedBackground)
            .navigationBarHidden(true)
        }
    }
}
