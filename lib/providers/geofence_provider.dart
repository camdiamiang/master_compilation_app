import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/geofence_marker.dart';

enum MapTileType {
  standard, // OpenStreetMap Standard
  light,    // CartoDB Positron / Clean
  dark,     // CartoDB Dark Matter
  topographic, // OpenTopoMap
}

enum NavigationSpeed {
  walk,
  bike,
  drive,
}

class GeofenceProvider extends ChangeNotifier {
  // Poblacion Barangay Hall, Lianga, Surigao del Sur, mapped in OpenStreetMap.
  static const LatLng liangaCenter = LatLng(8.63306, 126.09369);

  final Distance _distanceCalc = const Distance();

  // Markers
  List<GeofenceMarker> _markers = [];
  List<GeofenceMarker> get markers => List.unmodifiable(_markers);

  // Active / Selected State
  GeofenceMarker? _selectedMarker;
  GeofenceMarker? get selectedMarker => _selectedMarker;

  // Tracker Position
  LatLng _currentPosition = liangaCenter;
  LatLng get currentPosition => _currentPosition;

  // Movement Trail / Breadcrumbs
  final List<LatLng> _trail = [liangaCenter];
  List<LatLng> get trail => List.unmodifiable(_trail);

  // Controller speed mode
  NavigationSpeed _navigationSpeed = NavigationSpeed.walk;
  NavigationSpeed get navigationSpeed => _navigationSpeed;

  // Camera follow tracker mode
  bool _followTracker = false;
  bool get followTracker => _followTracker;

  // Set of marker IDs currently inside
  final Set<String> _activeGeofenceIds = {};
  Set<String> get activeGeofenceIds => Set.unmodifiable(_activeGeofenceIds);

  // Event audit log
  final List<GeofenceEvent> _eventLogs = [];
  List<GeofenceEvent> get eventLogs => List.unmodifiable(_eventLogs);

  // GPS tracking state
  bool _isGpsActive = false;
  bool get isGpsActive => _isGpsActive;
  StreamSubscription<Position>? _positionStreamSub;
  String? _gpsErrorMessage;
  String? get gpsErrorMessage => _gpsErrorMessage;

  // Simulation state
  bool _isSimulating = false;
  bool get isSimulating => _isSimulating;
  Timer? _simulationTimer;
  int _simulationRouteIndex = 0;
  int _simulationStep = 0;
  static const int _stepsPerLeg = 12;

  // Map Tile Style
  MapTileType _mapTileType = MapTileType.standard;
  MapTileType get mapTileType => _mapTileType;

  // Radius filtering / custom additions
  GeofenceProvider() {
    _initializeDefaultMarkers();
    _evaluateGeofences(isInitial: true);
  }

  void _initializeDefaultMarkers() {
    _markers = [
      GeofenceMarker(
        id: 'spot_boarding_house',
        title: 'Poblacion Barangay Hall',
        category: 'Government',
        subtitle: 'Poblacion, Lianga',
        description:
            'The mapped barangay hall for Poblacion, Lianga.',
        unmappedReason:
            'Public landmark from OpenStreetMap; verify local map coverage before relying on it for navigation.',
        imageUrl:
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
        point: const LatLng(8.63306, 126.09369),
        radiusMeters: 55.0,
        color: const Color(0xFFC85C3E),
        icon: Icons.home_rounded,
        createdAt: DateTime.now(),
      ),
      GeofenceMarker(
        id: 'spot_pagasa_office',
        title: 'North Eastern Mindanao State University - Lianga Campus',
        category: 'Education',
        subtitle: 'Poblacion, Lianga',
        description:
            'North Eastern Mindanao State University Lianga Campus, a mapped public campus in Poblacion.',
        unmappedReason:
            'Public landmark from OpenStreetMap; verify local map coverage before relying on it for navigation.',
        imageUrl:
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80',
        point: const LatLng(8.63386, 126.09324),
        radiusMeters: 60.0,
        color: const Color(0xFF0D9488),
        icon: Icons.business_rounded,
        createdAt: DateTime.now(),
      ),
      GeofenceMarker(
        id: 'spot_ez_print',
        title: 'Lianga Municipal Hall',
        category: 'Government',
        subtitle: 'Osmeña Street, Lianga',
        description:
            'The mapped municipal hall on Osmeña Street, Lianga.',
        unmappedReason:
            'Public landmark from OpenStreetMap; verify local map coverage before relying on it for navigation.',
        imageUrl:
            'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=900&q=80',
        point: const LatLng(8.63909, 126.09191),
        radiusMeters: 65.0,
        color: const Color(0xFF2563EB),
        icon: Icons.print_rounded,
        createdAt: DateTime.now(),
      ),
      GeofenceMarker(
        id: 'spot_ck_printahan',
        title: 'Iglesia ni Cristo - Lokal ng Lianga',
        category: 'Place of Worship',
        subtitle: 'Layno Street, Lianga',
        description:
            'The mapped Iglesia ni Cristo place of worship on Layno Street.',
        unmappedReason:
            'Public landmark from OpenStreetMap; verify local map coverage before relying on it for navigation.',
        imageUrl:
            'https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=900&q=80',
        point: const LatLng(8.62963, 126.09129),
        radiusMeters: 60.0,
        color: const Color(0xFF7C3AED),
        icon: Icons.local_print_shop_rounded,
        createdAt: DateTime.now(),
      ),
      GeofenceMarker(
        id: 'spot_moreno_compound',
        title: 'Lianga Bay Lighthouse',
        category: 'Landmark',
        subtitle: 'Lianga Bay, Lianga',
        description:
            'The mapped Lianga Bay Lighthouse, operated by the Philippine Coast Guard.',
        unmappedReason:
            'Public landmark from OpenStreetMap; verify local map coverage before relying on it for navigation.',
        imageUrl:
            'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=900&q=80',
        point: const LatLng(8.63411, 126.09971),
        radiusMeters: 58.0,
        color: const Color(0xFFEC4899),
        icon: Icons.location_city_rounded,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Set map tile type
  void setMapTileType(MapTileType type) {
    _mapTileType = type;
    notifyListeners();
  }

  String getTileUrl() {
    switch (_mapTileType) {
      case MapTileType.light:
        return 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case MapTileType.dark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapTileType.topographic:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapTileType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void selectMarker(GeofenceMarker? marker) {
    _selectedMarker = marker;
    notifyListeners();
  }

  double getDistanceToMarker(GeofenceMarker marker) {
    return _distanceCalc.as(LengthUnit.Meter, _currentPosition, marker.point);
  }

  double getBearingToMarker(GeofenceMarker marker) {
    return _distanceCalc.bearing(_currentPosition, marker.point);
  }

  String getCompassHeading(double bearing) {
    final normalized = (bearing % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized >= 22.5 && normalized < 67.5) return 'NE';
    if (normalized >= 67.5 && normalized < 112.5) return 'E';
    if (normalized >= 112.5 && normalized < 157.5) return 'SE';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'SW';
    if (normalized >= 247.5 && normalized < 292.5) return 'W';
    return 'NW';
  }

  GeofenceStatus getStatusForMarker(GeofenceMarker marker) {
    final dist = getDistanceToMarker(marker);
    if (dist <= marker.radiusMeters) {
      return GeofenceStatus.inside;
    } else if (dist <= marker.radiusMeters * 1.8) {
      return GeofenceStatus.approaching;
    }
    return GeofenceStatus.outside;
  }

  void setNavigationSpeed(NavigationSpeed speed) {
    _navigationSpeed = speed;
    notifyListeners();
  }

  void toggleFollowTracker() {
    _followTracker = !_followTracker;
    notifyListeners();
  }

  double get currentStepDelta {
    switch (_navigationSpeed) {
      case NavigationSpeed.walk:
        return 0.00007; // ~7.5m
      case NavigationSpeed.bike:
        return 0.00018; // ~20m
      case NavigationSpeed.drive:
        return 0.00048; // ~52m
    }
  }

  String get speedLabel {
    switch (_navigationSpeed) {
      case NavigationSpeed.walk:
        return 'Walk (5 km/h)';
      case NavigationSpeed.bike:
        return 'Bike (15 km/h)';
      case NavigationSpeed.drive:
        return 'Drive (45 km/h)';
    }
  }

  void clearTrail() {
    _trail.clear();
    _trail.add(_currentPosition);
    notifyListeners();
  }

  // Move position manually or via tap
  void setPosition(LatLng newPos) {
    if (_isSimulating) {
      stopSimulationPatrol();
    }
    if (_isGpsActive) {
      stopGpsTracking();
    }
    _currentPosition = newPos;
    _trail.add(newPos);
    if (_trail.length > 400) {
      _trail.removeAt(0);
    }
    _evaluateGeofences();
    notifyListeners();
  }

  // Teleport directly to a specific marker
  void teleportToMarker(GeofenceMarker marker) {
    setPosition(marker.point);
    selectMarker(marker);
  }

  // Nudge tracker in cardinal directions
  void nudgeTracker(double deltaLat, double deltaLng) {
    setPosition(LatLng(
      _currentPosition.latitude + deltaLat,
      _currentPosition.longitude + deltaLng,
    ));
  }

  void nudgeCardinal(String direction) {
    final step = currentStepDelta;
    switch (direction.toUpperCase()) {
      case 'N':
      case 'UP':
        nudgeTracker(step, 0);
        break;
      case 'S':
      case 'DOWN':
        nudgeTracker(-step, 0);
        break;
      case 'E':
      case 'RIGHT':
        nudgeTracker(0, step);
        break;
      case 'W':
      case 'LEFT':
        nudgeTracker(0, -step);
        break;
    }
  }

  // Evaluate geofence boundaries
  void _evaluateGeofences({bool isInitial = false}) {
    final currentActive = <String>{};

    for (final marker in _markers) {
      final dist = _distanceCalc.as(
        LengthUnit.Meter,
        _currentPosition,
        marker.point,
      );

      final isInside = dist <= marker.radiusMeters;
      final wasInside = _activeGeofenceIds.contains(marker.id);

      if (isInside) {
        currentActive.add(marker.id);
        if (!wasInside && !isInitial) {
          _addEvent(
            marker: marker,
            type: GeofenceEventType.entered,
            distance: dist,
            message:
                'ENTERED geofence of "${marker.title}" (${dist.toStringAsFixed(1)}m from center)',
          );
        }
      } else {
        if (wasInside && !isInitial) {
          _addEvent(
            marker: marker,
            type: GeofenceEventType.exited,
            distance: dist,
            message:
                'EXITED geofence of "${marker.title}" (${dist.toStringAsFixed(1)}m away)',
          );
        }
      }
    }

    _activeGeofenceIds.clear();
    _activeGeofenceIds.addAll(currentActive);
  }

  void _addEvent({
    required GeofenceMarker marker,
    required GeofenceEventType type,
    required double distance,
    required String message,
  }) {
    final event = GeofenceEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      markerId: marker.id,
      markerTitle: marker.title,
      type: type,
      distanceMeters: distance,
      message: message,
      color: marker.color,
    );

    _eventLogs.insert(0, event);
    if (_eventLogs.length > 50) {
      _eventLogs.removeLast();
    }
  }

  // Live GPS Tracking
  Future<bool> startGpsTracking() async {
    _gpsErrorMessage = null;

    if (_isSimulating) {
      stopSimulationPatrol();
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _gpsErrorMessage = 'Location services are disabled on this device.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _gpsErrorMessage = 'Location permissions were denied by user.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _gpsErrorMessage =
            'Location permissions are permanently denied. Please enable them in settings.';
        notifyListeners();
        return false;
      }

      // Initial position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _isGpsActive = true;
      _followTracker = true;
      _evaluateGeofences();
      notifyListeners();

      // Listen for continuous stream
      _positionStreamSub?.cancel();
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        ),
      ).listen(
        (Position updatedPos) {
          _currentPosition = LatLng(updatedPos.latitude, updatedPos.longitude);
          _trail.add(_currentPosition);
          if (_trail.length > 400) _trail.removeAt(0);
          _evaluateGeofences();
          notifyListeners();
        },
        onError: (err) {
          _gpsErrorMessage = 'GPS stream error: $err';
          _isGpsActive = false;
          notifyListeners();
        },
      );

      return true;
    } catch (e) {
      _gpsErrorMessage = 'Could not access GPS: $e. You can use Simulation Mode.';
      _isGpsActive = false;
      notifyListeners();
      return false;
    }
  }

  void stopGpsTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _isGpsActive = false;
    notifyListeners();
  }

  // Simulation Patrol Walk Mode
  void toggleSimulationPatrol() {
    if (_isSimulating) {
      stopSimulationPatrol();
    } else {
      startSimulationPatrol();
    }
  }

  void startSimulationPatrol() {
    if (_markers.isEmpty) return;

    if (_isGpsActive) {
      stopGpsTracking();
    }

    _isSimulating = true;
    _simulationRouteIndex = 0;
    _simulationStep = 0;
    _simulationTimer?.cancel();

    // Patrol starts at the verified Poblacion reference point, then visits
    // each custom spot in the same local area before looping back.
    final route = <LatLng>[
      liangaCenter,
      ..._markers.map((marker) => marker.point),
    ];
    _currentPosition = route.first;
    _trail
      ..clear()
      ..add(_currentPosition);
    _evaluateGeofences();
    notifyListeners();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (route.length < 2) return;

      final from = route[_simulationRouteIndex];
      final nextIndex = (_simulationRouteIndex + 1) % route.length;
      final to = route[nextIndex];

      _simulationStep++;
      final t = _simulationStep / _stepsPerLeg;

      // Simulated movement between local geofence waypoints.
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;

      _currentPosition = LatLng(lat, lng);
      _trail.add(_currentPosition);
      if (_trail.length > 400) _trail.removeAt(0);
      _evaluateGeofences();
      notifyListeners();

      if (_simulationStep >= _stepsPerLeg) {
        _simulationStep = 0;
        _simulationRouteIndex = nextIndex;
      }
    });

    notifyListeners();
  }

  void stopSimulationPatrol() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isSimulating = false;
    notifyListeners();
  }

  // Add custom marker
  void addCustomMarker({
    required String title,
    required String category,
    required String subtitle,
    required String description,
    required String unmappedReason,
    String? imageUrl,
    required LatLng point,
    required double radiusMeters,
    required Color color,
    required IconData icon,
  }) {
    final newMarker = GeofenceMarker(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      category: category.trim(),
      subtitle: subtitle.trim(),
      description: description.trim(),
      unmappedReason: unmappedReason.trim(),
      imageUrl: imageUrl,
      point: point,
      radiusMeters: radiusMeters,
      color: color,
      icon: icon,
      isCustom: true,
      createdAt: DateTime.now(),
    );

    _markers.add(newMarker);
    _evaluateGeofences();
    selectMarker(newMarker);
    notifyListeners();
  }

  // Delete custom marker
  void removeCustomMarker(String id) {
    _markers.removeWhere((m) => m.id == id);
    _activeGeofenceIds.remove(id);
    if (_selectedMarker?.id == id) {
      _selectedMarker = null;
    }
    _evaluateGeofences();
    notifyListeners();
  }

  // Update radius
  void updateMarkerRadius(String id, double radius) {
    final index = _markers.indexWhere((m) => m.id == id);
    if (index != -1) {
      _markers[index] = _markers[index].copyWith(radiusMeters: radius);
      if (_selectedMarker?.id == id) {
        _selectedMarker = _markers[index];
      }
      _evaluateGeofences();
      notifyListeners();
    }
  }

  // Clear audit log
  void clearLogs() {
    _eventLogs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
