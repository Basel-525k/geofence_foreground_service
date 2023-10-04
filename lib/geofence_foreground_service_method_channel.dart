import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/models/zone.dart';

import 'constants/json_keys.dart';
import 'geofence_foreground_service_platform_interface.dart';
import 'models/background_task_handlers.dart';

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

  /// This method is used to start the geofencing foreground service
  @override
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required Function callbackDispatcher,
    bool isInDebugMode = false,
  }) async {
    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);

    assert(
      callback != null,
      "The callbackDispatcher needs to be either a static function or a top level function to be accessible as a Flutter entry point.",
    );

    if (callback != null) {
      final int handle = callback.toRawHandle();

      final bool? didStart = await foregroundChannel.invokeMethod<bool>(
        'startGeofencingService',
        {
          JsonKeys.channelId: notificationChannelId,
          JsonKeys.contentTitle: contentTitle,
          JsonKeys.contentText: contentText,
          JsonKeys.serviceId: serviceId,
          JsonKeys.callbackHandle: handle,
          JsonKeys.isInDebugMode: isInDebugMode,
        },
      );
      return didStart ?? false;
    }

    return false;
  }

  @override
  void handleTrigger({
    required BackgroundTriggerHandler backgroundTriggerHandler,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    backgroundChannel.setMethodCallHandler((call) async {
      final inputData = call.arguments['ps.byshy.geofence.INPUT_DATA'];
      return backgroundTriggerHandler(
        call.arguments['ps.byshy.geofence.ZONE_ID'],
        inputData == null
            ? GeofenceEventType.unKnown
            : (jsonDecode(inputData) as int).toGeofenceEventType(),
      );
    });
    backgroundChannel.invokeMethod('backgroundChannelInitialized');
  }

  /// This method is used to stop the geofencing foreground service
  @override
  Future<bool> stopGeofencingService() async {
    final bool? didStop =
        await foregroundChannel.invokeMethod<bool>('stopGeofencingService');
    return didStop ?? false;
  }

  /// This method is used to check if the geofencing foreground service is running
  @override
  Future<bool> isForegroundServiceRunning() async {
    final bool? isServiceRunning = await foregroundChannel
        .invokeMethod<bool>('isForegroundServiceRunning');
    return isServiceRunning ?? false;
  }

  /// This method is used to add a geofence area
  @override
  Future<bool> addGeofence({
    required Zone zone,
  }) async {
    final bool? isGeofenceAdded = await foregroundChannel.invokeMethod<bool>(
      'addGeofence',
      zone.toJson(),
    );
    return isGeofenceAdded ?? false;
  }

  /// This method is used to remove a geofence area
  @override
  Future<bool> removeGeofence({
    required String zoneId,
  }) async {
    final bool? isGeofenceRemoved = await foregroundChannel.invokeMethod<bool>(
      'removeGeofence',
      {
        JsonKeys.zoneId: zoneId,
      },
    );
    return isGeofenceRemoved ?? false;
  }

  /// This method is used to remove all geofence areas
  @override
  Future<bool> removeAllGeoFences() async {
    final bool? areAllAreasRemoved =
        await foregroundChannel.invokeMethod<bool>('removeAllGeoFences');
    return areAllAreasRemoved ?? false;
  }
}
