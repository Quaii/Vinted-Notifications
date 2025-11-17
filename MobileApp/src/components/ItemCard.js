import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet, Linking, Image} from 'react-native';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * ItemCard Component
 * Displays a Vinted item in iOS list row format
 * iOS NATIVE DESIGN - Horizontal list row with thumbnail
 */
const ItemCard = ({item, onPress, isLast = false}) => {
  const COLORS = useThemeColors();

  const handlePress = () => {
    if (onPress) {
      onPress(item);
    } else if (item.url) {
      Linking.openURL(item.url);
    }
  };

  const styles = StyleSheet.create({
    row: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: 5,
      paddingVertical: 5,
      backgroundColor: 'transparent',
      borderBottomWidth: 0,
      borderBottomColor: COLORS.separator,
      minHeight: 74,
    },
    thumbnail: {
      width: 64,
      height: 64,
      borderRadius: 10,
      backgroundColor: COLORS.buttonFill,
      marginRight: SPACING.sm,
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
    <TouchableOpacity style={styles.row} onPress={handlePress} activeOpacity={0.6}>
      <Image
        style={styles.thumbnail}
        source={{uri: item.getPhotoUrl() || 'https://via.placeholder.com/150'}}
        resizeMode="cover"
      />
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={2}>
          {item.title}
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
  );
};

export default ItemCard;
