import {useColorScheme} from 'react-native';

// Light theme colors
export const LIGHT_COLORS = {
  // Primary colors
  primary: '#09B1BA',
  primaryDark: '#078A91',
  primaryLight: '#4DD4DC',

  // Secondary colors
  secondary: '#FF6B9D',
  secondaryDark: '#E5527D',
  secondaryLight: '#FF9FBF',

  // Neutral colors
  background: '#F5F5F5',
  surface: '#FFFFFF',
  card: '#FFFFFF',

  // Text colors
  text: '#1A1A1A',
  textSecondary: '#666666',
  textLight: '#999999',

  // Status colors
  success: '#4CAF50',
  error: '#F44336',
  warning: '#FF9800',
  info: '#2196F3',

  // UI colors
  border: '#E0E0E0',
  divider: '#E0E0E0',
  overlay: 'rgba(0, 0, 0, 0.5)',
  shadow: '#000000',
  inputBackground: '#F5F5F5',
};

// Dark theme colors
export const DARK_COLORS = {
  // Primary colors (slightly brighter for dark mode)
  primary: '#1FCCDB',
  primaryDark: '#09B1BA',
  primaryLight: '#5FE0E8',

  // Secondary colors
  secondary: '#FF8AB5',
  secondaryDark: '#FF6B9D',
  secondaryLight: '#FFA9C9',

  // Neutral colors
  background: '#0F0F0F',
  surface: '#1A1A1A',
  card: '#242424',

  // Text colors
  text: '#FFFFFF',
  textSecondary: '#B0B0B0',
  textLight: '#808080',

  // Status colors
  success: '#66BB6A',
  error: '#EF5350',
  warning: '#FFA726',
  info: '#42A5F5',

  // UI colors
  border: '#333333',
  divider: '#333333',
  overlay: 'rgba(0, 0, 0, 0.7)',
  shadow: '#000000',
  inputBackground: '#2A2A2A',
};

// Hook to get current theme colors
export const useThemeColors = () => {
  const colorScheme = useColorScheme();
  return colorScheme === 'dark' ? DARK_COLORS : LIGHT_COLORS;
};

// Default to light colors for non-component usage
export const COLORS = LIGHT_COLORS;

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const FONT_SIZES = {
  xs: 10,
  sm: 12,
  md: 14,
  lg: 16,
  xl: 18,
  xxl: 24,
  xxxl: 32,
};

export const FONT_WEIGHTS = {
  regular: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
};

export const BORDER_RADIUS = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  round: 999,
};

export const SHADOWS = {
  small: {
    shadowColor: COLORS.shadow,
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  medium: {
    shadowColor: COLORS.shadow,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 4,
  },
  large: {
    shadowColor: COLORS.shadow,
    shadowOffset: {
      width: 0,
      height: 6,
    },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 8,
  },
};
