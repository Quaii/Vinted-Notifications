import BackgroundFetch from 'react-native-background-fetch';
import VintedAPI from '../api/VintedAPI';
import DatabaseService from './DatabaseService';
import NotificationService from './NotificationService';
import {VintedItem} from '../models/Item';
import {APP_CONFIG} from '../constants/config';

/**
 * Monitoring Service
 * Handles background monitoring of Vinted queries
 * AUTO-STARTS when queries are added (like Python version)
 */
class MonitoringService {
  constructor() {
    this.isRunning = false;
    this.intervalId = null;
    this.initialized = false;
  }

  /**
   * Initialize monitoring state from database
   * Called on app launch to restore monitoring if it was running
   */
  async initializeState() {
    if (this.initialized) return;

    try {
      // Check if monitoring was previously running
      const wasRunning = await DatabaseService.getParameter('monitoring_enabled', 'false');
      const queries = await DatabaseService.getQueries(true);

      // Auto-start if there are active queries (like Python version)
      if (queries && queries.length > 0 && wasRunning === 'true') {
        console.log('[MonitoringService] Restoring monitoring state - auto-starting');
        await this.startMonitoring();
      }

      this.initialized = true;
    } catch (error) {
      console.error('[MonitoringService] Failed to initialize state:', error);
      this.initialized = true;
    }
  }

  /**
   * Initialize background fetch for iOS
   */
  async initBackgroundFetch() {
    try {
      const status = await BackgroundFetch.configure(
        {
          minimumFetchInterval: APP_CONFIG.BACKGROUND_FETCH_INTERVAL,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiredNetworkType: BackgroundFetch.NETWORK_TYPE_ANY,
        },
        async taskId => {
          console.log('[BackgroundFetch] Task started:', taskId);

          try {
            await this.checkAllQueries();
            BackgroundFetch.finish(taskId);
          } catch (error) {
            console.error('[BackgroundFetch] Error:', error);
            BackgroundFetch.finish(taskId);
          }
        },
        async taskId => {
          console.log('[BackgroundFetch] Task timeout:', taskId);
          BackgroundFetch.finish(taskId);
        },
      );

      console.log('[BackgroundFetch] Status:', status);
      return status;
    } catch (error) {
      console.error('[BackgroundFetch] Failed to configure:', error);
      return null;
    }
  }

  /**
   * Start monitoring (foreground)
   * Automatically persists state to database
   */
  async startMonitoring() {
    if (this.isRunning) {
      console.log('Monitoring already running');
      return;
    }

    console.log('Starting monitoring...');
    this.isRunning = true;

    // Persist monitoring state
    await DatabaseService.setParameter('monitoring_enabled', 'true');

    // Initial check
    await this.checkAllQueries();

    // Set up interval
    const refreshDelay = await DatabaseService.getParameter(
      'query_refresh_delay',
      APP_CONFIG.DEFAULT_REFRESH_DELAY,
    );

    this.intervalId = setInterval(async () => {
      if (this.isRunning) {
        await this.checkAllQueries();
      }
    }, parseInt(refreshDelay) * 1000);

    console.log(`Monitoring started with ${refreshDelay}s interval`);
  }

  /**
   * Stop monitoring (foreground)
   * Automatically persists state to database
   */
  async stopMonitoring() {
    if (!this.isRunning) {
      console.log('Monitoring not running');
      return;
    }

    console.log('Stopping monitoring...');
    this.isRunning = false;

    // Persist monitoring state
    await DatabaseService.setParameter('monitoring_enabled', 'false');

    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }

    console.log('Monitoring stopped');
  }

  /**
   * Check all active queries for new items
   */
  async checkAllQueries() {
    try {
      console.log('Checking all queries...');

      // Get all active queries
      const queries = await DatabaseService.getQueries(true);
      if (queries.length === 0) {
        console.log('No active queries to check');
        return;
      }

      const itemsPerQuery = await DatabaseService.getParameter(
        'items_per_query',
        APP_CONFIG.DEFAULT_ITEMS_PER_QUERY,
      );

      const newItems = [];

      // Check each query
      for (const query of queries) {
        try {
          const items = await this.checkQuery(query, parseInt(itemsPerQuery));
          if (items.length > 0) {
            newItems.push(...items);
          }
        } catch (error) {
          console.error(`Failed to check query ${query.id}:`, error.message);
        }
      }

      // Send notifications for new items
      if (newItems.length > 0) {
        console.log(`Found ${newItems.length} new items`);
        await NotificationService.sendBulkNotifications(newItems);
      } else {
        console.log('No new items found');
      }

      return newItems;
    } catch (error) {
      console.error('Failed to check queries:', error);
      return [];
    }
  }

  /**
   * Check a single query for new items
   */
  async checkQuery(query, itemsPerQuery) {
    console.log(`Checking query: ${query.query_name} (ID: ${query.id})`);

    try {
      // Fetch items from API
      const rawItems = await VintedAPI.search(query.query, itemsPerQuery);
      if (!rawItems || rawItems.length === 0) {
        console.log(`No items found for query ${query.id}`);
        return [];
      }

      const newItems = [];
      const timeWindow = await DatabaseService.getParameter(
        'time_window',
        APP_CONFIG.DEFAULT_TIME_WINDOW,
      );
      const timeWindowMs = parseInt(timeWindow) * 1000;
      const now = Date.now();

      // Get allowlist and banwords
      const allowlist = await DatabaseService.getAllowlist();
      const banwords = await DatabaseService.getParameter('banwords', '');
      const banwordList = banwords
        ? banwords.split('|||').map(w => w.trim().toLowerCase())
        : [];

      let latestTimestamp = query.last_item || 0;

      // Process items in reverse order (oldest first), like Python version
      const reversedItems = [...rawItems].reverse();

      for (const rawItem of reversedItems) {
        try {
          // Parse item
          const item = this.parseItem(rawItem, query.id);
          if (!item) continue;

          // Timestamp-based deduplication (more efficient than DB check)
          if (item.created_at_ts <= latestTimestamp) {
            console.log(`Item ${item.id} timestamp ${item.created_at_ts} <= last ${latestTimestamp}, skipping`);
            continue;
          }

          // Check if item is within time window
          if (now - item.created_at_ts > timeWindowMs) {
            console.log(`Item ${item.id} is too old, skipping`);
            continue;
          }

          // Check if item already exists in database
          const exists = await DatabaseService.itemExists(item.id);
          if (exists) {
            console.log(`Item ${item.id} already exists in DB, skipping`);
            continue;
          }

          // Apply allowlist filter (fetch user country if needed)
          if (allowlist.length > 0) {
            let userCountry = rawItem.user?.country_iso_code || rawItem.user?.country_code;

            // If country not in response, fetch it via API
            if (!userCountry && rawItem.user?.id) {
              userCountry = await VintedAPI.getUserCountry(rawItem.user.id, query.getDomain());
            }

            if (userCountry && !allowlist.includes(userCountry)) {
              console.log(`Item ${item.id} filtered by allowlist (${userCountry})`);
              continue;
            }
          }

          // Apply banwords filter
          if (banwordList.length > 0) {
            const titleLower = item.title.toLowerCase();
            const hasBanword = banwordList.some(word => titleLower.includes(word));
            if (hasBanword) {
              console.log(`Item ${item.id} filtered by banwords`);
              continue;
            }
          }

          // Add to database
          await DatabaseService.addItem(item);
          newItems.push(item);

          // Update latest timestamp
          if (item.created_at_ts > latestTimestamp) {
            latestTimestamp = item.created_at_ts;
          }

          console.log(`New item found: ${item.title} (${item.id})`);
        } catch (error) {
          console.error('Failed to process item:', error);
        }
      }

      // Update query last item timestamp
      if (latestTimestamp > (query.last_item || 0)) {
        await DatabaseService.updateQueryLastItem(query.id, latestTimestamp);
      }

      return newItems;
    } catch (error) {
      console.error(`Failed to check query ${query.id}:`, error);
      return [];
    }
  }

  /**
   * Parse raw item data into VintedItem
   */
  parseItem(rawItem, queryId) {
    try {
      // Extract timestamp
      let timestamp;
      if (rawItem.photo?.high_resolution?.timestamp) {
        timestamp = parseInt(rawItem.photo.high_resolution.timestamp) * 1000;
      } else if (rawItem.created_at_ts) {
        timestamp = parseInt(rawItem.created_at_ts) * 1000;
      } else {
        timestamp = Date.now();
      }

      // Extract price and currency (matching Python desktop app structure)
      const price = rawItem.price?.amount || rawItem.price || '0.00';
      const currency = rawItem.price?.currency_code || rawItem.currency || '€';

      // Extract photo URL (matching Python desktop app structure)
      const photoUrl = rawItem.photo?.url || rawItem.photo || '';

      // Build item (buyUrl will be auto-generated in constructor)
      const item = new VintedItem({
        id: rawItem.id,
        title: rawItem.title,
        brandTitle: rawItem.brand_title || rawItem.brand || '',
        sizeTitle: rawItem.size_title || rawItem.size || '',
        price: price,
        currency: currency,
        photo: photoUrl,
        url: rawItem.url,
        createdAtTs: timestamp,
        rawTimestamp: rawItem.photo?.high_resolution?.timestamp || '',
        queryId: queryId,
      });

      return item;
    } catch (error) {
      console.error('Failed to parse item:', error);
      return null;
    }
  }

  /**
   * Check if monitoring is running
   */
  isMonitoringRunning() {
    return this.isRunning;
  }

  /**
   * Auto-start monitoring when first query is added (like Python version)
   * Call this after adding a query
   */
  async ensureMonitoringStarted() {
    const queries = await DatabaseService.getQueries(true);

    // If there are queries and monitoring is not running, start it
    if (queries && queries.length > 0 && !this.isRunning) {
      console.log('[MonitoringService] First query added - auto-starting monitoring');
      await this.startMonitoring();
    }
  }

  /**
   * Get monitoring status
   */
  async getStatus() {
    const refreshDelay = await DatabaseService.getParameter(
      'query_refresh_delay',
      APP_CONFIG.DEFAULT_REFRESH_DELAY,
    );
    const itemsPerQuery = await DatabaseService.getParameter(
      'items_per_query',
      APP_CONFIG.DEFAULT_ITEMS_PER_QUERY,
    );
    const queries = await DatabaseService.getQueries(true);

    return {
      isRunning: this.isRunning,
      refreshDelay: parseInt(refreshDelay),
      itemsPerQuery: parseInt(itemsPerQuery),
      activeQueries: queries.length,
    };
  }
}

// Export singleton instance
export default new MonitoringService();
