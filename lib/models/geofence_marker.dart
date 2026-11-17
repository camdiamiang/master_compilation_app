import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum GeofenceEventType {
  entered,
  exited,
  dwell,
}

enum GeofenceStatus {
  inside,
  approaching,
  outside,
}

class GeofenceMarker {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String description;
  final String unmappedReason; // Why this spot isn't visible on Google Maps
  final String? imageUrl;
  final LatLng point;
  final double radiusMeters;
  final Color color;
  final IconData icon;
  final bool isCustom;
  final DateTime createdAt;

  const GeofenceMarker({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.description,
    required this.unmappedReason,
    this.imageUrl,
    required this.point,
    this.radiusMeters = 60.0,
    required this.color,
    required this.icon,
    this.isCustom = false,
    required this.createdAt,
  });

  GeofenceMarker copyWith({
    String? id,
    String? title,
    String? category,
    String? subtitle,
    String? description,
    String? unmappedReason,
    String? imageUrl,
    LatLng? point,
    double? radiusMeters,
    Color? color,
    IconData? icon,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return GeofenceMarker(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      unmappedReason: unmappedReason ?? this.unmappedReason,
      imageUrl: imageUrl ?? this.imageUrl,
      point: point ?? this.point,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'subtitle': subtitle,
      'description': description,
      'unmappedReason': unmappedReason,
      'imageUrl': imageUrl,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'radiusMeters': radiusMeters,
      'color': color.toARGB32(),
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class GeofenceEvent {
  final String id;
  final DateTime timestamp;
  final String markerId;
  final String markerTitle;
  final GeofenceEventType type;
  final double distanceMeters;
  final String message;
  final Color color;

  const GeofenceEvent({
    required this.id,
    required this.timestamp,
    required this.markerId,
    required this.markerTitle,
    required this.type,
    required this.distanceMeters,
    required this.message,
    required this.color,
  });
}
