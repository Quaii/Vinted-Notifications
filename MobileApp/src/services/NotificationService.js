import PushNotification from 'react-native-push-notification';
import PushNotificationIOS from '@react-native-community/push-notification-ios';
import {Platform} from 'react-native';
import {APP_CONFIG} from '../constants/config';
import DatabaseService from './DatabaseService';

/**
 * Notification Service
 * Handles push notifications for new items
 */
class NotificationService {
  constructor() {
    this.configured = false;
  }

  /**
   * Initialize the notification service
   */
  configure() {
    if (this.configured) return;

    PushNotification.configure({
      // Called when a remote or local notification is opened or received
      onNotification: function (notification) {
        console.log('NOTIFICATION:', notification);

        // Required on iOS only
        if (Platform.OS === 'ios') {
          notification.finish(PushNotificationIOS.FetchResult.NoData);
        }
      },

      // IOS ONLY: Called when the user fails to register for remote notifications
      onRegistrationError: function (err) {
        console.error('Notification registration error:', err.message, err);
      },

      // Should the initial notification be popped automatically
      popInitialNotification: true,

      // Requested permissions for iOS
      permissions: {
        alert: true,
        badge: true,
        sound: true,
      },

      requestPermissions: Platform.OS === 'ios',
    });

    // Create notification channel for Android (not needed for iOS but keeping for completeness)
    PushNotification.createChannel(
      {
        channelId: APP_CONFIG.NOTIFICATION_CHANNEL_ID,
        channelName: APP_CONFIG.NOTIFICATION_CHANNEL_NAME,
        channelDescription: 'Notifications for new Vinted items',
        playSound: true,
        soundName: 'default',
        importance: 4,
        vibrate: true,
      },
      created => console.log(`Notification channel created: ${created}`),
    );

    this.configured = true;
    console.log('Notification service configured');
  }

  /**
   * Request notification permissions (iOS)
   */
  async requestPermissions() {
    if (Platform.OS === 'ios') {
      const permissions = await PushNotificationIOS.requestPermissions();
      console.log('Notification permissions:', permissions);
      return permissions;
    }
    return true;
  }

  /**
   * Check if notifications are enabled
   */
  async areNotificationsEnabled() {
    const enabled = await DatabaseService.getParameter('notifications_enabled', '1');
    return enabled === '1';
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
   * Send a local notification for a new item
   */
  async sendItemNotification(item) {
    // Check if notifications are enabled
    const enabled = await this.areNotificationsEnabled();
    if (!enabled) {
      console.log('Notifications are disabled');
      return;
    }

    try {
      const message = await this.formatMessage(item);

      PushNotification.localNotification({
        channelId: APP_CONFIG.NOTIFICATION_CHANNEL_ID,
        title: '🆕 New Vinted Item',
        message: message,
        playSound: true,
        soundName: 'default',
        userInfo: {
          itemId: item.id,
          itemUrl: item.url,
        },
        // iOS specific
        ...(Platform.OS === 'ios' && {
          alertAction: 'View',
          category: 'VINTED_ITEM',
          subtitle: item.getFormattedPrice(),
        }),
      });

      console.log('Notification sent for item:', item.id);
    } catch (error) {
      console.error('Failed to send notification:', error);
    }
  }

  /**
   * Send multiple item notifications
   */
  async sendBulkNotifications(items) {
    const enabled = await this.areNotificationsEnabled();
    if (!enabled) {
      console.log('Notifications are disabled');
      return;
    }

    if (items.length === 0) return;

    // If only one item, send individual notification
    if (items.length === 1) {
      await this.sendItemNotification(items[0]);
      return;
    }

    // For multiple items, send a summary notification
    PushNotification.localNotification({
      channelId: APP_CONFIG.NOTIFICATION_CHANNEL_ID,
      title: '🆕 New Vinted Items',
      message: `${items.length} new items found!`,
      playSound: true,
      soundName: 'default',
      userInfo: {
        itemCount: items.length,
      },
      // iOS specific
      ...(Platform.OS === 'ios' && {
        alertAction: 'View All',
        category: 'VINTED_ITEMS',
      }),
    });

    console.log(`Sent bulk notification for ${items.length} items`);
  }

  /**
   * Cancel all notifications
   */
  cancelAllNotifications() {
    PushNotification.cancelAllLocalNotifications();
    console.log('All notifications cancelled');
  }

  /**
   * Get delivered notifications (iOS only)
   */
  async getDeliveredNotifications() {
    if (Platform.OS === 'ios') {
      return new Promise(resolve => {
        PushNotificationIOS.getDeliveredNotifications(notifications => {
          resolve(notifications);
        });
      });
    }
    return [];
  }

  /**
   * Remove delivered notifications (iOS only)
   */
  removeDeliveredNotifications(identifiers) {
    if (Platform.OS === 'ios') {
      PushNotificationIOS.removeDeliveredNotifications(identifiers);
    }
  }

  /**
   * Set badge count (iOS only)
   */
  setBadgeCount(count) {
    if (Platform.OS === 'ios') {
      PushNotificationIOS.setApplicationIconBadgeNumber(count);
    }
  }

  /**
   * Get badge count (iOS only)
   */
  async getBadgeCount() {
    if (Platform.OS === 'ios') {
      return new Promise(resolve => {
        PushNotificationIOS.getApplicationIconBadgeNumber(count => {
          resolve(count);
        });
      });
    }
    return 0;
  }
}

// Export singleton instance
export default new NotificationService();
