import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkHealth { unknown, testing, excellent, fair, poor, degraded }

enum DiagnosticPhase { idlePing, download, upload, complete }

class NetworkDiagnosticResult {
  const NetworkDiagnosticResult({
    required this.idlePingMs,
    required this.downloadPingMs,
    required this.uploadPingMs,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.packetLossPercent,
  });

  final double idlePingMs;
  final double downloadPingMs;
  final double uploadPingMs;
  final double downloadMbps;
  final double uploadMbps;
  final double packetLossPercent;
}

class NetworkProvider extends ChangeNotifier {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isRequestPending = false;
  bool _isRequestInProgress = false;
  double _requestProgress = 0.0;
  String _statusMessage = 'Ready';
  NetworkHealth _networkHealth = NetworkHealth.unknown;
  DiagnosticPhase? _diagnosticPhase;
  NetworkDiagnosticResult? _diagnosticResult;
  Timer? _diagnosticTimer;
  bool _diagnosticRunning = false;

  NetworkProvider() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  List<ConnectivityResult> get connectionStatus => _connectionStatus;
  bool get isOffline =>
      _connectionStatus.contains(ConnectivityResult.none) ||
      _connectionStatus.isEmpty;
  bool get isRequestPending => _isRequestPending;
  bool get isRequestInProgress => _isRequestInProgress;
  double get requestProgress => _requestProgress;
  String get statusMessage => _statusMessage;
  NetworkHealth get networkHealth => _networkHealth;
  DiagnosticPhase? get diagnosticPhase => _diagnosticPhase;
  NetworkDiagnosticResult? get diagnosticResult => _diagnosticResult;
  bool get diagnosticRunning => _diagnosticRunning;

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      result = [ConnectivityResult.none];
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus = result;

    if (isOffline) {
      if (_isRequestInProgress) {
        // Simulating connection drop during request
        _isRequestInProgress = false;
        _isRequestPending = true;
        _statusMessage = 'Connection dropped. Request queued.';
      }
    } else {
      // Reconnected, process pending queue if any
      if (_isRequestPending) {
        _statusMessage = 'Connection restored. Resuming request...';
        _processRequest();
      }
    }
    notifyListeners();
  }

  void startSimulatedRequest() {
    if (_isRequestInProgress) return;

    _requestProgress = 0.0;
    _isRequestPending = true;

    if (isOffline) {
      _statusMessage = 'Offline. Request added to queue.';
      notifyListeners();
    } else {
      _statusMessage = 'Starting request...';
      _processRequest();
    }
  }

  Future<void> _processRequest() async {
    _isRequestPending = false;
    _isRequestInProgress = true;
    notifyListeners();

    for (int i = (_requestProgress * 100).toInt(); i <= 100; i += 10) {
      if (isOffline) {
        // Got disconnected during the loop
        _isRequestInProgress = false;
        _isRequestPending = true;
        _statusMessage = 'Connection lost. Request queued.';
        notifyListeners();
        return;
      }

      _requestProgress = i / 100.0;
      _statusMessage = 'Downloading data... $i%';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Finished
    _isRequestInProgress = false;
    _requestProgress = 1.0;
    _statusMessage = 'Request completed successfully!';
    notifyListeners();
  }

  Future<void> runDiagnostic({bool repeat = false}) async {
    if (_diagnosticRunning) return;
    _diagnosticRunning = true;
    _networkHealth = NetworkHealth.testing;
    _diagnosticResult = null;
    notifyListeners();

    do {
      try {
        final result = await _measureDiagnostic();
        _diagnosticResult = result;
        _networkHealth = _classifyHealth(result);
        _statusMessage = 'Diagnostic complete';
        _diagnosticPhase = DiagnosticPhase.complete;
        notifyListeners();
      } catch (_) {
        _networkHealth = NetworkHealth.degraded;
        _statusMessage = 'Diagnostic failed. Check your connection.';
        _diagnosticPhase = DiagnosticPhase.complete;
        notifyListeners();
      }
      if (repeat && _diagnosticRunning) {
        await Future<void>.delayed(const Duration(seconds: 30));
      }
    } while (repeat && _diagnosticRunning);

    _diagnosticRunning = false;
    notifyListeners();
  }

  void stopDiagnostic() {
    _diagnosticRunning = false;
    _diagnosticTimer?.cancel();
    _diagnosticTimer = null;
    if (_diagnosticPhase != DiagnosticPhase.complete) {
      _diagnosticPhase = null;
      _networkHealth = NetworkHealth.unknown;
      _statusMessage = 'Ready';
    }
    notifyListeners();
  }

  Future<NetworkDiagnosticResult> _measureDiagnostic() async {
    _diagnosticPhase = DiagnosticPhase.idlePing;
    _statusMessage = 'Measuring baseline idle ping...';
    notifyListeners();
    final idle = await _measurePing();

    _diagnosticPhase = DiagnosticPhase.download;
    _statusMessage = 'Measuring download and download ping...';
    notifyListeners();
    final download = await Future.wait([
      _measureDownload(),
      _measurePing(),
    ]);

    _diagnosticPhase = DiagnosticPhase.upload;
    _statusMessage = 'Measuring upload and upload ping...';
    notifyListeners();
    final upload = await Future.wait([
      _measureUpload(),
      _measurePing(),
    ]);

    return NetworkDiagnosticResult(
      idlePingMs: idle.$1,
      downloadPingMs: download[1].$1,
      uploadPingMs: upload[1].$1,
      downloadMbps: download[0].$2,
      uploadMbps: upload[0].$2,
      packetLossPercent: (idle.$2 + download[1].$2 + upload[1].$2) / 3 * 100,
    );
  }

  Future<(double, double)> _measurePing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(_pingUri).timeout(const Duration(seconds: 8));
      stopwatch.stop();
      if (response.statusCode >= 400) return (stopwatch.elapsedMilliseconds.toDouble(), 1.0);
      return (stopwatch.elapsedMilliseconds.toDouble(), 0.0);
    } catch (_) {
      stopwatch.stop();
      return (stopwatch.elapsedMilliseconds.toDouble(), 1.0);
    }
  }

  Future<(double, double)> _measureDownload() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(_downloadUri).timeout(const Duration(seconds: 15));
      stopwatch.stop();
      final seconds = max(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond, 0.001);
      return (response.bodyBytes.length.toDouble(), response.bodyBytes.length * 8 / seconds / 1000000);
    } catch (_) {
      stopwatch.stop();
      return (0.0, 0.0);
    }
  }

  Future<(double, double)> _measureUpload() async {
    final payload = utf8.encode('network-diagnostic-' * 131072);
    final stopwatch = Stopwatch()..start();
    try {
      await http.post(_uploadUri, body: payload).timeout(const Duration(seconds: 15));
      stopwatch.stop();
      final seconds = max(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond, 0.001);
      return (payload.length.toDouble(), payload.length * 8 / seconds / 1000000);
    } catch (_) {
      stopwatch.stop();
      return (0.0, 0.0);
    }
  }

  NetworkHealth _classifyHealth(NetworkDiagnosticResult result) {
    final worstPing = max(result.idlePingMs, max(result.downloadPingMs, result.uploadPingMs));
    if (result.packetLossPercent >= 34 || worstPing >= 1000) return NetworkHealth.degraded;
    final bandwidth = min(result.downloadMbps, result.uploadMbps);
    if (bandwidth > 10 && worstPing < 150) return NetworkHealth.excellent;
    if (bandwidth >= 2 && worstPing < 400) return NetworkHealth.fair;
    return NetworkHealth.poor;
  }

  Uri get _pingUri => Uri.parse('https://speed.cloudflare.com/__down?bytes=1');
  Uri get _downloadUri => Uri.parse('https://speed.cloudflare.com/__down?bytes=2000000');
  Uri get _uploadUri => Uri.parse('https://speed.cloudflare.com/__up');

  @override
  void dispose() {
    _diagnosticRunning = false;
    _diagnosticTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
