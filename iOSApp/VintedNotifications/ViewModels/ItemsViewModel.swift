//
//  ItemsViewModel.swift
//  Vinted Notifications
//

import Foundation

enum ItemSortOption: String, CaseIterable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case priceAsc = "Price: Low to High"
    case priceDesc = "Price: High to Low"
    case alphaAsc = "Name: A to Z"
    case alphaDesc = "Name: Z to A"
}

enum ItemViewMode {
    case list
    case grid
}

class ItemsViewModel: ObservableObject {
    @Published var items: [VintedItem] = []
    @Published var filteredItems: [VintedItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var sortBy: ItemSortOption = .dateDesc
    @Published var viewMode: ItemViewMode = .list
    @Published var showSortSheet = false

    private var queryId: Int64?

    func loadItems(queryId: Int64? = nil) {
        self.queryId = queryId
        isLoading = true
        items = DatabaseService.shared.getItems(queryId: queryId, limit: 1000)
        applyFilters()
        isLoading = false
    }

    func applyFilters() {
        var filtered = items

        // Apply search filter
        if !searchQuery.isEmpty {
            let lowercased = searchQuery.lowercased()
            filtered = filtered.filter { item in
                item.title.lowercased().contains(lowercased) ||
                (item.brandTitle?.lowercased().contains(lowercased) ?? false) ||
                (item.sizeTitle?.lowercased().contains(lowercased) ?? false)
            }
        }

        // Apply sort
        filtered.sort { a, b in
            switch sortBy {
            case .dateAsc:
                return a.createdAtTs < b.createdAtTs
            case .dateDesc:
                return a.createdAtTs > b.createdAtTs
            case .priceAsc:
                return (Double(a.price) ?? 0) < (Double(b.price) ?? 0)
            case .priceDesc:
                return (Double(a.price) ?? 0) > (Double(b.price) ?? 0)
            case .alphaAsc:
                return a.title < b.title
            case .alphaDesc:
                return a.title > b.title
            }
        }

        filteredItems = filtered
    }
}
