//
//  VintedAPI.swift
//  Vinted Notifications
//
//  Vinted API client with enhanced anti-detection measures
//  Implements proxy support, session management, delays, and network monitoring
//

import Foundation
import Network

class VintedAPI: ObservableObject {
    static let shared = VintedAPI()

    private var session: URLSession
    private var currentLocale: String = "www.vinted.fr"
    private var authUrl: String
    private var userAgentsList: [String] = []
    private var defaultHeadersList: [String: String] = [:]
    private var proxyList: [String] = []
    private var currentProxyIndex: Int = 0
    private var workingProxies: [String] = []
    private var lastProxyCheckTime: TimeInterval = 0
    private let maxRetries = AppConfig.apiMaxRetries
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var lastNetworkChangeTime: TimeInterval = 0
    private var networkCooldownPeriod: TimeInterval = 30.0 // 30 seconds cooldown after network change
    private var isNetworkAvailable: Bool = true
    
    // Session management
    private var sessionWarmed: Bool = false
    private var lastCookieRefresh: TimeInterval = 0
    private let cookieRefreshInterval: TimeInterval = 300.0 // 5 minutes
    
    // Request timing
    private var lastRequestTime: TimeInterval = 0
    private let minRequestDelay: TimeInterval = 1.0 // Minimum 1 second between requests
    private let maxRequestDelay: TimeInterval = 3.0 // Maximum 3 seconds between requests
    
    // Proxy health checking
    private let proxyCheckInterval: TimeInterval = 6 * 60 * 60 // 6 hours
    private let proxyTestTimeout: TimeInterval = 2.0

    private init() {
        self.currentLocale = "www.vinted.fr"
        self.authUrl = "https://\(currentLocale)/"

        // Load settings from database
        loadSettings()

        // Initialize network monitoring
        setupNetworkMonitoring()

        // Create initial session (proxy will be configured after health check if enabled)
        self.session = createSession()

        LogService.shared.info("[VintedAPI] Initialized with \(userAgentsList.count) user agents, \(proxyList.count) proxies")
        
        // Initialize proxy session if proxies are available and checked
        Task {
            // Wait a bit for proxy health check to complete if it was started
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Recreate session with proxy if available
            if !workingProxies.isEmpty {
                let proxyString = workingProxies.first
                self.session = createSession(proxyString: proxyString)
                LogService.shared.info("[VintedAPI] Session configured with proxy: \(workingProxies.count) working proxies available")
            }
            
            // Warm up session
            await warmUpSession()
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let wasAvailable = self.isNetworkAvailable
            self.isNetworkAvailable = path.status == .satisfied
            
            if wasAvailable != self.isNetworkAvailable {
                let currentTime = Date().timeIntervalSince1970
                self.lastNetworkChangeTime = currentTime
                LogService.shared.info("[VintedAPI] Network changed: \(self.isNetworkAvailable ? "available" : "unavailable")")
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    private func checkNetworkCooldown() async {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceChange = currentTime - lastNetworkChangeTime
        
        if timeSinceChange < networkCooldownPeriod && lastNetworkChangeTime > 0 {
            let waitTime = networkCooldownPeriod - timeSinceChange
            LogService.shared.info("[VintedAPI] Network cooldown: waiting \(Int(waitTime))s after network change")
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }

    // MARK: - Settings Management

    private func loadSettings() {
        // Load user agents from database
        let userAgentsJSON = DatabaseService.shared.getParameter("user_agents", defaultValue: "[]")
        if let data = userAgentsJSON.data(using: .utf8),
           let agents = try? JSONSerialization.jsonObject(with: data) as? [String], !agents.isEmpty {
            userAgentsList = agents
        } else {
            userAgentsList = userAgents // Fallback to hardcoded defaults
        }

        // Load default headers from database
        let headersJSON = DatabaseService.shared.getParameter("default_headers", defaultValue: "{}")
        if let data = headersJSON.data(using: .utf8),
           let headers = try? JSONSerialization.jsonObject(with: data) as? [String: String], !headers.isEmpty {
            defaultHeadersList = headers
        } else {
            defaultHeadersList = defaultHeaders // Fallback to hardcoded defaults
        }

        // Load proxy list from database (semicolon-separated)
        let proxyListStr = DatabaseService.shared.getParameter("proxy_list", defaultValue: "")
        if !proxyListStr.isEmpty {
            proxyList = proxyListStr.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            proxyList = []
        }
        
        // Load proxy list from link if configured
        let proxyListLink = DatabaseService.shared.getParameter("proxy_list_link", defaultValue: "")
        if !proxyListLink.isEmpty {
            Task {
                await fetchProxiesFromLink(proxyListLink)
            }
        }
        
        // Check proxies if enabled (handle both "True"/"False" and "1"/"0" for backward compatibility)
        let checkProxiesValue = DatabaseService.shared.getParameter("check_proxies", defaultValue: "False")
        let checkProxies = checkProxiesValue == "True" || checkProxiesValue == "1"
        if checkProxies && !proxyList.isEmpty {
            Task {
                await checkProxiesHealth()
            }
        } else {
            workingProxies = proxyList
        }
    }

    func reloadSettings() {
        loadSettings()
        LogService.shared.info("[VintedAPI] Settings reloaded")
    }

    // MARK: - Session Creation

    private func createSession(proxyString: String? = nil) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiTimeout
        config.timeoutIntervalForResource = AppConfig.apiTimeout * 2
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.urlCache = nil // Disable caching to avoid stale data
        
        // Configure connection pooling
        config.httpMaximumConnectionsPerHost = 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Configure proxy if provided
        if let proxyString = proxyString, let proxy = parseProxy(proxyString) {
            config.connectionProxyDictionary = proxy
            LogService.shared.info("[VintedAPI] Session created with proxy: \(proxyString)")
        }
        
        return URLSession(configuration: config)
    }

    // MARK: - Proxy Management

    private func fetchProxiesFromLink(_ urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await session.data(from: url)
            if let text = String(data: data, encoding: .utf8) {
                let fetchedProxies = text.split(separator: "\n")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                proxyList.append(contentsOf: fetchedProxies)
                LogService.shared.info("[VintedAPI] Fetched \(fetchedProxies.count) proxies from link")
            }
        } catch {
            LogService.shared.error("[VintedAPI] Failed to fetch proxies from link: \(error.localizedDescription)")
        }
    }

    private func checkProxiesHealth() async {
        let currentTime = Date().timeIntervalSince1970
        
        // Check if we need to recheck proxies
        if currentTime - lastProxyCheckTime < proxyCheckInterval && !workingProxies.isEmpty {
            return
        }
        
        lastProxyCheckTime = currentTime
        DatabaseService.shared.setParameter("last_proxy_check_time", value: "\(currentTime)")
        
        LogService.shared.info("[VintedAPI] Checking \(proxyList.count) proxies...")
        
        var checked: [String] = []
        let testUrl = URL(string: "https://www.vinted.fr/")!
        
        // Check proxies in parallel batches
        await withTaskGroup(of: (String, Bool).self) { group in
            for proxy in proxyList {
                group.addTask {
                    let isWorking = await self.testProxy(proxy, testUrl: testUrl)
                    return (proxy, isWorking)
                }
            }
            
            for await (proxy, isWorking) in group {
                if isWorking {
                    checked.append(proxy)
                }
            }
        }
        
        workingProxies = checked
        LogService.shared.info("[VintedAPI] Found \(workingProxies.count) working proxies out of \(proxyList.count)")
    }

    private func testProxy(_ proxyString: String, testUrl: URL) async -> Bool {
        guard let proxy = parseProxy(proxyString) else { return false }
        
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = proxy
        config.timeoutIntervalForRequest = proxyTestTimeout
        
        let testSession = URLSession(configuration: config)
        var request = URLRequest(url: testUrl)
        request.httpMethod = "HEAD"
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await testSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            return false
        }
        
        return false
    }

    private func parseProxy(_ proxyString: String) -> [AnyHashable: Any]? {
        // Parse proxy string format: "http://host:port" or "host:port"
        var host: String
        var port: Int
        
        if proxyString.contains("://") {
            let parts = proxyString.components(separatedBy: "://")
            let address = parts[1]
            let addressParts = address.components(separatedBy: ":")
            host = addressParts[0]
            port = Int(addressParts[1]) ?? 8080
        } else {
            let parts = proxyString.components(separatedBy: ":")
            host = parts[0]
            port = Int(parts[1]) ?? 8080
        }
        
        // iOS only supports HTTP proxy settings (HTTPS proxy constants are unavailable)
        return [
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPProxy: host,
            kCFNetworkProxiesHTTPPort: port
        ]
    }

    private func getRandomProxy() -> String? {
        if workingProxies.isEmpty {
            return nil
        }
        
        // Rotate through proxies
        let proxy = workingProxies[currentProxyIndex % workingProxies.count]
        currentProxyIndex += 1
        return proxy
    }

    private func ensureProxySession() {
        // Rotate proxy by recreating session periodically
        // iOS URLSession doesn't support per-request proxy, so we rotate at session level
        if !workingProxies.isEmpty {
            let proxyString = getRandomProxy()
            if proxyString != nil {
                // Only recreate session if we have a different proxy
                // For now, we'll recreate every N requests (handled in search method)
                // This is a simplified approach - full rotation would require tracking
            }
        }
    }
    
    private func rotateProxySession() {
        // Recreate session with new proxy for rotation
        if !workingProxies.isEmpty {
            let proxyString = getRandomProxy()
            self.session = createSession(proxyString: proxyString)
            LogService.shared.info("[VintedAPI] Rotated to new proxy session")
        }
    }

    // MARK: - Session Management

    private func warmUpSession() async {
        guard !sessionWarmed else { return }
        
        do {
            try await setCookies()
            sessionWarmed = true
            LogService.shared.info("[VintedAPI] Session warmed up")
        } catch {
            LogService.shared.warning("[VintedAPI] Failed to warm up session: \(error.localizedDescription)")
        }
    }

    private func ensureFreshCookies() async throws {
        let currentTime = Date().timeIntervalSince1970
        
        // Refresh cookies if needed
        if currentTime - lastCookieRefresh > cookieRefreshInterval || !sessionWarmed {
            try await setCookies()
            lastCookieRefresh = currentTime
        }
    }

    private func getRandomUserAgent() -> String {
        return userAgentsList.randomElement() ?? (userAgents.first ?? "Mozilla/5.0")
    }

    private func getRandomizedHeaders() -> [String: String] {
        var headers = defaultHeadersList
        
        // Randomize header order by creating a new dictionary
        // Add some variation to Accept-Language
        let languages = ["en-US,en;q=0.9", "en-GB,en;q=0.9", "fr-FR,fr;q=0.9", "de-DE,de;q=0.9"]
        headers["Accept-Language"] = languages.randomElement() ?? "en-US,en;q=0.9"
        
        return headers
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

        let headers = getRandomizedHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            LogService.shared.info("[VintedAPI] Cookies refreshed successfully")
        }
    }

    // MARK: - Request Timing

    private func addRequestDelay() async {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastRequest = currentTime - lastRequestTime
        
        // Calculate random delay with jitter
        let baseDelay = Double.random(in: minRequestDelay...maxRequestDelay)
        let jitter = Double.random(in: -0.5...0.5)
        let delay = max(0, baseDelay + jitter - timeSinceLastRequest)
        
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        lastRequestTime = Date().timeIntervalSince1970
    }

    private func exponentialBackoffWithJitter(attempt: Int, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 30.0) -> TimeInterval {
        let exponentialDelay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        let jitter = Double.random(in: 0...exponentialDelay * 0.3) // 30% jitter
        return exponentialDelay + jitter
    }

    // MARK: - URL Parsing

    private func convertBrandUrl(_ urlString: String) -> String {
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

        if let queryItems = urlComponents.queryItems {
            for item in queryItems {
                guard let value = item.value else { continue }

                let key = item.name.replacingOccurrences(of: "\\[.*\\]", with: "", options: .regularExpression)

                if params[key] != nil {
                    params[key] = "\(params[key]!),\(value)"
                } else {
                    params[key] = value
                }
            }
        }

        params["order"] = "newest_first"
        params.removeValue(forKey: "time")
        params.removeValue(forKey: "search_id")
        params.removeValue(forKey: "disabled_personalization")
        params.removeValue(forKey: "page")

        return (domain: host, params: params)
    }

    // MARK: - Search

    func search(url vintedUrl: String, itemsPerQuery: Int = AppConfig.defaultItemsPerQuery) async throws -> [VintedItem] {
        // Check network cooldown
        await checkNetworkCooldown()
        
        // Ensure fresh cookies
        try await ensureFreshCookies()
        
        // Add request delay with jitter
        await addRequestDelay()

        guard let parsed = parseUrl(vintedUrl) else {
            throw NSError(domain: "VintedAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Vinted URL"])
        }

        let domain = parsed.domain
        let params = parsed.params

        setLocale(from: vintedUrl)

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

        // Retry loop with improved error handling
        var tried = 0
        var newSession = false

        while tried < maxRetries {
            tried += 1

            var request = URLRequest(url: apiUrl, timeoutInterval: AppConfig.apiTimeout)
            request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
            request.setValue(domain, forHTTPHeaderField: "Host")

            let headers = getRandomizedHeaders()
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            // Rotate proxy session periodically (every 10 requests)
            if tried == 1 && !workingProxies.isEmpty && currentProxyIndex % 10 == 0 {
                rotateProxySession()
            }

            do {
                LogService.shared.info("[VintedAPI] Request attempt \(tried)/\(maxRetries) to \(apiUrl.absoluteString)")

                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }

                // Handle different status codes
                switch httpResponse.statusCode {
                case 200:
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let itemsArray = json?["items"] as? [[String: Any]] ?? []

                    LogService.shared.info("[VintedAPI] Success! Got \(itemsArray.count) items")

                    var items: [VintedItem] = []
                    for itemData in itemsArray {
                        items.append(VintedItem(from: itemData))
                    }

                    return items

                case 401, 404:
                    LogService.shared.warning("[VintedAPI] Got \(httpResponse.statusCode), refreshing cookies (attempt \(tried)/\(maxRetries))")

                    if tried < maxRetries {
                        try await setCookies()
                        let delay = exponentialBackoffWithJitter(attempt: tried)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                case 429:
                    // Rate limiting - exponential backoff with jitter
                    LogService.shared.warning("[VintedAPI] Rate limited (429), backing off...")
                    let delay = exponentialBackoffWithJitter(attempt: tried, baseDelay: 2.0, maxDelay: 60.0)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Try switching proxy if available
                    if !workingProxies.isEmpty {
                        currentProxyIndex += 1
                    }
                    
                    if tried < maxRetries {
                        continue
                    }

                case 403:
                    // Blocked - reset session and try different proxy
                    LogService.shared.warning("[VintedAPI] Blocked (403), resetting session...")
                    if !newSession {
                        newSession = true
                        tried = 0
                        try await setCookies()
                        
                        // Switch to next proxy
                        if !workingProxies.isEmpty {
                            currentProxyIndex += 1
                        }
                        
                        let delay = exponentialBackoffWithJitter(attempt: 1, baseDelay: 5.0)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                default:
                    LogService.shared.warning("[VintedAPI] Got status \(httpResponse.statusCode)")
                    if tried < maxRetries {
                        let delay = exponentialBackoffWithJitter(attempt: tried)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }

            } catch {
                LogService.shared.error("[VintedAPI] Request error: \(error.localizedDescription)")

                // Exponential backoff with jitter for errors
                if tried < maxRetries {
                    let delay = exponentialBackoffWithJitter(attempt: tried)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        LogService.shared.warning("[VintedAPI] All retries exhausted, returning empty array")
        return []
    }

    // MARK: - User Country

    func getUserCountry(userId: Int64, domain: String? = nil) async -> String {
        // Add request delay
        await addRequestDelay()
        
        let targetDomain = domain ?? currentLocale

        guard let url = URL(string: "https://\(targetDomain)/api/v2/users/\(userId)?localize=false") else {
            return "XX"
        }

        var request = URLRequest(url: url, timeoutInterval: AppConfig.apiTimeout)
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(targetDomain, forHTTPHeaderField: "Host")

        let headers = getRandomizedHeaders()
        for (key, value) in headers {
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

                guard let altUrl = URL(string: "https://\(targetDomain)/api/v2/users/\(userId)/items?page=1&per_page=1") else {
                    return "XX"
                }

                var altRequest = URLRequest(url: altUrl, timeoutInterval: AppConfig.apiTimeout)
                altRequest.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
                altRequest.setValue(targetDomain, forHTTPHeaderField: "Host")

                for (key, value) in headers {
                    altRequest.setValue(value, forHTTPHeaderField: key)
                }

                // Add delay before fallback
                try? await Task.sleep(nanoseconds: UInt64(exponentialBackoffWithJitter(attempt: 1) * 1_000_000_000))

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
