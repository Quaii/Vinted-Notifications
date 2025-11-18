//
//  QueriesViewModel.swift
//  Vinted Notifications
//

import Foundation

class QueriesViewModel: ObservableObject {
    @Published var queries: [VintedQuery] = []
    @Published var isLoading = false
    @Published var showAddSheet = false
    @Published var editingQuery: VintedQuery?
    @Published var newQueryUrl = ""
    @Published var newQueryName = ""
    @Published var errorMessage: String?

    func loadQueries() {
        isLoading = true
        queries = DatabaseService.shared.getQueries()
        isLoading = false
    }

    func addQuery() {
        guard !newQueryUrl.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a Vinted URL"
            return
        }

        guard VintedAPI.shared.isValidVintedUrl(newQueryUrl) else {
            errorMessage = "Please enter a valid Vinted search URL"
            return
        }

        do {
            if let editing = editingQuery {
                // Update existing query
                DatabaseService.shared.updateQuery(
                    id: editing.id!,
                    query: newQueryUrl.trimmingCharacters(in: .whitespaces),
                    queryName: newQueryName.isEmpty ? nil : newQueryName
                )
            } else {
                // Add new query
                _ = try DatabaseService.shared.addQuery(
                    query: newQueryUrl.trimmingCharacters(in: .whitespaces),
                    queryName: newQueryName.isEmpty ? nil : newQueryName
                )

                // Auto-start monitoring if this is the first query
                if queries.isEmpty {
                    MonitoringService.shared.startMonitoring()
                }
            }

            newQueryUrl = ""
            newQueryName = ""
            editingQuery = nil
            showAddSheet = false
            loadQueries()

        } catch {
            errorMessage = "Failed to save query. It may already exist."
        }
    }

    func deleteQuery(_ query: VintedQuery) {
        guard let id = query.id else { return }
        DatabaseService.shared.deleteQuery(id: id)
        loadQueries()
    }

    func startEditing(_ query: VintedQuery) {
        editingQuery = query
        newQueryUrl = query.vintedUrl
        newQueryName = query.queryName
        showAddSheet = true
    }
}
