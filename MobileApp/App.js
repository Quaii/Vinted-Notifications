import React, {useEffect, useState} from 'react';
import {StatusBar, View, Text, StyleSheet, ActivityIndicator, useColorScheme} from 'react-native';
import AppNavigator from './src/navigation/AppNavigator';
import DatabaseService from './src/services/DatabaseService';
import NotificationService from './src/services/NotificationService';
import MonitoringService from './src/services/MonitoringService';
import {useThemeColors} from './src/constants/theme';

/**
 * Main App Component (with dark mode support)
 */
const App = () => {
  const COLORS = useThemeColors();
  const scheme = useColorScheme();
  const [isReady, setIsReady] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      console.log('Initializing Vinted Notifications App...');

      // Initialize database
      await DatabaseService.init();
      console.log('Database initialized');

      // Configure notifications
      await NotificationService.configure();
      console.log('Notifications configured');

      // Initialize background fetch
      await MonitoringService.initBackgroundFetch();
      console.log('Background fetch initialized');

      // Initialize monitoring state (auto-starts if previously running)
      await MonitoringService.initializeState();
      console.log('Monitoring state initialized');

      console.log('App initialization complete');
      setIsReady(true);
    } catch (err) {
      console.error('Failed to initialize app:', err);
      setError(err.message);
      setIsReady(true); // Still show app even if some services fail
    }
  };

  const styles = StyleSheet.create({
    loadingContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: COLORS.background,
    },
    loadingText: {
      marginTop: 16,
      fontSize: 16,
      color: COLORS.textSecondary,
    },
  });

  if (!isReady) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  if (error) {
    console.warn('App started with initialization error:', error);
  }

  return (
    <>
      <StatusBar
        barStyle={scheme === 'dark' ? 'light-content' : 'dark-content'}
        backgroundColor={COLORS.primary}
      />
      <AppNavigator />
    </>
  );
};

export default App;
