//
//  VintedAPI.swift
//  Vinted Notifications
//
//  Vinted API client with anti-detection measures
//  Replicates Python/JavaScript implementation
//

import Foundation

class VintedAPI: ObservableObject {
    static let shared = VintedAPI()

    private var session: URLSession
    private var currentLocale: String = "www.vinted.fr"
    private var authUrl: String
    private var userAgentsList: [String] = userAgents
    private var defaultHeadersList: [String: String] = defaultHeaders
    private let maxRetries = AppConfig.apiMaxRetries

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiTimeout
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        self.session = URLSession(configuration: config)
        self.authUrl = "https://\(currentLocale)/"

        LogService.shared.info("[VintedAPI] Initialized")
    }

    // MARK: - Session Management

    private func getRandomUserAgent() -> String {
        return userAgentsList.randomElement() ?? userAgents[0]
    }

    private func setLocale(from url: String) {
        guard let urlComponents = URLComponents(string: url),
              let host = urlComponents.host else {
            return
        }

        if host != currentLocale {
            currentLocale = host
            authUrl = "https://\(currentLocale)/"
            LogService.shared.info("[VintedAPI] Locale changed to: \(currentLocale)")
        }
    }

    private func setCookies() async throws {
        guard let url = URL(string: authUrl) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(currentLocale, forHTTPHeaderField: "Host")

        for (key, value) in defaultHeadersList {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            LogService.shared.info("[VintedAPI] Cookies refreshed successfully")
        }
    }

    // MARK: - URL Parsing

    private func convertBrandUrl(_ urlString: String) -> String {
        // Convert brand URLs to catalog URLs
        // Example: https://www.vinted.fr/brand/123-nike → /catalog?brand_ids=123
        guard urlString.contains("/brand/") else { return urlString }

        let pattern = "/brand/(\\d+)-"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
              let brandRange = Range(match.range(at: 1), in: urlString) else {
            return urlString
        }

        let brandId = String(urlString[brandRange])
        guard let urlComponents = URLComponents(string: urlString),
              let host = urlComponents.host else {
            return urlString
        }

        return "https://\(host)/catalog?brand_ids=\(brandId)"
    }

    private func parseUrl(_ urlString: String) -> (domain: String, params: [String: String])? {
        let convertedUrl = convertBrandUrl(urlString)

        guard let urlComponents = URLComponents(string: convertedUrl),
              let host = urlComponents.host else {
            LogService.shared.error("[VintedAPI] Failed to parse URL: \(urlString)")
            return nil
        }

        var params: [String: String] = [:]

        // Extract query parameters
        if let queryItems = urlComponents.queryItems {
            for item in queryItems {
                guard let value = item.value else { continue }

                // Handle array parameters (key[] or key[0])
                let key = item.name.replacingOccurrences(of: "\\[.*\\]", with: "", options: .regularExpression)

                if params[key] != nil {
                    // Append to existing value
                    params[key] = "\(params[key]!),\(value)"
                } else {
                    params[key] = value
                }
            }
        }

        // Force newest_first ordering
        params["order"] = "newest_first"

        // Remove unwanted parameters
        params.removeValue(forKey: "time")
        params.removeValue(forKey: "search_id")
        params.removeValue(forKey: "disabled_personalization")
        params.removeValue(forKey: "page")

        return (domain: host, params: params)
    }

    // MARK: - Search

    func search(url vintedUrl: String, itemsPerQuery: Int = AppConfig.defaultItemsPerQuery) async throws -> [VintedItem] {
        guard let parsed = parseUrl(vintedUrl) else {
            throw NSError(domain: "VintedAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Vinted URL"])
        }

        let domain = parsed.domain
        let params = parsed.params

        // Set locale for this domain
        setLocale(from: vintedUrl)

        // Build API URL
        guard var urlComponents = URLComponents(string: "https://\(domain)/api/v2/catalog/items") else {
            throw NSError(domain: "VintedAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }

        var queryItems: [URLQueryItem] = []
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        queryItems.append(URLQueryItem(name: "page", value: "1"))
        queryItems.append(URLQueryItem(name: "per_page", value: "\(itemsPerQuery)"))

        urlComponents.queryItems = queryItems

        guard let apiUrl = urlComponents.url else {
            throw NSError(domain: "VintedAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to build API URL"])
        }

        // Retry loop
        var tried = 0
        var newSession = false

        while tried < maxRetries {
            tried += 1

            var request = URLRequest(url: apiUrl, timeoutInterval: AppConfig.apiTimeout)
            request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
            request.setValue(domain, forHTTPHeaderField: "Host")

            for (key, value) in defaultHeadersList {
                request.setValue(value, forHTTPHeaderField: key)
            }

            do {
                LogService.shared.info("[VintedAPI] Request attempt \(tried)/\(maxRetries) to \(apiUrl.absoluteString)")

                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }

                // Handle status codes
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
                    LogService.shared.warning("[VintedAPI] Got \(httpResponse.statusCode), refreshing cookies (attempt \(tried)/\(maxRetries))")

                    if tried < maxRetries {
                        try await setCookies()
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                        continue
                    }
                }

                if httpResponse.statusCode == 200 {
                    // Parse response
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let itemsArray = json?["items"] as? [[String: Any]] ?? []

                    LogService.shared.info("[VintedAPI] Success! Got \(itemsArray.count) items")

                    // Convert to VintedItem objects
                    var items: [VintedItem] = []
                    for itemData in itemsArray {
                        items.append(VintedItem(from: itemData))
                    }

                    return items
                }

                // If we've exhausted retries and got 401/403, reset session
                if tried == maxRetries {
                    if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) && !newSession {
                        LogService.shared.info("[VintedAPI] Resetting session and retrying one last time...")
                        newSession = true
                        tried = 0 // Reset counter
                        try await setCookies()
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                }

                LogService.shared.warning("[VintedAPI] Got status \(httpResponse.statusCode), continuing...")

            } catch {
                LogService.shared.error("[VintedAPI] Request error: \(error.localizedDescription)")

                // Exponential backoff for timeout errors
                let delay = min(1_000_000_000 * UInt64(pow(2.0, Double(tried - 1))), 5_000_000_000) // Max 5s
                try? await Task.sleep(nanoseconds: delay)
            }
        }

        LogService.shared.warning("[VintedAPI] All retries exhausted, returning empty array")
        return []
    }

    // MARK: - User Country

    func getUserCountry(userId: Int64, domain: String? = nil) async -> String {
        let targetDomain = domain ?? currentLocale

        guard let url = URL(string: "https://\(targetDomain)/api/v2/users/\(userId)?localize=false") else {
            return "XX"
        }

        var request = URLRequest(url: url, timeoutInterval: AppConfig.apiTimeout)
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(targetDomain, forHTTPHeaderField: "Host")

        for (key, value) in defaultHeadersList {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            LogService.shared.info("[VintedAPI] Fetching country for user \(userId)")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return "XX"
            }

            // Handle rate limiting
            if httpResponse.statusCode == 429 {
                LogService.shared.warning("[VintedAPI] Rate limited (429), trying alternative endpoint...")

                // Fallback to items endpoint
                guard let altUrl = URL(string: "https://\(targetDomain)/api/v2/users/\(userId)/items?page=1&per_page=1") else {
                    return "XX"
                }

                var altRequest = URLRequest(url: altUrl, timeoutInterval: AppConfig.apiTimeout)
                altRequest.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
                altRequest.setValue(targetDomain, forHTTPHeaderField: "Host")

                let (altData, altResponse) = try await session.data(for: altRequest)

                if let altHttpResponse = altResponse as? HTTPURLResponse,
                   altHttpResponse.statusCode == 200,
                   let altJson = try? JSONSerialization.jsonObject(with: altData) as? [String: Any],
                   let items = altJson["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let user = firstItem["user"] as? [String: Any],
                   let countryCode = user["country_iso_code"] as? String {
                    LogService.shared.info("[VintedAPI] Got country via fallback: \(countryCode)")
                    return countryCode
                }

                LogService.shared.warning("[VintedAPI] Fallback endpoint failed")
                return "XX"
            }

            // Success with primary endpoint
            if httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let user = json["user"] as? [String: Any],
               let countryCode = user["country_iso_code"] as? String {
                LogService.shared.info("[VintedAPI] Got country: \(countryCode)")
                return countryCode
            }

            LogService.shared.warning("[VintedAPI] Unexpected status: \(httpResponse.statusCode)")
            return "XX"

        } catch {
            LogService.shared.error("[VintedAPI] Failed to get user country: \(error.localizedDescription)")
            return "XX"
        }
    }

    // MARK: - Validation

    func isValidVintedUrl(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return false
        }
        return host.contains("vinted.")
    }
}
