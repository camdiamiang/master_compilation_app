import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/geofence_marker.dart';
import '../providers/geofence_provider.dart';

class GeofencingMapScreen extends StatefulWidget {
  const GeofencingMapScreen({super.key});

  @override
  State<GeofencingMapScreen> createState() => _GeofencingMapScreenState();
}

class _GeofencingMapScreenState extends State<GeofencingMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  bool _showSpotList = true;
  bool _showDpad = true;
  bool _hasAutoStartedGps = false;

  // Track previous GPS position to know when to move camera
  LatLng? _lastCenteredPosition;

  void _onDpadStep(GeofenceProvider provider, String direction) {
    provider.nudgeCardinal(direction);
    if (provider.followTracker) {
      _mapController.move(provider.currentPosition, _mapController.camera.zoom);
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasAutoStartedGps) return;
      _hasAutoStartedGps = true;

      final provider = context.read<GeofenceProvider>();
      if (provider.isGpsActive) return;

      final ok = await provider.startGpsTracking();
      if (!mounted) return;

      if (ok) {
        if (!provider.followTracker) {
          provider.toggleFollowTracker();
        }
        _centerOn(provider.currentPosition, zoom: 17.0);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _centerOn(LatLng point, {double zoom = 16.0}) {
    _mapController.move(point, zoom);
  }

  /// Called after build — moves the camera when follow mode is active.
  void _followCameraIfNeeded(GeofenceProvider provider) {
    if (!provider.followTracker) return;
    final pos = provider.currentPosition;
    if (_lastCenteredPosition == pos) return;
    _lastCenteredPosition = pos;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(pos, _mapController.camera.zoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GeofenceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeIds = provider.activeGeofenceIds;

    // Auto-follow camera when GPS or simulation is active and follow mode on
    _followCameraIfNeeded(provider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: provider.isGpsActive
                  ? provider.currentPosition
                  : GeofenceProvider.liangaCenter,
              initialZoom: 15.6,
              minZoom: 11.0,
              maxZoom: 18.5,
              onTap: (tapPosition, point) {
                provider.setPosition(point);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 900),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1F2937),
                    content: Text(
                      'Tracker moved to ${point.latitude.toStringAsFixed(4)}°, ${point.longitude.toStringAsFixed(4)}°',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
            children: [
              // Map Tiles Layer
              TileLayer(
                urlTemplate: provider.getTileUrl(),
                userAgentPackageName: 'com.example.master_compilation_app',
                maxZoom: 19,
              ),

              // Geofence Radius Circles Layer + GPS accuracy circle
              CircleLayer(
                circles: [
                  ...provider.markers.map((marker) {
                    final isInside = activeIds.contains(marker.id);
                    return CircleMarker(
                      point: marker.point,
                      radius: marker.radiusMeters,
                      useRadiusInMeter: true,
                      color: marker.color.withValues(
                        alpha: isInside ? 0.32 : 0.14,
                      ),
                      borderColor: marker.color.withValues(
                        alpha: isInside ? 0.95 : 0.60,
                      ),
                      borderStrokeWidth: isInside ? 3.0 : 1.5,
                    );
                  }),
                  // Blue "My Location" accuracy halo shown when GPS is live
                  if (provider.isGpsActive)
                    CircleMarker(
                      point: provider.currentPosition,
                      radius: 22,
                      useRadiusInMeter: true,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                      borderColor: const Color(0xFF2563EB).withValues(alpha: 0.70),
                      borderStrokeWidth: 1.8,
                    ),
                ],
              ),

              // Movement Trail / Breadcrumb Polyline
              if (provider.trail.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: provider.trail,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.65),
                      strokeWidth: 3.0,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // Custom Spots Markers Layer
              MarkerLayer(
                markers: [
                  ...provider.markers.map((marker) {
                    final isInside = activeIds.contains(marker.id);
                    return Marker(
                      point: marker.point,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () {
                          provider.selectMarker(marker);
                          _showMarkerDetailsSheet(context, marker);
                        },
                        child: _SpotMarkerWidget(
                          marker: marker,
                          isInside: isInside,
                        ),
                      ),
                    );
                  }),

                  // User / Tracker Pin with Radar Pulse
                  Marker(
                    point: provider.currentPosition,
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return _TrackerPinWidget(
                          pulseValue: _pulseController.value,
                          isPatrolling: provider.isSimulating,
                          isGpsActive: provider.isGpsActive,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Header HUD with Status Banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopActionBar(
                    provider: provider,
                    onOpenLog: () => _showAuditLogSheet(context, provider),
                    onOpenAddMarker: () => _showAddSpotDialog(context, provider),
                    onToggleTileStyle: () => _showTileLayerSheet(context, provider),
                  ),
                  const SizedBox(height: 8),
                  _GeofenceStatusHUD(
                    provider: provider,
                    onTapStatus: () {
                      if (activeIds.isNotEmpty) {
                        final insideMarker = provider.markers.firstWhere(
                          (m) => activeIds.contains(m.id),
                        );
                        _centerOn(insideMarker.point);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Quick Control Buttons (Right Side)
          Positioned(
            right: 14,
            top: 150,
            child: Column(
              children: [
                // Center on current tracker / GPS position
                _MapFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on My Location',
                  onPressed: () {
                    _centerOn(provider.currentPosition, zoom: 17.0);
                  },
                ),
                const SizedBox(height: 10),
                // Lock camera to follow the tracker/GPS dot
                _MapFloatingButton(
                  icon: provider.followTracker
                      ? Icons.location_searching_rounded
                      : Icons.location_disabled_rounded,
                  tooltip: provider.followTracker
                      ? 'Following — Tap to Unlock Camera'
                      : 'Lock Camera to My Location',
                  activeColor: const Color(0xFF2563EB),
                  isActive: provider.followTracker,
                  onPressed: () {
                    provider.toggleFollowTracker();
                    if (!provider.followTracker) return;
                    // Immediately snap camera when enabling follow
                    _centerOn(provider.currentPosition, zoom: 17.0);
                  },
                ),
                const SizedBox(height: 10),
                _MapFloatingButton(
                  icon: provider.isSimulating
                      ? Icons.pause_circle_filled_rounded
                      : Icons.directions_walk_rounded,
                  tooltip: provider.isSimulating
                      ? 'Pause Auto-Patrol'
                      : 'Start Auto-Patrol Walk',
                  activeColor: const Color(0xFFE05638),
                  isActive: provider.isSimulating,
                  onPressed: () {
                    provider.toggleSimulationPatrol();
                  },
                ),
                const SizedBox(height: 10),
                _MapFloatingButton(
                  icon: provider.isGpsActive
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  tooltip: provider.isGpsActive
                      ? 'Disable Live GPS'
                      : 'Enable Device GPS',
                  activeColor: const Color(0xFF0D9488),
                  isActive: provider.isGpsActive,
                  onPressed: () async {
                    if (provider.isGpsActive) {
                      provider.stopGpsTracking();
                    } else {
                      final ok = await provider.startGpsTracking();
                      if (!context.mounted) return;
                      if (ok) {
                        // Auto-enable follow and snap camera to real GPS location
                        if (!provider.followTracker) provider.toggleFollowTracker();
                        _centerOn(provider.currentPosition, zoom: 17.0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF0D9488),
                            content: Text(
                              '📍 GPS active — map is now following your real location',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFFB91C1C),
                            content: Text(
                              provider.gpsErrorMessage ?? 'Could not start GPS',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                _MapFloatingButton(
                  icon: _showSpotList
                      ? Icons.expand_more_rounded
                      : Icons.view_carousel_rounded,
                  tooltip: _showSpotList ? 'Hide Spots Sheet' : 'Show Spots Sheet',
                  onPressed: () {
                    setState(() {
                      _showSpotList = !_showSpotList;
                    });
                  },
                ),
              ],
            ),
          ),

          // 4b. D-Pad Controller (bottom-left, above spots panel)
          if (_showDpad)
            Positioned(
              left: 12,
              bottom: _showSpotList ? 210 : 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Speed selector chips
                  _SpeedSelectorBar(provider: provider),
                  const SizedBox(height: 6),
                  // D-Pad
                  _DpadController(
                    onStep: (dir) => _onDpadStep(provider, dir),
                    onToggleVisibility: () {
                      setState(() => _showDpad = !_showDpad);
                    },
                  ),
                ],
              ),
            ),

          // D-Pad toggle button (when hidden)
          if (!_showDpad)
            Positioned(
              left: 12,
              bottom: _showSpotList ? 210 : 16,
              child: _MapFloatingButton(
                icon: Icons.gamepad_rounded,
                tooltip: 'Show D-Pad Controller',
                onPressed: () => setState(() => _showDpad = true),
              ),
            ),

          // 4. Bottom Spots Carousel & Quick Tracker Info
          if (_showSpotList)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomSpotsPanel(
                provider: provider,
                isDark: isDark,
                onSelectSpot: (marker) {
                  _centerOn(marker.point);
                  _showMarkerDetailsSheet(context, marker);
                },
                onTeleportToSpot: (marker) {
                  provider.teleportToMarker(marker);
                  _centerOn(marker.point);
                },
              ),
            ),
        ],
      ),
    );
  }

  // Bottom Sheet: Marker Details
  void _showMarkerDetailsSheet(BuildContext context, GeofenceMarker marker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _MarkerDetailModal(
          marker: marker,
          onTeleport: () {
            Navigator.pop(ctx);
            final provider = context.read<GeofenceProvider>();
            provider.teleportToMarker(marker);
            _centerOn(marker.point);
          },
        );
      },
    );
  }

  // Bottom Sheet: Audit Logs
  void _showAuditLogSheet(BuildContext context, GeofenceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.88,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            final events = provider.eventLogs;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geofence Audit Log',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Real-time boundary enter & exit events',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (events.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            provider.clearLogs();
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: events.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No geofence events logged yet.\nWalk or patrol near a custom spot to trigger an event.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: events.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final event = events[index];
                              final isEnter =
                                  event.type == GeofenceEventType.entered;
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isEnter
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: .18)
                                      : const Color(0xFFEF4444)
                                          .withValues(alpha: .18),
                                  child: Icon(
                                    isEnter
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    size: 18,
                                    color: isEnter
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                title: Text(
                                  event.markerTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  event.message,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Dialog: Add Custom Spot
  void _showAddSpotDialog(BuildContext context, GeofenceProvider provider) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Personal Residence');
    final descCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController(
      text: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
    );
    final reasonCtrl = TextEditingController(
      text: 'Private unmapped residential area not visible on commercial maps.',
    );
    double radius = 60.0;
    Color chosenColor = const Color(0xFFC85C3E);
    IconData chosenIcon = Icons.home_rounded;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_location_alt_rounded, color: Color(0xFFC85C3E)),
                  SizedBox(width: 8),
                  Text('Add Custom Spot', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a custom marker for your house, local hangout, or undiscovered Lianga spot.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Spot Name',
                          hintText: "e.g., My Ancestral House / Study Nook",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location / Barangay',
                          hintText: "e.g., Purok 3, Brgy. Poblacion, Lianga",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: "e.g., Home, Hidden Spring, Viewpoint",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Why not visible on Google Maps?',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief details about this location...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: imageUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          hintText: 'https://example.com/photo.jpg',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Geofence Radius:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${radius.toInt()} meters',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC85C3E))),
                        ],
                      ),
                      Slider(
                        value: radius,
                        min: 30,
                        max: 180,
                        divisions: 15,
                        label: '${radius.toInt()}m',
                        onChanged: (val) {
                          setDialogState(() {
                            radius = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Marker Color:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          const Color(0xFFC85C3E),
                          const Color(0xFF0D9488),
                          const Color(0xFF2E7D32),
                          const Color(0xFF7C3AED),
                          const Color(0xFFD97706),
                          const Color(0xFF0284C7),
                        ].map((col) {
                          final isSelected = chosenColor == col;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                chosenColor = col;
                              });
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: col,
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    provider.addCustomMarker(
                      title: title,
                      category: catCtrl.text.trim().isEmpty ? 'Custom Spot' : catCtrl.text.trim(),
                      subtitle: subCtrl.text.trim().isEmpty ? 'Lianga Area' : subCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? 'A custom community location in Lianga.'
                          : descCtrl.text.trim(),
                      unmappedReason: reasonCtrl.text.trim(),
                      imageUrl: imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim(),
                      point: provider.currentPosition,
                      radiusMeters: radius,
                      color: chosenColor,
                      icon: chosenIcon,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Location'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Bottom Sheet: Tile Layer Style Switcher
  void _showTileLayerSheet(BuildContext context, GeofenceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Style & Layer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.map_rounded),
                  title: const Text('OpenStreetMap Standard'),
                  trailing: provider.mapTileType == MapTileType.standard
                      ? const Icon(Icons.check_circle, color: Color(0xFFC85C3E))
                      : null,
                  onTap: () {
                    provider.setMapTileType(MapTileType.standard);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('CartoDB Clean Light'),
                  trailing: provider.mapTileType == MapTileType.light
                      ? const Icon(Icons.check_circle, color: Color(0xFFC85C3E))
                      : null,
                  onTap: () {
                    provider.setMapTileType(MapTileType.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.nightlight_round),
                  title: const Text('CartoDB Dark Matter'),
                  trailing: provider.mapTileType == MapTileType.dark
                      ? const Icon(Icons.check_circle, color: Color(0xFFC85C3E))
                      : null,
                  onTap: () {
                    provider.setMapTileType(MapTileType.dark);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.terrain_rounded),
                  title: const Text('OpenTopoMap (Topographic)'),
                  trailing: provider.mapTileType == MapTileType.topographic
                      ? const Icon(Icons.check_circle, color: Color(0xFFC85C3E))
                      : null,
                  onTap: () {
                    provider.setMapTileType(MapTileType.topographic);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-WIDGETS & COMPONENTS
// ---------------------------------------------------------------------------

/// D-Pad directional controller for manual tracker movement.
class _DpadController extends StatelessWidget {
  final void Function(String direction) onStep;
  final VoidCallback onToggleVisibility;

  const _DpadController({
    required this.onStep,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: hide button + N button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hide d-pad button (top-left corner of pad)
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.keyboard_hide_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _DpadButton(
                icon: Icons.keyboard_arrow_up_rounded,
                onTap: () => onStep('N'),
              ),
              const SizedBox(width: 36), // spacer for symmetry
            ],
          ),
          const SizedBox(height: 4),
          // Middle row: W, center dot, E
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DpadButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onTap: () => onStep('W'),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFC85C3E).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC85C3E).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFFC85C3E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              _DpadButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onTap: () => onStep('E'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Bottom row: spacer + S button + spacer
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 36),
              const SizedBox(width: 4),
              _DpadButton(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () => onStep('S'),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single D-Pad button that supports hold-to-repeat.
class _DpadButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DpadButton({required this.icon, required this.onTap});

  @override
  State<_DpadButton> createState() => _DpadButtonState();
}

class _DpadButtonState extends State<_DpadButton> {
  bool _pressed = false;
  Timer? _holdTimer;

  void _startHold() {
    widget.onTap();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (mounted) widget.onTap();
    });
  }

  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _startHold();
      },
      onTapUp: (_) => _endHold(),
      onTapCancel: _endHold,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFFC85C3E).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          widget.icon,
          color: _pressed ? Colors.white : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

/// Speed selector chips shown above the D-Pad.
class _SpeedSelectorBar extends StatelessWidget {
  final GeofenceProvider provider;

  const _SpeedSelectorBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: NavigationSpeed.values.map((speed) {
          final isSelected = provider.navigationSpeed == speed;
          final label = switch (speed) {
            NavigationSpeed.walk => '🚶',
            NavigationSpeed.bike => '🚲',
            NavigationSpeed.drive => '🚗',
          };
          return GestureDetector(
            onTap: () => provider.setNavigationSpeed(speed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFC85C3E)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopActionBar extends StatelessWidget {
  final GeofenceProvider provider;
  final VoidCallback onOpenLog;
  final VoidCallback onOpenAddMarker;
  final VoidCallback onToggleTileStyle;

  const _TopActionBar({
    required this.provider,
    required this.onOpenLog,
    required this.onOpenAddMarker,
    required this.onToggleTileStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF261B18) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lianga Geofence Tracker',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  'Activity 5 • Custom Map & Boundaries',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.layers_rounded, size: 21),
            tooltip: 'Map Layer',
            onPressed: onToggleTileStyle,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, size: 21),
                tooltip: 'Audit Event Log',
                onPressed: onOpenLog,
              ),
              if (provider.eventLogs.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE05638),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${provider.eventLogs.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, size: 22, color: Color(0xFFC85C3E)),
            tooltip: 'Add Custom Spot',
            onPressed: onOpenAddMarker,
          ),
        ],
      ),
    );
  }
}

class _GeofenceStatusHUD extends StatelessWidget {
  final GeofenceProvider provider;
  final VoidCallback onTapStatus;

  const _GeofenceStatusHUD({
    required this.provider,
    required this.onTapStatus,
  });

  @override
  Widget build(BuildContext context) {
    final activeIds = provider.activeGeofenceIds;
    final isInside = activeIds.isNotEmpty;

    final insideMarker = isInside
        ? provider.markers.firstWhere(
            (m) => activeIds.contains(m.id),
            orElse: () => provider.markers.first,
          )
        : null;

    final bgColor = isInside
        ? const Color(0xFF065F46) // Deep emerald green
        : const Color(0xFF1E293B); // Slate dark

    return GestureDetector(
      onTap: onTapStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isInside
                ? const Color(0xFF34D399)
                : Colors.white.withValues(alpha: .15),
            width: isInside ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isInside ? const Color(0xFF34D399) : Colors.amber,
                boxShadow: [
                  BoxShadow(
                    color: isInside
                        ? const Color(0xAA34D399)
                        : const Color(0xAAFFC107),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isInside
                        ? 'INSIDE GEOFENCE: ${insideMarker?.title}'
                        : 'STATUS: Roaming Lianga Outskirts',
                    style: TextStyle(
                      color: isInside ? const Color(0xFFD1FAE5) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInside
                        ? 'Active Radius: ${insideMarker?.radiusMeters.toInt()}m • Tap to inspect zone'
                        : 'Tap anywhere on map or choose a spot below to enter geofence',
                    style: TextStyle(
                      color: isInside
                          ? const Color(0xFFA7F3D0)
                          : Colors.white.withValues(alpha: .75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isInside)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34D399),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SpotMarkerWidget extends StatelessWidget {
  final GeofenceMarker marker;
  final bool isInside;

  const _SpotMarkerWidget({
    required this.marker,
    required this.isInside,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isInside ? 44 : 38,
          height: isInside ? 44 : 38,
          decoration: BoxDecoration(
            color: marker.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isInside ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: marker.color.withValues(alpha: .5),
                blurRadius: isInside ? 14 : 8,
                spreadRadius: isInside ? 3 : 1,
              ),
            ],
          ),
          child: Icon(
            marker.icon,
            size: isInside ? 24 : 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TrackerPinWidget extends StatelessWidget {
  final double pulseValue;
  final bool isPatrolling;
  final bool isGpsActive;

  const _TrackerPinWidget({
    required this.pulseValue,
    required this.isPatrolling,
    required this.isGpsActive,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isGpsActive
        ? const Color(0xFF059669)
        : (isPatrolling ? const Color(0xFFE05638) : const Color(0xFF2563EB));

    return Stack(
      alignment: Alignment.center,
      children: [
        // Expanding radar pulse
        Container(
          width: 52 * pulseValue,
          height: 52 * pulseValue,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor.withValues(alpha: (1.0 - pulseValue) * 0.45),
            border: Border.all(
              color: activeColor.withValues(alpha: (1.0 - pulseValue)),
              width: 1.5,
            ),
          ),
        ),
        // Central dot
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.navigation_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const _MapFloatingButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF2B1F1C) : Colors.white;
    final effectiveBg = isActive ? (activeColor ?? const Color(0xFFC85C3E)) : defaultBg;
    final effectiveIconColor = isActive
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF30201B));

    return Material(
      color: effectiveBg,
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, color: effectiveIconColor, size: 21),
          ),
        ),
      ),
    );
  }
}

class _BottomSpotsPanel extends StatelessWidget {
  final GeofenceProvider provider;
  final bool isDark;
  final Function(GeofenceMarker) onSelectSpot;
  final Function(GeofenceMarker) onTeleportToSpot;

  const _BottomSpotsPanel({
    required this.provider,
    required this.isDark,
    required this.onSelectSpot,
    required this.onTeleportToSpot,
  });

  @override
  Widget build(BuildContext context) {
    final markers = provider.markers;
    final bg = isDark ? const Color(0xFF221715) : const Color(0xFFFAF5EE);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 18, color: Color(0xFFC85C3E)),
                      const SizedBox(width: 6),
                      Text(
                        'Unmapped Lianga Spots (${markers.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Not on Google Maps',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: markers.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final marker = markers[index];
                    final dist = provider.getDistanceToMarker(marker);
                    final isInside = provider.activeGeofenceIds.contains(marker.id);
                    final isSelected = provider.selectedMarker?.id == marker.id;

                    return _SpotCard(
                      marker: marker,
                      distanceMeters: dist,
                      isInside: isInside,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => onSelectSpot(marker),
                      onTeleport: () => onTeleportToSpot(marker),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final GeofenceMarker marker;
  final double distanceMeters;
  final bool isInside;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onTeleport;

  const _SpotCard({
    required this.marker,
    required this.distanceMeters,
    required this.isInside,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onTeleport,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C1F1B) : Colors.white;
    final distText = distanceMeters < 1000
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(2)} km';

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInside
              ? const Color(0xFF10B981)
              : (isSelected
                  ? marker.color
                  : Colors.grey.withValues(alpha: .2)),
          width: (isInside || isSelected) ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: marker.color.withValues(alpha: .18),
                      child: Icon(marker.icon, size: 16, color: marker.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            marker.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.withValues(alpha: .9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInside
                            ? const Color(0xFF10B981).withValues(alpha: .18)
                            : Colors.grey.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInside ? Icons.check_circle : Icons.straighten,
                            size: 11,
                            color: isInside ? const Color(0xFF10B981) : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isInside ? 'INSIDE ($distText)' : distText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isInside ? const Color(0xFF10B981) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.near_me_rounded,
                        size: 20,
                        color: Color(0xFFC85C3E),
                      ),
                      tooltip: 'Teleport Tracker Here',
                      onPressed: onTeleport,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerDetailModal extends StatelessWidget {
  final GeofenceMarker marker;
  final VoidCallback onTeleport;

  const _MarkerDetailModal({
    required this.marker,
    required this.onTeleport,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GeofenceProvider>();
    final isInside = provider.activeGeofenceIds.contains(marker.id);
    final distance = provider.getDistanceToMarker(marker);
    final bearing = provider.getBearingToMarker(marker);
    final heading = provider.getCompassHeading(bearing);

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      maxChildSize: 0.88,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: marker.color.withValues(alpha: .18),
                    child: Icon(marker.icon, size: 24, color: marker.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marker.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          marker.subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInside
                          ? const Color(0xFF10B981).withValues(alpha: .18)
                          : Colors.grey.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isInside ? 'INSIDE ZONE' : 'OUTSIDE ZONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isInside ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Not on Google Maps explanation callout
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.visibility_off_rounded,
                      size: 20,
                      color: Color(0xFFC2410C),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why this is not visible on Google Maps:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            marker.unmappedReason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C2D12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (marker.imageUrl != null && marker.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    marker.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Description & Context',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                marker.description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Telemetry Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Distance to Tracker',
                      value: distance < 1000
                          ? '${distance.toStringAsFixed(1)} m'
                          : '${(distance / 1000).toStringAsFixed(2)} km',
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Compass Bearing',
                      value: '${bearing.toStringAsFixed(0)}° ($heading)',
                      icon: Icons.explore_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Geofence Radius',
                      value: '${marker.radiusMeters.toInt()} meters',
                      icon: Icons.radio_button_checked_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Coordinates',
                      value:
                          '${marker.point.latitude.toStringAsFixed(4)}°, ${marker.point.longitude.toStringAsFixed(4)}°',
                      icon: Icons.pin_drop_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onTeleport,
                icon: const Icon(Icons.near_me_rounded),
                label: const Text('Move Tracker Directly Inside This Spot'),
                style: FilledButton.styleFrom(
                  backgroundColor: marker.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2A1C19) : const Color(0xFFF3ECE4);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
