import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Linking} from 'react-native';
import FastImage from '@d11/react-native-fast-image';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS, SHADOWS} from '../constants/theme';

/**
 * ItemCard Component
 * Displays a Vinted item in a card format (with dark mode support)
 */
const ItemCard = ({item, onPress}) => {
  const COLORS = useThemeColors();

  const handlePress = () => {
    if (onPress) {
      onPress(item);
    } else if (item.url) {
      Linking.openURL(item.url);
    }
  };

  const styles = StyleSheet.create({
    card: {
      backgroundColor: COLORS.surface,
      borderRadius: BORDER_RADIUS.lg,
      marginHorizontal: SPACING.md,
      marginVertical: SPACING.sm,
      overflow: 'hidden',
      ...SHADOWS.medium,
    },
    image: {
      width: '100%',
      height: 200,
      backgroundColor: COLORS.background,
    },
    content: {
      padding: SPACING.md,
    },
    title: {
      fontSize: FONT_SIZES.lg,
      fontWeight: '600',
      color: COLORS.text,
      marginBottom: SPACING.sm,
    },
    details: {
      marginBottom: SPACING.sm,
    },
    detailRow: {
      flexDirection: 'row',
      marginBottom: SPACING.xs,
    },
    detailLabel: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.textSecondary,
      marginRight: SPACING.xs,
    },
    detailValue: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.text,
      fontWeight: '500',
    },
    footer: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginTop: SPACING.xs,
    },
    price: {
      fontSize: FONT_SIZES.xl,
      fontWeight: '700',
      color: COLORS.primary,
    },
    time: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.textLight,
    },
  });

  return (
    <TouchableOpacity style={styles.card} onPress={handlePress} activeOpacity={0.7}>
      <FastImage
        style={styles.image}
        source={{
          uri: item.getPhotoUrl() || 'https://via.placeholder.com/150',
          priority: FastImage.priority.normal,
        }}
        resizeMode={FastImage.resizeMode.cover}
      />
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={2}>
          {item.title}
        </Text>
        <View style={styles.details}>
          {item.brand_title ? (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Brand:</Text>
              <Text style={styles.detailValue}>{item.brand_title}</Text>
            </View>
          ) : null}
          {item.size_title ? (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Size:</Text>
              <Text style={styles.detailValue}>{item.size_title}</Text>
            </View>
          ) : null}
        </View>
        <View style={styles.footer}>
          <Text style={styles.price}>{item.getFormattedPrice()}</Text>
          <Text style={styles.time}>{item.getTimeSincePosted()}</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
};

export default ItemCard;
