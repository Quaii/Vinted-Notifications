import React, {useState} from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Linking, Image} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * ItemCard Component
 * Displays a Vinted item in iOS list row format
 * iOS NATIVE DESIGN - Horizontal list row with thumbnail
 */
const ItemCard = ({item, onPress, isLast = false, compact = false}) => {
  const COLORS = useThemeColors();
  const [imageError, setImageError] = useState(false);

  const handlePress = () => {
    if (onPress) {
      onPress(item);
    } else if (item.url) {
      Linking.openURL(item.url);
    }
  };

  const thumbnailSize = compact ? 90 : 74;
  const thumbnailPadding = compact ? SPACING.xs : SPACING.md;
  const cardMargin = compact ? 0 : SPACING.lg;

  const styles = StyleSheet.create({
    card: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: cardMargin,
      borderRadius: BORDER_RADIUS.xl,
      borderWidth: 1,
      borderColor: COLORS.separator,
      overflow: 'hidden',
    },
    row: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: thumbnailPadding,
      paddingVertical: thumbnailPadding,
      backgroundColor: 'transparent',
      minHeight: compact ? 106 : 90,
    },
    thumbnail: {
      width: thumbnailSize,
      height: thumbnailSize,
      borderRadius: 10,
      backgroundColor: COLORS.buttonFill,
      marginRight: SPACING.md,
    },
    placeholderContainer: {
      width: thumbnailSize,
      height: thumbnailSize,
      borderRadius: 10,
      backgroundColor: COLORS.buttonFill,
      marginRight: SPACING.md,
      justifyContent: 'center',
      alignItems: 'center',
    },
    content: {
      flex: 1,
      justifyContent: 'center',
    },
    title: {
      fontSize: FONT_SIZES.body,
      fontWeight: '500',
      color: COLORS.text,
      marginBottom: 4,
    },
    subtitle: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textSecondary,
      marginBottom: 2,
    },
    time: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
    },
    priceContainer: {
      alignItems: 'flex-end',
      justifyContent: 'center',
      marginLeft: SPACING.sm,
    },
    price: {
      fontSize: FONT_SIZES.headline,
      fontWeight: '600',
      color: COLORS.primary,
    },
  });

  // Build subtitle text (brand + size)
  const subtitleParts = [];
  if (item.brand_title) subtitleParts.push(item.brand_title);
  if (item.size_title) subtitleParts.push(`Size ${item.size_title}`);
  const subtitle = subtitleParts.join(' • ');

  return (
    <View style={styles.card}>
      <TouchableOpacity style={styles.row} onPress={handlePress} activeOpacity={0.6}>
        {imageError || !item.getPhotoUrl() ? (
          <View style={styles.placeholderContainer}>
            <MaterialIcons name="broken-image" size={32} color={COLORS.textTertiary} />
          </View>
        ) : (
          <Image
            style={styles.thumbnail}
            source={{uri: item.getPhotoUrl()}}
            resizeMode="cover"
            onError={() => setImageError(true)}
          />
        )}
        <View style={styles.content}>
          <Text style={styles.title} numberOfLines={2}>
            {item.title || '[Corrupt Data - Clear Items in Settings]'}
          </Text>
          {subtitle ? (
            <Text style={styles.subtitle} numberOfLines={1}>
              {subtitle}
            </Text>
          ) : null}
          <Text style={styles.time}>{item.getTimeSincePosted()}</Text>
        </View>
        <View style={styles.priceContainer}>
          <Text style={styles.price}>{item.getFormattedPrice()}</Text>
        </View>
      </TouchableOpacity>
    </View>
  );
};

export default ItemCard;
