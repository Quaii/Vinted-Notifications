import React, {useRef} from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Animated} from 'react-native';
import {Swipeable} from 'react-native-gesture-handler';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * QueryCard Component
 * Displays a search query in iOS list row format
 * iOS NATIVE DESIGN - Horizontal list row with icon and chevron
 * SWIPEABLE - Swipe left to reveal delete/edit, or fully swipe to delete
 */
const QueryCard = ({query, onPress, onDelete, onEdit, isLast = false}) => {
  const COLORS = useThemeColors();
  const swipeableRef = useRef(null);

  const styles = StyleSheet.create({
    row: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingVertical: SPACING.md + 4,
      backgroundColor: 'transparent',
      borderBottomWidth: isLast ? 0 : 0.5,
      borderBottomColor: COLORS.separator,
      minHeight: 76,
    },
    iconContainer: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: SPACING.md + 2,
    },
    content: {
      flex: 1,
      justifyContent: 'center',
    },
    title: {
      fontSize: FONT_SIZES.body + 1,
      fontWeight: '600',
      color: COLORS.text,
      marginBottom: 4,
    },
    subtitle: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textSecondary,
    },
    chevron: {
      marginLeft: SPACING.sm,
    },
    deleteButton: {
      padding: SPACING.xs,
      marginLeft: SPACING.xs,
    },
    rightActions: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    actionButton: {
      justifyContent: 'center',
      alignItems: 'center',
      width: 80,
      height: '100%',
    },
    editButton: {
      backgroundColor: COLORS.primary,
    },
    deleteActionButton: {
      backgroundColor: COLORS.error,
    },
    actionText: {
      color: '#FFFFFF',
      fontSize: FONT_SIZES.subheadline,
      fontWeight: '600',
      marginTop: 4,
    },
  });

  // Build subtitle: domain + last item time
  const domain = query.getDomain();
  const lastItemTime = query.getLastItemTime();
  const subtitle = lastItemTime && lastItemTime !== 'Never'
    ? `${domain} • ${lastItemTime}`
    : domain;

  const renderRightActions = (progress, dragX) => {
    const trans = dragX.interpolate({
      inputRange: [-160, 0],
      outputRange: [0, 160],
      extrapolate: 'clamp',
    });

    return (
      <Animated.View
        style={[
          styles.rightActions,
          {transform: [{translateX: trans}]},
        ]}>
        {onEdit && (
          <TouchableOpacity
            style={[styles.actionButton, styles.editButton]}
            onPress={() => {
              swipeableRef.current?.close();
              onEdit(query);
            }}>
            <MaterialIcons name="edit" size={22} color="#FFFFFF" />
            <Text style={styles.actionText}>Edit</Text>
          </TouchableOpacity>
        )}
        <TouchableOpacity
          style={[styles.actionButton, styles.deleteActionButton]}
          onPress={() => {
            swipeableRef.current?.close();
            onDelete(query);
          }}>
          <MaterialIcons name="delete" size={22} color="#FFFFFF" />
          <Text style={styles.actionText}>Delete</Text>
        </TouchableOpacity>
      </Animated.View>
    );
  };

  return (
    <Swipeable
      ref={swipeableRef}
      renderRightActions={renderRightActions}
      overshootRight={false}
      friction={2}
      rightThreshold={40}>
      <TouchableOpacity
        style={styles.row}
        onPress={() => onPress && onPress(query)}
        activeOpacity={0.6}>
        <View style={styles.iconContainer}>
          <MaterialIcons name="search" size={22} color={COLORS.primary} />
        </View>
        <View style={styles.content}>
          <Text style={styles.title} numberOfLines={1}>
            {query.query_name}
          </Text>
          <Text style={styles.subtitle} numberOfLines={1}>
            {subtitle}
          </Text>
        </View>
        <View style={styles.chevron}>
          <MaterialIcons name="chevron-right" size={20} color={COLORS.textTertiary} />
        </View>
      </TouchableOpacity>
    </Swipeable>
  );
};

export default QueryCard;
