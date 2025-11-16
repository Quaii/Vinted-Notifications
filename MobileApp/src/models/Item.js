// Item model representing a Vinted item
export class VintedItem {
  constructor(data) {
    this.id = data.id;
    this.title = data.title || '';
    this.brand_title = data.brand_title || data.brandTitle || '';
    this.size_title = data.size_title || data.sizeTitle || '';
    this.price = data.price || '';
    this.currency = data.currency || '€';
    this.photo = data.photo || '';
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
    // Photo is now always a string URL (extracted from API as rawItem.photo.url)
    return this.photo || null;
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
