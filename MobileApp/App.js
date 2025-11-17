import React, {useEffect, useState, Component} from 'react';
import {StatusBar, View, Text, ActivityIndicator, LogBox} from 'react-native';
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

// Development overlays (Building/Downloading bundle) are disabled in index.js
// This ensures a clean, production-like UI even in development mode

// Intercept console errors and warnings to route to LogService
// This captures API errors and other issues to display in the Logs screen
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

console.error = (...args) => {
  // Format the error message
  const message = args.map(arg =>
    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
  ).join(' ');

  // Log to LogService (which also logs to console internally)
  LogService.error(message);

  // Don't call original to avoid duplicate logs
  // originalConsoleError.apply(console, args);
};

console.warn = (...args) => {
  // Format the warning message
  const message = args.map(arg =>
    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
  ).join(' ');

  // Log to LogService (which also logs to console internally)
  LogService.warning(message);

  // Don't call original to avoid duplicate logs
  // originalConsoleWarn.apply(console, args);
};

// Global error handler for unhandled promise rejections
const handleUnhandledRejection = (event) => {
  const error = event.reason || event;
  const message = error.message || String(error);
  LogService.error(`Unhandled Promise Rejection: ${message}`);
};

// Set up global error handlers
if (global.ErrorUtils) {
  const originalGlobalHandler = global.ErrorUtils.getGlobalHandler();
  global.ErrorUtils.setGlobalHandler((error, isFatal) => {
    LogService.error(`${isFatal ? 'Fatal ' : ''}Error: ${error.message || String(error)}`);
    if (originalGlobalHandler) {
      originalGlobalHandler(error, isFatal);
    }
  });
}

/**
 * Error Boundary Component
 * Catches React component errors and logs them to LogService
 */
class ErrorBoundary extends Component {
  componentDidCatch(error, errorInfo) {
    LogService.error(`React Error: ${error.message} - ${errorInfo.componentStack}`);
  }

  render() {
    return this.props.children;
  }
}

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

      // Initialize database first (required by other services)
      await DatabaseService.init();
      console.log('Database initialized');
      LogService.info('Database initialized successfully');

      // OPTIMIZATION: Parallelize independent service initialization
      // These services don't depend on each other and can run concurrently
      await Promise.all([
        // Load VintedAPI settings from database
        VintedAPI.loadSettingsFromDatabase(DatabaseService).then(() => {
          console.log('VintedAPI settings loaded');
          LogService.info('VintedAPI settings loaded from database');
        }),

        // Configure notifications (independent of VintedAPI)
        NotificationService.configure().then(() => {
          console.log('Notifications configured');
          LogService.info('Notification service configured');
        }),

        // Initialize background fetch (independent of VintedAPI)
        MonitoringService.initBackgroundFetch().then(() => {
          console.log('Background fetch initialized');
          LogService.info('Background fetch service initialized');
        }),
      ]);

      // Initialize monitoring state (depends on database, run after parallel tasks)
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
    <ErrorBoundary>
      <GestureHandlerRootView style={{flex: 1}}>
        <SafeAreaProvider>
          <ThemeProvider>
            <AppContent />
          </ThemeProvider>
        </SafeAreaProvider>
      </GestureHandlerRootView>
    </ErrorBoundary>
  );
};

export default App;
