import 'package:flutter/material.dart';

class ActivityOneScreen extends StatefulWidget {
  const ActivityOneScreen({super.key});

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF281C19) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity 1: Mobile Environment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC85C3E), Color(0xFFDF7A58)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33C85C3E),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LABORATORY ACTIVITY 01',
                  style: TextStyle(
                    color: Color(0xFFFFECE4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Environment & UI Architecture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Foundational mobile computing architecture, responsive screen dimensions, device metrics, and state lifecycle initialization.',
                  style: TextStyle(
                    color: Color(0xFFFFEDE6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Interactive State Counter Demonstration
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFC85C3E).withValues(alpha: .2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: Color(0xFFC85C3E)),
                    SizedBox(width: 8),
                    Text(
                      'Stateful Lifecycle & User Interaction',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Demonstrates dynamic reactive state updates in Flutter via setState() without full widget rebuilding.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Interaction Count',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '$_counter',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC85C3E),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _resetCounter,
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _incrementCounter,
                          icon: const Icon(Icons.add),
                          label: const Text('Tap Me'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC85C3E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Device & Screen Telemetry',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Telemetry Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _InfoCard(
                title: 'Screen Dimensions',
                value:
                    '${media.size.width.toInt()} × ${media.size.height.toInt()} pt',
                icon: Icons.aspect_ratio_rounded,
                cardBg: cardBg,
              ),
              _InfoCard(
                title: 'Device Pixel Ratio',
                value: '${media.devicePixelRatio.toStringAsFixed(2)}x',
                icon: Icons.straighten_rounded,
                cardBg: cardBg,
              ),
              _InfoCard(
                title: 'Platform Orientation',
                value: media.orientation.name.toUpperCase(),
                icon: Icons.screen_rotation_rounded,
                cardBg: cardBg,
              ),
              _InfoCard(
                title: 'Accessibility Scale',
                value: '${media.textScaler.scale(1.0).toStringAsFixed(2)}x',
                icon: Icons.text_fields_rounded,
                cardBg: cardBg,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Compilation Checklist
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.withValues(alpha: .2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Midterm Compilation Roadmap',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                _ChecklistRow(
                  title: 'Activity 1: Mobile Environment & Telemetry',
                  done: true,
                ),
                _ChecklistRow(
                  title: 'Activity 2: Network Monitor & Queueing',
                  done: true,
                ),
                _ChecklistRow(
                  title: 'Activity 3: Network Diagnostics & Health',
                  done: true,
                ),
                _ChecklistRow(
                  title: 'Activity 4: Serverless Local Mesh Chat',
                  done: true,
                ),
                _ChecklistRow(
                  title: 'Activity 5: Custom Map with Geofencing Tracker',
                  done: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color cardBg;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFC85C3E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String title;
  final bool done;

  const _ChecklistRow({required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? const Color(0xFF10B981) : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
