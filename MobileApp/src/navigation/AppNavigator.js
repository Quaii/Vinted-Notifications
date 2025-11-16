import React from 'react';
import {useColorScheme} from 'react-native';
import {NavigationContainer, DefaultTheme, DarkTheme} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createStackNavigator} from '@react-navigation/stack';
import Icon from '@react-native-vector-icons/material-icons';
import {
  DashboardScreen,
  QueriesScreen,
  ItemsScreen,
  SettingsScreen,
} from '../screens';
import {useThemeColors, FONT_SIZES, COLORS} from '../constants/theme';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

/**
 * Items Stack Navigator
 * Using 'card' presentation to avoid iOS 17+ native sheet issues
 */
const ItemsStack = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        presentation: 'card', // Explicitly use card instead of modal/formSheet
        animationEnabled: true,
      }}>
      <Stack.Screen name="ItemsList" component={ItemsScreen} />
    </Stack.Navigator>
  );
};

/**
 * Bottom Tab Navigator (with dark mode support)
 */
const TabNavigator = () => {
  const COLORS = useThemeColors();

  return (
    <Tab.Navigator
      screenOptions={({route}) => ({
        headerShown: false,
        presentation: 'card', // Force card presentation for all tabs
        tabBarIcon: ({focused, color, size}) => {
          let iconName;

          switch (route.name) {
            case 'Dashboard':
              iconName = 'dashboard';
              break;
            case 'Queries':
              iconName = 'search';
              break;
            case 'Items':
              iconName = 'inventory';
              break;
            case 'Settings':
              iconName = 'settings';
              break;
            default:
              iconName = 'circle';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: COLORS.primary,
        tabBarInactiveTintColor: COLORS.textSecondary,
        tabBarStyle: {
          backgroundColor: COLORS.surface,
          borderTopColor: COLORS.border,
          borderTopWidth: 1,
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        tabBarLabelStyle: {
          fontSize: FONT_SIZES.xs,
          fontWeight: '600',
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
        component={ItemsStack}
        options={{
          tabBarLabel: 'Items',
          presentation: 'card',
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          tabBarLabel: 'Settings',
          presentation: 'card',
        }}
      />
    </Tab.Navigator>
  );
};

/**
 * Main App Navigator (with dark mode support)
 */
const AppNavigator = () => {
  const scheme = useColorScheme();

  // Create custom navigation theme using iOS system colors (auto-adapts to dark mode)
  const navigationTheme = {
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
  };

  return (
    <NavigationContainer theme={navigationTheme}>
      <TabNavigator />
    </NavigationContainer>
  );
};

export default AppNavigator;
