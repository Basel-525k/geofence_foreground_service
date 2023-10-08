import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_platform_interface.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_method_channel.dart';
import 'package:geofence_foreground_service/models/background_task_handlers.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeofenceForegroundServicePlatform
    with MockPlatformInterfaceMixin
    implements GeofenceForegroundServicePlatform {
  @override
  Future<bool> addGeofence({
    required Zone zone,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> stopGeofencingService() {
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
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required Function callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
  }) {
    throw UnimplementedError();
  }

  @override
  void handleTrigger(
      {required BackgroundTriggerHandler backgroundTriggerHandler}) {
    throw UnimplementedError();
  }
}

void main() {
  final GeofenceForegroundServicePlatform initialPlatform =
      GeofenceForegroundServicePlatform.instance;

  test('$MethodChannelGeofenceForegroundService is the default instance', () {
    expect(initialPlatform,
        isInstanceOf<MethodChannelGeofenceForegroundService>());
  });

  test('getPlatformVersion', () async {
    // GeofenceForegroundService geofenceForegroundServicePlugin = GeofenceForegroundService();
    MockGeofenceForegroundServicePlatform fakePlatform =
        MockGeofenceForegroundServicePlatform();
    GeofenceForegroundServicePlatform.instance = fakePlatform;
  });
}
