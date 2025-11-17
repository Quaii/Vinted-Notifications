import React, {useState, useEffect, useCallback} from 'react';
import {View, Text, StyleSheet, ScrollView, Dimensions} from 'react-native';
import {LineChart, BarChart, PieChart} from 'react-native-chart-kit';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {PageHeader} from '../components';
import DatabaseService from '../services/DatabaseService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

const {width} = Dimensions.get('window');
const CHART_WIDTH = width - SPACING.lg * 2;

/**
 * AnalyticsScreen
 * Detailed statistics and analytics with proper charts
 */
const AnalyticsScreen = () => {
  const COLORS = useThemeColors();
  const [stats, setStats] = useState({
    totalItems: 0,
    avgPrice: 0,
    itemsToday: 0,
    itemsThisWeek: 0,
    dailyData: [],
    weeklyData: {},
    priceDistribution: [],
    brandDistribution: {},
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

      // Daily data for line chart (last 30 days)
      const dailyData = [];
      const dailyCounts = {};
      for (let i = 29; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        date.setHours(0, 0, 0, 0);
        const dateKey = date.toISOString().split('T')[0];
        dailyCounts[dateKey] = 0;
      }

      items.forEach(item => {
        const date = new Date(item.created_at_ts);
        date.setHours(0, 0, 0, 0);
        const dateKey = date.toISOString().split('T')[0];
        if (dailyCounts.hasOwnProperty(dateKey)) {
          dailyCounts[dateKey]++;
        }
      });

      Object.keys(dailyCounts).forEach(dateKey => {
        dailyData.push(dailyCounts[dateKey]);
      });

      // Weekly data for bar chart (day of week distribution)
      const weeklyData = {
        Mon: 0,
        Tue: 0,
        Wed: 0,
        Thu: 0,
        Fri: 0,
        Sat: 0,
        Sun: 0,
      };
      const dayMapping = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

      items.forEach(item => {
        const date = new Date(item.created_at_ts);
        const dayName = dayMapping[date.getDay()];
        weeklyData[dayName]++;
      });

      // Price distribution for pie chart
      const priceRanges = {
        '0-10€': 0,
        '10-25€': 0,
        '25-50€': 0,
        '50-100€': 0,
        '100+€': 0,
      };

      items.forEach(item => {
        const price = parseFloat(item.price) || 0;
        if (price < 10) priceRanges['0-10€']++;
        else if (price < 25) priceRanges['10-25€']++;
        else if (price < 50) priceRanges['25-50€']++;
        else if (price < 100) priceRanges['50-100€']++;
        else priceRanges['100+€']++;
      });

      const priceDistribution = Object.entries(priceRanges).map(([name, count], index) => ({
        name,
        count,
        color: [
          '#C8B588',
          '#B09D6F',
          '#D8C38F',
          '#6A7A8C',
          '#8F9BA8',
        ][index],
        legendFontColor: COLORS.text,
        legendFontSize: 13,
      }));

      // Brand distribution
      const brandCounts = {};
      items.forEach(item => {
        if (item.brand_title) {
          brandCounts[item.brand_title] = (brandCounts[item.brand_title] || 0) + 1;
        }
      });

      setStats({
        totalItems,
        avgPrice,
        itemsToday,
        itemsThisWeek,
        dailyData,
        weeklyData,
        priceDistribution,
        brandDistribution: brandCounts,
      });
    } catch (error) {
      console.error('Failed to load analytics:', error);
    }
  }, [COLORS.text]);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  const chartConfig = {
    backgroundColor: COLORS.secondaryGroupedBackground,
    backgroundGradientFrom: COLORS.secondaryGroupedBackground,
    backgroundGradientTo: COLORS.secondaryGroupedBackground,
    decimalPlaces: 0,
    color: (opacity = 1) => `rgba(200, 181, 136, ${opacity})`, // Champagne gold
    labelColor: (opacity = 1) => `rgba(250, 250, 250, ${opacity})`,
    style: {
      borderRadius: BORDER_RADIUS.xl,
    },
    propsForDots: {
      r: '2',
      strokeWidth: '1',
      stroke: '#C8B588',
    },
    propsForBackgroundLines: {
      strokeDasharray: '',
      stroke: 'rgba(255, 255, 255, 0.06)',
      strokeWidth: 1,
    },
    propsForLabels: {
      fontSize: 14,
      fontWeight: '600',
    },
  };

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
    analyticsWidget: {
      flex: 1,
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      padding: SPACING.md,
      borderWidth: 1,
      borderColor: COLORS.separator,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      height: 80,
    },
    widgetLeft: {
      flex: 1,
      justifyContent: 'center',
    },
    widgetLabel: {
      fontSize: FONT_SIZES.caption2,
      fontWeight: '700',
      color: COLORS.textTertiary,
      letterSpacing: 0.4,
      textTransform: 'uppercase',
      marginBottom: 4,
    },
    widgetValue: {
      fontSize: FONT_SIZES.title2,
      fontWeight: '700',
      color: COLORS.text,
      letterSpacing: -0.5,
    },
    emptyChartState: {
      paddingVertical: SPACING.xxl * 2,
      alignItems: 'center',
      justifyContent: 'center',
    },
    emptyChartText: {
      fontSize: FONT_SIZES.body,
      color: COLORS.textTertiary,
      textAlign: 'center',
      marginTop: SPACING.md,
    },
    widgetIcon: {
      width: 44,
      height: 44,
      borderRadius: 22,
      justifyContent: 'center',
      alignItems: 'center',
      marginLeft: SPACING.sm,
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
      alignItems: 'center',
    },
    chartDescription: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      textAlign: 'center',
      marginTop: SPACING.sm,
      marginBottom: SPACING.md,
    },
    bottomSpacer: {
      height: 120, // Extra space to account for tab bar (100px) + padding
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Analytics" />
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Overview Stats */}
        <View style={styles.section}>
          <View style={styles.widgetRow}>
            <View style={styles.analyticsWidget}>
              <View style={styles.widgetLeft}>
                <Text style={styles.widgetLabel} numberOfLines={1}>Total Items</Text>
                <Text style={styles.widgetValue}>{stats.totalItems}</Text>
              </View>
              <View style={[styles.widgetIcon, {backgroundColor: `${COLORS.primary}15`}]}>
                <MaterialIcons name="inventory" size={24} color={COLORS.primary} />
              </View>
            </View>
            <View style={styles.analyticsWidget}>
              <View style={styles.widgetLeft}>
                <Text style={styles.widgetLabel}>Avg. Price</Text>
                <Text style={styles.widgetValue}>{stats.avgPrice}€</Text>
              </View>
              <View style={[styles.widgetIcon, {backgroundColor: `${COLORS.primary}15`}]}>
                <MaterialIcons name="euro" size={24} color={COLORS.primary} />
              </View>
            </View>
          </View>
          <View style={styles.widgetRow}>
            <View style={styles.analyticsWidget}>
              <View style={styles.widgetLeft}>
                <Text style={styles.widgetLabel}>Today</Text>
                <Text style={styles.widgetValue}>{stats.itemsToday}</Text>
              </View>
              <View style={[styles.widgetIcon, {backgroundColor: `${COLORS.primary}15`}]}>
                <MaterialIcons name="today" size={24} color={COLORS.primary} />
              </View>
            </View>
            <View style={styles.analyticsWidget}>
              <View style={styles.widgetLeft}>
                <Text style={styles.widgetLabel}>This Week</Text>
                <Text style={styles.widgetValue}>{stats.itemsThisWeek}</Text>
              </View>
              <View style={[styles.widgetIcon, {backgroundColor: `${COLORS.primary}15`}]}>
                <MaterialIcons name="calendar-today" size={24} color={COLORS.primary} />
              </View>
            </View>
          </View>
        </View>

        {/* Area Chart - Items Over Time (Last 30 Days) */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Items Over Time</Text>
          <View style={styles.chartCard}>
            <Text style={styles.chartDescription}>Last 30 days</Text>
            {stats.dailyData.length > 0 && stats.totalItems > 0 ? (
              <LineChart
                data={{
                  labels: ['', '', '', '', '', ''],
                  datasets: [
                    {
                      data: stats.dailyData.length > 0 ? stats.dailyData : [0],
                    },
                  ],
                }}
                width={CHART_WIDTH - SPACING.lg * 2}
                height={220}
                yAxisLabel=""
                yAxisSuffix=""
                yLabelsOffset={25}
                chartConfig={{
                  ...chartConfig,
                  fillShadowGradientFrom: '#C8B588',
                  fillShadowGradientFromOpacity: 0.8,
                  fillShadowGradientTo: COLORS.secondaryGroupedBackground,
                  fillShadowGradientToOpacity: 0.2,
                  propsForLabels: {
                    fontSize: 13,
                    fontWeight: '600',
                  },
                }}
                bezier
                style={{
                  borderRadius: BORDER_RADIUS.lg,
                  marginLeft: -25,
                }}
                withInnerLines={true}
                withOuterLines={true}
                withVerticalLines={false}
                withHorizontalLines={true}
                withDots={false}
                withShadow={true}
                fromZero={true}
                segments={4}
              />
            ) : (
              <View style={styles.emptyChartState}>
                <MaterialIcons name="show-chart" size={64} color={COLORS.textTertiary} />
                <Text style={styles.emptyChartText}>No information available at this point in time</Text>
              </View>
            )}
          </View>
        </View>

        {/* Bar Chart - Items by Day of Week */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Items by Day of Week</Text>
          <View style={styles.chartCard}>
            <Text style={styles.chartDescription}>Weekly distribution</Text>
            {Object.keys(stats.weeklyData).length > 0 && stats.totalItems > 0 ? (
              <BarChart
                data={{
                  labels: Object.keys(stats.weeklyData),
                  datasets: [
                    {
                      data: Object.values(stats.weeklyData).length > 0
                        ? Object.values(stats.weeklyData)
                        : [0],
                    },
                  ],
                }}
                width={CHART_WIDTH - SPACING.lg * 2}
                height={220}
                yAxisLabel=""
                yAxisSuffix=""
                yLabelsOffset={25}
                chartConfig={{
                  ...chartConfig,
                  propsForLabels: {
                    fontSize: 13,
                    fontWeight: '600',
                  },
                }}
                style={{
                  borderRadius: BORDER_RADIUS.lg,
                  marginLeft: -25,
                }}
                withInnerLines={true}
                showBarTops={false}
                fromZero={true}
                withVerticalLabels={true}
                withHorizontalLabels={true}
                segments={4}
              />
            ) : (
              <View style={styles.emptyChartState}>
                <MaterialIcons name="bar-chart" size={64} color={COLORS.textTertiary} />
                <Text style={styles.emptyChartText}>No information available at this point in time</Text>
              </View>
            )}
          </View>
        </View>

        {/* Pie Chart - Price Distribution */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Price Distribution</Text>
          <View style={styles.chartCard}>
            <Text style={styles.chartDescription}>Items grouped by price range</Text>
            {stats.priceDistribution.length > 0 && stats.totalItems > 0 ? (
              <PieChart
                data={stats.priceDistribution}
                width={CHART_WIDTH - SPACING.lg * 2}
                height={220}
                chartConfig={chartConfig}
                accessor="count"
                backgroundColor="transparent"
                paddingLeft="15"
                absolute
                hasLegend={true}
                style={{
                  borderRadius: BORDER_RADIUS.lg,
                }}
              />
            ) : (
              <View style={styles.emptyChartState}>
                <MaterialIcons name="pie-chart" size={64} color={COLORS.textTertiary} />
                <Text style={styles.emptyChartText}>No information available at this point in time</Text>
              </View>
            )}
          </View>
        </View>

        {/* Area Chart - Cumulative Items */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Cumulative Growth</Text>
          <View style={styles.chartCard}>
            <Text style={styles.chartDescription}>Total items accumulated over last 30 days</Text>
            {stats.dailyData.length > 0 && stats.totalItems > 0 ? (
              <LineChart
                data={{
                  labels: ['', '', '', '', '', ''],
                  datasets: [
                    {
                      data: stats.dailyData.reduce((acc, val, idx) => {
                        acc.push((acc[idx - 1] || 0) + val);
                        return acc;
                      }, []),
                    },
                  ],
                }}
                width={CHART_WIDTH - SPACING.lg * 2}
                height={220}
                yAxisLabel=""
                yAxisSuffix=""
                yLabelsOffset={25}
                chartConfig={{
                  ...chartConfig,
                  fillShadowGradientFrom: '#C8B588',
                  fillShadowGradientFromOpacity: 0.8,
                  fillShadowGradientTo: COLORS.secondaryGroupedBackground,
                  fillShadowGradientToOpacity: 0.2,
                  propsForLabels: {
                    fontSize: 13,
                    fontWeight: '600',
                  },
                }}
                bezier
                style={{
                  borderRadius: BORDER_RADIUS.lg,
                  marginLeft: -25,
                }}
                withInnerLines={true}
                withOuterLines={true}
                withVerticalLines={false}
                withHorizontalLines={true}
                withDots={false}
                withShadow={true}
                fromZero={true}
                segments={4}
              />
            ) : (
              <View style={styles.emptyChartState}>
                <MaterialIcons name="trending-up" size={64} color={COLORS.textTertiary} />
                <Text style={styles.emptyChartText}>No information available at this point in time</Text>
              </View>
            )}
          </View>
        </View>

        {/* Bottom spacer for tab bar */}
        <View style={styles.bottomSpacer} />
      </ScrollView>
    </View>
  );
};

export default AnalyticsScreen;
