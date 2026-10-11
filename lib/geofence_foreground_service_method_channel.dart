import 'dart:developer';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/models/zone.dart';

import 'constants/api_methods.dart';
import 'constants/json_keys.dart';
import 'geofence_foreground_service_platform_interface.dart';
import 'models/background_task_handlers.dart';
import 'models/notification_icon_data.dart';

/// An implementation of [GeofenceForegroundServicePlatform] that uses method channels.
class MethodChannelGeofenceForegroundService
    extends GeofenceForegroundServicePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final foregroundChannel = const MethodChannel(
      'ps.byshy.geofence/foreground_geofence_foreground_service');

  @visibleForTesting
  final backgroundChannel = const MethodChannel(
      "ps.byshy.geofence/background_geofence_foreground_service");

  static const String _zoneIdKey = 'ps.byshy.geofence.ZONE_ID';
  static const String _inputDataKey = 'ps.byshy.geofence.INPUT_DATA';

  Future<T?> _invokeMethod<T>(String method, [dynamic arguments]) =>
      foregroundChannel.invokeMethod(method, arguments);

  /// Invokes [method] and maps a null result or a platform error to `false`,
  /// logging the failure under [logName].
  Future<bool> _invokeBool(String method, String logName,
      [dynamic arguments]) async {
    try {
      return await _invokeMethod<bool>(method, arguments) ?? false;
    } catch (e) {
      log(e.toString(), name: logName);
      return false;
    }
  }

  /// This method is used to start the geofencing foreground service
  @override
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required void Function() callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
  }) async {
    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);

    if (callback == null) {
      // An `assert` would vanish in release builds and leave a confusing native failure.
      log(
        'The callbackDispatcher must be a top-level or static function so it '
        'can be used as a Flutter entry point.',
        name: 'startGeofencingService_failure',
      );
      return false;
    }

    final Map<String, dynamic> data = {
      JsonKeys.channelId: notificationChannelId,
      JsonKeys.contentTitle: contentTitle,
      JsonKeys.contentText: contentText,
      JsonKeys.serviceId: serviceId,
      JsonKeys.callbackHandle: callback.toRawHandle(),
      JsonKeys.isInDebugMode: isInDebugMode,
    };

    if (notificationIconData != null) {
      data[JsonKeys.iconData] = notificationIconData.toJson();
    }

    return _invokeBool(
      ApiMethods.startGeofencingService,
      'startGeofencingService_failure',
      data,
    );
  }

  @override
  void handleTrigger({
    required BackgroundTriggerHandler backgroundTriggerHandler,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    backgroundChannel.setMethodCallHandler((call) async {
      final arguments = call.arguments;
      if (arguments is! Map) {
        log('Ignoring ${call.method} without arguments', name: 'handleTrigger');
        return false;
      }

      final zoneId = arguments[_zoneIdKey];
      final inputData = arguments[_inputDataKey];
      if (zoneId is! String || inputData is! String) {
        log('Ignoring ${call.method} with malformed arguments',
            name: 'handleTrigger');
        return false;
      }

      return backgroundTriggerHandler(
        zoneId,
        GeofenceEventType.findById(int.tryParse(inputData)),
      );
    });

    backgroundChannel.invokeMethod('backgroundChannelInitialized');
  }

  /// This method is used to stop the geofencing foreground service
  @override
  Future<bool> stopGeofencingService() => _invokeBool(
        ApiMethods.stopGeofencingService,
        'stopGeofencingService_failure',
      );

  /// This method is used to check if the geofencing foreground service is running
  @override
  Future<bool> isForegroundServiceRunning() => _invokeBool(
        ApiMethods.isForegroundServiceRunning,
        'isForegroundServiceRunning_failure',
      );

  /// This method is used to add a geofence area
  @override
  Future<bool> addGeofence({required Zone zone}) => _invokeBool(
        ApiMethods.addGeofence,
        'addGeofence_failure',
        zone.toJson(),
      );

  /// This method is used to add several geofence areas in one call
  @override
  Future<bool> addGeoFences({required List<Zone> zones}) => _invokeBool(
        ApiMethods.addGeoFences,
        'addGeoFences_failure',
        {JsonKeys.zones: zones.map((zone) => zone.toJson()).toList()},
      );

  /// This method is used to remove a geofence area
  @override
  Future<bool> removeGeofence({required String zoneId}) => _invokeBool(
        ApiMethods.removeGeofence,
        'removeGeofence_failure',
        {JsonKeys.zoneId: zoneId},
      );

  /// This method is used to remove all geofence areas
  @override
  Future<bool> removeAllGeoFences() => _invokeBool(
        ApiMethods.removeAllGeoFences,
        'removeAllGeoFences_failure',
      );
}
