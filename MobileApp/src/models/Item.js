// Item model representing a Vinted item
export class VintedItem {
  constructor(data) {
    this.id = data.id;

    // Handle title - ensure it's never an object
    if (typeof data.title === 'string') {
      this.title = data.title;
    } else {
      this.title = '';
    }

    this.brand_title = data.brand_title || data.brandTitle || '';
    this.size_title = data.size_title || data.sizeTitle || '';

    // Handle price - ensure it's always a string
    if (typeof data.price === 'object' && data.price !== null) {
      // Price is an object from API: {amount: "5.0", currency_code: "EUR"}
      this.price = String(data.price.amount || data.price.value || '0.00');
      this.currency = String(data.price.currency_code || data.price.currency || '€');
    } else if (data.price !== undefined && data.price !== null) {
      // Price is already extracted as string
      this.price = String(data.price);
      // Currency should be separate
      this.currency = data.currency ? String(data.currency) : '€';
    } else {
      this.price = '0.00';
      this.currency = '€';
    }

    // Handle photo - ensure it's always a URL string
    if (typeof data.photo === 'object' && data.photo !== null) {
      // Photo is an object from API: {url: "https://...", full_size_url: "..."}
      this.photo = String(data.photo.url || data.photo.full_size_url || data.photo.temp_uuid || '');
    } else {
      this.photo = data.photo || '';
    }

    this.url = data.url || '';
    this.buy_url = data.buy_url || data.buyUrl || this.generateBuyUrl(data.url, data.id);
    this.created_at_ts = data.created_at_ts || data.createdAtTs || Date.now();
    this.raw_timestamp = data.raw_timestamp || data.rawTimestamp || '';
    this.query_id = data.query_id || data.queryId || null;
  }

  // Generate buy URL from item URL and ID
  generateBuyUrl(url, id) {
    try {
      if (!url || !id) return '';
      const baseUrl = url.split('items')[0];
      return `${baseUrl}transaction/buy/new?source_screen=item&transaction[item_id]=${id}`;
    } catch (error) {
      return '';
    }
  }

  // Format price for display
  getFormattedPrice() {
    // Price and currency are now always strings (extracted from API correctly)
    return `${this.price} ${this.currency}`;
  }

  // Get display photo URL
  getPhotoUrl() {
    // Photo should always be a string URL (extracted from API as rawItem.photo.url)
    if (!this.photo || typeof this.photo !== 'string') {
      console.warn('[Item] Invalid photo for item', this.id, ':', this.photo);
      return null;
    }

    // Check if photo looks like a stringified object
    if (this.photo.includes('[object') || this.photo.includes('{')) {
      console.error('[Item] Photo is corrupted (contains object) for item', this.id, ':', this.photo);
      return null;
    }

    return this.photo;
  }

  // Get time since posted
  getTimeSincePosted() {
    const now = Date.now();
    const diff = now - this.created_at_ts;
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
      title: this.title,
      brand_title: this.brand_title,
      size_title: this.size_title,
      price: this.price,
      currency: this.currency,
      photo: this.photo,
      url: this.url,
      buy_url: this.buy_url,
      created_at_ts: this.created_at_ts,
      raw_timestamp: this.raw_timestamp,
      query_id: this.query_id,
    };
  }
}
