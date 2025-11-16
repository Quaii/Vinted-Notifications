import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {StatCard, ItemCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import MonitoringService from '../services/MonitoringService';
import {COLORS, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * Dashboard Screen
 * Main screen showing statistics and recent items
 */
const DashboardScreen = ({navigation}) => {
  const [statistics, setStatistics] = useState({
    totalItems: 0,
    totalQueries: 0,
    itemsToday: 0,
  });
  const [recentItems, setRecentItems] = useState([]);
  const [refreshing, setRefreshing] = useState(false);
  const [monitoringStatus, setMonitoringStatus] = useState({
    isRunning: false,
    refreshDelay: 60,
    itemsPerQuery: 20,
    activeQueries: 0,
  });

  const loadData = useCallback(async () => {
    try {
      const stats = await DatabaseService.getStatistics();
      setStatistics(stats);

      const items = await DatabaseService.getItems(null, 10);
      setRecentItems(items);

      const status = await MonitoringService.getStatus();
      setMonitoringStatus(status);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    }
  }, []);

  useEffect(() => {
    loadData();

    // Reload data when screen comes into focus
    const unsubscribe = navigation.addListener('focus', loadData);
    return unsubscribe;
  }, [navigation, loadData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }, [loadData]);

  const toggleMonitoring = async () => {
    try {
      if (monitoringStatus.isRunning) {
        MonitoringService.stopMonitoring();
        Alert.alert('Success', 'Monitoring stopped');
      } else {
        if (monitoringStatus.activeQueries === 0) {
          Alert.alert(
            'No Queries',
            'Please add at least one search query before starting monitoring.',
            [{text: 'OK'}],
          );
          return;
        }
        await MonitoringService.startMonitoring();
        Alert.alert('Success', 'Monitoring started');
      }
      await loadData();
    } catch (error) {
      Alert.alert('Error', 'Failed to toggle monitoring');
    }
  };

  const handleCheckNow = async () => {
    try {
      if (monitoringStatus.activeQueries === 0) {
        Alert.alert(
          'No Queries',
          'Please add at least one search query first.',
          [{text: 'OK'}],
        );
        return;
      }

      Alert.alert('Checking', 'Checking all queries for new items...');
      const newItems = await MonitoringService.checkAllQueries();

      if (newItems.length > 0) {
        Alert.alert('Success', `Found ${newItems.length} new item(s)!`);
      } else {
        Alert.alert('No New Items', 'No new items found at this time.');
      }

      await loadData();
    } catch (error) {
      Alert.alert('Error', 'Failed to check queries');
    }
  };

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Vinted Notifications</Text>
        <Text style={styles.headerSubtitle}>Track new Vinted items</Text>
      </View>

      {/* Monitoring Status */}
      <View style={styles.statusCard}>
        <View style={styles.statusHeader}>
          <View style={styles.statusIndicator}>
            <View
              style={[
                styles.statusDot,
                {
                  backgroundColor: monitoringStatus.isRunning
                    ? COLORS.success
                    : COLORS.textLight,
                },
              ]}
            />
            <Text style={styles.statusText}>
              {monitoringStatus.isRunning ? 'Monitoring Active' : 'Monitoring Stopped'}
            </Text>
          </View>
          <TouchableOpacity
            style={[
              styles.toggleButton,
              {
                backgroundColor: monitoringStatus.isRunning
                  ? COLORS.error
                  : COLORS.success,
              },
            ]}
            onPress={toggleMonitoring}>
            <Text style={styles.toggleButtonText}>
              {monitoringStatus.isRunning ? 'Stop' : 'Start'}
            </Text>
          </TouchableOpacity>
        </View>
        <View style={styles.statusDetails}>
          <Text style={styles.statusDetailText}>
            Refresh: {monitoringStatus.refreshDelay}s | Items:{' '}
            {monitoringStatus.itemsPerQuery} | Queries:{' '}
            {monitoringStatus.activeQueries}
          </Text>
        </View>
        <TouchableOpacity style={styles.checkNowButton} onPress={handleCheckNow}>
          <Icon name="refresh" size={20} color={COLORS.primary} />
          <Text style={styles.checkNowText}>Check Now</Text>
        </TouchableOpacity>
      </View>

      {/* Statistics */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Statistics</Text>
        <View style={styles.statsGrid}>
          <View style={styles.statItem}>
            <StatCard
              icon="inventory"
              label="Total Items"
              value={statistics.totalItems}
              color={COLORS.primary}
            />
          </View>
          <View style={styles.statItem}>
            <StatCard
              icon="search"
              label="Active Queries"
              value={statistics.totalQueries}
              color={COLORS.secondary}
            />
          </View>
          <View style={styles.statItem}>
            <StatCard
              icon="today"
              label="Items Today"
              value={statistics.itemsToday}
              color={COLORS.success}
            />
          </View>
        </View>
      </View>

      {/* Recent Items */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Recent Items</Text>
          <TouchableOpacity onPress={() => navigation.navigate('Items')}>
            <Text style={styles.seeAllText}>See All</Text>
          </TouchableOpacity>
        </View>
        {recentItems.length > 0 ? (
          recentItems.map(item => <ItemCard key={item.id} item={item} />)
        ) : (
          <View style={styles.emptyState}>
            <Icon name="inbox" size={64} color={COLORS.textLight} />
            <Text style={styles.emptyStateText}>No items yet</Text>
            <Text style={styles.emptyStateSubtext}>
              Add a search query and start monitoring
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    padding: SPACING.lg,
    paddingTop: SPACING.xl,
    backgroundColor: COLORS.primary,
  },
  headerTitle: {
    fontSize: FONT_SIZES.xxxl,
    fontWeight: '700',
    color: COLORS.surface,
    marginBottom: SPACING.xs,
  },
  headerSubtitle: {
    fontSize: FONT_SIZES.md,
    color: COLORS.surface,
    opacity: 0.9,
  },
  statusCard: {
    backgroundColor: COLORS.surface,
    margin: SPACING.md,
    padding: SPACING.md,
    borderRadius: BORDER_RADIUS.lg,
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.sm,
  },
  statusIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: SPACING.sm,
  },
  statusText: {
    fontSize: FONT_SIZES.lg,
    fontWeight: '600',
    color: COLORS.text,
  },
  toggleButton: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    borderRadius: BORDER_RADIUS.md,
  },
  toggleButtonText: {
    color: COLORS.surface,
    fontWeight: '600',
    fontSize: FONT_SIZES.md,
  },
  statusDetails: {
    marginBottom: SPACING.sm,
  },
  statusDetailText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textSecondary,
  },
  checkNowButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: SPACING.sm,
    borderRadius: BORDER_RADIUS.md,
    borderWidth: 1,
    borderColor: COLORS.primary,
  },
  checkNowText: {
    color: COLORS.primary,
    fontWeight: '600',
    marginLeft: SPACING.xs,
  },
  section: {
    marginTop: SPACING.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: SPACING.md,
    marginBottom: SPACING.sm,
  },
  sectionTitle: {
    fontSize: FONT_SIZES.xl,
    fontWeight: '700',
    color: COLORS.text,
    paddingHorizontal: SPACING.md,
    marginBottom: SPACING.sm,
  },
  seeAllText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.primary,
    fontWeight: '600',
  },
  statsGrid: {
    paddingHorizontal: SPACING.md,
  },
  statItem: {
    marginBottom: SPACING.md,
  },
  emptyState: {
    alignItems: 'center',
    padding: SPACING.xxl,
  },
  emptyStateText: {
    fontSize: FONT_SIZES.lg,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginTop: SPACING.md,
  },
  emptyStateSubtext: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
    marginTop: SPACING.xs,
    textAlign: 'center',
  },
});

export default DashboardScreen;
