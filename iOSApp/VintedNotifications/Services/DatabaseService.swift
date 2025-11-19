//
//  DatabaseService.swift
//  Vinted Notifications
//
//  SQLite database manager using GRDB
//  Handles all CRUD operations for queries, items, allowlist, and parameters
//

import Foundation
import SQLite3

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    private var db: OpaquePointer?
    private let dbPath: String

    private init() {
        // Get documents directory
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent(AppConfig.dbName).path

        LogService.shared.info("Database path: \(dbPath)")
        openDatabase()
        createTables()
        initializeParameters()
    }

    private func openDatabase() {
        // Enable SQLite serialized mode for thread safety
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            LogService.shared.info("Successfully opened database in serialized mode")
        } else {
            LogService.shared.error("Failed to open database")
        }
    }

    private func createTables() {
        let queries = [
            // Queries table
            """
            CREATE TABLE IF NOT EXISTS queries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                query TEXT NOT NULL UNIQUE,
                query_name TEXT,
                last_item INTEGER,
                created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                is_active INTEGER DEFAULT 1
            )
            """,

            // Items table
            """
            CREATE TABLE IF NOT EXISTS items (
                id INTEGER PRIMARY KEY,
                title TEXT,
                brand_title TEXT,
                size_title TEXT,
                price TEXT,
                currency TEXT,
                photo TEXT,
                url TEXT,
                buy_url TEXT,
                created_at_ts INTEGER,
                raw_timestamp TEXT,
                query_id INTEGER,
                notified INTEGER DEFAULT 0,
                FOREIGN KEY (query_id) REFERENCES queries(id) ON DELETE CASCADE
            )
            """,

            // Allowlist table
            """
            CREATE TABLE IF NOT EXISTS allowlist (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                country_code TEXT NOT NULL UNIQUE
            )
            """,

            // Parameters table
            """
            CREATE TABLE IF NOT EXISTS parameters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT NOT NULL UNIQUE,
                value TEXT
            )
            """,

            // Indexes for performance
            "CREATE INDEX IF NOT EXISTS idx_items_query_id ON items(query_id)",
            "CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at_ts DESC)",
            "CREATE INDEX IF NOT EXISTS idx_queries_is_active ON queries(is_active)"
        ]

        for query in queries {
            if sqlite3_exec(db, query, nil, nil, nil) == SQLITE_OK {
                // Success
            } else {
                LogService.shared.error("Failed to execute: \(query)")
            }
        }

        LogService.shared.info("Database tables created successfully")
    }

    private func initializeParameters() {
        // Convert userAgents array and defaultHeaders dict to JSON strings
        let userAgentsJSON = try? JSONSerialization.data(withJSONObject: userAgents, options: [])
        let userAgentsString = userAgentsJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let defaultHeadersJSON = try? JSONSerialization.data(withJSONObject: defaultHeaders, options: [])
        let defaultHeadersString = defaultHeadersJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let defaultParams: [(String, String)] = [
            ("items_per_query", "\(AppConfig.defaultItemsPerQuery)"),
            ("query_refresh_delay", "\(AppConfig.defaultRefreshDelay)"),
            ("message_template", defaultMessageTemplate),
            ("banwords", ""),
            ("time_window", "\(AppConfig.defaultTimeWindow)"),
            ("notifications_enabled", "1"),
            ("notification_mode", NotificationMode.precise.rawValue),
            ("user_agents", userAgentsString),
            ("default_headers", defaultHeadersString),
            ("proxy_list", ""),
            ("proxy_list_link", ""),
            ("check_proxies", "False"),
            ("last_proxy_check_time", "0")
        ]

        for (key, value) in defaultParams {
            let query = "INSERT OR IGNORE INTO parameters (key, value) VALUES (?, ?)"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (value as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Parameters

    func getParameter(_ key: String, defaultValue: String = "") -> String {
        let query = "SELECT value FROM parameters WHERE key = ?"
        var statement: OpaquePointer?
        var result = defaultValue

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    result = String(cString: cString)
                }
            }
        }
        sqlite3_finalize(statement)
        return result
    }

    func setParameter(_ key: String, value: String) {
        let query = "INSERT OR REPLACE INTO parameters (key, value) VALUES (?, ?)"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (value as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            LogService.shared.info("Parameter saved: \(key) = \(value)")
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Queries

    func addQuery(query: String, queryName: String? = nil) throws -> Int64 {
        let name = queryName ?? VintedQuery.extractQueryName(from: query)
        let sql = "INSERT INTO queries (query, query_name) VALUES (?, ?)"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (query as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                let id = sqlite3_last_insert_rowid(db)
                sqlite3_finalize(statement)
                LogService.shared.info("Query added: \(name)")
                return id
            } else {
                sqlite3_finalize(statement)
                throw NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Query already exists"])
            }
        }
        sqlite3_finalize(statement)
        throw NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to add query"])
    }

    func getQueries(activeOnly: Bool = false) -> [VintedQuery] {
        let sql = activeOnly
            ? "SELECT * FROM queries WHERE is_active = 1 ORDER BY id DESC"
            : "SELECT * FROM queries ORDER BY id DESC"
        var statement: OpaquePointer?
        var queries: [VintedQuery] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let query = String(cString: sqlite3_column_text(statement, 1))
                let queryName = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
                let lastItem = sqlite3_column_type(statement, 3) != SQLITE_NULL ? sqlite3_column_int64(statement, 3) : nil
                let createdAt = sqlite3_column_int64(statement, 4)
                let isActive = sqlite3_column_int(statement, 5) == 1

                queries.append(VintedQuery(
                    id: id,
                    query: query,
                    queryName: queryName,
                    lastItem: lastItem,
                    createdAt: createdAt,
                    isActive: isActive
                ))
            }
        }
        sqlite3_finalize(statement)
        return queries
    }

    func updateQuery(id: Int64, query: String, queryName: String?) {
        let sql = "UPDATE queries SET query = ?, query_name = ? WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (query as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, ((queryName ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 3, id)
            sqlite3_step(statement)
            LogService.shared.info("Query updated: \(id)")
        }
        sqlite3_finalize(statement)
    }

    func updateQueryLastItem(queryId: Int64, timestamp: Int64) {
        let sql = "UPDATE queries SET last_item = ? WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, timestamp)
            sqlite3_bind_int64(statement, 2, queryId)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func deleteQuery(id: Int64) {
        let sql = "DELETE FROM queries WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            sqlite3_step(statement)
            LogService.shared.info("Query deleted: \(id)")
        }
        sqlite3_finalize(statement)
    }

    func deleteAllQueries() {
        sqlite3_exec(db, "DELETE FROM queries", nil, nil, nil)
        LogService.shared.info("All queries deleted")
    }

    // MARK: - Items

    func addItem(_ item: VintedItem) {
        let sql = """
        INSERT OR IGNORE INTO items
        (id, title, brand_title, size_title, price, currency, photo, url, buy_url,
         created_at_ts, raw_timestamp, query_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, item.id)
            sqlite3_bind_text(statement, 2, (item.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, ((item.brandTitle ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, ((item.sizeTitle ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (item.price as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (item.currency as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, ((item.photo ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, ((item.url ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, ((item.buyUrl ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 10, item.createdAtTs)
            sqlite3_bind_text(statement, 11, ((item.rawTimestamp ?? "") as NSString).utf8String, -1, nil)

            if let queryId = item.queryId {
                sqlite3_bind_int64(statement, 12, queryId)
            } else {
                sqlite3_bind_null(statement, 12)
            }

            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func getItems(queryId: Int64? = nil, limit: Int = 1000) -> [VintedItem] {
        var sql = "SELECT * FROM items"
        if queryId != nil {
            sql += " WHERE query_id = ?"
        }
        sql += " ORDER BY created_at_ts DESC LIMIT ?"

        var statement: OpaquePointer?
        var items: [VintedItem] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            var bindIndex: Int32 = 1
            if let qid = queryId {
                sqlite3_bind_int64(statement, bindIndex, qid)
                bindIndex += 1
            }
            sqlite3_bind_int(statement, bindIndex, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let title = String(cString: sqlite3_column_text(statement, 1))
                let brandTitle = sqlite3_column_text(statement, 2).map { String(cString: $0) }
                let sizeTitle = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let price = String(cString: sqlite3_column_text(statement, 4))
                let currency = String(cString: sqlite3_column_text(statement, 5))
                let photo = sqlite3_column_text(statement, 6).map { String(cString: $0) }
                let url = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let buyUrl = sqlite3_column_text(statement, 8).map { String(cString: $0) }
                let createdAtTs = sqlite3_column_int64(statement, 9)
                let rawTimestamp = sqlite3_column_text(statement, 10).map { String(cString: $0) }
                let itemQueryId = sqlite3_column_type(statement, 11) != SQLITE_NULL ? sqlite3_column_int64(statement, 11) : nil
                let notified = sqlite3_column_int(statement, 12) == 1

                items.append(VintedItem(
                    id: id,
                    title: title,
                    brandTitle: brandTitle,
                    sizeTitle: sizeTitle,
                    price: price,
                    currency: currency,
                    photo: photo,
                    url: url,
                    buyUrl: buyUrl,
                    createdAtTs: createdAtTs,
                    rawTimestamp: rawTimestamp,
                    queryId: itemQueryId,
                    notified: notified
                ))
            }
        }
        sqlite3_finalize(statement)
        return items
    }

    func itemExists(itemId: Int64) -> Bool {
        let sql = "SELECT COUNT(*) FROM items WHERE id = ?"
        var statement: OpaquePointer?
        var exists = false

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, itemId)
            if sqlite3_step(statement) == SQLITE_ROW {
                exists = sqlite3_column_int(statement, 0) > 0
            }
        }
        sqlite3_finalize(statement)
        return exists
    }

    func deleteAllItems() {
        sqlite3_exec(db, "DELETE FROM items", nil, nil, nil)
        LogService.shared.info("All items deleted")
    }

    // MARK: - Allowlist

    func getAllowlist() -> [String] {
        let sql = "SELECT country_code FROM allowlist ORDER BY country_code"
        var statement: OpaquePointer?
        var countries: [String] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let code = String(cString: sqlite3_column_text(statement, 0))
                countries.append(code)
            }
        }
        sqlite3_finalize(statement)
        return countries
    }

    func addToAllowlist(_ countryCode: String) {
        let sql = "INSERT OR IGNORE INTO allowlist (country_code) VALUES (?)"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (countryCode.uppercased() as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            LogService.shared.info("Added to allowlist: \(countryCode)")
        }
        sqlite3_finalize(statement)
    }

    func removeFromAllowlist(_ countryCode: String) {
        let sql = "DELETE FROM allowlist WHERE country_code = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (countryCode.uppercased() as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
            LogService.shared.info("Removed from allowlist: \(countryCode)")
        }
        sqlite3_finalize(statement)
    }

    func clearAllowlist() {
        sqlite3_exec(db, "DELETE FROM allowlist", nil, nil, nil)
        LogService.shared.info("Allowlist cleared")
    }

    // MARK: - Statistics

    func getStatistics() -> (totalItems: Int, totalQueries: Int, itemsToday: Int) {
        var totalItems = 0
        var totalQueries = 0
        var itemsToday = 0

        // Total items
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM items", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                totalItems = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)

        // Total queries
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM queries WHERE is_active = 1", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                totalQueries = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)

        // Items today
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayTimestamp = Int64(todayStart.timeIntervalSince1970 * 1000)

        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM items WHERE created_at_ts >= ?", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, todayTimestamp)
            if sqlite3_step(statement) == SQLITE_ROW {
                itemsToday = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)

        return (totalItems, totalQueries, itemsToday)
    }

    deinit {
        sqlite3_close(db)
    }
}
