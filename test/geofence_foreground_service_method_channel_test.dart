import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_method_channel.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:geofence_foreground_service/exports.dart' show LatLng;

// Top-level function for callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  // This is just a test callback
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGeofenceForegroundService platform =
      MethodChannelGeofenceForegroundService();
  const MethodChannel foregroundChannel =
      MethodChannel('ps.byshy.geofence/foreground_geofence_foreground_service');
  const MethodChannel backgroundChannel =
      MethodChannel('ps.byshy.geofence/background_geofence_foreground_service');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      foregroundChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startGeofencingService':
            return true;
          case 'stopGeofencingService':
            return true;
          case 'addGeofence':
            return true;
          case 'removeGeofence':
            return true;
          case 'removeAllGeoFences':
            return true;
          case 'isForegroundServiceRunning':
            return false;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      backgroundChannel,
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(foregroundChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, null);
  });

  test('startGeofencingService', () async {
    final result = await platform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: callbackDispatcher,
    );
    expect(result, true);
  });

  test('stopGeofencingService', () async {
    final result = await platform.stopGeofencingService();
    expect(result, true);
  });

  test('addGeofence', () async {
    final zone = Zone(
      id: 'test_zone',
      radius: 100,
      coordinates: [
        LatLng.degree(40.7128, -74.0060),
        LatLng.degree(40.7129, -74.0061),
      ],
    );
    final result = await platform.addGeofence(zone: zone);
    expect(result, true);
  });

  test('removeGeofence', () async {
    final result = await platform.removeGeofence(zoneId: 'test_zone');
    expect(result, true);
  });

  test('removeAllGeoFences', () async {
    final result = await platform.removeAllGeoFences();
    expect(result, true);
  });

  test('isForegroundServiceRunning', () async {
    final result = await platform.isForegroundServiceRunning();
    expect(result, false);
  });

  test('startGeofencingService with custom icon', () async {
    final result = await platform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: callbackDispatcher,
      notificationIconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    );
    expect(result, true);
  });

  test('startGeofencingService with service ID', () async {
    final result = await platform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: callbackDispatcher,
      serviceId: 525600,
    );
    expect(result, true);
  });
}
