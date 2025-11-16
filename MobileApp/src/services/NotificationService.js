import notifee, {AuthorizationStatus} from '@notifee/react-native';
import {APP_CONFIG, NOTIFICATION_MODES} from '../constants/config';
import DatabaseService from './DatabaseService';

/**
 * Notification Service
 * Handles push notifications for new items using Notifee (modern iOS API)
 */
class NotificationService {
  constructor() {
    this.configured = false;
    this.channelId = null;
  }

  /**
   * Initialize the notification service
   */
  async configure() {
    if (this.configured) return;

    try {
      // Request permissions
      await this.requestPermissions();

      // Create notification channel (required for Android, harmless for iOS)
      this.channelId = await notifee.createChannel({
        id: APP_CONFIG.NOTIFICATION_CHANNEL_ID,
        name: APP_CONFIG.NOTIFICATION_CHANNEL_NAME,
        sound: 'default',
        importance: 4, // High importance
        vibration: true,
      });

      this.configured = true;
      console.log('[Notifee] Service configured successfully');
    } catch (error) {
      console.error('[Notifee] Failed to configure:', error);
    }
  }

  /**
   * Request notification permissions
   */
  async requestPermissions() {
    try {
      const settings = await notifee.requestPermission();

      if (settings.authorizationStatus === AuthorizationStatus.AUTHORIZED) {
        console.log('[Notifee] Permissions granted');
        return true;
      } else if (settings.authorizationStatus === AuthorizationStatus.DENIED) {
        console.warn('[Notifee] Permissions denied');
        return false;
      } else {
        console.log('[Notifee] Permissions not determined');
        return false;
      }
    } catch (error) {
      console.error('[Notifee] Failed to request permissions:', error);
      return false;
    }
  }

  /**
   * Check if notifications are enabled
   */
  async areNotificationsEnabled() {
    try {
      // Check app settings
      const enabled = await DatabaseService.getParameter('notifications_enabled', '1');
      if (enabled !== '1') {
        return false;
      }

      // Check system permissions
      const settings = await notifee.getNotificationSettings();
      return settings.authorizationStatus === AuthorizationStatus.AUTHORIZED;
    } catch (error) {
      console.error('[Notifee] Failed to check notification status:', error);
      return false;
    }
  }

  /**
   * Get notification mode (precise or compact)
   */
  async getNotificationMode() {
    try {
      const mode = await DatabaseService.getParameter('notification_mode', NOTIFICATION_MODES.PRECISE);
      return mode || NOTIFICATION_MODES.PRECISE;
    } catch (error) {
      console.error('[Notifee] Failed to get notification mode:', error);
      return NOTIFICATION_MODES.PRECISE;
    }
  }

  /**
   * Format message using template
   */
  async formatMessage(item) {
    const template = await DatabaseService.getParameter('message_template');
    if (!template) {
      return `New item: ${item.title}`;
    }

    let message = template;
    message = message.replace('{title}', item.title || 'N/A');
    message = message.replace('{price}', item.getFormattedPrice() || 'N/A');
    message = message.replace('{brand}', item.brand_title || 'N/A');
    message = message.replace('{size}', item.size_title || 'N/A');

    return message;
  }

  /**
   * Send a local notification for a new item (PLAIN TEXT, NO EMOJIS)
   */
  async sendItemNotification(item) {
    // Check if notifications are enabled
    const enabled = await this.areNotificationsEnabled();
    if (!enabled) {
      console.log('[Notifee] Notifications are disabled');
      return;
    }

    try {
      const mode = await this.getNotificationMode();

      // PRECISE mode: Show full details for this item
      if (mode === NOTIFICATION_MODES.PRECISE) {
        const message = await this.formatMessage(item);

        await notifee.displayNotification({
          title: 'New Vinted Item', // PLAIN TEXT, NO EMOJI
          body: message,
          subtitle: item.getFormattedPrice(),
          ios: {
            sound: 'default',
            categoryId: 'VINTED_ITEM',
            attachments: item.photo
              ? [
                  {
                    url: item.photo,
                    thumbnailHidden: false,
                  },
                ]
              : [],
            foregroundPresentationOptions: {
              banner: true,
              sound: true,
              badge: true,
            },
          },
          data: {
            itemId: item.id.toString(),
            itemUrl: item.url,
          },
        });

        console.log('[Notifee] Notification sent for item:', item.id);
      }
      // COMPACT mode: Don't send individual notifications, wait for bulk
    } catch (error) {
      console.error('[Notifee] Failed to send notification:', error);
    }
  }

  /**
   * Send multiple item notifications (respects precise/compact mode)
   */
  async sendBulkNotifications(items) {
    const enabled = await this.areNotificationsEnabled();
    if (!enabled) {
      console.log('[Notifee] Notifications are disabled');
      return;
    }

    if (items.length === 0) return;

    try {
      const mode = await this.getNotificationMode();

      // PRECISE mode: Send individual notification for each item
      if (mode === NOTIFICATION_MODES.PRECISE) {
        for (const item of items) {
          await this.sendItemNotification(item);
        }
        return;
      }

      // COMPACT mode: Send summary notification (PLAIN TEXT, NO EMOJIS)
      if (mode === NOTIFICATION_MODES.COMPACT) {
        const title = items.length === 1
          ? 'New Vinted Item'
          : 'New Vinted Items';
        const body = items.length === 1
          ? `${items[0].title} - ${items[0].getFormattedPrice()}`
          : `${items.length} new items found`;

        await notifee.displayNotification({
          title: title, // PLAIN TEXT
          body: body,   // PLAIN TEXT
          ios: {
            sound: 'default',
            categoryId: 'VINTED_ITEMS',
            foregroundPresentationOptions: {
              banner: true,
              sound: true,
              badge: true,
            },
          },
          data: {
            itemCount: items.length.toString(),
          },
        });

        console.log(`[Notifee] Sent compact notification for ${items.length} items`);
      }
    } catch (error) {
      console.error('[Notifee] Failed to send bulk notification:', error);
    }
  }

  /**
   * Cancel all notifications
   */
  async cancelAllNotifications() {
    try {
      await notifee.cancelAllNotifications();
      console.log('[Notifee] All notifications cancelled');
    } catch (error) {
      console.error('[Notifee] Failed to cancel notifications:', error);
    }
  }

  /**
   * Get delivered notifications
   */
  async getDeliveredNotifications() {
    try {
      const notifications = await notifee.getDisplayedNotifications();
      return notifications;
    } catch (error) {
      console.error('[Notifee] Failed to get delivered notifications:', error);
      return [];
    }
  }

  /**
   * Remove delivered notifications
   */
  async removeDeliveredNotifications(notificationIds) {
    try {
      if (Array.isArray(notificationIds)) {
        for (const id of notificationIds) {
          await notifee.cancelNotification(id);
        }
      } else {
        await notifee.cancelNotification(notificationIds);
      }
      console.log('[Notifee] Notifications removed');
    } catch (error) {
      console.error('[Notifee] Failed to remove notifications:', error);
    }
  }

  /**
   * Set badge count
   */
  async setBadgeCount(count) {
    try {
      await notifee.setBadgeCount(count);
      console.log(`[Notifee] Badge count set to ${count}`);
    } catch (error) {
      console.error('[Notifee] Failed to set badge count:', error);
    }
  }

  /**
   * Get badge count
   */
  async getBadgeCount() {
    try {
      const count = await notifee.getBadgeCount();
      return count;
    } catch (error) {
      console.error('[Notifee] Failed to get badge count:', error);
      return 0;
    }
  }

  /**
   * Increment badge count
   */
  async incrementBadgeCount() {
    try {
      const current = await this.getBadgeCount();
      await this.setBadgeCount(current + 1);
    } catch (error) {
      console.error('[Notifee] Failed to increment badge count:', error);
    }
  }

  /**
   * Clear badge count
   */
  async clearBadgeCount() {
    await this.setBadgeCount(0);
  }
}

// Export singleton instance
export default new NotificationService();
