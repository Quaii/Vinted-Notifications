import {Platform} from 'react-native';

/**
 * ImageCacheService
 * Handles image URL validation and caching hints for React Native Image component
 */
class ImageCacheService {
  /**
   * Validate and normalize image URL
   */
  validateImageUrl(url) {
    if (!url || typeof url !== 'string') {
      console.warn('[ImageCache] Invalid image URL:', url);
      return null;
    }

    // Remove any object stringification artifacts
    let cleanUrl = url.trim();

    // Check if it looks like a stringified object
    if (cleanUrl.includes('[object') || cleanUrl.includes('{')) {
      console.error('[ImageCache] Image URL is corrupted (contains object):', cleanUrl);
      return null;
    }

    // Ensure it's a valid HTTP/HTTPS URL
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      console.warn('[ImageCache] Image URL missing protocol:', cleanUrl);
      return null;
    }

    return cleanUrl;
  }

  /**
   * Get image source object with caching headers
   */
  getImageSource(url) {
    const validUrl = this.validateImageUrl(url);

    if (!validUrl) {
      return null;
    }

    // Return image source with caching headers
    return {
      uri: validUrl,
      cache: Platform.OS === 'ios' ? 'default' : 'force-cache', // iOS: default, Android: force-cache
      headers: {
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
      },
    };
  }

  /**
   * Get placeholder image source
   */
  getPlaceholder() {
    return {
      uri: 'https://via.placeholder.com/150/1A1A1A/CCCCCC?text=No+Image',
    };
  }
}

export default new ImageCacheService();
