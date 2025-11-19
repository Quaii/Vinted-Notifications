//
//  QueriesView.swift
//  Vinted Notifications
//
//  Queries Screen
//

import SwiftUI

// MARK: - Queries Screen
struct QueriesView: View {
    @StateObject private var viewModel = QueriesViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Page Header
                PageHeader(title: "Queries")

                ZStack {
                    if viewModel.queries.isEmpty {
                        // Empty state
                        VStack(spacing: Spacing.xl) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 64))
                                .foregroundColor(theme.textTertiary)

                            Text("No search queries")
                                .font(.system(size: FontSizes.title3, weight: .semibold))
                                .foregroundColor(theme.textSecondary)

                            Text("Add a Vinted search URL to start tracking new items")
                                .font(.system(size: FontSizes.subheadline))
                                .foregroundColor(theme.textTertiary)
                                .multilineTextAlignment(.center)

                            Button(action: { viewModel.showAddSheet = true }) {
                                Text("Add Your First Query")
                                    .font(.system(size: FontSizes.body, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.xl)
                                    .padding(.vertical, Spacing.md)
                                    .background(theme.primary)
                                    .cornerRadius(BorderRadius.lg)
                            }
                        }
                        .padding(Spacing.xl)
                    } else {
                        // List of queries
                        List {
                            ForEach(viewModel.queries) { query in
                                QueryCard(
                                    query: query,
                                    onPress: {}
                                )
                                .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
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
                        .background(theme.groupedBackground)
                    }

                    // FAB button - only show when there are queries
                    if !viewModel.queries.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: { viewModel.showAddSheet = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(theme.primary)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .padding(.trailing, Spacing.md)
                                .padding(.bottom, 50)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.groupedBackground)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showAddSheet) {
                QuerySheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadQueries()
        }
    }
}

// MARK: - Query Sheet
struct QuerySheet: View {
    @ObservedObject var viewModel: QueriesViewModel
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // URL Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Vinted Search URL")
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.text)

                            Spacer()

                            Text("Required")
                                .font(.system(size: FontSizes.caption1))
                                .foregroundColor(theme.error)
                        }

                        TextField("https://www.vinted.com/catalog?...", text: $viewModel.newQueryUrl)
                            .font(.system(size: FontSizes.body))
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.xl)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.xl)
                                    .stroke(viewModel.newQueryUrl.isEmpty ? theme.border : theme.primary.opacity(0.3), lineWidth: viewModel.newQueryUrl.isEmpty ? 1 : 2)
                            )
                    }

                    // Name Input Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Custom Name")
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.text)

                            Spacer()

                            Text("Optional")
                                .font(.system(size: FontSizes.caption1))
                                .foregroundColor(theme.textTertiary)
                        }

                        TextField("e.g., Nike Sneakers", text: $viewModel.newQueryName)
                            .font(.system(size: FontSizes.body))
                            .padding(Spacing.md)
                            .background(theme.secondaryGroupedBackground)
                            .cornerRadius(BorderRadius.xl)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadius.xl)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }

                    // Info Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: FontSizes.subheadline))
                                .foregroundColor(theme.primary)

                            Text("How it works")
                                .font(.system(size: FontSizes.subheadline, weight: .semibold))
                                .foregroundColor(theme.text)
                        }

                        Text("1. Search for items on Vinted\n2. Copy the full URL from your browser\n3. Paste it here to start monitoring\n4. Get notifications when new items appear")
                            .font(.system(size: FontSizes.footnote))
                            .foregroundColor(theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.primary.opacity(0.08))
                    .cornerRadius(BorderRadius.xl)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.xl)
                            .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                    )

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: FontSizes.body))
                                .foregroundColor(theme.error)

                            Text(error)
                                .font(.system(size: FontSizes.footnote))
                                .foregroundColor(theme.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.error.opacity(0.1))
                        .cornerRadius(BorderRadius.xl)
                        .overlay(
                            RoundedRectangle(cornerRadius: BorderRadius.xl)
                                .stroke(theme.error.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(Spacing.lg)
            }
            .background(theme.groupedBackground)
            .navigationTitle(viewModel.editingQuery != nil ? "Edit Query" : "Add Query")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.newQueryUrl = ""
                        viewModel.newQueryName = ""
                        viewModel.editingQuery = nil
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.editingQuery != nil ? "Update" : "Add") {
                        viewModel.addQuery()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .font(.system(size: FontSizes.body, weight: .semibold))
                    .foregroundColor(viewModel.newQueryUrl.isEmpty ? theme.textTertiary : theme.primary)
                    .disabled(viewModel.newQueryUrl.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
