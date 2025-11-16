import React, {useState, useEffect, useCallback} from 'react';
import {View, Text, StyleSheet, ScrollView, Dimensions} from 'react-native';
import {PageHeader, StatWidget} from '../components';
import DatabaseService from '../services/DatabaseService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

const {width} = Dimensions.get('window');

/**
 * AnalyticsScreen
 * Detailed statistics and analytics
 */
const AnalyticsScreen = () => {
  const COLORS = useThemeColors();
  const [stats, setStats] = useState({
    totalItems: 0,
    avgPrice: 0,
    itemsToday: 0,
    itemsThisWeek: 0,
    topBrands: [],
    dayDistribution: {},
  });

  const loadAnalytics = useCallback(async () => {
    try {
      // Get all items
      const items = await DatabaseService.getItems(null, 10000);

      // Calculate total items
      const totalItems = items.length;

      // Calculate average price
      const totalPrice = items.reduce((sum, item) => {
        const price = parseFloat(item.price) || 0;
        return sum + price;
      }, 0);
      const avgPrice = totalItems > 0 ? (totalPrice / totalItems).toFixed(2) : 0;

      // Calculate items today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const itemsToday = items.filter(item => {
        return item.created_at_ts >= today.getTime();
      }).length;

      // Calculate items this week
      const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      const itemsThisWeek = items.filter(item => {
        return item.created_at_ts >= weekAgo;
      }).length;

      // Day distribution (last 7 days)
      const dayDistribution = {};
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      for (let i = 0; i < 7; i++) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        date.setHours(0, 0, 0, 0);
        const dayName = days[date.getDay()];
        dayDistribution[dayName] = 0;
      }

      items.forEach(item => {
        const date = new Date(item.created_at_ts);
        const dayName = days[date.getDay()];
        if (dayDistribution.hasOwnProperty(dayName)) {
          dayDistribution[dayName]++;
        }
      });

      setStats({
        totalItems,
        avgPrice,
        itemsToday,
        itemsThisWeek,
        topBrands: [],
        dayDistribution,
      });
    } catch (error) {
      console.error('Failed to load analytics:', error);
    }
  }, []);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    content: {
      padding: SPACING.lg,
    },
    widgetRow: {
      flexDirection: 'row',
      gap: SPACING.md,
      marginBottom: SPACING.md,
    },
    section: {
      marginBottom: SPACING.xl,
    },
    sectionTitle: {
      fontSize: FONT_SIZES.title3,
      fontWeight: '600',
      color: COLORS.text,
      marginBottom: SPACING.md,
    },
    chartCard: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.xl,
      padding: SPACING.lg,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    barChartRow: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: SPACING.md,
    },
    barLabel: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '600',
      color: COLORS.text,
      width: 36,
    },
    barContainer: {
      flex: 1,
      height: 24,
      backgroundColor: COLORS.buttonFill,
      borderRadius: BORDER_RADIUS.sm,
      marginHorizontal: SPACING.sm,
      overflow: 'hidden',
    },
    bar: {
      height: '100%',
      borderRadius: BORDER_RADIUS.sm,
      minWidth: 2,
    },
    barCount: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '700',
      color: COLORS.primary,
      width: 32,
      textAlign: 'right',
    },
    comingSoon: {
      textAlign: 'center',
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textTertiary,
      fontStyle: 'italic',
      paddingVertical: SPACING.xl,
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Analytics" />
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Overview Stats */}
        <View style={styles.section}>
          <View style={styles.widgetRow}>
            <StatWidget
              title="Total Items"
              value={stats.totalItems.toString()}
              icon="inventory"
              iconColor="#007AFF"
            />
            <StatWidget
              title="Average Price"
              value={`${stats.avgPrice}€`}
              icon="euro"
              iconColor="#34C759"
            />
          </View>
          <View style={styles.widgetRow}>
            <StatWidget
              title="Today"
              value={stats.itemsToday.toString()}
              icon="today"
              iconColor="#FF9500"
            />
            <StatWidget
              title="This Week"
              value={stats.itemsThisWeek.toString()}
              icon="calendar-today"
              iconColor="#5856D6"
            />
          </View>
        </View>

        {/* Day Distribution - Bar Chart */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Items by Day of Week</Text>
          <View style={styles.chartCard}>
            {Object.entries(stats.dayDistribution).map(([day, count]) => {
              const maxCount = Math.max(...Object.values(stats.dayDistribution), 1);
              const barWidth = (count / maxCount) * 100;

              return (
                <View key={day} style={styles.barChartRow}>
                  <Text style={styles.barLabel}>{day}</Text>
                  <View style={styles.barContainer}>
                    <View
                      style={[
                        styles.bar,
                        {
                          width: `${barWidth}%`,
                          backgroundColor: COLORS.primary,
                        },
                      ]}
                    />
                  </View>
                  <Text style={styles.barCount}>{count}</Text>
                </View>
              );
            })}
          </View>
        </View>

        {/* Brand Analytics - Coming Soon */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Brand Analytics</Text>
          <View style={styles.chartCard}>
            <Text style={styles.comingSoon}>
              Brand statistics will be available once brand tracking is implemented
            </Text>
          </View>
        </View>
      </ScrollView>
    </View>
  );
};

export default AnalyticsScreen;
