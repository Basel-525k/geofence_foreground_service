import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'geofence_foreground_service_method_channel.dart';
import 'models/background_task_handlers.dart';
import 'models/notification_icon_data.dart';
import 'models/zone.dart';

abstract class GeofenceForegroundServicePlatform extends PlatformInterface {
  /// Constructs a GeofenceForegroundServicePlatform.
  GeofenceForegroundServicePlatform() : super(token: _token);

  static final Object _token = Object();

  static GeofenceForegroundServicePlatform _instance =
      MethodChannelGeofenceForegroundService();

  /// The default instance of [GeofenceForegroundServicePlatform] to use.
  ///
  /// Defaults to [MethodChannelGeofenceForegroundService].
  static GeofenceForegroundServicePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GeofenceForegroundServicePlatform] when
  /// they register themselves.
  static set instance(GeofenceForegroundServicePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required Function callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
  }) {
    throw UnimplementedError(
        'startGeofencingService() has not been implemented.');
  }

  void handleTrigger({
    required BackgroundTriggerHandler backgroundTriggerHandler,
  }) {
    throw UnimplementedError('handleTrigger() has not been implemented.');
  }

  Future<bool> stopGeofencingService() {
    throw UnimplementedError(
        'stopGeofencingService() has not been implemented.');
  }

  Future<bool> isForegroundServiceRunning() {
    throw UnimplementedError(
        'isForegroundServiceRunning() has not been implemented.');
  }

  Future<bool> addGeofence({
    required Zone zone,
  }) {
    throw UnimplementedError('addGeofence() has not been implemented.');
  }

  Future<bool> removeGeofence({
    required String zoneId,
  }) {
    throw UnimplementedError('removeGeofence() has not been implemented.');
  }

  Future<bool> removeAllGeoFences() {
    throw UnimplementedError('removeAllGeoFences() has not been implemented.');
  }
}
