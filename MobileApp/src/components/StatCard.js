import React from 'react';
import {View, Text, StyleSheet} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS, SHADOWS} from '../constants/theme';

/**
 * StatCard Component
 * Displays a statistic with an icon (with dark mode support)
 */
const StatCard = ({icon, label, value, color}) => {
  const COLORS = useThemeColors();
  const cardColor = color || COLORS.primary;

  const styles = StyleSheet.create({
    card: {
      backgroundColor: COLORS.surface,
      borderRadius: BORDER_RADIUS.lg,
      padding: SPACING.md,
      flexDirection: 'row',
      alignItems: 'center',
      borderLeftWidth: 4,
      ...SHADOWS.small,
    },
    iconContainer: {
      width: 56,
      height: 56,
      borderRadius: BORDER_RADIUS.md,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.md,
    },
    content: {
      flex: 1,
    },
    value: {
      fontSize: FONT_SIZES.xxxl,
      fontWeight: '700',
      color: COLORS.text,
      marginBottom: SPACING.xs,
    },
    label: {
      fontSize: FONT_SIZES.md,
      color: COLORS.textSecondary,
    },
  });

  return (
    <View style={[styles.card, {borderLeftColor: cardColor}]}>
      <View style={[styles.iconContainer, {backgroundColor: cardColor + '20'}]}>
        <Icon name={icon} size={32} color={cardColor} />
      </View>
      <View style={styles.content}>
        <Text style={styles.value}>{value}</Text>
        <Text style={styles.label}>{label}</Text>
      </View>
    </View>
  );
};

export default StatCard;
