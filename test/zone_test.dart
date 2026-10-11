import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:latlng/latlng.dart';

void main() {
  group('Zone.fromJson', () {
    test('accepts the loosely typed maps produced by platform channels', () {
      final zone = Zone.fromJson(<String, dynamic>{
        'id': 'zone-1',
        // Whole numbers arrive as ints, not doubles.
        'radius': 150,
        'coordinates': <dynamic>[
          <dynamic, dynamic>{'latitude': 31, 'longitude': 35.5},
          <String, Object?>{'latitude': 31.5, 'longitude': 35},
        ],
        'notification_responsiveness_ms': 5000,
        'fence_triggers': <dynamic>[1, 2],
        'fence_expiration_duration': 60000,
        'fence_dwell_loitering_delay': 1000,
        'fence_initial_trigger': 2,
      });

      expect(zone.id, 'zone-1');
      expect(zone.radius, 150.0);
      expect(zone.coordinates, hasLength(2));
      expect(zone.coordinates.first.latitude.degrees, 31.0);
      expect(zone.coordinates.last.longitude.degrees, 35.0);
      expect(zone.notificationResponsivenessMs, 5000);
      expect(zone.triggers, [GeofenceEventType.enter, GeofenceEventType.exit]);
      expect(zone.expirationDuration, const Duration(minutes: 1));
      expect(zone.dwellLoiteringDelay, const Duration(seconds: 1));
      expect(zone.initialTrigger, GeofenceEventType.exit);
    });

    test('round-trips through toJson', () {
      final zone = Zone(
        id: 'z',
        radius: 100,
        coordinates: [LatLng.degree(1, 2)],
      );

      final restored = Zone.fromJson(zone.toJson());

      expect(restored.id, zone.id);
      expect(restored.radius, zone.radius);
      expect(restored.coordinates.single.latitude.degrees, 1);
      expect(restored.coordinates.single.longitude.degrees, 2);
    });

    test('initialTriggers round-trip as a bitmask', () {
      final zone = Zone(
        id: 'z',
        radius: 100,
        coordinates: [LatLng.degree(1, 2)],
        initialTriggers: [GeofenceEventType.enter, GeofenceEventType.exit],
      );

      expect(zone.toJson()['fence_initial_trigger'], 3);

      final restored = Zone.fromJson(zone.toJson());
      expect(restored.initialTriggers,
          [GeofenceEventType.enter, GeofenceEventType.exit]);
      expect(restored.initialTrigger, GeofenceEventType.enter);
    });

    test('a single initialTrigger keeps its wire value', () {
      final zone = Zone(
        id: 'z',
        radius: 100,
        coordinates: [LatLng.degree(1, 2)],
        initialTrigger: GeofenceEventType.exit,
      );

      expect(zone.initialTriggers, [GeofenceEventType.exit]);
      expect(zone.toJson()['fence_initial_trigger'], 2);
    });

    test('default initial trigger is enter', () {
      final zone = Zone(
        id: 'z',
        radius: 100,
        coordinates: [LatLng.degree(1, 2)],
      );

      expect(zone.initialTriggers, [GeofenceEventType.enter]);
      expect(zone.toJson()['fence_initial_trigger'], 1);
    });
  });
}
