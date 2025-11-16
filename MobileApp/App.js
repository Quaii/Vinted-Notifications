import React, {useEffect, useState} from 'react';
import {StatusBar, View, Text, StyleSheet, ActivityIndicator} from 'react-native';
import AppNavigator from './src/navigation/AppNavigator';
import DatabaseService from './src/services/DatabaseService';
import NotificationService from './src/services/NotificationService';
import MonitoringService from './src/services/MonitoringService';
import {COLORS} from './src/constants/theme';

/**
 * Main App Component
 */
const App = () => {
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
      NotificationService.configure();
      await NotificationService.requestPermissions();
      console.log('Notifications configured');

      // Initialize background fetch
      await MonitoringService.initBackgroundFetch();
      console.log('Background fetch initialized');

      console.log('App initialization complete');
      setIsReady(true);
    } catch (err) {
      console.error('Failed to initialize app:', err);
      setError(err.message);
      setIsReady(true); // Still show app even if some services fail
    }
  };

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
      <StatusBar barStyle="light-content" backgroundColor={COLORS.primary} />
      <AppNavigator />
    </>
  );
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

export default App;
