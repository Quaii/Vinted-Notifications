import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES} from '../constants/theme';

/**
 * QueryCard Component
 * Displays a search query in iOS list row format
 * iOS NATIVE DESIGN - Horizontal list row with icon and chevron
 */
const QueryCard = ({query, onPress, onDelete, isLast = false}) => {
  const COLORS = useThemeColors();

  const styles = StyleSheet.create({
    row: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm + 2,
      backgroundColor: 'transparent',
      borderBottomWidth: isLast ? 0 : 0.5,
      borderBottomColor: COLORS.separator,
      minHeight: 60,
    },
    iconContainer: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.md,
    },
    content: {
      flex: 1,
      justifyContent: 'center',
    },
    title: {
      fontSize: FONT_SIZES.body,
      fontWeight: '500',
      color: COLORS.text,
      marginBottom: 3,
    },
    subtitle: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textSecondary,
    },
    chevron: {
      marginLeft: SPACING.sm,
    },
    deleteButton: {
      padding: SPACING.xs,
      marginLeft: SPACING.xs,
    },
  });

  // Build subtitle: domain + last item time
  const domain = query.getDomain();
  const lastItemTime = query.getLastItemTime();
  const subtitle = lastItemTime && lastItemTime !== 'Never'
    ? `${domain} • ${lastItemTime}`
    : domain;

  return (
    <TouchableOpacity
      style={styles.row}
      onPress={() => onPress && onPress(query)}
      activeOpacity={0.6}>
      <View style={styles.iconContainer}>
        <MaterialIcons name="search" size={18} color={COLORS.primary} />
      </View>
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={1}>
          {query.query_name}
        </Text>
        <Text style={styles.subtitle} numberOfLines={1}>
          {subtitle}
        </Text>
      </View>
      {onDelete && (
        <TouchableOpacity
          style={styles.deleteButton}
          onPress={(e) => {
            e.stopPropagation();
            onDelete(query);
          }}
          activeOpacity={0.6}>
          <MaterialIcons name="delete" size={20} color={COLORS.error} />
        </TouchableOpacity>
      )}
      <View style={styles.chevron}>
        <MaterialIcons name="chevron-right" size={20} color={COLORS.textTertiary} />
      </View>
    </TouchableOpacity>
  );
};

export default QueryCard;
