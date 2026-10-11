import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_platform_interface.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:latlng/latlng.dart';

import 'support/fake_geofence_foreground_service_platform.dart';

void _dispatcher() {}

void main() {
  late FakeGeofenceForegroundServicePlatform fake;
  final service = GeofenceForegroundService();

  Zone zone({
    String id = 'z',
    double radius = 100,
    List<LatLng>? coordinates,
    double polygonMarginMeters = 0,
  }) =>
      Zone(
        id: id,
        radius: radius,
        coordinates: coordinates ?? [LatLng.degree(10, 20)],
        polygonMarginMeters: polygonMarginMeters,
      );

  setUp(() async {
    fake = FakeGeofenceForegroundServicePlatform();
    GeofenceForegroundServicePlatform.instance = fake;
    await service.startGeofencingService(
      notificationChannelId: 'c',
      contentTitle: 't',
      contentText: 'x',
      callbackDispatcher: _dispatcher,
    );
  });

  group('addGeofenceZone validation', () {
    test('rejects a negative or non-finite polygon margin', () async {
      expect(await service.addGeofenceZone(zone: zone(polygonMarginMeters: -1)),
          isFalse);
      expect(
          await service.addGeofenceZone(
              zone: zone(polygonMarginMeters: double.nan)),
          isFalse);
      expect(
          await service.addGeofenceZone(
              zone: zone(polygonMarginMeters: double.infinity)),
          isFalse);
    });

    test('accepts a margin of 0 or more', () async {
      expect(await service.addGeofenceZone(zone: zone(polygonMarginMeters: 0)),
          isTrue);
      expect(
          await service.addGeofenceZone(
              zone: zone(id: 'b', polygonMarginMeters: 40)),
          isTrue);
    });

    test('accepts a valid zone', () async {
      expect(await service.addGeofenceZone(zone: zone()), isTrue);
      expect(fake.registeredZoneIds, {'z'});
    });

    test('rejects blank id, non-positive or non-finite radius', () async {
      expect(await service.addGeofenceZone(zone: zone(id: '  ')), isFalse);
      expect(await service.addGeofenceZone(zone: zone(radius: 0)), isFalse);
      expect(await service.addGeofenceZone(zone: zone(radius: -5)), isFalse);
      expect(await service.addGeofenceZone(zone: zone(radius: double.nan)),
          isFalse);
      expect(await service.addGeofenceZone(zone: zone(radius: double.infinity)),
          isFalse);
      expect(fake.registeredZoneIds, isEmpty);
    });

    test('rejects out-of-range coordinates', () async {
      expect(
        await service.addGeofenceZone(
            zone: zone(coordinates: [LatLng.degree(91, 0)])),
        isFalse,
      );
      expect(
        await service.addGeofenceZone(
            zone: zone(coordinates: [LatLng.degree(0, 181)])),
        isFalse,
      );
      expect(fake.registeredZoneIds, isEmpty);
    });
  });

  group('addGeofenceZones', () {
    test('registers every zone', () async {
      final ok = await service.addGeofenceZones(
        zones: [zone(id: 'a'), zone(id: 'b')],
      );

      expect(ok, isTrue);
      expect(fake.registeredZoneIds, {'a', 'b'});
    });

    test('is a successful no-op for an empty list', () async {
      expect(await service.addGeofenceZones(zones: const []), isTrue);
      expect(fake.registeredZoneIds, isEmpty);
    });

    test('registers nothing when one zone is invalid', () async {
      final ok = await service.addGeofenceZones(
        zones: [zone(id: 'a'), zone(id: 'b', radius: -1)],
      );

      expect(ok, isFalse);
      expect(fake.registeredZoneIds, isEmpty);
    });

    test('rejects duplicate ids', () async {
      final ok = await service.addGeofenceZones(
        zones: [zone(id: 'a'), zone(id: 'a')],
      );

      expect(ok, isFalse);
      expect(fake.registeredZoneIds, isEmpty);
    });
  });

  test('removeGeofenceZone rejects a blank id without calling the platform',
      () async {
    await service.addGeofenceZone(zone: zone());

    expect(await service.removeGeofenceZone(zoneId: ' '), isFalse);
    expect(fake.registeredZoneIds, {'z'});
  });
}
