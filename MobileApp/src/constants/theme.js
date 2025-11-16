import {useContext} from 'react';
import {ThemeContext} from '../contexts/ThemeContext';

/**
 * Modern Theme Colors
 * Dark mode first approach with light mode toggle
 */

// Dark theme colors (default)
const DARK_COLORS = {
  // Primary
  primary: '#10B981',
  primaryDark: '#059669',
  primaryLight: '#34D399',

  // Backgrounds
  background: '#0F172A',
  secondaryBackground: '#1E293B',
  groupedBackground: '#0F172A',
  secondaryGroupedBackground: '#1E293B',
  cardBackground: '#1E293B',
  tertiaryBackground: '#334155',

  // Text
  text: '#F1F5F9',
  textSecondary: '#CBD5E1',
  textTertiary: '#94A3B8',
  placeholder: '#64748B',

  // Status
  success: '#10B981',
  error: '#EF4444',
  warning: '#F59E0B',
  info: '#3B82F6',

  // UI Elements
  separator: '#334155',
  border: '#334155',
  link: '#3B82F6',

  // Buttons & Controls
  buttonFill: '#334155',
  secondaryButtonFill: '#475569',
};

// Light theme colors
const LIGHT_COLORS = {
  // Primary
  primary: '#10B981',
  primaryDark: '#059669',
  primaryLight: '#34D399',

  // Backgrounds
  background: '#F8FAFC',
  secondaryBackground: '#FFFFFF',
  groupedBackground: '#F8FAFC',
  secondaryGroupedBackground: '#FFFFFF',
  cardBackground: '#FFFFFF',
  tertiaryBackground: '#F1F5F9',

  // Text
  text: '#0F172A',
  textSecondary: '#475569',
  textTertiary: '#64748B',
  placeholder: '#94A3B8',

  // Status
  success: '#10B981',
  error: '#EF4444',
  warning: '#F59E0B',
  info: '#3B82F6',

  // UI Elements
  separator: '#E2E8F0',
  border: '#E2E8F0',
  link: '#3B82F6',

  // Buttons & Controls
  buttonFill: '#F1F5F9',
  secondaryButtonFill: '#E2E8F0',
};

// Hook to get current theme colors
export const useThemeColors = () => {
  const themeContext = useContext(ThemeContext);
  // If ThemeContext is not available (e.g., during initialization), default to dark mode
  const isDarkMode = themeContext?.isDarkMode ?? true;
  return isDarkMode ? DARK_COLORS : LIGHT_COLORS;
};

// iOS Typography Scale (Dynamic Type)
export const FONT_SIZES = {
  largeTitle: 34,    // iOS Large Title
  title1: 28,        // iOS Title 1
  title2: 22,        // iOS Title 2
  title3: 20,        // iOS Title 3
  headline: 17,      // iOS Headline (semibold)
  body: 17,          // iOS Body (regular)
  callout: 16,       // iOS Callout
  subheadline: 15,   // iOS Subheadline
  footnote: 13,      // iOS Footnote
  caption1: 12,      // iOS Caption 1
  caption2: 11,      // iOS Caption 2
};

// iOS Font Weights
export const FONT_WEIGHTS = {
  ultraLight: '100',
  thin: '200',
  light: '300',
  regular: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
  heavy: '800',
  black: '900',
};

// iOS Standard Font Families
export const FONTS = {
  // Use SF Pro (iOS system font) - React Native uses by default
  regular: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontWeight: '400',
  },
  medium: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontWeight: '500',
  },
  semibold: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontWeight: '600',
  },
  bold: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontWeight: '700',
  },
};

// iOS Standard Spacing (8pt grid)
export const SPACING = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 16,    // Standard margin
  lg: 20,
  xl: 24,
  xxl: 32,
  xxxl: 48,
};

// iOS Standard Border Radius
export const BORDER_RADIUS = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 10,
  xl: 12,
  xxl: 16,
  round: 999,
};

// iOS Standard Shadows
export const SHADOWS = {
  small: {
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.18,
    shadowRadius: 1.0,
    elevation: 1,
  },
  medium: {
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.20,
    shadowRadius: 3.0,
    elevation: 2,
  },
  large: {
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 4},
    shadowOpacity: 0.22,
    shadowRadius: 5.0,
    elevation: 4,
  },
};

// iOS Standard Component Heights
export const HEIGHTS = {
  navBar: 44,
  tabBar: 49,
  listRow: 44,
  listRowLarge: 60,
  button: 44,
  input: 44,
};

// iOS Standard Layout
export const LAYOUT = {
  screenPadding: SPACING.md,        // 16pt margin from edges
  listInset: SPACING.md,            // 16pt list inset
  sectionSpacing: SPACING.lg,       // 20pt between sections
  cardPadding: SPACING.md,          // 16pt inside cards
  listSeparatorInset: SPACING.md,   // 16pt separator inset
};

// Animation durations (iOS standard)
export const ANIMATION = {
  quick: 200,
  standard: 300,
  slow: 500,
};
