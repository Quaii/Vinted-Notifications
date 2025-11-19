//
//  ItemsView.swift
//  Vinted Notifications
//
//  Items Screen
//

import SwiftUI

// MARK: - Items Screen
struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Items")

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    TextField("Search items...", text: $viewModel.searchQuery)
                        .onChange(of: viewModel.searchQuery) {
                            viewModel.applyFilters()
                        }
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.applyFilters()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(theme.secondaryGroupedBackground)
                .cornerRadius(BorderRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .stroke(theme.border, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xs)

                // Toolbar
                HStack(spacing: Spacing.sm) {
                    Button(action: { viewModel.showSortSheet = true }) {
                        HStack {
                            Text(viewModel.sortBy.rawValue)
                                .font(.system(size: FontSizes.body, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: FontSizes.subheadline))
                        }
                        .foregroundColor(theme.text)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.secondaryGroupedBackground)
                        .cornerRadius(BorderRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.lg)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }

                    HStack(spacing: 4) {
                        Button(action: { viewModel.viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewModel.viewMode == .list ? .white : theme.textSecondary)
                                .padding(Spacing.sm)
                                .background(viewModel.viewMode == .list ? theme.primary : Color.clear)
                                .cornerRadius(BorderRadius.md)
                        }

                        Button(action: { viewModel.viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(viewModel.viewMode == .grid ? .white : theme.textSecondary)
                                .padding(Spacing.sm)
                                .background(viewModel.viewMode == .grid ? theme.primary : Color.clear)
                                .cornerRadius(BorderRadius.md)
                        }
                    }
                    .background(theme.secondaryGroupedBackground)
                    .cornerRadius(BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.lg)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                // Items list/grid
                if viewModel.filteredItems.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textTertiary)
                        Text("No items found")
                            .font(.system(size: FontSizes.title3, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if viewModel.viewMode == .list {
                            LazyVStack(spacing: Spacing.md) {
                                ForEach(viewModel.filteredItems) { item in
                                    ItemCard(item: item)
                                }
                            }
                            .padding(Spacing.lg)
                            .padding(.bottom, 100)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)
                            ], spacing: Spacing.md) {
                                ForEach(viewModel.filteredItems) { item in
                                    ItemGridCard(item: item)
                                }
                            }
                            .padding(Spacing.lg)
                            .padding(.bottom, 100)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(theme.groupedBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadItems()
        }
        .refreshable {
            viewModel.loadItems()
        }
        .sheet(isPresented: $viewModel.showSortSheet) {
            SortSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Sort Sheet
struct SortSheet: View {
    @ObservedObject var viewModel: ItemsViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(ItemSortOption.allCases, id: \.self) { option in
                Button(action: {
                    viewModel.sortBy = option
                    viewModel.applyFilters()
                    dismiss()
                }) {
                    HStack {
                        Text(option.rawValue)
                            .foregroundColor(theme.text)
                        Spacer()
                        if viewModel.sortBy == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primary)
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
