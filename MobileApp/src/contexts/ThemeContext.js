import React, {
  createContext,
  useState,
  useEffect,
  useContext,
  useMemo,
  useCallback,
} from 'react';
import {useColorScheme} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

/**
 * ThemeContext
 * Manages dark/light theme with persistence using AsyncStorage
 * Dark mode is default, light mode is toggleable in settings
 */

export const ThemeContext = createContext();

const THEME_STORAGE_KEY = 'theme_mode';
const APPEARANCE_MODES = {
  SYSTEM: 'system',
  LIGHT: 'light',
  DARK: 'dark',
};

const isValidAppearanceMode = mode =>
  Object.values(APPEARANCE_MODES).includes(mode);

export const ThemeProvider = ({children}) => {
  const systemColorScheme = useColorScheme();
  const [appearanceMode, setAppearanceMode] = useState(APPEARANCE_MODES.SYSTEM);

  useEffect(() => {
    // Load saved theme preference from AsyncStorage
    const loadTheme = async () => {
      try {
        const savedTheme = await AsyncStorage.getItem(THEME_STORAGE_KEY);

        if (savedTheme && isValidAppearanceMode(savedTheme)) {
          setAppearanceMode(savedTheme);
        } else if (savedTheme === 'dark' || savedTheme === 'light') {
          // Backwards compatibility with earlier versions that only stored dark/light
          setAppearanceMode(savedTheme);
        } else {
          // Default to system theme and persist for future launches
          await AsyncStorage.setItem(THEME_STORAGE_KEY, APPEARANCE_MODES.SYSTEM);
          setAppearanceMode(APPEARANCE_MODES.SYSTEM);
        }
      } catch (error) {
        console.error('Failed to load theme preference:', error);
      }
    };
    loadTheme();
  }, []);

  const persistAppearanceMode = useCallback(async mode => {
    try {
      await AsyncStorage.setItem(THEME_STORAGE_KEY, mode);
    } catch (error) {
      console.error('Failed to save theme preference:', error);
    }
  }, []);

  const updateAppearanceMode = useCallback(
    nextValue => {
      setAppearanceMode(prevMode => {
        const resolvedNext =
          typeof nextValue === 'function' ? nextValue(prevMode) : nextValue;
        const normalized = isValidAppearanceMode(resolvedNext)
          ? resolvedNext
          : APPEARANCE_MODES.SYSTEM;

        persistAppearanceMode(normalized);
        return normalized;
      });
    },
    [persistAppearanceMode],
  );

  const setAppearanceModeExplicit = useCallback(
    mode => {
      updateAppearanceMode(mode);
    },
    [updateAppearanceMode],
  );

  const toggleTheme = useCallback(() => {
    updateAppearanceMode(prevMode => {
      if (prevMode === APPEARANCE_MODES.SYSTEM) {
        return systemColorScheme === APPEARANCE_MODES.DARK
          ? APPEARANCE_MODES.LIGHT
          : APPEARANCE_MODES.DARK;
      }
      return prevMode === APPEARANCE_MODES.DARK
        ? APPEARANCE_MODES.LIGHT
        : APPEARANCE_MODES.DARK;
    });
  }, [systemColorScheme, updateAppearanceMode]);

  const isDarkMode = useMemo(() => {
    if (appearanceMode === APPEARANCE_MODES.DARK) {
      return true;
    }
    if (appearanceMode === APPEARANCE_MODES.LIGHT) {
      return false;
    }
    // appearanceMode === system
    if (!systemColorScheme) {
      return true; // fallback to dark if system preference is unavailable
    }
    return systemColorScheme === 'dark';
  }, [appearanceMode, systemColorScheme]);

  return (
    <ThemeContext.Provider
      value={{
        isDarkMode,
        appearanceMode,
        setAppearanceMode: setAppearanceModeExplicit,
        toggleTheme,
      }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};
