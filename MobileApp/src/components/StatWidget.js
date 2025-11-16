import React from 'react';
import {View, Text, StyleSheet} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * StatWidget Component
 * Modern stat card for dashboard
 */
const StatWidget = ({title, value, icon, iconColor}) => {
  const COLORS = useThemeColors();

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.xl,
      padding: SPACING.lg,
      shadowColor: '#000',
      shadowOffset: {width: 0, height: 2},
      shadowOpacity: 0.05,
      shadowRadius: 8,
      elevation: 2,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    header: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: SPACING.md,
    },
    iconContainer: {
      width: 36,
      height: 36,
      borderRadius: 18,
      backgroundColor: iconColor ? `${iconColor}15` : COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.sm,
    },
    title: {
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '500',
      color: COLORS.textSecondary,
      flex: 1,
    },
    value: {
      fontSize: FONT_SIZES.title1,
      fontWeight: '700',
      color: COLORS.text,
      letterSpacing: -0.5,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.iconContainer}>
          <MaterialIcons name={icon} size={20} color={iconColor || COLORS.primary} />
        </View>
        <Text style={styles.title}>{title}</Text>
      </View>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
};

export default StatWidget;
