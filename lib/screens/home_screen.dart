import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/network_provider.dart';
import '../widgets/activity_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final networkProvider = context.watch<NetworkProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lab Companion',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(
                isDarkMode: appProvider.isDarkMode,
                onToggleTheme: appProvider.toggleTheme,
              ),
              const SizedBox(height: 16),
              _HomeOverview(isOnline: !networkProvider.isOffline),
              const SizedBox(height: 28),
              const Text('Your activities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Choose a workspace to continue.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .62))),
              const SizedBox(height: 16),

              // Activity 1
              ActivityCard(
                title: 'Activity 1',
                description: 'First laboratory activity',
                icon: Icons.grid_view_rounded,
                accentColor: const Color(0xFFC85C3E),
                onTap: () {
                  Navigator.pushNamed(context, '/activity1');
                },
              ),

              const SizedBox(height: 13),

              // Activity 2
              ActivityCard(
                title: 'Activity 2',
                description: 'Second laboratory activity',
                icon: Icons.phone_android_rounded,
                accentColor: const Color(0xFFB06A25),
                onTap: () {
                  Navigator.pushNamed(context, '/activity2');
                },
              ),

              const SizedBox(height: 13),

              // Activity 3
              ActivityCard(
                title: 'Network monitor',
                description: 'Track your connection and requests',
                icon: Icons.wifi_rounded,
                accentColor: const Color(0xFF3D9476),
                onTap: () {
                  Navigator.pushNamed(context, '/activity3');
                },
              ),

              const SizedBox(height: 24),

              _LearningNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA94732), Color(0xFFD76F47), Color(0xFFF0A156)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Color(0x3D9B3F2C), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('WELCOME BACK', style: TextStyle(color: Color(0xFFEFFAF3), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          SizedBox(height: 10),
          Text('Ready to learn\nand explore?', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.13, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('All your laboratory tools in one warm, focused place.', style: TextStyle(color: Color(0xFFFFEDE2), fontSize: 14, height: 1.35)),
        ])),
        Column(children: [
          Semantics(
            button: true,
            label: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleTheme,
                borderRadius: BorderRadius.circular(15),
                child: Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(15)), child: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 23, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text('Theme', style: TextStyle(color: Color(0xFFFFEDE2), fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final background = isDark ? const Color(0xFF2A1D1A) : const Color(0xFFFFFCF8);
    final connectionColor = isOnline ? const Color(0xFF31936D) : const Color(0xFFC8513B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: .09)),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE18A36), size: 21),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ready for today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('3 workspaces available', style: TextStyle(fontSize: 12, color: Color(0xFF876C62))),
        ])),
        Container(width: 1, height: 31, color: foreground.withValues(alpha: .10)),
        const SizedBox(width: 13),
        Icon(Icons.circle, size: 9, color: connectionColor),
        const SizedBox(width: 6),
        Text(isOnline ? 'Online' : 'Offline', style: TextStyle(color: connectionColor, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _LearningNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: const Color(0xFFFFE9C8), borderRadius: BorderRadius.circular(18)),
        child: const Row(children: [
          Icon(Icons.lightbulb_rounded, color: Color(0xFF9A6214)),
          SizedBox(width: 12),
          Expanded(child: Text('New laboratory activities will appear here as you add them.', style: TextStyle(color: Color(0xFF6D4614), fontSize: 14, height: 1.3))),
        ]),
      );
}
