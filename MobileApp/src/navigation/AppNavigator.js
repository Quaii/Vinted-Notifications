import React from 'react';
import {View, useColorScheme, StyleSheet} from 'react-native';
import {NavigationContainer, DefaultTheme, DarkTheme} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import MaterialIcons from '@react-native-vector-icons/material-icons';
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

  return (
    <Tab.Navigator
      safeAreaInsets={{left: 0, right: 0, bottom: 0, top: 0}}
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

          return <MaterialIcons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: COLORS.primary,
        tabBarInactiveTintColor: COLORS.textSecondary,
        tabBarStyle: {
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: COLORS.secondaryGroupedBackground,
          borderTopColor: COLORS.border,
          borderTopWidth: 1,
          height: 100,
          paddingBottom: 20,
          paddingTop: 12,
          paddingLeft: 0,
          paddingRight: 0,
          width: '100%',
        },
        tabBarLabelStyle: {
          fontSize: FONT_SIZES.caption2,
          fontWeight: '600',
          marginTop: 4,
          marginBottom: 0,
        },
        tabBarItemStyle: {
          flex: 1, // let each tab take equal space
          paddingVertical: 4,
          paddingHorizontal: 0,
          marginHorizontal: 0,
          alignItems: 'center', // center icon+label horizontally
          justifyContent: 'center', // center vertically within the tab item
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

  // Create custom navigation theme using our theme colors
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
      <RootStack.Navigator screenOptions={{headerShown: false}}>
        <RootStack.Screen name="Tabs" component={TabNavigator} />
        <RootStack.Screen
          name="Settings"
          component={SettingsScreen}
          options={{presentation: 'modal'}}
        />
      </RootStack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
