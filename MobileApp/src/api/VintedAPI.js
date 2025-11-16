import axios from 'axios';
import {APP_CONFIG, USER_AGENTS, DEFAULT_HEADERS} from '../constants/config';

/**
 * Vinted API Client
 * Replicates Python requester.py with full anti-detection measures
 */
export class VintedAPI {
  constructor() {
    this.locale = 'www.vinted.fr';
    this.authUrl = `https://${this.locale}/`;
    this.headers = {};
    this.axiosInstance = null;
    this.MAX_RETRIES = 3;
    this.currentProxy = null;
    this.initializeSession();
  }

  /**
   * Initialize a new axios instance (session)
   */
  initializeSession() {
    const userAgent = this.getRandomUserAgent();

    this.headers = {
      ...DEFAULT_HEADERS,
      'User-Agent': userAgent,
      'Host': this.locale,
    };

    this.axiosInstance = axios.create({
      timeout: APP_CONFIG.API_TIMEOUT,
      headers: this.headers,
      withCredentials: true,
      validateStatus: null, // Don't throw on any status code
    });
  }

  /**
   * Get a random user agent
   */
  getRandomUserAgent() {
    return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];
  }

  /**
   * Set locale and update headers
   */
  setLocale(url) {
    try {
      const urlObj = new URL(url);
      const newLocale = urlObj.hostname;

      if (newLocale !== this.locale) {
        this.locale = newLocale;
        this.authUrl = `https://${this.locale}/`;

        // Update headers with new locale
        const userAgent = this.getRandomUserAgent();
        this.headers = {
          ...DEFAULT_HEADERS,
          'User-Agent': userAgent,
          'Host': this.locale,
        };

        // Update axios instance headers
        if (this.axiosInstance) {
          this.axiosInstance.defaults.headers = this.headers;
        }
      }
    } catch (error) {
      console.error('Failed to set locale:', error);
    }
  }

  /**
   * Set cookies via HEAD request (replicates Python set_cookies)
   */
  async setCookies() {
    try {
      console.log(`[VintedAPI] Refreshing cookies for ${this.locale}`);
      const response = await this.axiosInstance.head(this.authUrl);

      if (response.status === 200) {
        console.log('[VintedAPI] Cookies refreshed successfully');
        return true;
      }

      console.warn(`[VintedAPI] Cookie refresh returned status ${response.status}`);
      return false;
    } catch (error) {
      console.error('[VintedAPI] Failed to refresh cookies:', error.message);
      return false;
    }
  }

  /**
   * Convert brand URL to catalog URL
   * Example: https://www.vinted.fr/brand/123-nike → /catalog?brand_ids=123
   */
  convertBrandUrl(url) {
    try {
      const brandMatch = url.match(/\/brand\/(\d+)-/);
      if (brandMatch) {
        const brandId = brandMatch[1];
        const urlObj = new URL(url);
        return `https://${urlObj.hostname}/catalog?brand_ids=${brandId}`;
      }
      return url;
    } catch (error) {
      return url;
    }
  }

  /**
   * Parse Vinted URL and extract parameters (handles array params)
   * Matches Python's permissive behavior - accepts any valid URL
   */
  parseUrl(url) {
    try {
      // Convert brand URLs first
      url = this.convertBrandUrl(url);

      const urlObj = new URL(url);
      const domain = urlObj.hostname;
      const params = {};

      // Extract query parameters, handling arrays
      const searchParams = urlObj.search.substring(1);
      if (searchParams) {
        const pairs = searchParams.split('&');
        for (const pair of pairs) {
          if (!pair) continue; // Skip empty params

          const [key, value = ''] = pair.split('=');

          try {
            const decodedKey = decodeURIComponent(key || '');
            const decodedValue = decodeURIComponent(value || '');

            if (!decodedKey) continue; // Skip empty keys

            // Handle array parameters (key[]=value or key[0]=value)
            if (decodedKey.includes('[')) {
              const baseKey = decodedKey.replace(/\[.*\]/, '');

              if (!baseKey) continue; // Skip if base key is empty

              if (!params[baseKey]) {
                params[baseKey] = [];
              }

              if (Array.isArray(params[baseKey])) {
                params[baseKey].push(decodedValue);
              }
            } else {
              params[decodedKey] = decodedValue;
            }
          } catch (decodeError) {
            // If decoding fails, use raw values
            const rawKey = key || '';
            const rawValue = value || '';
            if (rawKey) {
              params[rawKey] = rawValue;
            }
          }
        }
      }

      // Convert arrays to comma-separated strings (Vinted API format)
      for (const key in params) {
        if (Array.isArray(params[key])) {
          params[key] = params[key].join(',');
        }
      }

      // Force newest_first ordering
      params.order = 'newest_first';

      // Remove unwanted parameters
      delete params.time;
      delete params.search_id;
      delete params.disabled_personalization;
      delete params.page;

      return {domain, params};
    } catch (error) {
      // Only fail on catastrophic URL parsing errors
      // Like Python's urlparse(), we're very permissive
      console.error('Failed to parse URL:', error.message);

      // Try to extract at least the domain
      try {
        const urlObj = new URL(url);
        return {
          domain: urlObj.hostname,
          params: {order: 'newest_first'}
        };
      } catch {
        return null;
      }
    }
  }

  /**
   * Search for items using a Vinted URL (with full retry logic)
   */
  async search(vintedUrl, nbrItems = APP_CONFIG.DEFAULT_ITEMS_PER_QUERY, page = 1) {
    const parsed = this.parseUrl(vintedUrl);
    if (!parsed) {
      throw new Error('Invalid Vinted URL');
    }

    const {domain, params} = parsed;

    // Set locale for this domain
    this.setLocale(vintedUrl);

    // Build API URL
    const apiUrl = `https://${domain}/api/v2/catalog/items`;
    const queryParams = {
      ...params,
      page: page.toString(),
      per_page: nbrItems.toString(),
    };

    // Retry loop (max 3 attempts)
    let tried = 0;
    let newSession = false;
    let lastResponse = null;

    while (tried < this.MAX_RETRIES) {
      tried++;

      try {
        console.log(`[VintedAPI] Request attempt ${tried}/${this.MAX_RETRIES} to ${apiUrl}`);

        const response = await this.axiosInstance.get(apiUrl, {
          params: queryParams,
        });

        lastResponse = response;

        // Handle status codes
        if (response.status === 401 || response.status === 404) {
          console.warn(`[VintedAPI] Got ${response.status}, refreshing cookies...`);

          if (tried < this.MAX_RETRIES) {
            await this.setCookies();
            continue; // Retry
          }
        }

        if (response.status === 200) {
          console.log(`[VintedAPI] Success! Got ${response.data?.items?.length || 0} items`);
          return response.data?.items || [];
        }

        // If we've exhausted retries and got 401/403, reset session
        if (tried === this.MAX_RETRIES) {
          if ((response.status === 401 || response.status === 403) && !newSession) {
            console.log('[VintedAPI] Resetting session and retrying one last time...');
            newSession = true;
            tried = 0; // Reset counter for final attempt
            this.initializeSession(); // Create new session
            await this.setCookies();
            continue;
          }
        }

        // For other status codes, log and continue
        console.warn(`[VintedAPI] Got status ${response.status}`);

      } catch (error) {
        console.error(`[VintedAPI] Request error:`, error.message);
        lastResponse = error.response;
      }
    }

    // Return empty array if all retries failed
    console.warn('[VintedAPI] All retries exhausted, returning empty array');
    return [];
  }

  /**
   * Get user country by user ID (with 429 rate limit fallback)
   */
  async getUserCountry(userId, domain = null) {
    if (!domain) {
      domain = this.locale;
    }

    try {
      // Try primary endpoint
      const url = `https://${domain}/api/v2/users/${userId}?localize=false`;
      console.log(`[VintedAPI] Fetching country for user ${userId}`);

      const response = await this.axiosInstance.get(url);

      // Handle rate limiting
      if (response.status === 429) {
        console.warn('[VintedAPI] Rate limited (429), trying alternative endpoint...');

        // Fallback to items endpoint
        const altUrl = `https://${domain}/api/v2/users/${userId}/items?page=1&per_page=1`;
        const altResponse = await this.axiosInstance.get(altUrl);

        if (altResponse.status === 200 && altResponse.data?.items?.[0]?.user) {
          const countryCode = altResponse.data.items[0].user.country_iso_code || 'XX';
          console.log(`[VintedAPI] Got country via fallback: ${countryCode}`);
          return countryCode;
        }

        console.warn('[VintedAPI] Fallback endpoint failed');
        return 'XX';
      }

      // Success with primary endpoint
      if (response.status === 200 && response.data?.user) {
        const countryCode = response.data.user.country_iso_code || 'XX';
        console.log(`[VintedAPI] Got country: ${countryCode}`);
        return countryCode;
      }

      console.warn(`[VintedAPI] Unexpected status: ${response.status}`);
      return 'XX';

    } catch (error) {
      console.error('[VintedAPI] Failed to get user country:', error.message);
      return 'XX';
    }
  }

  /**
   * Generate buy URL for an item
   */
  getBuyUrl(itemUrl, itemId) {
    try {
      if (!itemUrl) return '';
      const baseUrl = itemUrl.split('items')[0];
      return `${baseUrl}transaction/buy/new?source_screen=item&transaction[item_id]=${itemId}`;
    } catch (error) {
      return '';
    }
  }

  /**
   * Validate if a URL is a valid Vinted URL
   */
  isValidVintedUrl(url) {
    try {
      const urlObj = new URL(url);
      const domain = urlObj.hostname;
      return domain.includes('vinted.');
    } catch (error) {
      return false;
    }
  }

  /**
   * Extract item ID from URL
   */
  getItemIdFromUrl(url) {
    try {
      const match = url.match(/items\/(\d+)/);
      return match ? match[1] : null;
    } catch (error) {
      return null;
    }
  }
}

// Export singleton instance
export default new VintedAPI();
