import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet} from 'react-native';
import {SafeAreaView} from 'react-native-safe-area-context';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useNavigation} from '@react-navigation/native';
import {useThemeColors, SPACING, FONT_SIZES} from '../constants/theme';

/**
 * PageHeader Component
 * Modern page header with title and settings button
 * Properly handles safe areas for notch/Dynamic Island
 */
const PageHeader = ({title, showSettings = true, showBack = false}) => {
  const COLORS = useThemeColors();
  const navigation = useNavigation();

  const handleSettingsPress = () => {
    navigation.navigate('Settings');
  };

  const handleBackPress = () => {
    navigation.goBack();
  };

  const styles = StyleSheet.create({
    safeArea: {
      backgroundColor: COLORS.background,
    },
    container: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingTop: SPACING.sm,
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
      padding: SPACING.xs,
    },
    backButton: {
      padding: SPACING.xs,
    },
  });

  return (
    <SafeAreaView edges={['top']} style={styles.safeArea}>
      <View style={styles.container}>
        {showBack && (
          <TouchableOpacity
            style={styles.backButton}
            onPress={handleBackPress}
            activeOpacity={0.6}>
            <MaterialIcons name="close" size={34} color={COLORS.text} />
          </TouchableOpacity>
        )}
        <Text style={styles.title}>{title}</Text>
        {showSettings && (
          <TouchableOpacity
            style={styles.settingsButton}
            onPress={handleSettingsPress}
            activeOpacity={0.6}>
            <MaterialIcons name="settings" size={34} color={COLORS.primary} />
          </TouchableOpacity>
        )}
      </View>
    </SafeAreaView>
  );
};

export default PageHeader;
