import React, {useRef, useState} from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Animated} from 'react-native';
import {Swipeable, TapGestureHandler, State} from 'react-native-gesture-handler';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * QueryCard Component
 * Displays a search query in iOS list row format
 * iOS NATIVE DESIGN - Horizontal list row with icon and chevron
 * SWIPEABLE - Swipe left to reveal delete/edit (only when onDelete/onEdit provided)
 */
const QueryCard = ({query, onPress, onDelete, onEdit, isLast = false, disableSwipe = false}) => {
  const COLORS = useThemeColors();
  const swipeableRef = useRef(null);
  const [isSwiping, setIsSwiping] = useState(false);

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
      backgroundColor: COLORS.primary, // Champagne gold accent color
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
            style={[styles.actionButton, {backgroundColor: COLORS.primary}]}
            onPress={() => {
              swipeableRef.current?.close();
              onEdit(query);
            }}>
            <MaterialIcons name="edit" size={22} color="#FFFFFF" />
            <Text style={styles.actionText}>Edit</Text>
          </TouchableOpacity>
        )}
        {onDelete && (
          <TouchableOpacity
            style={[styles.actionButton, styles.deleteActionButton]}
            onPress={() => {
              swipeableRef.current?.close();
              onDelete(query);
            }}>
            <MaterialIcons name="delete" size={22} color="#FFFFFF" />
            <Text style={styles.actionText}>Delete</Text>
          </TouchableOpacity>
        )}
      </Animated.View>
    );
  };

  const handlePress = () => {
    // Only trigger press if we're not actively swiping
    if (!isSwiping && onPress) {
      onPress(query);
    }
  };

  const cardContent = (
    <TouchableOpacity
      style={styles.row}
      onPress={handlePress}
      activeOpacity={0.6}
      disabled={isSwiping}>
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
  );

  // Only enable swipe if handlers are provided and swipe is not disabled
  const swipeEnabled = !disableSwipe && (onDelete || onEdit);

  if (!swipeEnabled) {
    return cardContent;
  }

  return (
    <Swipeable
      ref={swipeableRef}
      renderRightActions={renderRightActions}
      overshootRight={false}
      friction={2}
      rightThreshold={40}
      onSwipeableWillOpen={() => setIsSwiping(true)}
      onSwipeableClose={() => setIsSwiping(false)}
      onSwipeableOpen={() => setIsSwiping(true)}
      onBegan={() => setIsSwiping(true)}
      onEnded={() => setTimeout(() => setIsSwiping(false), 100)}>
      {cardContent}
    </Swipeable>
  );
};

export default QueryCard;
