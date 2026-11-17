import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:master_compilation_app/main.dart';
import 'package:master_compilation_app/models/geofence_marker.dart';
import 'package:master_compilation_app/providers/app_provider.dart';
import 'package:master_compilation_app/providers/geofence_provider.dart';
import 'package:master_compilation_app/providers/mesh_chat_provider.dart';
import 'package:master_compilation_app/providers/network_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders correctly with Activities 1 to 5 compiled',
      (WidgetTester tester) async {
    // Build app and trigger frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
          ChangeNotifierProvider(create: (_) => MeshChatProvider()),
          ChangeNotifierProvider(create: (_) => GeofenceProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify title and compilation header
    expect(find.text('Master Compilation App'), findsOneWidget);
    expect(find.text('Midterm Compilation (Activities 1–5)'), findsOneWidget);

    // Verify all 5 activities are present
    expect(find.text('Activity 1: Mobile Environment'), findsOneWidget);
    expect(find.text('Activity 2: Network Monitor'), findsOneWidget);
    expect(find.text('Activity 3: Network Diagnostic'), findsOneWidget);
    expect(find.text('Activity 4: Local Mesh Chat'), findsOneWidget);
    expect(find.text('Activity 5: Custom Map & Geofencing'), findsOneWidget);
  });

  testWidgets('Can navigate to Activity 1 and interact with state counter',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
          ChangeNotifierProvider(create: (_) => MeshChatProvider()),
          ChangeNotifierProvider(create: (_) => GeofenceProvider()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.tap(find.text('Activity 1: Mobile Environment'));
    await tester.pumpAndSettle();

    expect(find.text('Environment & UI Architecture'), findsOneWidget);
    expect(find.text('Stateful Lifecycle & User Interaction'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Tap Me'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  group('GeofenceProvider Unit Tests', () {
    test('Initializes with at least 5 custom unmapped Poblacion locations', () {
      final provider = GeofenceProvider();
      expect(provider.markers.length, greaterThanOrEqualTo(5));

      final spotTitles = provider.markers.map((m) => m.title).toList();
      expect(spotTitles, contains('My Boarding House - Purok 4 Sabang'));
      expect(spotTitles, contains('PAG-ASA Office - Purok 3'));
      expect(spotTitles, contains('EZ Print - Purok 1 Poblacion'));
      expect(spotTitles, contains('CK Printahan - Bonifacio St'));
      expect(spotTitles, contains('Moreno Compound - Poblacion Lianga'));
    });

    test('Triggers geofence entry when position is moved inside marker radius', () {
      final provider = GeofenceProvider();
      final marker = provider.markers.firstWhere(
        (m) => m.id == 'spot_boarding_house',
      );

      provider.setPosition(const LatLng(8.6600, 126.1200));
      expect(provider.activeGeofenceIds.contains(marker.id), isFalse);

      provider.setPosition(marker.point);

      expect(provider.activeGeofenceIds.contains(marker.id), isTrue);
      expect(provider.getStatusForMarker(marker), equals(GeofenceStatus.inside));
      expect(provider.eventLogs.isNotEmpty, isTrue);
      expect(provider.eventLogs.first.type, equals(GeofenceEventType.entered));
    });

    test('Triggers geofence exit when moving away', () {
      final provider = GeofenceProvider();
      final marker = provider.markers.firstWhere(
        (m) => m.id == 'spot_boarding_house',
      );

      provider.setPosition(marker.point);
      expect(provider.activeGeofenceIds.contains(marker.id), isTrue);

      provider.setPosition(LatLng(
        marker.point.latitude + 0.02,
        marker.point.longitude,
      ));

      expect(provider.activeGeofenceIds.contains(marker.id), isFalse);
      expect(provider.getStatusForMarker(marker), equals(GeofenceStatus.outside));
      expect(provider.eventLogs.first.type, equals(GeofenceEventType.exited));
    });

    test('Can dynamically add a new custom spot', () {
      final provider = GeofenceProvider();
      final initialCount = provider.markers.length;

      provider.addCustomMarker(
        title: "Hidden Mango Tree Study Grove",
        category: "Study Spot",
        subtitle: "Behind Barangay Hall, Lianga",
        description: "Shaded private retreat for student midterm review.",
        unmappedReason: "Private community footpath under fruit trees.",
        point: const LatLng(8.6340, 126.0960),
        radiusMeters: 40.0,
        color: const Color(0xFF10B981),
        icon: Icons.school_rounded,
      );

      expect(provider.markers.length, equals(initialCount + 1));
      expect(provider.markers.last.title, equals("Hidden Mango Tree Study Grove"));
      expect(provider.markers.last.isCustom, isTrue);
    });
  });
}
