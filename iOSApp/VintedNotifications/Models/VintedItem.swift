//
//  VintedItem.swift
//  Vinted Notifications
//
//  Model representing a Vinted item
//

import Foundation

struct VintedItem: Identifiable, Codable {
    let id: Int64
    var title: String
    var brandTitle: String?
    var sizeTitle: String?
    var price: String
    var currency: String
    var photo: String?
    var url: String?
    var buyUrl: String?
    var createdAtTs: Int64
    var rawTimestamp: String?
    var queryId: Int64?
    var notified: Bool = false
    var userId: Int64?
    var userCountry: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case brandTitle = "brand_title"
        case sizeTitle = "size_title"
        case price
        case currency
        case photo
        case url
        case buyUrl = "buy_url"
        case createdAtTs = "created_at_ts"
        case rawTimestamp = "raw_timestamp"
        case queryId = "query_id"
        case notified
        case userId = "user_id"
        case userCountry = "user_country"
    }

    // Initialize from API response
    init(from apiData: [String: Any], queryId: Int64? = nil) {
        self.id = apiData["id"] as? Int64 ?? 0

        // Handle title - ensure it's never an object or stringified JSON
        if let titleString = apiData["title"] as? String {
            // Detect corrupt data
            if titleString.contains("{\"amount\"") ||
               titleString.contains("\"currency_code\"") ||
               (titleString.hasPrefix("{") && titleString.contains("\"")) {
                self.title = ""
            } else {
                self.title = titleString
            }
        } else {
            self.title = ""
        }

        self.brandTitle = apiData["brand_title"] as? String ?? apiData["brandTitle"] as? String
        self.sizeTitle = apiData["size_title"] as? String ?? apiData["sizeTitle"] as? String

        // Handle price - ensure it's always a string
        if let priceDict = apiData["price"] as? [String: Any] {
            // Price is an object from API
            self.price = String(describing: priceDict["amount"] ?? priceDict["value"] ?? "0.00")
            self.currency = String(describing: priceDict["currency_code"] ?? priceDict["currency"] ?? "€")
        } else if let priceString = apiData["price"] as? String {
            self.price = priceString
            self.currency = apiData["currency"] as? String ?? "€"
        } else {
            self.price = "0.00"
            self.currency = "€"
        }

        // Handle photo - ensure it's always a URL string
        if let photoDict = apiData["photo"] as? [String: Any] {
            self.photo = photoDict["url"] as? String ?? photoDict["full_size_url"] as? String
        } else {
            self.photo = apiData["photo"] as? String
        }

        self.url = apiData["url"] as? String
        self.buyUrl = apiData["buy_url"] as? String ?? apiData["buyUrl"] as? String
        self.createdAtTs = apiData["created_at_ts"] as? Int64 ?? apiData["createdAtTs"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.rawTimestamp = apiData["raw_timestamp"] as? String ?? apiData["rawTimestamp"] as? String
        self.queryId = queryId

        // Extract user ID from user object
        if let userDict = apiData["user"] as? [String: Any] {
            self.userId = userDict["id"] as? Int64
        } else {
            self.userId = nil
        }
        self.userCountry = nil // Will be fetched separately if needed

        // Generate buy URL if not provided
        if self.buyUrl == nil || self.buyUrl?.isEmpty == true {
            self.buyUrl = self.generateBuyUrl()
        }
    }

    // Initialize from database row
    init(id: Int64, title: String, brandTitle: String?, sizeTitle: String?, price: String, currency: String, photo: String?, url: String?, buyUrl: String?, createdAtTs: Int64, rawTimestamp: String?, queryId: Int64?, notified: Bool = false, userId: Int64? = nil, userCountry: String? = nil) {
        self.id = id
        self.title = title
        self.brandTitle = brandTitle
        self.sizeTitle = sizeTitle
        self.price = price
        self.currency = currency
        self.photo = photo
        self.url = url
        self.buyUrl = buyUrl
        self.createdAtTs = createdAtTs
        self.rawTimestamp = rawTimestamp
        self.queryId = queryId
        self.notified = notified
        self.userId = userId
        self.userCountry = userCountry
    }

    // Generate buy URL from item URL and ID
    func generateBuyUrl() -> String? {
        guard let url = self.url, !url.isEmpty else { return nil }
        guard let baseUrl = url.components(separatedBy: "items").first else { return nil }
        return "\(baseUrl)transaction/buy/new?source_screen=item&transaction[item_id]=\(id)"
    }

    // Format price for display
    func formattedPrice() -> String {
        return "\(price) \(currency)"
    }

    // Get display photo URL
    func photoUrl() -> String? {
        return photo
    }

    // Get time since posted
    func timeSincePosted() -> String {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = now - createdAtTs
        let minutes = diff / 60000
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 { return "\(days)d ago" }
        if hours > 0 { return "\(hours)h ago" }
        if minutes > 0 { return "\(minutes)m ago" }
        return "Just now"
    }
}
