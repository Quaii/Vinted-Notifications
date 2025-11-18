import React, {useMemo} from 'react';
import {View, useColorScheme, StyleSheet, Dimensions} from 'react-native';
import {NavigationContainer, DefaultTheme, DarkTheme} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import {
  DashboardScreen,
  QueriesScreen,
  ItemsScreen,
  AnalyticsScreen,
  LogsScreen,
  SettingsScreen,
} from '../screens';
import {useThemeColors, FONT_SIZES} from '../constants/theme';

const Tab = createBottomTabNavigator();
const RootStack = createNativeStackNavigator();

/**
 * Bottom Tab Navigator (with dark mode support)
 * Contains only the 5 visible tabs for proper distribution
 */
const TabNavigator = () => {
  const COLORS = useThemeColors();
  const insets = useSafeAreaInsets();
  const screenWidth = Dimensions.get('window').width;

  // DEBUG: Log all dimensions and insets
  console.log('🔍 TAB BAR DEBUG:', {
    screenWidth,
    perTabWidth: screenWidth / 5,
    insets,
    hasLeftInset: insets.left > 0,
    hasRightInset: insets.right > 0,
  });

  // Calculate proper bottom padding for devices with home indicator
  const tabBarHeight = 49; // Standard iOS tab bar height
  const bottomPadding = Math.max(insets.bottom, 20); // Use safe area or minimum 20px

  return (
    <Tab.Navigator
      sceneContainerStyle={{backgroundColor: COLORS.background}}
      screenOptions={({route}) => ({
        headerShown: false,
        presentation: 'card',
        tabBarIcon: ({focused, color, size}) => {
          let iconName;

          switch (route.name) {
            case 'Dashboard':
              iconName = 'home';
              break;
            case 'Queries':
              iconName = 'search';
              break;
            case 'Items':
              iconName = 'inventory';
              break;
            case 'Analytics':
              iconName = 'analytics';
              break;
            case 'Logs':
              iconName = 'description';
              break;
            default:
              iconName = 'circle';
          }

          // Wrap icon in View for consistent alignment
          return (
            <View style={{
              alignItems: 'center',
              justifyContent: 'center',
              width: size, // Force icon container to exact size
              height: size,
            }}>
              <MaterialIcons
                name={iconName}
                size={size}
                color={color}
                style={{
                  textAlign: 'center',
                  width: size,
                  height: size,
                }}
              />
            </View>
          );
        },
        tabBarActiveTintColor: COLORS.primary,
        tabBarInactiveTintColor: COLORS.textSecondary,
        tabBarStyle: {
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0, // Try both constraints together
          width: screenWidth, // CRITICAL: Force exact screen width for React 19
          backgroundColor: COLORS.secondaryGroupedBackground,
          borderTopColor: COLORS.border,
          borderTopWidth: 1, // Use whole number instead of hairline
          height: tabBarHeight + bottomPadding,
          paddingBottom: bottomPadding,
          paddingTop: 8,
          paddingLeft: 0, // Explicit instead of paddingHorizontal
          paddingRight: 0,
          marginLeft: 0, // Explicit instead of marginHorizontal
          marginRight: 0,
        },
        tabBarLabelStyle: {
          fontSize: FONT_SIZES.caption2,
          fontWeight: '600',
          marginTop: 2,
          marginBottom: 0,
        },
        tabBarItemStyle: {
          width: screenWidth / 5, // CRITICAL: Explicit width for 5 tabs (React 19 fix)
          paddingVertical: 0,
          paddingHorizontal: 0,
          marginHorizontal: 0,
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: tabBarHeight,
        },
        tabBarIconStyle: {
          marginTop: 0,
          marginBottom: 0,
        },
      })}>
      <Tab.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{
          tabBarLabel: 'Dashboard',
          presentation: 'card',
        }}
      />
      <Tab.Screen
        name="Queries"
        component={QueriesScreen}
        options={{
          tabBarLabel: 'Queries',
          presentation: 'card',
        }}
      />
      <Tab.Screen
        name="Items"
        component={ItemsScreen}
        options={{
          tabBarLabel: 'Items',
          presentation: 'card',
        }}
      />
      <Tab.Screen
        name="Analytics"
        component={AnalyticsScreen}
        options={{
          tabBarLabel: 'Analytics',
          presentation: 'card',
        }}
      />
      <Tab.Screen
        name="Logs"
        component={LogsScreen}
        options={{
          tabBarLabel: 'Logs',
          presentation: 'card',
        }}
      />
    </Tab.Navigator>
  );
};

/**
 * Main App Navigator (with dark mode support)
 * Uses a Stack Navigator to hold Tabs + Settings modal
 */
const AppNavigator = () => {
  const COLORS = useThemeColors();
  const scheme = useColorScheme();

  // Memoize navigation theme to prevent recreation on every render
  const navigationTheme = useMemo(
    () => ({
      ...(scheme === 'dark' ? DarkTheme : DefaultTheme),
      colors: {
        ...(scheme === 'dark' ? DarkTheme.colors : DefaultTheme.colors),
        primary: COLORS.primary,
        background: COLORS.background,
        card: COLORS.cardBackground,
        text: COLORS.text,
        border: COLORS.border,
        notification: COLORS.primary,
      },
    }),
    [scheme, COLORS]
  );

  return (
    <NavigationContainer theme={navigationTheme}>
      <View
        style={{flex: 1}}
        onLayout={(e) => {
          console.log('📐 ROOT CONTAINER LAYOUT:', {
            width: e.nativeEvent.layout.width,
            height: e.nativeEvent.layout.height,
          });
        }}>
        <RootStack.Navigator screenOptions={{headerShown: false}}>
          <RootStack.Screen name="Tabs" component={TabNavigator} />
          <RootStack.Screen
            name="Settings"
            component={SettingsScreen}
            options={{presentation: 'modal'}}
          />
        </RootStack.Navigator>
      </View>
    </NavigationContainer>
  );
};

export default AppNavigator;
