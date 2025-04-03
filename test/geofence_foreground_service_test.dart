import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_platform_interface.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_method_channel.dart';
import 'package:geofence_foreground_service/models/background_task_handlers.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:geofence_foreground_service/exports.dart' show LatLng;

// Invalid implementation that doesn't use the correct token
class InvalidGeofenceForegroundServicePlatform extends PlatformInterface
    implements GeofenceForegroundServicePlatform {
  InvalidGeofenceForegroundServicePlatform() : super(token: Object());

  @override
  Future<bool> addGeofence({required Zone zone}) {
    throw UnimplementedError();
  }

  @override
  void handleTrigger(
      {required BackgroundTriggerHandler backgroundTriggerHandler}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isForegroundServiceRunning() {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeAllGeoFences() {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeGeofence({required String zoneId}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> startGeofencingService(
      {required String notificationChannelId,
      required String contentTitle,
      required String contentText,
      int? serviceId,
      required Function callbackDispatcher,
      bool isInDebugMode = false,
      NotificationIconData? notificationIconData}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> stopGeofencingService() {
    throw UnimplementedError();
  }
}

class MockGeofenceForegroundServicePlatform
    with MockPlatformInterfaceMixin
    implements GeofenceForegroundServicePlatform {
  @override
  Future<bool> addGeofence({
    required Zone zone,
  }) async {
    return true;
  }

  @override
  Future<bool> stopGeofencingService() async {
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async {
    return false;
  }

  @override
  Future<bool> removeAllGeoFences() async {
    return true;
  }

  @override
  Future<bool> removeGeofence({required String zoneId}) async {
    return true;
  }

  @override
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required Function callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
  }) async {
    return true;
  }

  @override
  void handleTrigger(
      {required BackgroundTriggerHandler backgroundTriggerHandler}) {
    // No-op in mock
  }
}

void main() {
  final GeofenceForegroundServicePlatform initialPlatform =
      GeofenceForegroundServicePlatform.instance;

  test('$MethodChannelGeofenceForegroundService is the default instance', () {
    expect(initialPlatform,
        isInstanceOf<MethodChannelGeofenceForegroundService>());
  });

  test('Cannot set instance to invalid type', () {
    expect(
      () {
        GeofenceForegroundServicePlatform.instance =
            InvalidGeofenceForegroundServicePlatform();
      },
      throwsA(isA<AssertionError>()),
    );
  });

  test('Platform interface methods', () async {
    MockGeofenceForegroundServicePlatform fakePlatform =
        MockGeofenceForegroundServicePlatform();
    GeofenceForegroundServicePlatform.instance = fakePlatform;

    // Test startGeofencingService
    final startResult = await fakePlatform.startGeofencingService(
      notificationChannelId: 'test_channel',
      contentTitle: 'Test Service',
      contentText: 'Running in background',
      callbackDispatcher: () {},
    );
    expect(startResult, true);

    // Test addGeofence
    final zone = Zone(
      id: 'test_zone',
      radius: 100,
      coordinates: [
        LatLng.degree(40.7128, -74.0060),
        LatLng.degree(40.7129, -74.0061),
      ],
    );
    final addResult = await fakePlatform.addGeofence(zone: zone);
    expect(addResult, true);

    // Test removeGeofence
    final removeResult = await fakePlatform.removeGeofence(zoneId: 'test_zone');
    expect(removeResult, true);

    // Test removeAllGeoFences
    final removeAllResult = await fakePlatform.removeAllGeoFences();
    expect(removeAllResult, true);

    // Test isForegroundServiceRunning
    final isRunningResult = await fakePlatform.isForegroundServiceRunning();
    expect(isRunningResult, false);

    // Test stopGeofencingService
    final stopResult = await fakePlatform.stopGeofencingService();
    expect(stopResult, true);

    // Test handleTrigger
    fakePlatform.handleTrigger(
      backgroundTriggerHandler: (zoneId, triggerType) async {
        return true;
      },
    );
  });
}
