import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {StatCard, ItemCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import MonitoringService from '../services/MonitoringService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * Dashboard Screen
 * Main screen showing statistics and recent items
 * iOS NATIVE DESIGN - Monitoring runs automatically (like Python version)
 */
const DashboardScreen = ({navigation}) => {
  const COLORS = useThemeColors();

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

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    // iOS Grouped List Section
    section: {
      marginTop: SPACING.lg,
    },
    sectionHeader: {
      paddingHorizontal: SPACING.md,
      paddingTop: SPACING.sm,
      paddingBottom: SPACING.xs,
    },
    sectionHeaderText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    // Status Info (Read-only)
    infoGroup: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.md,
      borderRadius: BORDER_RADIUS.lg,
      overflow: 'hidden',
    },
    infoRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm + 2,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    infoRowLast: {
      borderBottomWidth: 0,
    },
    infoLabel: {
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
    },
    infoValue: {
      fontSize: FONT_SIZES.body,
      color: COLORS.textSecondary,
    },
    // Status Indicator
    statusIndicator: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    statusDot: {
      width: 10,
      height: 10,
      borderRadius: 5,
      marginRight: SPACING.xs,
    },
    // Statistics Cards
    statsGrid: {
      paddingHorizontal: SPACING.md,
    },
    statItem: {
      marginBottom: SPACING.sm,
    },
    // Recent Items
    itemsContainer: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.md,
      borderRadius: BORDER_RADIUS.lg,
      overflow: 'hidden',
    },
    seeAllRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    seeAllText: {
      fontSize: FONT_SIZES.body,
      color: COLORS.link,
    },
    // Empty State
    emptyState: {
      alignItems: 'center',
      paddingVertical: SPACING.xxl * 2,
      paddingHorizontal: SPACING.md,
    },
    emptyIcon: {
      marginBottom: SPACING.md,
    },
    emptyStateText: {
      fontSize: FONT_SIZES.body,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginBottom: SPACING.xs,
    },
    emptyStateSubtext: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textTertiary,
      textAlign: 'center',
    },
  });

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }>
      {/* Monitoring Status (Read-Only) */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>MONITORING STATUS</Text>
        </View>
        <View style={styles.infoGroup}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Status</Text>
            <View style={styles.statusIndicator}>
              <View
                style={[
                  styles.statusDot,
                  {
                    backgroundColor: monitoringStatus.isRunning
                      ? COLORS.success
                      : COLORS.textTertiary,
                  },
                ]}
              />
              <Text style={styles.infoValue}>
                {monitoringStatus.isRunning ? 'Active' : 'Inactive'}
              </Text>
            </View>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Active Queries</Text>
            <Text style={styles.infoValue}>{monitoringStatus.activeQueries}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Check Interval</Text>
            <Text style={styles.infoValue}>{monitoringStatus.refreshDelay}s</Text>
          </View>
          <View style={[styles.infoRow, styles.infoRowLast]}>
            <Text style={styles.infoLabel}>Items Per Query</Text>
            <Text style={styles.infoValue}>{monitoringStatus.itemsPerQuery}</Text>
          </View>
        </View>
      </View>

      {/* Statistics */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>STATISTICS</Text>
        </View>
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
              color={COLORS.info}
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
          <Text style={styles.sectionHeaderText}>RECENT ITEMS</Text>
        </View>
        {recentItems.length > 0 ? (
          <View style={styles.itemsContainer}>
            <TouchableOpacity
              style={styles.seeAllRow}
              onPress={() => navigation.navigate('Items')}>
              <Text style={styles.infoLabel}>All Items</Text>
              <Text style={styles.seeAllText}>See All</Text>
            </TouchableOpacity>
            {recentItems.map((item, index) => (
              <ItemCard
                key={item.id}
                item={item}
                isLast={index === recentItems.length - 1}
              />
            ))}
          </View>
        ) : (
          <View style={styles.emptyState}>
            <View style={styles.emptyIcon}>
              <Icon name="inbox" size={48} color={COLORS.textTertiary} />
            </View>
            <Text style={styles.emptyStateText}>No items yet</Text>
            <Text style={styles.emptyStateSubtext}>
              Add a search query to start tracking new Vinted items
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
};

export default DashboardScreen;
