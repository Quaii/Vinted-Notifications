// CRITICAL: Disable native screens BEFORE any imports
// This must be the very first thing to prevent iOS 17+ sheet crashes
import {enableScreens} from 'react-native-screens';
enableScreens(false);

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

// Register the app
AppRegistry.registerComponent(appName, () => App);
