import SQLite from 'react-native-sqlite-storage';
import {APP_CONFIG, DEFAULT_MESSAGE_TEMPLATE} from '../constants/config';
import {VintedItem} from '../models/Item';
import {VintedQuery} from '../models/Query';

SQLite.DEBUG(false);
SQLite.enablePromise(true);

/**
 * Database Service
 * Handles all database operations for the app
 */
class DatabaseService {
  constructor() {
    this.db = null;
  }

  /**
   * Initialize the database
   */
  async init() {
    try {
      this.db = await SQLite.openDatabase({
        name: APP_CONFIG.DB_NAME,
        location: 'default',
      });

      console.log('Database opened successfully');
      await this.createTables();
      await this.initializeParameters();
      return true;
    } catch (error) {
      console.error('Failed to initialize database:', error);
      throw error;
    }
  }

  /**
   * Create database tables
   */
  async createTables() {
    const queries = [
      // Queries table
      `CREATE TABLE IF NOT EXISTS queries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        query_name TEXT,
        last_item INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        is_active INTEGER DEFAULT 1
      )`,

      // Items table
      `CREATE TABLE IF NOT EXISTS items (
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
      )`,

      // Allowlist table
      `CREATE TABLE IF NOT EXISTS allowlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        country_code TEXT NOT NULL UNIQUE
      )`,

      // Parameters table
      `CREATE TABLE IF NOT EXISTS parameters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT
      )`,

      // Create indexes for better performance
      `CREATE INDEX IF NOT EXISTS idx_items_query_id ON items(query_id)`,
      `CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at_ts DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_queries_is_active ON queries(is_active)`,
    ];

    for (const query of queries) {
      await this.db.executeSql(query);
    }

    console.log('Database tables created successfully');
  }

  /**
   * Initialize default parameters
   */
  async initializeParameters() {
    const defaultParams = [
      {key: 'items_per_query', value: APP_CONFIG.DEFAULT_ITEMS_PER_QUERY.toString()},
      {key: 'query_refresh_delay', value: APP_CONFIG.DEFAULT_REFRESH_DELAY.toString()},
      {key: 'message_template', value: DEFAULT_MESSAGE_TEMPLATE},
      {key: 'banwords', value: ''},
      {key: 'time_window', value: APP_CONFIG.DEFAULT_TIME_WINDOW.toString()},
      {key: 'notifications_enabled', value: '1'},
    ];

    for (const param of defaultParams) {
      await this.db.executeSql(
        'INSERT OR IGNORE INTO parameters (key, value) VALUES (?, ?)',
        [param.key, param.value],
      );
    }
  }

  /**
   * Get a parameter value
   */
  async getParameter(key, defaultValue = null) {
    try {
      const [results] = await this.db.executeSql(
        'SELECT value FROM parameters WHERE key = ?',
        [key],
      );

      if (results.rows.length > 0) {
        return results.rows.item(0).value;
      }

      return defaultValue;
    } catch (error) {
      console.error('Failed to get parameter:', error);
      return defaultValue;
    }
  }

  /**
   * Set a parameter value
   */
  async setParameter(key, value) {
    try {
      await this.db.executeSql(
        'INSERT OR REPLACE INTO parameters (key, value) VALUES (?, ?)',
        [key, value.toString()],
      );
      return true;
    } catch (error) {
      console.error('Failed to set parameter:', error);
      return false;
    }
  }

  /**
   * Add a new query
   */
  async addQuery(query, queryName = null) {
    try {
      const name = queryName || new VintedQuery({query}).query_name;
      const [result] = await this.db.executeSql(
        'INSERT INTO queries (query, query_name) VALUES (?, ?)',
        [query, name],
      );

      return result.insertId;
    } catch (error) {
      console.error('Failed to add query:', error);
      throw error;
    }
  }

  /**
   * Get all queries
   */
  async getQueries(activeOnly = false) {
    try {
      const sql = activeOnly
        ? 'SELECT * FROM queries WHERE is_active = 1 ORDER BY id DESC'
        : 'SELECT * FROM queries ORDER BY id DESC';

      const [results] = await this.db.executeSql(sql);

      const queries = [];
      for (let i = 0; i < results.rows.length; i++) {
        const row = results.rows.item(i);
        queries.push(new VintedQuery({
          id: row.id,
          query: row.query,
          queryName: row.query_name,
          lastItem: row.last_item,
          createdAt: row.created_at,
          is_active: row.is_active === 1,
        }));
      }

      return queries;
    } catch (error) {
      console.error('Failed to get queries:', error);
      return [];
    }
  }

  /**
   * Get a single query by ID
   */
  async getQuery(id) {
    try {
      const [results] = await this.db.executeSql(
        'SELECT * FROM queries WHERE id = ?',
        [id],
      );

      if (results.rows.length > 0) {
        const row = results.rows.item(0);
        return new VintedQuery({
          id: row.id,
          query: row.query,
          queryName: row.query_name,
          lastItem: row.last_item,
          createdAt: row.created_at,
          is_active: row.is_active === 1,
        });
      }

      return null;
    } catch (error) {
      console.error('Failed to get query:', error);
      return null;
    }
  }

  /**
   * Update query last item timestamp
   */
  async updateQueryLastItem(queryId, timestamp) {
    try {
      await this.db.executeSql(
        'UPDATE queries SET last_item = ? WHERE id = ?',
        [timestamp, queryId],
      );
      return true;
    } catch (error) {
      console.error('Failed to update query last item:', error);
      return false;
    }
  }

  /**
   * Delete a query
   */
  async deleteQuery(id) {
    try {
      await this.db.executeSql('DELETE FROM queries WHERE id = ?', [id]);
      return true;
    } catch (error) {
      console.error('Failed to delete query:', error);
      return false;
    }
  }

  /**
   * Delete all queries
   */
  async deleteAllQueries() {
    try {
      await this.db.executeSql('DELETE FROM queries');
      return true;
    } catch (error) {
      console.error('Failed to delete all queries:', error);
      return false;
    }
  }

  /**
   * Add an item
   */
  async addItem(item) {
    try {
      const itemData = item instanceof VintedItem ? item : new VintedItem(item);
      const json = itemData.toJSON();

      await this.db.executeSql(
        `INSERT OR IGNORE INTO items
         (id, title, brand_title, size_title, price, currency, photo, url, buy_url,
          created_at_ts, raw_timestamp, query_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          json.id,
          json.title,
          json.brand_title,
          json.size_title,
          json.price,
          json.currency,
          json.photo,
          json.url,
          json.buy_url,
          json.created_at_ts,
          json.raw_timestamp,
          json.query_id,
        ],
      );

      return true;
    } catch (error) {
      console.error('Failed to add item:', error);
      return false;
    }
  }

  /**
   * Check if item exists
   */
  async itemExists(itemId) {
    try {
      const [results] = await this.db.executeSql(
        'SELECT COUNT(*) as count FROM items WHERE id = ?',
        [itemId],
      );

      return results.rows.item(0).count > 0;
    } catch (error) {
      console.error('Failed to check item existence:', error);
      return false;
    }
  }

  /**
   * Get items
   */
  async getItems(queryId = null, limit = 100) {
    try {
      let sql = 'SELECT * FROM items';
      const params = [];

      if (queryId) {
        sql += ' WHERE query_id = ?';
        params.push(queryId);
      }

      sql += ' ORDER BY created_at_ts DESC LIMIT ?';
      params.push(limit);

      const [results] = await this.db.executeSql(sql, params);

      const items = [];
      for (let i = 0; i < results.rows.length; i++) {
        const row = results.rows.item(i);
        items.push(new VintedItem({
          id: row.id,
          title: row.title,
          brandTitle: row.brand_title,
          sizeTitle: row.size_title,
          price: row.price,
          currency: row.currency,
          photo: row.photo,
          url: row.url,
          buyUrl: row.buy_url,
          createdAtTs: row.created_at_ts,
          rawTimestamp: row.raw_timestamp,
          queryId: row.query_id,
        }));
      }

      return items;
    } catch (error) {
      console.error('Failed to get items:', error);
      return [];
    }
  }

  /**
   * Get statistics
   */
  async getStatistics() {
    try {
      // Total items
      const [totalItemsResult] = await this.db.executeSql(
        'SELECT COUNT(*) as count FROM items',
      );
      const totalItems = totalItemsResult.rows.item(0).count;

      // Total queries
      const [totalQueriesResult] = await this.db.executeSql(
        'SELECT COUNT(*) as count FROM queries WHERE is_active = 1',
      );
      const totalQueries = totalQueriesResult.rows.item(0).count;

      // Items today
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const todayTimestamp = todayStart.getTime();

      const [itemsTodayResult] = await this.db.executeSql(
        'SELECT COUNT(*) as count FROM items WHERE created_at_ts >= ?',
        [todayTimestamp],
      );
      const itemsToday = itemsTodayResult.rows.item(0).count;

      return {
        totalItems,
        totalQueries,
        itemsToday,
      };
    } catch (error) {
      console.error('Failed to get statistics:', error);
      return {
        totalItems: 0,
        totalQueries: 0,
        itemsToday: 0,
      };
    }
  }

  /**
   * Get allowlist countries
   */
  async getAllowlist() {
    try {
      const [results] = await this.db.executeSql(
        'SELECT country_code FROM allowlist ORDER BY country_code',
      );

      const countries = [];
      for (let i = 0; i < results.rows.length; i++) {
        countries.push(results.rows.item(i).country_code);
      }

      return countries;
    } catch (error) {
      console.error('Failed to get allowlist:', error);
      return [];
    }
  }

  /**
   * Add country to allowlist
   */
  async addToAllowlist(countryCode) {
    try {
      await this.db.executeSql(
        'INSERT OR IGNORE INTO allowlist (country_code) VALUES (?)',
        [countryCode.toUpperCase()],
      );
      return true;
    } catch (error) {
      console.error('Failed to add to allowlist:', error);
      return false;
    }
  }

  /**
   * Remove country from allowlist
   */
  async removeFromAllowlist(countryCode) {
    try {
      await this.db.executeSql(
        'DELETE FROM allowlist WHERE country_code = ?',
        [countryCode.toUpperCase()],
      );
      return true;
    } catch (error) {
      console.error('Failed to remove from allowlist:', error);
      return false;
    }
  }

  /**
   * Clear allowlist
   */
  async clearAllowlist() {
    try {
      await this.db.executeSql('DELETE FROM allowlist');
      return true;
    } catch (error) {
      console.error('Failed to clear allowlist:', error);
      return false;
    }
  }

  /**
   * Close database connection
   */
  async close() {
    if (this.db) {
      await this.db.close();
      console.log('Database closed');
    }
  }
}

// Export singleton instance
export default new DatabaseService();
