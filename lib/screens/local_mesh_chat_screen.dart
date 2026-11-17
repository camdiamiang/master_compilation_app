import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/mesh_chat_provider.dart';

class LocalMeshChatScreen extends StatefulWidget {
  const LocalMeshChatScreen({super.key});

  @override
  State<LocalMeshChatScreen> createState() => _LocalMeshChatScreenState();
}

class _LocalMeshChatScreenState extends State<LocalMeshChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MeshChatProvider>().scanSubnet();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(MeshChatProvider provider) {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    provider.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _showNearbyPeersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _NearbyPeersSheet(),
    );
  }

  void _showManualConnectDialog(BuildContext context, MeshChatProvider provider) {
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '9876');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_link_rounded),
            SizedBox(width: 8),
            Text('Connect by IP Address'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the peer IP and port shown in their device scanner. Both devices must be on the same Wi-Fi or hotspot.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'e.g. 192.168.1.15',
                labelText: 'Peer IP Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lan_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peer Port',
                hintText: '9876',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text.trim());
              if (ip.isNotEmpty && port != null && port > 0 && port <= 65535) {
                provider.connectToIp(ip, port);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid IP address and port.')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshChatProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local Mesh Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${provider.connectedPeerCount} connected • ${provider.deviceName}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded),
            tooltip: 'Direct IP Connect',
            onPressed: () => _showManualConnectDialog(context, provider),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: provider.peers.isNotEmpty,
              label: Text('${provider.peers.length}'),
              child: const Icon(Icons.radar_rounded),
            ),
            tooltip: 'Device Scanner',
            onPressed: () => _showNearbyPeersModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _MeshStatusBar(
              provider: provider,
              onOpenPeers: () => _showNearbyPeersModal(context),
            ),
            Expanded(
              child: provider.messages.isEmpty
                  ? _EmptyChatPlaceholder(
                      onFindPeers: () => _showNearbyPeersModal(context),
                      onDirectConnect: () => _showManualConnectDialog(context, provider),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        return _MessageBubble(message: msg);
                      },
                    ),
            ),
            _ChatInputBar(
              controller: _textController,
              onSend: () => _sendMessage(provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshStatusBar extends StatelessWidget {
  const _MeshStatusBar({
    required this.provider,
    required this.onOpenPeers,
  });

  final MeshChatProvider provider;
  final VoidCallback onOpenPeers;

  @override
  Widget build(BuildContext context) {
    final hasConnected = provider.connectedPeerCount > 0;
    final statusColor = hasConnected
        ? const Color(0xFF18895C)
        : provider.isScanning
            ? const Color(0xFFB06A25)
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .10),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: .20),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasConnected
                ? Icons.wifi_tethering_rounded
                : Icons.wifi_find_rounded,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasConnected
                  ? 'Mesh Active: ${provider.connectedPeerCount} Peer(s) connected'
                  : provider.isSubnetScanning
                      ? 'Scanning local Wi-Fi subnet for devices…'
                      : 'Broadcasting & scanning for neighboring peers…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onOpenPeers,
            icon: const Icon(Icons.devices_rounded, size: 14),
            label: const Text('Scan', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: .7)
                    : theme.colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: .08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a mesh message…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: .15),
                  ),
                ),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: .4),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder({
    required this.onFindPeers,
    required this.onDirectConnect,
  });

  final VoidCallback onFindPeers;
  final VoidCallback onDirectConnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F6CB5).withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 48,
                color: Color(0xFF3F6CB5),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Serverless Local Mesh Chat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover nearby devices or connect directly over local Wi-Fi / Hotspot to chat without internet or central servers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onFindPeers,
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text('Scan Devices'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onDirectConnect,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Direct IP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyPeersSheet extends StatelessWidget {
  const _NearbyPeersSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshChatProvider>();
    final peers = provider.peers;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded),
              const SizedBox(width: 8),
              const Text(
                'Nearby Device Scanner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (provider.isSubnetScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Rescan Subnet',
                  onPressed: () => provider.scanSubnet(),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: provider.localIpAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('IP Address copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your IP: ${provider.localIpAddress}:${provider.serverPort} • ${provider.deviceName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 14),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          if (peers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Broadcasting & scanning for neighboring devices…',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open this app on your partner\'s device connected to the same Wi-Fi/Hotspot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => provider.scanSubnet(),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(provider.isSubnetScanning ? 'Scanning…' : 'Scan Local Subnet Range'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: peers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final peer = peers[index];
                final isConnected = peer.status == PeerStatus.connected;
                final isConnecting = peer.status == PeerStatus.connecting;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isConnected
                          ? const Color(0xFF18895C)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .12),
                    ),
                    color: isConnected
                        ? const Color(0xFF18895C).withValues(alpha: .06)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected
                            ? Icons.phone_android_rounded
                            : Icons.perm_scan_wifi_rounded,
                        color: isConnected
                            ? const Color(0xFF18895C)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${peer.address}:${peer.port}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isConnected)
                        OutlinedButton(
                          onPressed: () => provider.disconnectPeer(peer),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Disconnect'),
                        )
                      else
                        FilledButton(
                          onPressed: isConnecting
                              ? null
                              : () => provider.connectToPeer(peer),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(isConnecting ? 'Connecting…' : 'Connect'),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
