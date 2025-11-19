//
//  DashboardView.swift
//  Vinted Notifications
//
//  Dashboard Screen
//

import SwiftUI

// MARK: - Dashboard Screen
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Dashboard")

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Stats widgets
                        HStack(spacing: Spacing.md) {
                            StatWidget(
                                tag: "Total Items",
                                value: "\(viewModel.stats.totalItems)",
                                subheading: viewModel.stats.totalItems == 0 ? "No items yet" : "\(viewModel.stats.totalItems) cached",
                                lastUpdated: viewModel.stats.lastUpdated,
                                icon: "square.grid.2x2",
                                iconColor: theme.primary
                            )

                            StatWidget(
                                tag: "Items / Day",
                                value: String(format: "%.0f", viewModel.stats.itemsPerDay),
                                subheading: "Last 7 days",
                                lastUpdated: viewModel.stats.lastUpdated,
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: theme.primary
                            )
                        }

                        // Last found item
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Last Found Item")
                                    .font(.system(size: FontSizes.title3, weight: .semibold))
                                    .foregroundColor(theme.text)

                                Spacer()

                                NavigationLink("View All") {
                                    ItemsView()
                                }
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                            }

                            if let item = viewModel.lastItem {
                                ItemCard(item: item, compact: true)
                            } else {
                                Text("No items found yet")
                                    .font(.system(size: FontSizes.subheadline))
                                    .foregroundColor(theme.textTertiary)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.lg)
                            }
                        }

                        // Recent queries
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Queries")
                                    .font(.system(size: FontSizes.title3, weight: .semibold))
                                    .foregroundColor(theme.text)

                                Spacer()

                                NavigationLink("Manage") {
                                    QueriesView()
                                }
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                            }

                            if viewModel.recentQueries.isEmpty {
                                Text("No queries saved")
                                    .font(.system(size: FontSizes.subheadline))
                                    .foregroundColor(theme.textTertiary)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.lg)
                            } else {
                                List {
                                    ForEach(viewModel.recentQueries) { query in
                                        QueryCard(
                                            query: query,
                                            onPress: {}
                                        )
                                        .listRowInsets(EdgeInsets(top: Spacing.sm, leading: 0, bottom: Spacing.sm, trailing: 0))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.deleteQuery(query)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }

                                            Button {
                                                viewModel.startEditing(query)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: CGFloat(viewModel.recentQueries.count) * 100)
                            }
                        }

                        // Recent logs
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Recent Logs")
                                    .font(.system(size: FontSizes.title3, weight: .semibold))
                                    .foregroundColor(theme.text)

                                Spacer()

                                NavigationLink("View All") {
                                    LogsView()
                                }
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                            }

                            ForEach(viewModel.recentLogs) { log in
                                LogEntryView(log: log)
                            }
                        }

                        Spacer()
                            .frame(height: 100) // Tab bar spacing
                    }
                    .padding(Spacing.lg)
                }
                .scrollIndicators(.hidden)
                .background(theme.groupedBackground)
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadDashboard()
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            DashboardQueryEditSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Dashboard Query Edit Sheet
struct DashboardQueryEditSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: {
                    viewModel.newQueryUrl = ""
                    viewModel.newQueryName = ""
                    viewModel.editingQuery = nil
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: FontSizes.body))
                        .foregroundColor(theme.primary)
                }

                Spacer()

                Text("Edit Query")
                    .font(.system(size: FontSizes.headline, weight: .bold))
                    .foregroundColor(theme.text)

                Spacer()

                Button(action: {
                    viewModel.updateQuery()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }) {
                    Text("Update")
                        .font(.system(size: FontSizes.body, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(theme.background)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // URL Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vinted Search URL")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("https://www.vinted.com/catalog?...", text: $viewModel.newQueryUrl)
                            .font(.system(size: FontSizes.body))
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Name Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Custom Name (Optional)")
                            .font(.system(size: FontSizes.subheadline, weight: .semibold))
                            .foregroundColor(theme.text)

                        TextField("e.g., Nike Shoes", text: $viewModel.newQueryName)
                            .font(.system(size: FontSizes.body))
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(.red)

                            Text(error)
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(BorderRadius.lg)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
        }
        .background(theme.groupedBackground)
    }
}
