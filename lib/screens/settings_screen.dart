import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          Card(
            child: SwitchListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: Text(
                appProvider.isDarkMode
                    ? 'Dark theme is enabled'
                    : 'Light theme is enabled',
              ),

              value: appProvider.isDarkMode,

              onChanged: (value) {
                appProvider.toggleTheme();
              },

              secondary: Icon(
                appProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
