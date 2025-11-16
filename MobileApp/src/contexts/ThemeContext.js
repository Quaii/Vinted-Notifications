import React, {createContext, useState, useEffect, useContext} from 'react';
import DatabaseService from '../services/DatabaseService';

/**
 * ThemeContext
 * Manages dark/light theme with persistence
 * Dark mode is default, light mode is toggleable in settings
 */

export const ThemeContext = createContext();

export const ThemeProvider = ({children}) => {
  const [isDarkMode, setIsDarkMode] = useState(true); // Dark mode as default

  useEffect(() => {
    // Load saved theme preference
    const loadTheme = async () => {
      try {
        const savedTheme = await DatabaseService.getParameter('theme_mode', 'dark');
        setIsDarkMode(savedTheme === 'dark');
      } catch (error) {
        console.error('Failed to load theme:', error);
      }
    };
    loadTheme();
  }, []);

  const toggleTheme = async () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    try {
      await DatabaseService.setParameter('theme_mode', newMode ? 'dark' : 'light');
    } catch (error) {
      console.error('Failed to save theme:', error);
    }
  };

  return (
    <ThemeContext.Provider value={{isDarkMode, toggleTheme}}>
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
