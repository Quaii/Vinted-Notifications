import {useColorScheme, Platform, PlatformColor} from 'react-native';

/**
 * iOS Native Colors
 * Uses iOS system colors that automatically adapt to dark mode,
 * high contrast mode, and accessibility settings
 */

// Helper to get platform color or fallback
const platformColor = (iosColor, fallbackLight, fallbackDark) => {
  if (Platform.OS === 'ios') {
    return PlatformColor(iosColor);
  }
  const colorScheme = useColorScheme();
  return colorScheme === 'dark' ? fallbackDark : fallbackLight;
};

// iOS System Colors
export const IOS_COLORS = {
  // Labels
  label: PlatformColor('label'),                          // Primary text
  secondaryLabel: PlatformColor('secondaryLabel'),        // Secondary text
  tertiaryLabel: PlatformColor('tertiaryLabel'),          // Tertiary text
  quaternaryLabel: PlatformColor('quaternaryLabel'),      // Quaternary text

  // Backgrounds
  systemBackground: PlatformColor('systemBackground'),                    // Main background
  secondarySystemBackground: PlatformColor('secondarySystemBackground'),  // Secondary background
  tertiarySystemBackground: PlatformColor('tertiarySystemBackground'),    // Tertiary background

  // Grouped backgrounds (for lists)
  systemGroupedBackground: PlatformColor('systemGroupedBackground'),
  secondarySystemGroupedBackground: PlatformColor('secondarySystemGroupedBackground'),
  tertiarySystemGroupedBackground: PlatformColor('tertiarySystemGroupedBackground'),

  // Fills (for buttons, controls)
  systemFill: PlatformColor('systemFill'),
  secondarySystemFill: PlatformColor('secondarySystemFill'),
  tertiarySystemFill: PlatformColor('tertiarySystemFill'),
  quaternarySystemFill: PlatformColor('quaternarySystemFill'),

  // Grays
  systemGray: PlatformColor('systemGray'),
  systemGray2: PlatformColor('systemGray2'),
  systemGray3: PlatformColor('systemGray3'),
  systemGray4: PlatformColor('systemGray4'),
  systemGray5: PlatformColor('systemGray5'),
  systemGray6: PlatformColor('systemGray6'),

  // Colors
  systemBlue: PlatformColor('systemBlue'),
  systemGreen: PlatformColor('systemGreen'),
  systemIndigo: PlatformColor('systemIndigo'),
  systemOrange: PlatformColor('systemOrange'),
  systemPink: PlatformColor('systemPink'),
  systemPurple: PlatformColor('systemPurple'),
  systemRed: PlatformColor('systemRed'),
  systemTeal: PlatformColor('systemTeal'),
  systemYellow: PlatformColor('systemYellow'),

  // Semantic colors
  link: PlatformColor('link'),
  placeholderText: PlatformColor('placeholderText'),
  separator: PlatformColor('separator'),
  opaqueSeparator: PlatformColor('opaqueSeparator'),
};

// Semantic mapping for app
export const COLORS = {
  // Primary
  primary: IOS_COLORS.systemTeal,
  primaryText: IOS_COLORS.label,

  // Backgrounds
  background: IOS_COLORS.systemBackground,
  secondaryBackground: IOS_COLORS.secondarySystemBackground,
  groupedBackground: IOS_COLORS.systemGroupedBackground,
  secondaryGroupedBackground: IOS_COLORS.secondarySystemGroupedBackground,
  cardBackground: IOS_COLORS.secondarySystemGroupedBackground,

  // Text
  text: IOS_COLORS.label,
  textSecondary: IOS_COLORS.secondaryLabel,
  textTertiary: IOS_COLORS.tertiaryLabel,
  textQuaternary: IOS_COLORS.quaternaryLabel,
  placeholder: IOS_COLORS.placeholderText,

  // Status
  success: IOS_COLORS.systemGreen,
  error: IOS_COLORS.systemRed,
  warning: IOS_COLORS.systemOrange,
  info: IOS_COLORS.systemBlue,

  // UI Elements
  separator: IOS_COLORS.separator,
  border: IOS_COLORS.separator,
  link: IOS_COLORS.link,

  // Buttons & Controls
  buttonFill: IOS_COLORS.systemFill,
  secondaryButtonFill: IOS_COLORS.secondarySystemFill,
};

// Hook to get current color scheme (for conditional logic)
export const useThemeColors = () => {
  return COLORS; // Returns iOS system colors that auto-adapt
};

export const useColorScheme = () => {
  return useColorScheme();
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
