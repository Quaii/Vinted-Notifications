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
 * Logs display with level-based color coding (matching desktop app)
 */
const LogsScreen = () => {
  const COLORS = useThemeColors();
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    // Initial load
    setLogs(LogService.getLogs());

    // Subscribe to updates
    const unsubscribe = LogService.subscribe(updatedLogs => {
      setLogs(updatedLogs);
    });

    return unsubscribe;
  }, []);

  const formatTime = timestamp => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  const formatDate = timestamp => {
    const date = new Date(timestamp);
    const today = new Date();
    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    }
    return date.toLocaleDateString('en-US', {month: 'short', day: 'numeric'});
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

  const renderLogEntry = ({item}) => {
    const levelColor = getLevelColor(item.level);
    const levelIcon = getLevelIcon(item.level);

    return (
      <View style={[styles.logEntry, {borderLeftColor: levelColor, borderLeftWidth: 4}]}>
        <View style={styles.logHeader}>
          <View style={styles.logHeaderLeft}>
            <View style={[styles.levelBadge, {backgroundColor: `${levelColor}20`}]}>
              <Icon name={levelIcon} size={14} color={levelColor} />
              <Text style={[styles.levelText, {color: levelColor}]}>
                {item.level || 'INFO'}
              </Text>
            </View>
            <Text style={styles.logDate}>{formatDate(item.timestamp)}</Text>
          </View>
          <Text style={styles.logTime}>{formatTime(item.timestamp)}</Text>
        </View>
        <Text style={styles.logMessage}>{item.message}</Text>
      </View>
    );
  };

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Icon name="description" size={64} color={COLORS.textTertiary} />
      <Text style={styles.emptyText}>No logs yet</Text>
      <Text style={styles.emptySubtext}>
        Application events will appear here
      </Text>
    </View>
  );

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    listContainer: {
      padding: SPACING.lg,
    },
    logEntry: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      padding: SPACING.md,
      marginBottom: SPACING.sm,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    logHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: SPACING.xs,
    },
    logHeaderLeft: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: SPACING.sm,
      flex: 1,
    },
    levelBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.xs,
      paddingVertical: 2,
      borderRadius: BORDER_RADIUS.sm,
      gap: 4,
    },
    levelText: {
      fontSize: FONT_SIZES.caption2,
      fontWeight: '700',
      letterSpacing: 0.5,
    },
    logDate: {
      fontSize: FONT_SIZES.caption1,
      fontWeight: '500',
      color: COLORS.textSecondary,
    },
    logTime: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
      fontFamily: 'monospace',
    },
    logMessage: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      lineHeight: 20,
    },
    emptyState: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      paddingVertical: SPACING.xxl * 3,
      paddingHorizontal: SPACING.lg,
    },
    emptyText: {
      fontSize: FONT_SIZES.title2,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginTop: SPACING.lg,
      marginBottom: SPACING.xs,
    },
    emptySubtext: {
      fontSize: FONT_SIZES.body,
      color: COLORS.textTertiary,
      textAlign: 'center',
    },
  });

  const handleClearLogs = () => {
    LogService.clearLogs();
  };

  return (
    <View style={styles.container}>
      <PageHeader title="Logs" />
      {logs.length > 0 ? (
        <FlatList
          data={logs}
          renderItem={renderLogEntry}
          keyExtractor={item => item.id.toString()}
          contentContainerStyle={styles.listContainer}
          showsVerticalScrollIndicator={false}
        />
      ) : (
        renderEmpty()
      )}
    </View>
  );
};

export default LogsScreen;
