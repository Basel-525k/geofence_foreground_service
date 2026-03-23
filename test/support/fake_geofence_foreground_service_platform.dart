import 'package:geofence_foreground_service/geofence_foreground_service_platform_interface.dart';
import 'package:geofence_foreground_service/models/background_task_handlers.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stateful fake for [GeofenceForegroundService] tests (avoids sharing global
/// [MethodChannel] mocks across test files).
class FakeGeofenceForegroundServicePlatform
    with MockPlatformInterfaceMixin
    implements GeofenceForegroundServicePlatform {
  bool serviceRunning = false;
  final Set<String> registeredZoneIds = <String>{};

  BackgroundTriggerHandler? lastBackgroundTriggerHandler;

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
    if (notificationChannelId.trim().isEmpty ||
        contentTitle.trim().isEmpty ||
        contentText.trim().isEmpty) {
      return false;
    }
    serviceRunning = true;
    return true;
  }

  @override
  void handleTrigger({
    required BackgroundTriggerHandler backgroundTriggerHandler,
  }) {
    lastBackgroundTriggerHandler = backgroundTriggerHandler;
  }

  @override
  Future<bool> stopGeofencingService() async {
    if (!serviceRunning) {
      return false;
    }
    serviceRunning = false;
    registeredZoneIds.clear();
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async => serviceRunning;

  @override
  Future<bool> addGeofence({required Zone zone}) async {
    if (!serviceRunning) {
      return false;
    }
    if (zone.id.trim().isEmpty ||
        zone.radius <= 0 ||
        zone.coordinates.isEmpty) {
      return false;
    }
    registeredZoneIds.add(zone.id);
    return true;
  }

  @override
  Future<bool> removeGeofence({required String zoneId}) async {
    if (!registeredZoneIds.remove(zoneId)) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> removeAllGeoFences() async {
    registeredZoneIds.clear();
    return true;
  }
}
