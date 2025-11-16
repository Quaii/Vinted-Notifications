import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Alert} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {COLORS, SPACING, FONT_SIZES, BORDER_RADIUS, SHADOWS} from '../constants/theme';

/**
 * QueryCard Component
 * Displays a search query in a card format
 */
const QueryCard = ({query, onPress, onDelete}) => {
  const handleDelete = () => {
    Alert.alert(
      'Delete Query',
      `Are you sure you want to delete "${query.query_name}"?`,
      [
        {text: 'Cancel', style: 'cancel'},
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => onDelete && onDelete(query),
        },
      ],
    );
  };

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={() => onPress && onPress(query)}
      activeOpacity={0.7}>
      <View style={styles.header}>
        <Icon name="search" size={24} color={COLORS.primary} />
        <View style={styles.headerText}>
          <Text style={styles.title} numberOfLines={1}>
            {query.query_name}
          </Text>
          <Text style={styles.domain}>{query.getDomain()}</Text>
        </View>
        <TouchableOpacity onPress={handleDelete} style={styles.deleteButton}>
          <Icon name="delete" size={24} color={COLORS.error} />
        </TouchableOpacity>
      </View>
      <View style={styles.footer}>
        <View style={styles.infoItem}>
          <Icon name="schedule" size={16} color={COLORS.textSecondary} />
          <Text style={styles.infoText}>{query.getLastItemTime()}</Text>
        </View>
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{query.getCountryCode()}</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: BORDER_RADIUS.lg,
    marginHorizontal: SPACING.md,
    marginVertical: SPACING.sm,
    padding: SPACING.md,
    ...SHADOWS.small,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: SPACING.md,
  },
  headerText: {
    flex: 1,
    marginLeft: SPACING.md,
  },
  title: {
    fontSize: FONT_SIZES.lg,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: SPACING.xs,
  },
  domain: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textSecondary,
  },
  deleteButton: {
    padding: SPACING.xs,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  infoItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  infoText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textSecondary,
    marginLeft: SPACING.xs,
  },
  badge: {
    backgroundColor: COLORS.primaryLight,
    borderRadius: BORDER_RADIUS.sm,
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
  },
  badgeText: {
    fontSize: FONT_SIZES.xs,
    fontWeight: '600',
    color: COLORS.surface,
  },
});

export default QueryCard;
