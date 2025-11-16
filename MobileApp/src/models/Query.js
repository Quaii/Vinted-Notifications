// Query model representing a Vinted search query
export class VintedQuery {
  constructor(data) {
    this.id = data.id || null;
    this.query = data.query || '';
    this.query_name = data.query_name || data.queryName || this.extractQueryName(data.query);
    this.last_item = data.last_item || data.lastItem || null;
    this.created_at = data.created_at || data.createdAt || Date.now();
    this.is_active = data.is_active !== undefined ? data.is_active : true;
  }

  // Extract a readable name from the query URL
  extractQueryName(url) {
    if (!url) return 'Unnamed Query';

    try {
      const urlObj = new URL(url);
      const params = new URLSearchParams(urlObj.search);

      // Try to build a name from search parameters
      const parts = [];

      if (params.get('search_text')) {
        parts.push(params.get('search_text'));
      }
      if (params.get('brand_ids')) {
        parts.push('Brand filter');
      }
      if (params.get('size_ids')) {
        parts.push('Size filter');
      }
      if (params.get('color_ids')) {
        parts.push('Color filter');
      }
      if (params.get('price_from') || params.get('price_to')) {
        const priceFrom = params.get('price_from') || '0';
        const priceTo = params.get('price_to') || '∞';
        parts.push(`${priceFrom}-${priceTo}`);
      }

      return parts.length > 0 ? parts.join(' · ') : 'Custom Query';
    } catch (error) {
      return 'Unnamed Query';
    }
  }

  // Get domain from query URL
  getDomain() {
    try {
      const urlObj = new URL(this.query);
      return urlObj.hostname;
    } catch (error) {
      return '';
    }
  }

  // Get country code from domain
  getCountryCode() {
    const domain = this.getDomain();
    const countryMap = {
      'vinted.fr': 'FR',
      'vinted.de': 'DE',
      'vinted.co.uk': 'GB',
      'vinted.com': 'US',
      'vinted.es': 'ES',
      'vinted.it': 'IT',
      'vinted.pl': 'PL',
      'vinted.be': 'BE',
      'vinted.nl': 'NL',
      'vinted.lt': 'LT',
      'vinted.cz': 'CZ',
      'vinted.se': 'SE',
      'vinted.at': 'AT',
      'vinted.pt': 'PT',
      'vinted.lu': 'LU',
    };
    return countryMap[domain] || '';
  }

  // Get formatted last item time
  getLastItemTime() {
    if (!this.last_item) return 'No items yet';

    const now = Date.now();
    const lastItemMs = typeof this.last_item === 'number' ? this.last_item : parseInt(this.last_item);
    const diff = now - lastItemMs;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    if (minutes > 0) return `${minutes}m ago`;
    return 'Just now';
  }

  // Convert to JSON for storage
  toJSON() {
    return {
      id: this.id,
      query: this.query,
      query_name: this.query_name,
      last_item: this.last_item,
      created_at: this.created_at,
      is_active: this.is_active,
    };
  }
}
