import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkProvider extends ChangeNotifier {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isRequestPending = false;
  bool _isRequestInProgress = false;
  double _requestProgress = 0.0;
  String _statusMessage = 'Ready';

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

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
