import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_provider.dart';

class NetworkDiagnosticScreen extends StatefulWidget {
  const NetworkDiagnosticScreen({super.key});

  @override
  State<NetworkDiagnosticScreen> createState() => _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NetworkProvider>();
      if (!provider.diagnosticRunning && provider.diagnosticResult == null) {
        provider.runDiagnostic(repeat: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkProvider>();
    final result = provider.diagnosticResult;
    final colorScheme = Theme.of(context).colorScheme;
    final healthColor = _healthColor(provider.networkHealth, colorScheme);

    return Scaffold(
      appBar: AppBar(title: const Text('Network Diagnostic Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HealthHeader(health: provider.networkHealth, color: healthColor),
          const SizedBox(height: 18),
          _ProgressPanel(provider: provider, color: healthColor),
          const SizedBox(height: 18),
          if (result != null) ...[
            _MetricGrid(result: result),
            const SizedBox(height: 18),
          ],
          FilledButton.icon(
            onPressed: provider.diagnosticRunning ? null : () => provider.runDiagnostic(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(provider.diagnosticRunning ? 'Diagnostic in progress' : 'Run diagnostic again'),
          ),
          const SizedBox(height: 10),
          Text(
            'The diagnostic checks idle latency first, then measures download and upload bandwidth while tracking latency during each transfer.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: .65), height: 1.35),
          ),
        ],
      ),
    );
  }

  Color _healthColor(NetworkHealth health, ColorScheme scheme) {
    switch (health) {
      case NetworkHealth.excellent: return const Color(0xFF18895C);
      case NetworkHealth.fair: return const Color(0xFFB06A25);
      case NetworkHealth.poor: return const Color(0xFFC6533E);
      case NetworkHealth.degraded: return const Color(0xFFB52E45);
      case NetworkHealth.testing: return scheme.primary;
      case NetworkHealth.unknown: return scheme.onSurface.withValues(alpha: .55);
    }
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({required this.health, required this.color});
  final NetworkHealth health;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (health) {
      NetworkHealth.excellent => 'Excellent connection',
      NetworkHealth.fair => 'Fair connection',
      NetworkHealth.poor => 'Poor connection',
      NetworkHealth.degraded => 'Degraded connection',
      NetworkHealth.testing => 'Testing connection',
      NetworkHealth.unknown => 'Waiting for diagnostic',
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(Icons.speed_rounded, color: color, size: 34),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NETWORK HEALTH', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.provider, required this.color});
  final NetworkProvider provider;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final phase = provider.diagnosticPhase;
    final labels = ['Idle ping', 'Download + ping', 'Upload + ping'];
    final activeIndex = switch (phase) { DiagnosticPhase.idlePing => 0, DiagnosticPhase.download => 1, DiagnosticPhase.upload => 2, _ => -1 };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.timeline_rounded), const SizedBox(width: 9), const Text('Live test sequence', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), if (provider.diagnosticRunning) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))]),
          const SizedBox(height: 14),
          for (var index = 0; index < labels.length; index++) _StepRow(label: labels[index], active: index == activeIndex, complete: phase == DiagnosticPhase.complete || index < activeIndex, color: color),
          const SizedBox(height: 10),
          Text(provider.statusMessage, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
        ]),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.active, required this.complete, required this.color});
  final String label; final bool active; final bool complete; final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(complete ? Icons.check_circle_rounded : active ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: complete || active ? color : Colors.grey, size: 20), const SizedBox(width: 10), Text(label, style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500))]));
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.result});
  final NetworkDiagnosticResult result;
  @override
  Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.75, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
    _Metric(label: 'Idle ping', value: '${result.idlePingMs.toStringAsFixed(0)} ms', icon: Icons.timer_outlined),
    _Metric(label: 'Packet loss', value: '${result.packetLossPercent.toStringAsFixed(0)}%', icon: Icons.network_check_rounded),
    _Metric(label: 'Download', value: '${result.downloadMbps.toStringAsFixed(1)} Mbps', icon: Icons.download_rounded),
    _Metric(label: 'Upload', value: '${result.uploadMbps.toStringAsFixed(1)} Mbps', icon: Icons.upload_rounded),
  ]);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .62)))])));
}