import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

// Enable react-native-screens
import {enableScreens} from 'react-native-screens';
enableScreens(false); // Disable native screens to avoid iOS 17+ sheet presentation issues

// Register the app
AppRegistry.registerComponent(appName, () => App);
