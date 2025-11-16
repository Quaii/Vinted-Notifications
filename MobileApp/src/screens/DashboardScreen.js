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
import {PageHeader, StatWidget, ItemCard, QueryCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import LogService from '../services/LogService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * DashboardScreen
 * Modern dashboard with widgets, last item, queries, and logs
 */
const DashboardScreen = ({navigation}) => {
  const COLORS = useThemeColors();

  const [stats, setStats] = useState({
    totalItems: 0,
    itemsPerDay: 0,
  });
  const [lastItem, setLastItem] = useState(null);
  const [queries, setQueries] = useState([]);
  const [logs, setLogs] = useState([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadDashboard = useCallback(async () => {
    try {
      // Load total items
      const items = await DatabaseService.getItems(null, 1000);
      const totalItems = items.length;

      // Calculate items per day (last 7 days)
      const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      const recentItems = items.filter(item => item.created_at_ts >= weekAgo);
      const itemsPerDay = recentItems.length > 0 ? (recentItems.length / 7).toFixed(1) : 0;

      setStats({totalItems, itemsPerDay});

      // Load last found item
      if (items.length > 0) {
        setLastItem(items[0]);
      }

      // Load queries (max 2)
      const allQueries = await DatabaseService.getQueries(true);
      setQueries(allQueries.slice(0, 2));

      // Load recent logs (max 5)
      setLogs(LogService.getRecentLogs(60, 5));
    } catch (error) {
      console.error('Failed to load dashboard:', error);
      LogService.error('Failed to load dashboard', error.message);
    }
  }, []);

  useEffect(() => {
    loadDashboard();

    // Subscribe to log updates
    const unsubscribe = LogService.subscribe(() => {
      setLogs(LogService.getRecentLogs(60, 5));
    });

    return unsubscribe;
  }, [loadDashboard]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadDashboard();
    setRefreshing(false);
  };

  const getLogIcon = level => {
    switch (level) {
      case 'success':
        return 'check-circle';
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      default:
        return 'info';
    }
  };

  const getLogColor = level => {
    switch (level) {
      case 'success':
        return '#34C759';
      case 'error':
        return '#FF3B30';
      case 'warning':
        return '#FF9500';
      default:
        return '#007AFF';
    }
  };

  const formatLogTime = timestamp => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    return date.toLocaleDateString();
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    content: {
      padding: SPACING.lg,
    },
    // Widgets
    widgetRow: {
      flexDirection: 'row',
      gap: SPACING.md,
      marginBottom: SPACING.xl,
    },
    // Section
    section: {
      marginBottom: SPACING.xl,
    },
    sectionHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: SPACING.md,
    },
    sectionTitle: {
      fontSize: FONT_SIZES.title3,
      fontWeight: '600',
      color: COLORS.text,
    },
    sectionButton: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.sm,
      paddingVertical: SPACING.xs,
    },
    sectionButtonText: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '600',
      color: COLORS.link,
      marginRight: 2,
    },
    // Last Item Card
    lastItemCard: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.xl,
      padding: SPACING.md,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    // Queries
    queryList: {
      gap: SPACING.sm,
    },
    // Logs
    logsList: {
      gap: SPACING.xs,
    },
    logEntry: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      padding: SPACING.md,
      flexDirection: 'row',
      alignItems: 'flex-start',
      borderWidth: 1,
      borderColor: COLORS.separator,
      borderLeftWidth: 3,
    },
    logIcon: {
      width: 28,
      height: 28,
      borderRadius: 14,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.sm,
    },
    logContent: {
      flex: 1,
    },
    logMessage: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      marginBottom: 2,
    },
    logTime: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
    },
    emptyText: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textTertiary,
      textAlign: 'center',
      fontStyle: 'italic',
      paddingVertical: SPACING.lg,
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Dashboard" />
      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        showsVerticalScrollIndicator={false}>
        {/* Stats Widgets */}
        <View style={styles.widgetRow}>
          <StatWidget
            title="Total Items"
            value={stats.totalItems.toString()}
            icon="inventory"
            iconColor="#007AFF"
          />
          <StatWidget
            title="Items / Day"
            value={stats.itemsPerDay.toString()}
            icon="trending-up"
            iconColor="#34C759"
          />
        </View>

        {/* Last Found Item */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Last Found Item</Text>
            <TouchableOpacity
              style={styles.sectionButton}
              onPress={() => navigation.navigate('Items')}>
              <Text style={styles.sectionButtonText}>View All</Text>
              <Icon name="chevron-right" size={18} color={COLORS.link} />
            </TouchableOpacity>
          </View>
          {lastItem ? (
            <View style={styles.lastItemCard}>
              <ItemCard item={lastItem} />
            </View>
          ) : (
            <Text style={styles.emptyText}>No items found yet</Text>
          )}
        </View>

        {/* Queries */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Queries</Text>
            <TouchableOpacity
              style={styles.sectionButton}
              onPress={() => navigation.navigate('Queries')}>
              <Text style={styles.sectionButtonText}>Manage</Text>
              <Icon name="chevron-right" size={18} color={COLORS.link} />
            </TouchableOpacity>
          </View>
          {queries.length > 0 ? (
            <View style={styles.queryList}>
              {queries.map(query => (
                <QueryCard
                  key={query.id}
                  query={query}
                  onPress={() => navigation.navigate('Items', {queryId: query.id})}
                />
              ))}
            </View>
          ) : (
            <Text style={styles.emptyText}>No active queries</Text>
          )}
        </View>

        {/* Logs */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Recent Logs</Text>
            <TouchableOpacity
              style={styles.sectionButton}
              onPress={() => navigation.navigate('Logs')}>
              <Text style={styles.sectionButtonText}>View All</Text>
              <Icon name="chevron-right" size={18} color={COLORS.link} />
            </TouchableOpacity>
          </View>
          {logs.length > 0 ? (
            <View style={styles.logsList}>
              {logs.map(log => {
                const color = getLogColor(log.level);
                const icon = getLogIcon(log.level);
                return (
                  <View key={log.id} style={[styles.logEntry, {borderLeftColor: color}]}>
                    <View style={[styles.logIcon, {backgroundColor: `${color}15`}]}>
                      <Icon name={icon} size={16} color={color} />
                    </View>
                    <View style={styles.logContent}>
                      <Text style={styles.logMessage} numberOfLines={2}>
                        {log.message}
                      </Text>
                      <Text style={styles.logTime}>{formatLogTime(log.timestamp)}</Text>
                    </View>
                  </View>
                );
              })}
            </View>
          ) : (
            <Text style={styles.emptyText}>No recent logs</Text>
          )}
        </View>
      </ScrollView>
    </View>
  );
};

export default DashboardScreen;
