import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A compact, native-feeling view of the connection and request recovery flow.
class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({super.key});

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _networkType = 'Checking…';
  bool _isOnline = false;
  bool _requestRunning = false;
  int _pendingRequests = 0;
  int _completedRequests = 0;
  final List<_ActivityItem> _activityLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeNetworkMonitor();
  }

  Future<void> _initializeNetworkMonitor() async {
    final result = await _connectivity.checkConnectivity();
    _updateNetworkStatus(result, isInitialCheck: true);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateNetworkStatus,
    );
  }

  void _updateNetworkStatus(
    List<ConnectivityResult> results, {
    bool isInitialCheck = false,
  }) {
    if (!mounted) return;

    final network = _networkFrom(results);
    final online = network != 'Offline' && network != 'Checking…';
    final wasOnline = _isOnline;
    final previousNetwork = _networkType;

    setState(() {
      _networkType = network;
      _isOnline = online;
    });

    if (isInitialCheck) {
      _addLog(online ? 'Connection ready on $network' : 'Waiting for a connection');
    } else if (!wasOnline && online) {
      _addLog('Connection restored', type: _LogType.success);
      if (_pendingRequests > 0) _resumeQueuedRequests();
    } else if (wasOnline && !online) {
      _addLog('Connection lost', type: _LogType.warning);
    } else if (online && network != previousNetwork) {
      _addLog('Switched to $network');
    }
  }

  String _networkFrom(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (results.contains(ConnectivityResult.mobile)) return 'Cellular';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    return 'Offline';
  }

  void _startNetworkRequest() {
    if (_requestRunning) return;
    if (!_isOnline) {
      setState(() => _pendingRequests++);
      _addLog('Request queued', type: _LogType.queue);
      return;
    }
    _simulateLongRequest();
  }

  Future<void> _simulateLongRequest() async {
    if (!mounted) return;
    setState(() => _requestRunning = true);
    _addLog('Request started');

    try {
      // This loop represents a large download. Checking the network after
      // every chunk lets a handover pause the work instead of losing it.
      for (var progress = 1; progress <= 10; progress++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        if (!_isOnline) throw const _NetworkInterrupted();
      }

      setState(() {
        _requestRunning = false;
        _completedRequests++;
      });
      _addLog('Request completed', type: _LogType.success);
    } on _NetworkInterrupted {
      _queueInterruptedRequest('Connection lost');
    } catch (_) {
      // A real request could fail for another recoverable network reason.
      _queueInterruptedRequest('Request interrupted');
    }
  }

  void _queueInterruptedRequest(String reason) {
    if (!mounted) return;
    setState(() {
      _requestRunning = false;
      _pendingRequests++;
    });
    _addLog(reason, type: _LogType.warning);
    _addLog('Request queued', type: _LogType.queue);
  }

  Future<void> _resumeQueuedRequests() async {
    if (_pendingRequests == 0 || _requestRunning) return;
    setState(() => _pendingRequests--);
    _addLog('Request resumed', type: _LogType.success);
    await _simulateLongRequest();
  }

  void _addLog(String message, {_LogType type = _LogType.success}) {
    if (!mounted) return;
    setState(() {
      _activityLogs.insert(0, _ActivityItem(message, type));
      if (_activityLogs.length > 5) _activityLogs.removeLast();
    });
  }

  Color get _statusColor {
    if (!_isOnline) return const Color(0xFFDC3545);
    if (_networkType == 'Cellular') return const Color(0xFF367BF5);
    return const Color(0xFF20A464);
  }

  IconData get _networkIcon {
    switch (_networkType) {
      case 'Wi-Fi': return Icons.wifi_rounded;
      case 'Cellular': return Icons.signal_cellular_alt_rounded;
      case 'Ethernet': return Icons.settings_ethernet_rounded;
      case 'Offline': return Icons.wifi_off_rounded;
      default: return Icons.network_check_rounded;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1B1B1D) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF37373B) : const Color(0xFFE7E7EA);
    final mutedColor = isDark ? const Color(0xFFA9A9B1) : const Color(0xFF707078);

    return Scaffold(
      appBar: AppBar(title: const Text('Network Monitor')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => _updateNetworkStatus(await _connectivity.checkConnectivity()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor),
                  boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: _statusColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(_networkIcon, color: _statusColor)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('NETWORK MONITOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
                        _StatusPill(isOnline: _isOnline, color: _statusColor),
                      ]),
                      const SizedBox(height: 26),
                      _ConnectionSummary(networkType: _networkType, isOnline: _isOnline, color: _statusColor, mutedColor: mutedColor),
                      _Divider(color: dividerColor),
                      const _SectionLabel('Connection status'),
                      const SizedBox(height: 10),
                      _StatusRow(isOnline: _isOnline, color: _statusColor),
                      _Divider(color: dividerColor),
                      const _SectionLabel('Request queue', icon: Icons.inventory_2_outlined),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _QueueMetric(label: 'Pending', value: _pendingRequests, mutedColor: mutedColor)),
                        Container(width: 1, height: 32, color: dividerColor),
                        Expanded(child: _QueueMetric(label: 'Completed', value: _completedRequests, mutedColor: mutedColor)),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _requestRunning ? null : _startNetworkRequest,
                          icon: _requestRunning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow_rounded),
                          label: Text(_requestRunning ? 'Request in progress…' : 'Start network request'),
                        ),
                      ),
                      _Divider(color: dividerColor),
                      const _SectionLabel('Activity log'),
                      const SizedBox(height: 10),
                      if (_activityLogs.isEmpty) Text('No activity yet.', style: TextStyle(color: mutedColor)) else ..._activityLogs.map((entry) => _ActivityLogRow(entry: entry, mutedColor: mutedColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.networkType, required this.isOnline, required this.color, required this.mutedColor});
  final String networkType; final bool isOnline; final Color color; final Color mutedColor;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.circle, size: 11, color: color), const SizedBox(width: 8), Text(isOnline ? '$networkType connected' : 'No connection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color))]),
    const SizedBox(height: 7), Text('Current interface: $networkType', style: TextStyle(fontSize: 14, color: mutedColor)),
  ]);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline, required this.color});
  final bool isOnline; final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)));
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color}); final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 22), child: Divider(height: 1, color: color));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.icon}); final String label; final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(children: [if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 7)], Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))]);
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.isOnline, required this.color}); final bool isOnline; final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(Icons.circle, size: 10, color: color), const SizedBox(width: 8), Text(isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]);
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({required this.label, required this.value, required this.mutedColor}); final String label; final int value; final Color mutedColor;
  @override
  Widget build(BuildContext context) => Column(children: [Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 13, color: mutedColor))]);
}

enum _LogType { success, warning, queue }

class _NetworkInterrupted implements Exception {
  const _NetworkInterrupted();
}

class _ActivityItem { const _ActivityItem(this.message, this.type); final String message; final _LogType type; }

class _ActivityLogRow extends StatelessWidget {
  const _ActivityLogRow({required this.entry, required this.mutedColor}); final _ActivityItem entry; final Color mutedColor;
  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.type) { _LogType.success => Icons.check_circle_rounded, _LogType.warning => Icons.warning_amber_rounded, _LogType.queue => Icons.inventory_2_rounded };
    final color = switch (entry.type) { _LogType.success => const Color(0xFF20A464), _LogType.warning => const Color(0xFFE18A18), _LogType.queue => mutedColor };
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(icon, size: 17, color: color), const SizedBox(width: 9), Expanded(child: Text(entry.message, style: const TextStyle(fontSize: 14)))]));
  }
}
