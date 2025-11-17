import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
} from 'react-native';
import {useFocusEffect} from '@react-navigation/native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
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
    lastItemTime: null,
    lastCalculatedTime: Date.now(),
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
      const itemsPerDay = recentItems.length > 0 ? Math.round(recentItems.length / 7) : 0;

      // Get last item timestamp
      const lastItemTime = items.length > 0 ? items[0].created_at_ts : null;

      setStats({
        totalItems,
        itemsPerDay,
        lastItemTime,
        lastCalculatedTime: Date.now(),
      });

      // Load last found item
      if (items.length > 0) {
        setLastItem(items[0]);
      }

      // Load queries (max 2)
      const allQueries = await DatabaseService.getQueries(true);
      setQueries(allQueries.slice(0, 2));

      // Load recent logs (max 3)
      setLogs(LogService.getLogs(3));
    } catch (error) {
      console.error('Failed to load dashboard:', error);
      LogService.log(`Failed to load dashboard: ${error.message}`);
    }
  }, []);

  // Reload dashboard when screen is focused
  useFocusEffect(
    useCallback(() => {
      loadDashboard();
    }, [loadDashboard])
  );

  // Subscribe to log updates (only once)
  useEffect(() => {
    const unsubscribe = LogService.subscribe((updatedLogs) => {
      setLogs(updatedLogs.slice(0, 3));
    });

    return () => {
      if (unsubscribe) {
        unsubscribe();
      }
    };
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadDashboard();
    setRefreshing(false);
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

  const formatRelativeTime = timestamp => {
    if (!timestamp) return 'Never';

    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes} minute${minutes === 1 ? '' : 's'} ago`;
    if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;
    if (days === 1) return 'Yesterday';
    if (days < 7) return `${days} days ago`;
    return `${days} days ago`;
  };

  const getLevelColor = level => {
    switch (level) {
      case 'ERROR':
        return COLORS.error;
      case 'WARNING':
        return COLORS.warning;
      case 'INFO':
      default:
        return COLORS.info;
    }
  };

  const getLevelIcon = level => {
    switch (level) {
      case 'ERROR':
        return 'error';
      case 'WARNING':
        return 'warning';
      case 'INFO':
      default:
        return 'info';
    }
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
      paddingHorizontal: 0,
      paddingVertical: 0,
      backgroundColor: 'transparent',
    },
    sectionButtonText: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginRight: 2,
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
      borderWidth: 1,
      borderColor: COLORS.separator,
      borderLeftWidth: 4,
    },
    logHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: SPACING.xs,
    },
    levelBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.xs,
      paddingVertical: 2,
      borderRadius: BORDER_RADIUS.sm,
      gap: 4,
      marginRight: SPACING.sm,
    },
    levelText: {
      fontSize: FONT_SIZES.caption2,
      fontWeight: '700',
      letterSpacing: 0.5,
    },
    logMessage: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      lineHeight: 20,
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
            tag="Total Items"
            value={stats.totalItems.toString()}
            subheading={stats.totalItems === 0 ? 'No items yet' : `${stats.totalItems} item${stats.totalItems === 1 ? '' : 's'} cached`}
            lastUpdated={stats.lastItemTime ? formatRelativeTime(stats.lastItemTime) : 'No items found'}
            icon="inventory"
            iconColor={COLORS.primary}
          />
          <StatWidget
            tag="Items / Day"
            value={stats.itemsPerDay.toString()}
            subheading="Last 7 days"
            lastUpdated={formatRelativeTime(stats.lastCalculatedTime)}
            icon="trending-up"
            iconColor={COLORS.primary}
          />
        </View>

        {/* Last Found Item */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Last Found Item</Text>
            <TouchableOpacity
              style={styles.sectionButton}
              onPress={() => navigation.navigate('Items')}
              activeOpacity={0.6}>
              <Text style={styles.sectionButtonText}>View All</Text>
              <MaterialIcons name="chevron-right" size={18} color={COLORS.textSecondary} />
            </TouchableOpacity>
          </View>
          {lastItem ? (
            <ItemCard item={lastItem} compact={true} />
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
              onPress={() => navigation.navigate('Queries')}
              activeOpacity={0.6}>
              <Text style={styles.sectionButtonText}>Manage</Text>
              <MaterialIcons name="chevron-right" size={18} color={COLORS.textSecondary} />
            </TouchableOpacity>
          </View>
          {queries.length > 0 ? (
            <View style={styles.queryList}>
              {queries.map(query => (
                <QueryCard
                  key={query.id}
                  query={query}
                  onPress={() => navigation.navigate('Items', {queryId: query.id})}
                  disableSwipe={true}
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
              onPress={() => navigation.navigate('Logs')}
              activeOpacity={0.6}>
              <Text style={styles.sectionButtonText}>View All</Text>
              <MaterialIcons name="chevron-right" size={18} color={COLORS.textSecondary} />
            </TouchableOpacity>
          </View>
          {logs.length > 0 ? (
            <View style={styles.logsList}>
              {logs.map(log => {
                const levelColor = getLevelColor(log.level);
                const levelIcon = getLevelIcon(log.level);
                return (
                  <View key={log.id} style={[styles.logEntry, {borderLeftColor: levelColor}]}>
                    <View style={styles.logHeader}>
                      <View style={[styles.levelBadge, {backgroundColor: `${levelColor}20`}]}>
                        <MaterialIcons name={levelIcon} size={14} color={levelColor} />
                        <Text style={[styles.levelText, {color: levelColor}]}>
                          {log.level || 'INFO'}
                        </Text>
                      </View>
                      <Text style={styles.logTime}>{formatLogTime(log.timestamp)}</Text>
                    </View>
                    <Text style={styles.logMessage} numberOfLines={2}>
                      {log.message}
                    </Text>
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
