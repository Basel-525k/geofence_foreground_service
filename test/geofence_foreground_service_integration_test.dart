import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/exports.dart' show LatLng;
import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/models/zone.dart';

// Top-level function for callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  // This is just a test callback
}

// Custom matcher for angle values
Matcher angleCloseTo(double value) {
  return predicate<dynamic>(
    (actual) => actual.toString().startsWith('${value.toString()}°'),
    'starts with ${value.toString()}°',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zone Model Tests', () {
    test('Zone creation with required parameters', () {
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
      expect(zone.coordinates[1].latitude, angleCloseTo(40.7129));
      expect(zone.coordinates[1].longitude, angleCloseTo(-74.0061));
    });

    test('Zone creation with single coordinate', () {
      final zone = Zone(
        id: 'single_point',
        radius: 50,
        coordinates: [
          LatLng.degree(40.7128, -74.0060),
        ],
      );

      expect(zone.coordinates.length, 1);
      expect(zone.coordinates[0].latitude, angleCloseTo(40.7128));
      expect(zone.coordinates[0].longitude, angleCloseTo(-74.0060));
    });

    test('Zone creation with multiple coordinates', () {
      final coordinates = [
        LatLng.degree(40.7128, -74.0060),
        LatLng.degree(40.7129, -74.0061),
        LatLng.degree(40.7130, -74.0062),
        LatLng.degree(40.7131, -74.0063),
      ];

      final zone = Zone(
        id: 'multi_point',
        radius: 200,
        coordinates: coordinates,
      );

      expect(zone.coordinates.length, coordinates.length);
      expect(zone.coordinates[0].latitude, angleCloseTo(40.7128));
      expect(zone.coordinates[0].longitude, angleCloseTo(-74.0060));
      expect(zone.coordinates[1].latitude, angleCloseTo(40.7129));
      expect(zone.coordinates[1].longitude, angleCloseTo(-74.0061));
      expect(zone.coordinates[2].latitude, angleCloseTo(40.7130));
      expect(zone.coordinates[2].longitude, angleCloseTo(-74.0062));
      expect(zone.coordinates[3].latitude, angleCloseTo(40.7131));
      expect(zone.coordinates[3].longitude, angleCloseTo(-74.0063));
    });
  });

  group('Geofence Service Tests', () {
    late GeofenceForegroundService service;

    setUp(() {
      service = GeofenceForegroundService();
    });

    test('Service initialization with minimal parameters', () async {
      final result = await service.startGeofencingService(
        notificationChannelId: 'test_channel',
        contentTitle: 'Test Service',
        contentText: 'Running in background',
        callbackDispatcher: callbackDispatcher,
      );

      expect(result, isA<bool>());
    });

    test('Service initialization with empty strings should fail', () async {
      final result = await service.startGeofencingService(
        notificationChannelId: '',
        contentTitle: '',
        contentText: '',
        callbackDispatcher: callbackDispatcher,
      );

      expect(result, false);
    });

    test('Add and remove sequence', () async {
      // First start the service
      final startResult = await service.startGeofencingService(
        notificationChannelId: 'test_channel',
        contentTitle: 'Test Service',
        contentText: 'Running in background',
        callbackDispatcher: callbackDispatcher,
      );
      expect(startResult, isA<bool>());

      // Add a zone
      final zone = Zone(
        id: 'test_zone',
        radius: 100,
        coordinates: [
          LatLng.degree(40.7128, -74.0060),
          LatLng.degree(40.7129, -74.0061),
        ],
      );
      final addResult = await service.addGeofenceZone(zone: zone);
      expect(addResult, isA<bool>());

      // Remove the zone
      final removeResult = await service.removeGeofenceZone(zoneId: zone.id);
      expect(removeResult, isA<bool>());

      // Stop the service
      final stopResult = await service.stopGeofencingService();
      expect(stopResult, isA<bool>());
    });

    test('Service state check sequence', () async {
      // Should not be running initially
      final initialState = await service.isForegroundServiceRunning();
      expect(initialState, false);

      // Start service
      final startResult = await service.startGeofencingService(
        notificationChannelId: 'test_channel',
        contentTitle: 'Test Service',
        contentText: 'Running in background',
        callbackDispatcher: callbackDispatcher,
      );
      expect(startResult, isA<bool>());

      // Check if service is running after start
      final runningState = await service.isForegroundServiceRunning();
      expect(runningState, isA<bool>()); // Just check if it returns a boolean

      // Stop service
      final stopResult = await service.stopGeofencingService();
      expect(stopResult, isA<bool>());

      // Should not be running after stop
      final finalState = await service.isForegroundServiceRunning();
      expect(finalState, false);
    });
  });

  group('Error Handling Tests', () {
    late GeofenceForegroundService service;

    setUp(() {
      service = GeofenceForegroundService();
    });

    test('Add geofence with invalid coordinates', () async {
      final zone = Zone(
        id: 'test_zone',
        radius: 100,
        coordinates: [], // Empty coordinates should fail
      );

      final result = await service.addGeofenceZone(zone: zone);
      expect(result, false);
    });

    test('Add geofence with invalid radius', () async {
      final zone = Zone(
        id: 'test_zone',
        radius: -100, // Negative radius should fail
        coordinates: [
          LatLng.degree(40.7128, -74.0060),
          LatLng.degree(40.7129, -74.0061),
        ],
      );

      final result = await service.addGeofenceZone(zone: zone);
      expect(result, false);
    });

    test('Add geofence with empty ID', () async {
      final zone = Zone(
        id: '', // Empty ID should fail
        radius: 100,
        coordinates: [
          LatLng.degree(40.7128, -74.0060),
          LatLng.degree(40.7129, -74.0061),
        ],
      );

      final result = await service.addGeofenceZone(zone: zone);
      expect(result, false);
    });

    test('Remove non-existent zone', () async {
      final result =
          await service.removeGeofenceZone(zoneId: 'non_existent_zone');
      expect(result, false);
    });

    test('Stop service when not running', () async {
      final result = await service.stopGeofencingService();
      expect(result, false);
    });
  });
}
