import React from 'react';
import {View, Text, StyleSheet} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * StatWidget Component
 * Modern stat card for dashboard with tag, value, subheading, and last updated
 */
const StatWidget = ({tag, value, subheading, lastUpdated, icon, iconColor}) => {
  const COLORS = useThemeColors();

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      minHeight: 140,
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: 20,
      padding: SPACING.lg,
      shadowColor: '#000',
      shadowOffset: {width: 0, height: 2},
      shadowOpacity: 0.05,
      shadowRadius: 8,
      elevation: 2,
      borderWidth: 1,
      borderColor: COLORS.separator,
      justifyContent: 'space-between',
    },
    header: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: SPACING.xs,
    },
    tag: {
      fontSize: FONT_SIZES.caption1,
      fontWeight: '700',
      color: COLORS.textTertiary,
      letterSpacing: 0.5,
      textTransform: 'uppercase',
      flex: 1,
    },
    iconContainer: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: iconColor ? `${iconColor}15` : COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
    },
    content: {
      flex: 1,
      justifyContent: 'center',
    },
    value: {
      fontSize: 48,
      fontWeight: '700',
      color: COLORS.text,
      letterSpacing: -1,
      lineHeight: 52,
      marginBottom: 2,
    },
    subheading: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '500',
      color: COLORS.textSecondary,
      marginBottom: SPACING.xs,
    },
    footer: {
      marginTop: SPACING.xs,
    },
    lastUpdated: {
      fontSize: FONT_SIZES.caption2,
      fontWeight: '500',
      color: COLORS.textTertiary,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.tag}>{tag}</Text>
        <View style={styles.iconContainer}>
          <MaterialIcons name={icon} size={18} color={iconColor || COLORS.primary} />
        </View>
      </View>
      <View style={styles.content}>
        <Text style={styles.value}>{value}</Text>
        {subheading ? <Text style={styles.subheading}>{subheading}</Text> : null}
      </View>
      <View style={styles.footer}>
        <Text style={styles.lastUpdated}>{lastUpdated}</Text>
      </View>
    </View>
  );
};

export default StatWidget;
