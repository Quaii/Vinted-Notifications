// App Configuration
export const APP_CONFIG = {
  // Default settings
  DEFAULT_REFRESH_DELAY: 60, // seconds
  DEFAULT_ITEMS_PER_QUERY: 20,
  DEFAULT_TIME_WINDOW: 1200, // 20 minutes in seconds

  // Database
  DB_NAME: 'vinted_notifications.db',
  DB_VERSION: '1.0',
  DB_DISPLAY_NAME: 'Vinted Notifications Database',
  DB_SIZE: 5 * 1024 * 1024, // 5MB

  // API
  API_MAX_RETRIES: 3,
  API_TIMEOUT: 10000, // 10 seconds

  // Notification
  NOTIFICATION_CHANNEL_ID: 'vinted_notifications',
  NOTIFICATION_CHANNEL_NAME: 'Vinted New Items',

  // Background fetch
  BACKGROUND_FETCH_INTERVAL: 15, // minimum interval in minutes for iOS
};

// Vinted domains
export const VINTED_DOMAINS = [
  'vinted.fr',
  'vinted.de',
  'vinted.co.uk',
  'vinted.com',
  'vinted.es',
  'vinted.it',
  'vinted.pl',
  'vinted.be',
  'vinted.nl',
  'vinted.lt',
  'vinted.cz',
  'vinted.se',
  'vinted.at',
  'vinted.pt',
  'vinted.lu',
];

// Default message template (PLAIN TEXT, NO EMOJIS per user requirement)
export const DEFAULT_MESSAGE_TEMPLATE = `Title: {title}
Price: {price}
Brand: {brand}
Size: {size}`;

// Notification modes
export const NOTIFICATION_MODES = {
  PRECISE: 'precise', // Individual notification for each item with details
  COMPACT: 'compact', // Summary notification "X new items found"
};

// User Agents for rotation
export const USER_AGENTS = [
  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1',
];

// Default headers for API requests
export const DEFAULT_HEADERS = {
  'Accept': 'application/json, text/plain, */*',
  'Accept-Language': 'en-US,en;q=0.9',
  'Content-Type': 'application/json',
};
