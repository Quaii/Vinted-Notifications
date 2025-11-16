import React from 'react';
import {useColorScheme} from 'react-native';
import {NavigationContainer, DefaultTheme, DarkTheme} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createStackNavigator} from '@react-navigation/stack';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {
  DashboardScreen,
  QueriesScreen,
  ItemsScreen,
  SettingsScreen,
} from '../screens';
import {useThemeColors, FONT_SIZES, DARK_COLORS, LIGHT_COLORS} from '../constants/theme';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

/**
 * Items Stack Navigator
 */
const ItemsStack = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
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
        }}
      />
      <Tab.Screen
        name="Queries"
        component={QueriesScreen}
        options={{
          tabBarLabel: 'Queries',
        }}
      />
      <Tab.Screen
        name="Items"
        component={ItemsStack}
        options={{
          tabBarLabel: 'Items',
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          tabBarLabel: 'Settings',
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

  // Create custom navigation theme based on color scheme
  const navigationTheme = scheme === 'dark' ? {
    ...DarkTheme,
    colors: {
      ...DarkTheme.colors,
      primary: DARK_COLORS.primary,
      background: DARK_COLORS.background,
      card: DARK_COLORS.surface,
      text: DARK_COLORS.text,
      border: DARK_COLORS.border,
      notification: DARK_COLORS.primary,
    },
  } : {
    ...DefaultTheme,
    colors: {
      ...DefaultTheme.colors,
      primary: LIGHT_COLORS.primary,
      background: LIGHT_COLORS.background,
      card: LIGHT_COLORS.surface,
      text: LIGHT_COLORS.text,
      border: LIGHT_COLORS.border,
      notification: LIGHT_COLORS.primary,
    },
  };

  return (
    <NavigationContainer theme={navigationTheme}>
      <TabNavigator />
    </NavigationContainer>
  );
};

export default AppNavigator;
