//
//  VintedQuery.swift
//  Vinted Notifications
//
//  Model representing a Vinted search query
//

import Foundation

struct VintedQuery: Identifiable, Codable {
    let id: Int64?
    var query: String
    var queryName: String
    var lastItem: Int64?
    var createdAt: Int64
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case query
        case queryName = "query_name"
        case lastItem = "last_item"
        case createdAt = "created_at"
        case isActive = "is_active"
    }

    // Initialize with URL
    init(id: Int64? = nil, query: String, queryName: String? = nil, lastItem: Int64? = nil, createdAt: Int64? = nil, isActive: Bool = true) {
        self.id = id
        self.query = query
        self.queryName = queryName ?? VintedQuery.extractQueryName(from: query)
        self.lastItem = lastItem
        self.createdAt = createdAt ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.isActive = isActive
    }

    // Extract a readable name from the query URL
    static func extractQueryName(from url: String) -> String {
        guard let urlComponents = URLComponents(string: url) else {
            return "Unnamed Query"
        }

        let queryItems = urlComponents.queryItems
        var parts: [String] = []

        // Try to build a name from search parameters
        if let searchText = queryItems?.first(where: { $0.name == "search_text" })?.value, !searchText.isEmpty {
            parts.append(searchText)
        }

        if let brandIds = queryItems?.first(where: { $0.name == "brand_ids" })?.value, !brandIds.isEmpty {
            parts.append("Brand filter")
        }

        if let sizeIds = queryItems?.first(where: { $0.name == "size_ids" })?.value, !sizeIds.isEmpty {
            parts.append("Size filter")
        }

        if let colorIds = queryItems?.first(where: { $0.name == "color_ids" })?.value, !colorIds.isEmpty {
            parts.append("Color filter")
        }

        if let priceFrom = queryItems?.first(where: { $0.name == "price_from" })?.value,
           let priceTo = queryItems?.first(where: { $0.name == "price_to" })?.value {
            let from = priceFrom.isEmpty ? "0" : priceFrom
            let to = priceTo.isEmpty ? "∞" : priceTo
            parts.append("\(from)-\(to)")
        }

        return parts.isEmpty ? "Custom Query" : parts.joined(separator: " · ")
    }

    // Get domain from query URL
    func domain() -> String {
        guard let urlComponents = URLComponents(string: query),
              let host = urlComponents.host else {
            return ""
        }
        return host
    }

    // Get country code from domain
    func countryCode() -> String {
        let countryMap: [String: String] = [
            "vinted.fr": "FR",
            "vinted.de": "DE",
            "vinted.co.uk": "GB",
            "vinted.com": "US",
            "vinted.es": "ES",
            "vinted.it": "IT",
            "vinted.pl": "PL",
            "vinted.be": "BE",
            "vinted.nl": "NL",
            "vinted.lt": "LT",
            "vinted.cz": "CZ",
            "vinted.se": "SE",
            "vinted.at": "AT",
            "vinted.pt": "PT",
            "vinted.lu": "LU"
        ]
        return countryMap[domain()] ?? ""
    }

    // Get formatted last item time
    func lastItemTime() -> String {
        guard let lastItem = lastItem else {
            return "No items yet"
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = now - lastItem
        let minutes = diff / 60000
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 { return "\(days)d ago" }
        if hours > 0 { return "\(hours)h ago" }
        if minutes > 0 { return "\(minutes)m ago" }
        return "Just now"
    }

    // Get Vinted URL properly
    var vintedUrl: String {
        return query
    }
}
