import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/network_provider.dart';
import 'screens/home_screen.dart';
import 'screens/activity_one_screen.dart';
import 'screens/activity_two_screen.dart';
import 'screens/network_monitor_screen.dart';
import 'screens/network_diagnostic_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'Master Compilation App',

          // YOUR CUSTOM THEME
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          // Provider controls Light/Dark Mode
          themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          initialRoute: '/',

          routes: {
            '/': (context) => const HomeScreen(),
            '/activity1': (context) => const ActivityOneScreen(),
            '/activity2': (context) => const ActivityTwoScreen(),
            '/activity3': (context) => const NetworkDiagnosticScreen(),
            '/network-monitor': (context) => const NetworkMonitorScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
