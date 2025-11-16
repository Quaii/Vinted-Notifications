import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {PageHeader} from '../components';
import LogService from '../services/LogService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * LogsScreen
 * Display application logs
 */
const LogsScreen = () => {
  const COLORS = useThemeColors();
  const [logs, setLogs] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    // Initial load
    loadLogs();

    // Subscribe to updates
    const unsubscribe = LogService.subscribe(() => {
      loadLogs();
    });

    return unsubscribe;
  }, [filter]);

  const loadLogs = () => {
    if (filter === 'all') {
      setLogs(LogService.getLogs(200));
    } else {
      setLogs(LogService.getLogsByLevel(filter, 200));
    }
  };

  const getLogIcon = level => {
    switch (level) {
      case 'success':
        return 'check-circle';
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      case 'debug':
        return 'bug-report';
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
      case 'debug':
        return '#5856D6';
      default:
        return '#007AFF';
    }
  };

  const formatTime = timestamp => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  const renderLogEntry = ({item}) => {
    const color = getLogColor(item.level);
    const icon = getLogIcon(item.level);

    return (
      <View style={[styles.logEntry, {borderLeftColor: color}]}>
        <View style={styles.logHeader}>
          <View style={[styles.logIcon, {backgroundColor: `${color}15`}]}>
            <Icon name={icon} size={16} color={color} />
          </View>
          <Text style={styles.logTime}>{formatTime(item.timestamp)}</Text>
          <View style={[styles.levelBadge, {backgroundColor: `${color}20`}]}>
            <Text style={[styles.levelText, {color}]}>
              {item.level.toUpperCase()}
            </Text>
          </View>
        </View>
        <Text style={styles.logMessage}>{item.message}</Text>
        {item.data && (
          <Text style={styles.logData} numberOfLines={2}>
            {JSON.stringify(item.data)}
          </Text>
        )}
      </View>
    );
  };

  const renderFilterButton = (label, value) => {
    const isActive = filter === value;
    return (
      <TouchableOpacity
        style={[styles.filterButton, isActive && styles.filterButtonActive]}
        onPress={() => setFilter(value)}>
        <Text
          style={[
            styles.filterButtonText,
            isActive && styles.filterButtonTextActive,
          ]}>
          {label}
        </Text>
      </TouchableOpacity>
    );
  };

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Icon name="description" size={48} color={COLORS.textTertiary} />
      <Text style={styles.emptyText}>No logs available</Text>
    </View>
  );

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    filters: {
      flexDirection: 'row',
      paddingHorizontal: SPACING.lg,
      paddingVertical: SPACING.md,
      gap: SPACING.sm,
    },
    filterButton: {
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.xs,
      borderRadius: BORDER_RADIUS.md,
      backgroundColor: COLORS.buttonFill,
    },
    filterButtonActive: {
      backgroundColor: COLORS.primary,
    },
    filterButtonText: {
      fontSize: FONT_SIZES.footnote,
      fontWeight: '600',
      color: COLORS.textSecondary,
    },
    filterButtonTextActive: {
      color: '#FFFFFF',
    },
    listContainer: {
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.xl,
    },
    logEntry: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      padding: SPACING.md,
      marginBottom: SPACING.sm,
      borderLeftWidth: 3,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    logHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: SPACING.xs,
    },
    logIcon: {
      width: 24,
      height: 24,
      borderRadius: 12,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.xs,
    },
    logTime: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
      fontWeight: '500',
      flex: 1,
    },
    levelBadge: {
      paddingHorizontal: SPACING.xs,
      paddingVertical: 2,
      borderRadius: BORDER_RADIUS.sm,
    },
    levelText: {
      fontSize: FONT_SIZES.caption2,
      fontWeight: '700',
    },
    logMessage: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      lineHeight: 20,
    },
    logData: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textSecondary,
      fontFamily: 'Courier',
      marginTop: SPACING.xs,
      paddingTop: SPACING.xs,
      borderTopWidth: 1,
      borderTopColor: COLORS.separator,
    },
    emptyState: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      paddingVertical: SPACING.xxl * 2,
    },
    emptyText: {
      fontSize: FONT_SIZES.body,
      color: COLORS.textTertiary,
      marginTop: SPACING.md,
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Logs" />
      <View style={styles.filters}>
        {renderFilterButton('All', 'all')}
        {renderFilterButton('Info', 'info')}
        {renderFilterButton('Success', 'success')}
        {renderFilterButton('Warning', 'warning')}
        {renderFilterButton('Error', 'error')}
      </View>
      <FlatList
        data={logs}
        renderItem={renderLogEntry}
        keyExtractor={item => item.id.toString()}
        contentContainerStyle={styles.listContainer}
        ListEmptyComponent={renderEmpty}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
};

export default LogsScreen;
