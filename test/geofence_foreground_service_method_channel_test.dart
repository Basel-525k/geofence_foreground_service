import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/constants/json_keys.dart';
import 'package:geofence_foreground_service/constants/location_update_mode.dart';
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

  final foregroundCalls = <MethodCall>[];
  String? lastBackgroundMethodCall;

  setUp(() {
    foregroundCalls.clear();
    lastBackgroundMethodCall = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      foregroundChannel,
      (MethodCall methodCall) async {
        foregroundCalls.add(methodCall);
        switch (methodCall.method) {
          case 'startGeofencingService':
            return true;
          case 'stopGeofencingService':
            return true;
          case 'addGeofence':
            return true;
          case 'addGeoFences':
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
        lastBackgroundMethodCall = methodCall.method;
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

  test('startGeofencingService sends the location update mode', () async {
    await platform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: callbackDispatcher,
      locationUpdateMode: LocationUpdateMode.off,
    );
    final call = foregroundCalls
        .lastWhere((c) => c.method == 'startGeofencingService');
    expect((call.arguments as Map)['location_update_mode'], 'off');
  });

  test('startGeofencingService defaults to high accuracy', () async {
    await platform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: callbackDispatcher,
    );
    final call = foregroundCalls
        .lastWhere((c) => c.method == 'startGeofencingService');
    expect((call.arguments as Map)['location_update_mode'], 'highAccuracy');
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
    final startCall =
        foregroundCalls.lastWhere((c) => c.method == 'startGeofencingService');
    final args = startCall.arguments as Map<dynamic, dynamic>;
    expect(args[JsonKeys.channelId], 'test_channel');
    expect(args[JsonKeys.serviceId], 525600);
  });

  test('addGeofence forwards zone JSON shape', () async {
    final zone = Zone(
      id: 'z1',
      radius: 42,
      coordinates: [LatLng.degree(3.0, 4.0)],
    );
    await platform.addGeofence(zone: zone);
    final addCall = foregroundCalls.lastWhere((c) => c.method == 'addGeofence');
    expect(addCall.arguments, zone.toJson());
  });

  test('handleTrigger invokes backgroundChannelInitialized', () async {
    platform.handleTrigger(
      backgroundTriggerHandler: (zoneId, triggerType) async {
        expect(zoneId, 'zone-a');
        expect(triggerType, GeofenceEventType.enter);
        return true;
      },
    );
    expect(lastBackgroundMethodCall, 'backgroundChannelInitialized');

    final codec = const StandardMethodCodec();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      backgroundChannel.name,
      codec.encodeMethodCall(
        MethodCall(
          'ignored',
          <String, dynamic>{
            'ps.byshy.geofence.ZONE_ID': 'zone-a',
            'ps.byshy.geofence.INPUT_DATA':
                jsonEncode(GeofenceEventType.enter.value),
          },
        ),
      ),
      (data) {},
    );
  });

  test('addGeoFences sends every zone under the zones key', () async {
    final ok = await platform.addGeoFences(zones: [
      Zone(id: 'a', radius: 10, coordinates: [LatLng.degree(1, 2)]),
      Zone(id: 'b', radius: 20, coordinates: [LatLng.degree(3, 4)]),
    ]);

    expect(ok, isTrue);
    final call = foregroundCalls.single;
    expect(call.method, 'addGeoFences');
    final zones = (call.arguments as Map)[JsonKeys.zones] as List;
    expect(zones.map((z) => (z as Map)[JsonKeys.id]), ['a', 'b']);
  });

  test('a platform error resolves to false instead of throwing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(foregroundChannel, (call) async {
      throw PlatformException(code: 'permission_denied');
    });

    expect(
      await platform.addGeofence(
        zone: Zone(id: 'a', radius: 10, coordinates: [LatLng.degree(1, 2)]),
      ),
      isFalse,
    );
    expect(await platform.removeAllGeoFences(), isFalse);
    expect(await platform.stopGeofencingService(), isFalse);
  });

  test('startGeofencingService returns false for a non top-level callback',
      () async {
    final ok = await platform.startGeofencingService(
      notificationChannelId: 'c',
      contentTitle: 't',
      contentText: 'x',
      // A closure cannot be turned into a Flutter entry point handle.
      callbackDispatcher: () {},
    );

    expect(ok, isFalse);
    expect(foregroundCalls, isEmpty);
  });

  test('handleTrigger ignores malformed background calls', () async {
    var handlerCalls = 0;
    platform.handleTrigger(
      backgroundTriggerHandler: (zoneId, triggerType) async {
        handlerCalls++;
        return true;
      },
    );

    const codec = StandardMethodCodec();
    for (final arguments in <Object?>[
      null,
      'not a map',
      <String, dynamic>{'ps.byshy.geofence.ZONE_ID': 1},
      <String, dynamic>{'ps.byshy.geofence.ZONE_ID': 'z'},
    ]) {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        backgroundChannel.name,
        codec.encodeMethodCall(MethodCall('onResultSend', arguments)),
        (data) {},
      );
    }

    expect(handlerCalls, 0);
  });
}
