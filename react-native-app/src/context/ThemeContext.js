import React, { createContext, useContext, useMemo, useState } from 'react';

const palettes = {
  light: {
    background: '#F5F7F3', surface: '#FFFFFF', card: '#FFFFFF', primary: '#176B54',
    primarySoft: '#E5F1EA', text: '#17251F', textSecondary: '#6A7970', border: '#E6EBE5',
    accent: '#D9EF86', success: '#26785A', warning: '#B77724', danger: '#B74D46',
    hero: '#123F34', heroText: '#F5F6EC', field: '#F7F9F5', tab: '#EAF0E9',
  },
  dark: {
    background: '#111A17', surface: '#19241F', card: '#1C2923', primary: '#86D2AF',
    primarySoft: '#243B31', text: '#EDF3EE', textSecondary: '#A6B5AB', border: '#2A3931',
    accent: '#D9EF86', success: '#86D2AF', warning: '#EDC16F', danger: '#F08A7F',
    hero: '#1B392F', heroText: '#F5F6EC', field: '#202C26', tab: '#25342C',
  },
};

const ThemeContext = createContext(null);

export const ThemeProvider = ({ children }) => {
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [userName, setUserName] = useState('Alex Rivera');
  const [userCourse, setUserCourse] = useState('BS Information Technology');
  const colors = isDarkMode ? palettes.dark : palettes.light;
  const value = useMemo(() => ({
    colors, isDarkMode, toggleTheme: () => setIsDarkMode((value) => !value),
    setLightTheme: () => setIsDarkMode(false), userName, setUserName, userCourse, setUserCourse,
  }), [colors, isDarkMode, userName, userCourse]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within a ThemeProvider');
  return context;
};
