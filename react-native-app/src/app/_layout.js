import React from 'react';
import { Stack } from 'expo-router';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ThemeProvider, useTheme } from '../context/ThemeContext';

const AppStack = () => {
  const { colors } = useTheme();
  return (
    <Stack screenOptions={{
      headerStyle: { backgroundColor: colors.background },
      headerTintColor: colors.text,
      headerTitleStyle: { fontWeight: '700', fontSize: 15 },
      headerShadowVisible: false,
      contentStyle: { backgroundColor: colors.background },
    }}>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen name="settings" options={{ title: 'Settings' }} />
      <Stack.Screen name="about" options={{ title: 'About Fieldnotes' }} />
      <Stack.Screen name="activity/[id]" options={{ title: 'Lab activity' }} />
    </Stack>
  );
};

export default function RootLayout() {
  return <SafeAreaProvider><ThemeProvider><AppStack /></ThemeProvider></SafeAreaProvider>;
}
