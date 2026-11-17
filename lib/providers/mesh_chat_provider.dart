import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum PeerStatus { discovered, connecting, connected, disconnected }

class MeshPeer {
  MeshPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    this.status = PeerStatus.discovered,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  final String id;
  String name;
  String address;
  int port;
  PeerStatus status;
  DateTime lastSeen;

  MeshPeer copyWith({
    PeerStatus? status,
    DateTime? lastSeen,
  }) {
    return MeshPeer(
      id: id,
      name: name,
      address: address,
      port: port,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required bool isMe}) {
    return ChatMessage(
      id: json['id'] as String? ?? UniqueKey().toString(),
      senderId: json['senderId'] as String? ?? 'peer',
      senderName: json['senderName'] as String? ?? 'Nearby Peer',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isMe: isMe,
    );
  }
}

class MeshChatProvider extends ChangeNotifier {
  MeshChatProvider() {
    _deviceId = 'DEV-${Random().nextInt(9000) + 1000}';
    _deviceName = 'Device ${_deviceId.substring(4)}';
    _meshInitialization = _initMeshEngine();
  }

  late final Future<void> _meshInitialization;
  late final String _deviceId;
  late String _deviceName;
  String _localIpAddress = 'Detecting…';
  bool _isBroadcasting = false;
  bool _isScanning = false;
  bool _isSubnetScanning = false;
  int _serverPort = 9876;
  static const int _discoveryPort = 8888;

  final Map<String, MeshPeer> _peers = {};
  final List<ChatMessage> _messages = [];
  final Map<String, Socket> _activeSockets = {};
  ServerSocket? _serverSocket;
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  String get localIpAddress => _localIpAddress;
  int get serverPort => _serverPort;
  bool get isBroadcasting => _isBroadcasting;
  bool get isScanning => _isScanning;
  bool get isSubnetScanning => _isSubnetScanning;
  List<MeshPeer> get peers => _peers.values.toList();
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get connectedPeerCount =>
      _peers.values.where((p) => p.status == PeerStatus.connected).length;

  void setDeviceName(String name) {
    if (name.trim().isEmpty) return;
    _deviceName = name.trim();
    notifyListeners();
  }

  Future<void> _initMeshEngine() async {
    await _detectLocalIp();
    try {
      await _startTcpServer();
      await _startUdpDiscovery();
      startBroadcastAndScan();
    } catch (e) {
      debugPrint('Mesh Socket Init: $e');
    }

    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      _peers.removeWhere((id, peer) =>
          peer.status != PeerStatus.connected &&
          now.difference(peer.lastSeen).inSeconds > 45);
      notifyListeners();
    });
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _localIpAddress = addr.address;
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {}
    _localIpAddress = '127.0.0.1';
    notifyListeners();
  }

  Future<void> _startTcpServer() async {
    try {
      // First try standard port 9876
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 9876);
      _serverPort = 9876;
      _serverSocket!.listen(_handleIncomingConnection);
    } catch (_) {
      try {
        // Fallback to any available port
        _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        _serverPort = _serverSocket!.port;
        _serverSocket!.listen(_handleIncomingConnection);
      } catch (e) {
        debugPrint('TCP Server Error: $e');
      }
    }
  }

  void _handleIncomingConnection(Socket socket) {
    String? peerId;
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        try {
          if (line.trim().isEmpty) return;
          final payload = jsonDecode(line) as Map<String, dynamic>;
          final type = payload['type'] as String?;

          if (type == 'handshake') {
            peerId = payload['senderId'] as String;
            final peerName = payload['senderName'] as String? ?? 'Nearby Peer';
            _peers[peerId!] = MeshPeer(
              id: peerId!,
              name: peerName,
              address: socket.remoteAddress.address,
              port: payload['port'] as int? ?? socket.remotePort,
              status: PeerStatus.connected,
            );
            _activeSockets[peerId!] = socket;
            notifyListeners();
          } else if (type == 'chat') {
            final msg = ChatMessage.fromJson(payload, isMe: false);
            _messages.add(msg);
            notifyListeners();
          }
        } catch (_) {}
      },
      onDone: () {
        if (peerId != null) {
          _peers[peerId!]?.status = PeerStatus.disconnected;
          _activeSockets.remove(peerId);
          notifyListeners();
        }
      },
      onError: (_) {
        if (peerId != null) {
          _peers[peerId!]?.status = PeerStatus.disconnected;
          _activeSockets.remove(peerId);
          notifyListeners();
        }
      },
    );
  }

  Future<void> _startUdpDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpSocket?.broadcastEnabled = true;
      _udpSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram == null) return;
          try {
            final text = utf8.decode(datagram.data);
            final json = jsonDecode(text) as Map<String, dynamic>;
            final id = json['id'] as String?;
            final name = json['name'] as String?;
            final port = json['port'] as int?;

            if (id != null && id != _deviceId && name != null && port != null) {
              final existing = _peers[id];
              if (existing != null) {
                existing.lastSeen = DateTime.now();
                // Refresh endpoint details in case the peer moved to another
                // Wi-Fi network or its listening port changed.
                existing.name = name;
                existing.address = datagram.address.address;
                existing.port = port;
                if (existing.status != PeerStatus.connected &&
                    existing.status != PeerStatus.connecting) {
                  existing.status = PeerStatus.discovered;
                }
              } else {
                _peers[id] = MeshPeer(
                  id: id,
                  name: name,
                  address: datagram.address.address,
                  port: port,
                  status: PeerStatus.discovered,
                );
              }
              notifyListeners();

              // Both devices discover each other. Let only one side open the
              // TCP connection so automatic pairing does not create duplicate
              // sockets. The other side accepts the incoming handshake.
              final peer = _peers[id]!;
              if (_deviceId.compareTo(id) < 0 &&
                  peer.status == PeerStatus.discovered) {
                unawaited(connectToPeer(peer));
              }
            }
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  void startBroadcastAndScan() {
    _isBroadcasting = true;
    _isScanning = true;
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _sendDiscoveryBeacon();
    });
    _sendDiscoveryBeacon();
    notifyListeners();
  }

  void stopBroadcastAndScan() {
    _isBroadcasting = false;
    _isScanning = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    notifyListeners();
  }

  void _sendDiscoveryBeacon() {
    if (!_isBroadcasting || _udpSocket == null) return;
    try {
      final payload = jsonEncode({
        'id': _deviceId,
        'name': _deviceName,
        'port': _serverPort,
      });
      final bytes = utf8.encode(payload);
      _udpSocket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );
    } catch (_) {}
  }

  /// Actively scans the local subnet to detect neighboring devices
  Future<void> scanSubnet() async {
    await _meshInitialization;
    if (_isSubnetScanning) return;
    _isSubnetScanning = true;
    notifyListeners();

    await _detectLocalIp();
    if (_localIpAddress.contains('.') && !_localIpAddress.startsWith('127.')) {
      final subnet = _localIpAddress.substring(0, _localIpAddress.lastIndexOf('.'));
      final tasks = <Future>[];

      // Probe common IP ranges on the subnet
      for (int i = 1; i <= 254; i++) {
        final targetIp = '$subnet.$i';
        if (targetIp == _localIpAddress) continue;
        tasks.add(_probeSubnetIp(targetIp, _serverPort));
      }

      // Run in batches to avoid socket exhaustion
      const batchSize = 30;
      for (var i = 0; i < tasks.length; i += batchSize) {
        final end = min(i + batchSize, tasks.length);
        await Future.wait(tasks.sublist(i, end));
      }
    }

    _isSubnetScanning = false;
    notifyListeners();
  }

  Future<void> _probeSubnetIp(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 600),
      );

      final handshake = jsonEncode({
        'type': 'handshake',
        'senderId': _deviceId,
        'senderName': _deviceName,
        'port': _serverPort,
      });
      socket.write('$handshake\n');
      await socket.flush();

      final peerId = 'IP-$ip-$port';
      if (!_peers.containsKey(peerId)) {
        _peers[peerId] = MeshPeer(
          id: peerId,
          name: 'Device @ $ip',
          address: ip,
          port: port,
          status: PeerStatus.connected,
        );
        _activeSockets[peerId] = socket;
        _listenToSocket(socket, peerId);
        notifyListeners();
      } else {
        socket.destroy();
      }
    } catch (_) {}
  }

  Future<void> connectToIp(String ipAddress, [int port = 9876]) async {
    final cleanIp = ipAddress.trim();
    if (cleanIp.isEmpty) return;

    final peerId = 'MANUAL-$cleanIp-$port';
    final peer = MeshPeer(
      id: peerId,
      name: 'Peer @ $cleanIp',
      address: cleanIp,
      port: port,
      status: PeerStatus.connecting,
    );
    _peers[peerId] = peer;
    notifyListeners();

    await connectToPeer(peer);
  }

  Future<void> connectToPeer(MeshPeer peer) async {
    peer.status = PeerStatus.connecting;
    notifyListeners();

    try {
      final socket = await Socket.connect(
        peer.address,
        peer.port,
        timeout: const Duration(seconds: 5),
      );

      final handshake = jsonEncode({
        'type': 'handshake',
        'senderId': _deviceId,
        'senderName': _deviceName,
        'port': _serverPort,
      });
      socket.write('$handshake\n');
      await socket.flush();

      _activeSockets[peer.id] = socket;
      peer.status = PeerStatus.connected;
      notifyListeners();

      _listenToSocket(socket, peer.id);
    } catch (e) {
      peer.status = PeerStatus.disconnected;
      notifyListeners();
    }
  }

  void _listenToSocket(Socket socket, String peerId) {
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        try {
          if (line.trim().isEmpty) return;
          final payload = jsonDecode(line) as Map<String, dynamic>;
          if (payload['type'] == 'chat') {
            final msg = ChatMessage.fromJson(payload, isMe: false);
            _messages.add(msg);
            notifyListeners();
          }
        } catch (_) {}
      },
      onDone: () {
        _peers[peerId]?.status = PeerStatus.disconnected;
        _activeSockets.remove(peerId);
        notifyListeners();
      },
      onError: (_) {
        _peers[peerId]?.status = PeerStatus.disconnected;
        _activeSockets.remove(peerId);
        notifyListeners();
      },
    );
  }

  void disconnectPeer(MeshPeer peer) {
    _activeSockets[peer.id]?.destroy();
    _activeSockets.remove(peer.id);
    peer.status = PeerStatus.disconnected;
    notifyListeners();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final message = ChatMessage(
      id: UniqueKey().toString(),
      senderId: _deviceId,
      senderName: _deviceName,
      text: trimmed,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _messages.add(message);
    notifyListeners();

    final payload = jsonEncode({
      'type': 'chat',
      ...message.toJson(),
    });

    for (final socket in _activeSockets.values) {
      try {
        socket.write('$payload\n');
        socket.flush();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _udpSocket?.close();
    _serverSocket?.close();
    for (final socket in _activeSockets.values) {
      socket.destroy();
    }
    super.dispose();
  }
}
