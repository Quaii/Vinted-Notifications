// CRITICAL: Disable native screens BEFORE any imports
// This must be the very first thing to prevent iOS 17+ sheet crashes
import {enableScreens} from 'react-native-screens';
enableScreens(false);

import {AppRegistry, LogBox} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

// Completely disable all development mode overlays and warnings
LogBox.ignoreAllLogs(true);

// Disable the Metro bundler progress overlay
if (__DEV__) {
  // Hide "Building JavaScript bundle" and download progress
  const originalWarn = console.warn;
  const originalLog = console.log;

  console.warn = (...args) => {
    const message = args.join(' ');
    // Filter out Metro bundler messages
    if (
      message.includes('Building JavaScript bundle') ||
      message.includes('Downloading JavaScript bundle') ||
      message.includes('Loading from Metro')
    ) {
      return; // Suppress these messages
    }
    originalWarn.apply(console, args);
  };

  console.log = (...args) => {
    const message = args.join(' ');
    // Filter out Metro bundler messages
    if (
      message.includes('Building JavaScript bundle') ||
      message.includes('Downloading JavaScript bundle') ||
      message.includes('Loading from Metro')
    ) {
      return; // Suppress these messages
    }
    originalLog.apply(console, args);
  };
}

// Register the app
AppRegistry.registerComponent(appName, () => App);
