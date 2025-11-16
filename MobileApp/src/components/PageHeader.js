import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {useNavigation} from '@react-navigation/native';
import {useThemeColors, SPACING, FONT_SIZES} from '../constants/theme';

/**
 * PageHeader Component
 * Modern page header with title and settings button
 */
const PageHeader = ({title, showSettings = true}) => {
  const COLORS = useThemeColors();
  const navigation = useNavigation();

  const handleSettingsPress = () => {
    navigation.navigate('Settings');
  };

  const styles = StyleSheet.create({
    container: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingTop: SPACING.xl,
      paddingBottom: SPACING.md,
      backgroundColor: COLORS.background,
    },
    title: {
      fontSize: FONT_SIZES.largeTitle,
      fontWeight: '700',
      color: COLORS.text,
      letterSpacing: -0.5,
    },
    settingsButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
      shadowColor: '#000',
      shadowOffset: {width: 0, height: 2},
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 3,
    },
  });

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      {showSettings && (
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
          activeOpacity={0.7}>
          <Icon name="settings" size={22} color={COLORS.primary} />
        </TouchableOpacity>
      )}
    </View>
  );
};

export default PageHeader;
