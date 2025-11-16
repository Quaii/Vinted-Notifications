import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  Image,
  TouchableOpacity,
  TextInput,
  ScrollView,
  Linking,
  RefreshControl,
  Platform,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import * as BackgroundFetch from 'expo-background-fetch';
import * as TaskManager from 'expo-task-manager';
import * as Notifications from 'expo-notifications';
import AsyncStorage from '@react-native-async-storage/async-storage';

// ============================================================================
// CONFIGURATION
// ============================================================================
const BACKGROUND_FETCH_TASK = 'vinted-background-check';
const STORAGE_KEYS = {
  QUERIES: '@vinted_queries',
  SEEN_ITEMS: '@vinted_seen_items',
  TELEGRAM_TOKEN: '@telegram_token',
  TELEGRAM_CHAT_ID: '@telegram_chat_id',
};

// ============================================================================
// VINTED API CLIENT
// ============================================================================
class VintedAPI {
  static async search(url, perPage = 20) {
    try {
      const parsedUrl = new URL(url);
      const locale = parsedUrl.hostname;
      const params = this.parseUrl(url, perPage);

      const queryString = new URLSearchParams(params).toString();
      const apiUrl = `https://${locale}/api/v2/catalog/items?${queryString}`;

      const response = await fetch(apiUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      return data.items || [];
    } catch (error) {
      console.error('Vinted API error:', error);
      return [];
    }
  }

  static parseUrl(url, perPage = 20) {
    const parsedUrl = new URL(url);
    const searchParams = new URLSearchParams(parsedUrl.search);

    const params = {
      per_page: perPage,
      order: 'newest_first',
    };

    // Map common search parameters
    const mappings = {
      'search_text': 'search_text',
      'brand_ids[]': 'brand_ids',
      'price_to': 'price_to',
      'price_from': 'price_from',
      'currency': 'currency',
      'size_ids[]': 'size_ids',
      'color_ids[]': 'color_ids',
    };

    for (const [key, value] of searchParams.entries()) {
      const mappedKey = mappings[key] || key.replace('[]', '');
      if (params[mappedKey]) {
        params[mappedKey] += ',' + value;
      } else {
        params[mappedKey] = value;
      }
    }

    return params;
  }
}

// ============================================================================
// NOTIFICATION SETUP
// ============================================================================
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

// ============================================================================
// BACKGROUND TASK
// ============================================================================
TaskManager.defineTask(BACKGROUND_FETCH_TASK, async () => {
  try {
    console.log('[Background] Task started');

    // Load queries and seen items
    const queriesJson = await AsyncStorage.getItem(STORAGE_KEYS.QUERIES);
    const seenItemsJson = await AsyncStorage.getItem(STORAGE_KEYS.SEEN_ITEMS);

    const queries = queriesJson ? JSON.parse(queriesJson) : [];
    const seenItems = seenItemsJson ? JSON.parse(seenItemsJson) : [];

    let newCount = 0;

    // Check each query
    for (const query of queries) {
      if (!query.url) continue;

      const items = await VintedAPI.search(query.url, 10);

      // Check for new items
      for (const item of items.reverse()) {
        const itemId = String(item.id);

        if (!seenItems.includes(itemId)) {
          seenItems.push(itemId);
          newCount++;

          // Send notification
          await Notifications.scheduleNotificationAsync({
            content: {
              title: '🆕 New Vinted Item',
              body: `${item.title}\n💶 ${item.price} ${item.currency}`,
              data: { url: item.url, itemId },
            },
            trigger: null,
          });

          // Optional: Send to Telegram
          const telegramToken = await AsyncStorage.getItem(STORAGE_KEYS.TELEGRAM_TOKEN);
          const telegramChatId = await AsyncStorage.getItem(STORAGE_KEYS.TELEGRAM_CHAT_ID);

          if (telegramToken && telegramChatId) {
            await sendTelegramNotification(telegramToken, telegramChatId, item);
          }
        }
      }
    }

    // Save updated seen items
    await AsyncStorage.setItem(STORAGE_KEYS.SEEN_ITEMS, JSON.stringify(seenItems));

    console.log(`[Background] Checked queries. Found ${newCount} new items.`);

    return BackgroundFetch.BackgroundFetchResult.NewData;
  } catch (error) {
    console.error('[Background] Error:', error);
    return BackgroundFetch.BackgroundFetchResult.Failed;
  }
});

async function sendTelegramNotification(token, chatId, item) {
  try {
    const message = `🆕 ${item.title}\n💶 ${item.price} ${item.currency}\n🛍️ ${item.brand_title || 'No brand'}\n\n${item.url}`;

    await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML',
      }),
    });
  } catch (error) {
    console.error('Telegram error:', error);
  }
}

// ============================================================================
// MAIN APP COMPONENT
// ============================================================================
export default function App() {
  const [items, setItems] = useState([]);
  const [queries, setQueries] = useState([]);
  const [newQueryUrl, setNewQueryUrl] = useState('');
  const [isMonitoring, setIsMonitoring] = useState(false);
  const [stats, setStats] = useState({ total: 0, new: 0, queries: 0 });
  const [refreshing, setRefreshing] = useState(false);
  const [activeTab, setActiveTab] = useState('items'); // 'items' or 'settings'

  useEffect(() => {
    initializeApp();
  }, []);

  async function initializeApp() {
    // Request notification permissions
    await Notifications.requestPermissionsAsync();

    // Load saved queries
    const queriesJson = await AsyncStorage.getItem(STORAGE_KEYS.QUERIES);
    if (queriesJson) {
      const loadedQueries = JSON.parse(queriesJson);
      setQueries(loadedQueries);
      setStats(prev => ({ ...prev, queries: loadedQueries.length }));
    }

    // Check if background fetch is registered
    const isRegistered = await TaskManager.isTaskRegisteredAsync(BACKGROUND_FETCH_TASK);
    setIsMonitoring(isRegistered);

    // Load items
    fetchAllItems();
  }

  async function fetchAllItems() {
    setRefreshing(true);
    let allItems = [];

    for (const query of queries) {
      const items = await VintedAPI.search(query.url, 20);
      allItems = [...allItems, ...items];
    }

    // Remove duplicates by ID
    const uniqueItems = allItems.filter((item, index, self) =>
      index === self.findIndex(t => t.id === item.id)
    );

    setItems(uniqueItems);
    setStats(prev => ({ ...prev, total: uniqueItems.length }));
    setRefreshing(false);
  }

  async function addQuery() {
    if (!newQueryUrl.trim()) return;

    const newQuery = {
      id: Date.now().toString(),
      url: newQueryUrl,
      name: extractQueryName(newQueryUrl),
    };

    const updatedQueries = [...queries, newQuery];
    setQueries(updatedQueries);
    await AsyncStorage.setItem(STORAGE_KEYS.QUERIES, JSON.stringify(updatedQueries));

    setNewQueryUrl('');
    setStats(prev => ({ ...prev, queries: updatedQueries.length }));
    fetchAllItems();
  }

  function extractQueryName(url) {
    try {
      const parsed = new URL(url);
      const searchText = parsed.searchParams.get('search_text');
      return searchText || 'Query';
    } catch {
      return 'Query';
    }
  }

  async function removeQuery(id) {
    const updatedQueries = queries.filter(q => q.id !== id);
    setQueries(updatedQueries);
    await AsyncStorage.setItem(STORAGE_KEYS.QUERIES, JSON.stringify(updatedQueries));
    setStats(prev => ({ ...prev, queries: updatedQueries.length }));
  }

  async function toggleMonitoring() {
    if (isMonitoring) {
      // Stop monitoring
      await BackgroundFetch.unregisterTaskAsync(BACKGROUND_FETCH_TASK);
      setIsMonitoring(false);
    } else {
      // Start monitoring
      await BackgroundFetch.registerTaskAsync(BACKGROUND_FETCH_TASK, {
        minimumInterval: 60, // 1 minute (iOS minimum is 15 minutes in production)
        stopOnTerminate: false,
        startOnBoot: true,
      });
      setIsMonitoring(true);
    }
  }

  function openItem(url) {
    Linking.openURL(url);
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>📦 Vinted Monitor</Text>
        <View style={styles.statusRow}>
          <View style={[styles.indicator, isMonitoring && styles.indicatorActive]} />
          <Text style={styles.statusText}>
            {isMonitoring ? 'Monitoring Active' : 'Monitoring Stopped'}
          </Text>
        </View>

        {/* Stats */}
        <View style={styles.stats}>
          <View style={styles.stat}>
            <Text style={styles.statValue}>{stats.total}</Text>
            <Text style={styles.statLabel}>Items</Text>
          </View>
          <View style={styles.stat}>
            <Text style={styles.statValue}>{stats.queries}</Text>
            <Text style={styles.statLabel}>Queries</Text>
          </View>
          <View style={styles.stat}>
            <Text style={styles.statValue}>{stats.new}</Text>
            <Text style={styles.statLabel}>New</Text>
          </View>
        </View>
      </View>

      {/* Tabs */}
      <View style={styles.tabs}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'items' && styles.tabActive]}
          onPress={() => setActiveTab('items')}
        >
          <Text style={[styles.tabText, activeTab === 'items' && styles.tabTextActive]}>
            Items
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'settings' && styles.tabActive]}
          onPress={() => setActiveTab('settings')}
        >
          <Text style={[styles.tabText, activeTab === 'settings' && styles.tabTextActive]}>
            Settings
          </Text>
        </TouchableOpacity>
      </View>

      {/* Content */}
      {activeTab === 'items' ? (
        <FlatList
          data={items}
          keyExtractor={(item) => item.id.toString()}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={fetchAllItems} />
          }
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.item}
              onPress={() => openItem(item.url)}
            >
              <Image
                source={{ uri: item.photo?.url || 'https://via.placeholder.com/80' }}
                style={styles.itemImage}
              />
              <View style={styles.itemDetails}>
                <Text style={styles.itemTitle} numberOfLines={2}>
                  {item.title}
                </Text>
                <Text style={styles.itemBrand}>{item.brand_title || 'No brand'}</Text>
                <Text style={styles.itemPrice}>
                  {item.price} {item.currency}
                </Text>
              </View>
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            <View style={styles.emptyState}>
              <Text style={styles.emptyText}>No items yet</Text>
              <Text style={styles.emptySubtext}>Add a query to start monitoring</Text>
            </View>
          }
        />
      ) : (
        <ScrollView style={styles.settings}>
          {/* Add Query */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Add Search Query</Text>
            <TextInput
              style={styles.input}
              placeholder="Paste Vinted search URL..."
              placeholderTextColor="#999"
              value={newQueryUrl}
              onChangeText={setNewQueryUrl}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <TouchableOpacity style={styles.button} onPress={addQuery}>
              <Text style={styles.buttonText}>Add Query</Text>
            </TouchableOpacity>
          </View>

          {/* Query List */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Active Queries ({queries.length})</Text>
            {queries.map(query => (
              <View key={query.id} style={styles.queryItem}>
                <Text style={styles.queryName}>{query.name}</Text>
                <TouchableOpacity onPress={() => removeQuery(query.id)}>
                  <Text style={styles.removeButton}>Remove</Text>
                </TouchableOpacity>
              </View>
            ))}
          </View>

          {/* Monitoring Control */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Background Monitoring</Text>
            <TouchableOpacity
              style={[styles.button, isMonitoring && styles.buttonStop]}
              onPress={toggleMonitoring}
            >
              <Text style={styles.buttonText}>
                {isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'}
              </Text>
            </TouchableOpacity>
            <Text style={styles.helpText}>
              {Platform.OS === 'ios'
                ? 'Note: iOS limits background checks to every 15 minutes in production.'
                : 'Background checks run every minute.'}
            </Text>
          </View>
        </ScrollView>
      )}
    </View>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#667eea',
    paddingTop: 50,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 10,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  indicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#ccc',
    marginRight: 8,
  },
  indicatorActive: {
    backgroundColor: '#10b981',
  },
  statusText: {
    color: 'white',
    fontSize: 14,
  },
  stats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  stat: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
  },
  statLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.8)',
    marginTop: 2,
  },
  tabs: {
    flexDirection: 'row',
    backgroundColor: 'white',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  tab: {
    flex: 1,
    paddingVertical: 15,
    alignItems: 'center',
  },
  tabActive: {
    borderBottomWidth: 2,
    borderBottomColor: '#667eea',
  },
  tabText: {
    fontSize: 16,
    color: '#666',
  },
  tabTextActive: {
    color: '#667eea',
    fontWeight: '600',
  },
  item: {
    flexDirection: 'row',
    backgroundColor: 'white',
    padding: 15,
    marginHorizontal: 10,
    marginVertical: 5,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  itemImage: {
    width: 80,
    height: 80,
    borderRadius: 8,
    backgroundColor: '#f3f4f6',
  },
  itemDetails: {
    flex: 1,
    marginLeft: 15,
    justifyContent: 'center',
  },
  itemTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  itemBrand: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  itemPrice: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#667eea',
  },
  emptyState: {
    padding: 40,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
  },
  settings: {
    flex: 1,
  },
  section: {
    backgroundColor: 'white',
    padding: 20,
    marginVertical: 8,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 15,
  },
  input: {
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    marginBottom: 12,
  },
  button: {
    backgroundColor: '#667eea',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonStop: {
    backgroundColor: '#ef4444',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  queryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f3f4f6',
  },
  queryName: {
    fontSize: 16,
    color: '#333',
    flex: 1,
  },
  removeButton: {
    color: '#ef4444',
    fontSize: 14,
    fontWeight: '600',
  },
  helpText: {
    fontSize: 12,
    color: '#666',
    marginTop: 12,
    fontStyle: 'italic',
  },
});
