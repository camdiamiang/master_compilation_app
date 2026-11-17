import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/network_provider.dart';
import 'providers/mesh_chat_provider.dart';
import 'providers/geofence_provider.dart';
import 'screens/home_screen.dart';
import 'screens/activity_one_screen.dart';
import 'screens/activity_two_screen.dart';
import 'screens/activity_four_screen.dart';
import 'screens/activity_five_screen.dart';
import 'screens/geofencing_map_screen.dart';
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
        ChangeNotifierProvider(create: (_) => MeshChatProvider()),
        ChangeNotifierProvider(create: (_) => GeofenceProvider()),
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

          // CUSTOM THEME
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
            '/activity4': (context) => const ActivityFourScreen(),
            '/activity5': (context) => const ActivityFiveScreen(),
            '/geofencing-map': (context) => const GeofencingMapScreen(),
            '/network-monitor': (context) => const NetworkMonitorScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
