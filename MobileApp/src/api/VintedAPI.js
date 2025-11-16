import axios from 'axios';
import {APP_CONFIG, USER_AGENTS, DEFAULT_HEADERS} from '../constants/config';

/**
 * Vinted API Client
 * Handles all interactions with the Vinted API
 */
export class VintedAPI {
  constructor() {
    this.session = null;
    this.cookies = {};
    this.userAgentIndex = 0;
    this.retryCount = 0;
  }

  /**
   * Get a random user agent
   */
  getUserAgent() {
    const userAgent = USER_AGENTS[this.userAgentIndex % USER_AGENTS.length];
    this.userAgentIndex++;
    return userAgent;
  }

  /**
   * Initialize session with cookies
   */
  async initSession(domain = 'vinted.fr') {
    try {
      const url = `https://${domain}`;
      const headers = {
        ...DEFAULT_HEADERS,
        'User-Agent': this.getUserAgent(),
      };

      const response = await axios.get(url, {
        headers,
        timeout: APP_CONFIG.API_TIMEOUT,
      });

      // Extract cookies from response
      if (response.headers['set-cookie']) {
        response.headers['set-cookie'].forEach(cookie => {
          const [nameValue] = cookie.split(';');
          const [name, value] = nameValue.split('=');
          this.cookies[name.trim()] = value.trim();
        });
      }

      return true;
    } catch (error) {
      console.error('Failed to initialize session:', error.message);
      return false;
    }
  }

  /**
   * Get cookie string for requests
   */
  getCookieString() {
    return Object.entries(this.cookies)
      .map(([name, value]) => `${name}=${value}`)
      .join('; ');
  }

  /**
   * Parse Vinted URL and extract parameters
   */
  parseUrl(url) {
    try {
      const urlObj = new URL(url);
      const domain = urlObj.hostname;
      const params = {};

      // Extract all query parameters
      urlObj.searchParams.forEach((value, key) => {
        params[key] = value;
      });

      // Ensure newest_first ordering
      params.order = 'newest_first';

      return {domain, params};
    } catch (error) {
      console.error('Failed to parse URL:', error.message);
      return null;
    }
  }

  /**
   * Build API URL from parameters
   */
  buildApiUrl(domain, params, page = 1) {
    const baseUrl = `https://${domain}/api/v2/catalog/items`;
    const queryParams = new URLSearchParams({
      ...params,
      page: page.toString(),
      per_page: params.per_page || APP_CONFIG.DEFAULT_ITEMS_PER_QUERY.toString(),
    });

    return `${baseUrl}?${queryParams.toString()}`;
  }

  /**
   * Search for items using a Vinted URL
   */
  async search(vintedUrl, nbrItems = APP_CONFIG.DEFAULT_ITEMS_PER_QUERY, page = 1) {
    const parsed = this.parseUrl(vintedUrl);
    if (!parsed) {
      throw new Error('Invalid Vinted URL');
    }

    const {domain, params} = parsed;

    // Initialize session if needed
    if (!this.cookies[domain]) {
      await this.initSession(domain);
    }

    // Build API URL
    const apiUrl = this.buildApiUrl(domain, params, page);

    // Make request
    try {
      const headers = {
        ...DEFAULT_HEADERS,
        'User-Agent': this.getUserAgent(),
        'Cookie': this.getCookieString(),
      };

      const response = await axios.get(apiUrl, {
        headers,
        timeout: APP_CONFIG.API_TIMEOUT,
      });

      if (response.status === 200 && response.data) {
        const items = response.data.items || [];
        this.retryCount = 0; // Reset retry count on success
        return items;
      }

      return [];
    } catch (error) {
      // Handle 401 (unauthorized) - refresh cookies
      if (error.response?.status === 401) {
        console.log('Session expired, refreshing cookies...');
        await this.initSession(domain);

        // Retry request if we haven't exceeded max retries
        if (this.retryCount < APP_CONFIG.API_MAX_RETRIES) {
          this.retryCount++;
          return await this.search(vintedUrl, nbrItems, page);
        }
      }

      console.error('API request failed:', error.message);
      throw error;
    }
  }

  /**
   * Get user country by user ID
   */
  async getUserCountry(userId, domain = 'vinted.fr') {
    try {
      const url = `https://${domain}/api/v2/users/${userId}`;
      const headers = {
        ...DEFAULT_HEADERS,
        'User-Agent': this.getUserAgent(),
        'Cookie': this.getCookieString(),
      };

      const response = await axios.get(url, {
        headers,
        timeout: APP_CONFIG.API_TIMEOUT,
      });

      if (response.status === 200 && response.data?.user) {
        return response.data.user.country_code || null;
      }

      return null;
    } catch (error) {
      console.error('Failed to get user country:', error.message);
      return null;
    }
  }

  /**
   * Validate if a URL is a valid Vinted URL
   */
  isValidVintedUrl(url) {
    try {
      const urlObj = new URL(url);
      const domain = urlObj.hostname;

      // Check if domain is a Vinted domain
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
