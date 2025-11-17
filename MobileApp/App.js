import React, {useEffect, useState} from 'react';
import {StatusBar, View, Text, ActivityIndicator} from 'react-native';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import {GestureHandlerRootView} from 'react-native-gesture-handler';
import {ThemeProvider, useTheme} from './src/contexts/ThemeContext';
import AppNavigator from './src/navigation/AppNavigator';
import DatabaseService from './src/services/DatabaseService';
import NotificationService from './src/services/NotificationService';
import MonitoringService from './src/services/MonitoringService';
import LogService from './src/services/LogService';
import VintedAPI from './src/api/VintedAPI';
import {useThemeColors} from './src/constants/theme';

/**
 * Main App Content (wrapped by ThemeProvider)
 */
const AppContent = () => {
  const COLORS = useThemeColors();
  const {isDarkMode} = useTheme();
  const [isReady, setIsReady] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      console.log('Initializing Vinted Notifications App...');
      LogService.info('Vinted Notifications app starting...');

      // Initialize database
      await DatabaseService.init();
      console.log('Database initialized');
      LogService.info('Database initialized successfully');

      // Load VintedAPI settings from database (user agents, headers, proxies)
      await VintedAPI.loadSettingsFromDatabase(DatabaseService);
      console.log('VintedAPI settings loaded');
      LogService.info('VintedAPI settings loaded from database');

      // Configure notifications
      await NotificationService.configure();
      console.log('Notifications configured');
      LogService.info('Notification service configured');

      // Initialize background fetch
      await MonitoringService.initBackgroundFetch();
      console.log('Background fetch initialized');
      LogService.info('Background fetch service initialized');

      // Initialize monitoring state (auto-starts if previously running)
      await MonitoringService.initializeState();
      console.log('Monitoring state initialized');

      console.log('App initialization complete');
      LogService.info('App initialization complete - ready to use');
      setIsReady(true);
    } catch (err) {
      console.error('Failed to initialize app:', err);
      LogService.error(`Failed to initialize app: ${err.message}`);
      setError(err.message);
      setIsReady(true); // Still show app even if some services fail
    }
  };

  const styles = {
    loadingContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: COLORS.background,
    },
    logo: {
      fontSize: 36,
      fontWeight: '700',
      color: COLORS.text,
      marginBottom: 8,
      letterSpacing: -1,
    },
    tagline: {
      fontSize: 14,
      color: COLORS.textTertiary,
      marginBottom: 48,
      letterSpacing: 2,
      textTransform: 'uppercase',
    },
    loadingText: {
      marginTop: 16,
      fontSize: 14,
      color: COLORS.textSecondary,
      fontWeight: '500',
    },
  };

  if (!isReady) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.logo}>Vinted Notifications</Text>
        <Text style={styles.tagline}>Never Miss a Deal</Text>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Initializing...</Text>
      </View>
    );
  }

  if (error) {
    console.warn('App started with initialization error:', error);
  }

  return (
    <>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={COLORS.background}
      />
      <AppNavigator />
    </>
  );
};

/**
 * Main App Component with GestureHandlerRootView, ThemeProvider and SafeAreaProvider
 */
const App = () => {
  return (
    <GestureHandlerRootView style={{flex: 1}}>
      <SafeAreaProvider>
        <ThemeProvider>
          <AppContent />
        </ThemeProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
};

export default App;
