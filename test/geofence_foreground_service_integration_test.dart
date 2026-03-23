import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/exports.dart' show LatLng;
import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_method_channel.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_platform_interface.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';

import 'support/fake_geofence_foreground_service_platform.dart';

// Top-level function for callback dispatcher (required by API shape).
@pragma('vm:entry-point')
void callbackDispatcher() {}

Matcher angleCloseTo(double value) {
  return predicate<dynamic>(
    (actual) => actual.toString().startsWith('${value.toString()}°'),
    'starts with ${value.toString()}°',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zone model', () {
    test('required fields and coordinates', () {
      final zone = Zone(
        id: 'test_zone',
        radius: 100,
        coordinates: [
          LatLng.degree(40.7128, -74.0060),
          LatLng.degree(40.7129, -74.0061),
        ],
      );

      expect(zone.id, 'test_zone');
      expect(zone.radius, 100);
      expect(zone.coordinates.length, 2);
      expect(zone.coordinates[0].latitude, angleCloseTo(40.7128));
      expect(zone.coordinates[0].longitude, angleCloseTo(-74.0060));
      expect(zone.triggers, contains(GeofenceEventType.enter));
      expect(zone.initialTrigger, GeofenceEventType.enter);
    });

    test('fromJson / toJson round trip', () {
      final zone = Zone(
        id: 'z1',
        radius: 75.5,
        coordinates: [LatLng.degree(1.0, 2.0)],
        notificationResponsivenessMs: 3000,
        triggers: const [GeofenceEventType.enter, GeofenceEventType.exit],
        expirationDuration: const Duration(minutes: 1),
        dwellLoiteringDelay: const Duration(seconds: 30),
        initialTrigger: GeofenceEventType.exit,
      );
      final restored = Zone.fromJson(zone.toJson());
      expect(restored.id, zone.id);
      expect(restored.radius, zone.radius);
      expect(restored.coordinates.length, 1);
      expect(restored.notificationResponsivenessMs, 3000);
      expect(restored.triggers, zone.triggers);
      expect(restored.expirationDuration, zone.expirationDuration);
      expect(restored.dwellLoiteringDelay, zone.dwellLoiteringDelay);
      expect(restored.initialTrigger, zone.initialTrigger);
    });
  });

  group('GeofenceForegroundService with fake platform', () {
    late FakeGeofenceForegroundServicePlatform fake;
    late GeofenceForegroundService service;
    GeofenceForegroundServicePlatform? savedPlatform;

    setUp(() {
      savedPlatform = GeofenceForegroundServicePlatform.instance;
      fake = FakeGeofenceForegroundServicePlatform();
      GeofenceForegroundServicePlatform.instance = fake;
      service = GeofenceForegroundService();
    });

    tearDown(() {
      GeofenceForegroundServicePlatform.instance =
          savedPlatform ?? MethodChannelGeofenceForegroundService();
    });

    test('start, zones, running state, stop', () async {
      expect(await service.isForegroundServiceRunning(), false);

      expect(
        await service.startGeofencingService(
          notificationChannelId: 'ch',
          contentTitle: 'T',
          contentText: 'B',
          callbackDispatcher: callbackDispatcher,
        ),
        true,
      );
      expect(await service.isForegroundServiceRunning(), true);

      final zone = Zone(
        id: 'a',
        radius: 10,
        coordinates: [LatLng.degree(0, 0)],
      );
      expect(await service.addGeofenceZone(zone: zone), true);
      expect(await service.removeGeofenceZone(zoneId: 'a'), true);
      expect(await service.removeAllGeoFences(), true);

      expect(await service.stopGeofencingService(), true);
      expect(await service.isForegroundServiceRunning(), false);
    });

    test('start rejects blank notification fields', () async {
      expect(
        await service.startGeofencingService(
          notificationChannelId: '   ',
          contentTitle: 'T',
          contentText: 'B',
          callbackDispatcher: callbackDispatcher,
        ),
        false,
      );
      expect(fake.serviceRunning, false);
    });
  });

  group('GeofenceForegroundService validation (facade)', () {
    late FakeGeofenceForegroundServicePlatform fake;
    late GeofenceForegroundService service;
    GeofenceForegroundServicePlatform? savedPlatform;

    setUp(() {
      savedPlatform = GeofenceForegroundServicePlatform.instance;
      fake = FakeGeofenceForegroundServicePlatform();
      GeofenceForegroundServicePlatform.instance = fake;
      service = GeofenceForegroundService();
    });

    tearDown(() {
      GeofenceForegroundServicePlatform.instance =
          savedPlatform ?? MethodChannelGeofenceForegroundService();
    });

    test('addGeofenceZone does not call platform when invalid', () async {
      await service.startGeofencingService(
        notificationChannelId: 'ch',
        contentTitle: 'T',
        contentText: 'B',
        callbackDispatcher: callbackDispatcher,
      );

      expect(
        await service.addGeofenceZone(
          zone: Zone(
            id: 'ok',
            radius: 10,
            coordinates: [],
          ),
        ),
        false,
      );
      expect(fake.registeredZoneIds, isEmpty);

      expect(
        await service.addGeofenceZone(
          zone: Zone(
            id: 'ok',
            radius: -1,
            coordinates: [LatLng.degree(0, 0)],
          ),
        ),
        false,
      );
      expect(
        await service.addGeofenceZone(
          zone: Zone(
            id: '',
            radius: 10,
            coordinates: [LatLng.degree(0, 0)],
          ),
        ),
        false,
      );
    });

    test('remove and stop behavior with fake', () async {
      expect(
        await service.removeGeofenceZone(zoneId: 'missing'),
        false,
      );
      expect(await service.stopGeofencingService(), false);
    });
  });
}
