import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/models/zone.dart';

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

  /// This method is used to start the geofencing foreground service
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
    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);

    assert(
      callback != null,
      "The callbackDispatcher needs to be either a static function or a top level function to be accessible as a Flutter entry point.",
    );

    if (callback != null) {
      final int handle = callback.toRawHandle();

      Map<String, dynamic> data = {
        JsonKeys.channelId: notificationChannelId,
        JsonKeys.contentTitle: contentTitle,
        JsonKeys.contentText: contentText,
        JsonKeys.serviceId: serviceId,
        JsonKeys.callbackHandle: handle,
        JsonKeys.isInDebugMode: isInDebugMode,
      };

      if (notificationIconData != null) {
        data[JsonKeys.iconData] = notificationIconData.toJson();
      }

      bool didStart = false;

      try {
        didStart = await foregroundChannel.invokeMethod<bool?>(
              'startGeofencingService',
              data,
            ) ??
            false;
      } catch (e) {
        log(
          e.toString(),
          name: 'startGeofencingService_failure',
        );
      }

      return didStart;
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
    bool didStop = false;

    try {
      didStop = await foregroundChannel
              .invokeMethod<bool?>('stopGeofencingService') ??
          false;
    } catch (e) {
      log(
        e.toString(),
        name: 'stopGeofencingService_failure',
      );
    }

    return didStop;
  }

  /// This method is used to check if the geofencing foreground service is running
  @override
  Future<bool> isForegroundServiceRunning() async {
    bool isServiceRunning = false;

    try {
      isServiceRunning = await foregroundChannel
              .invokeMethod<bool?>('isForegroundServiceRunning') ??
          false;
    } catch (e) {
      log(
        e.toString(),
        name: 'isForegroundServiceRunning_failure',
      );
    }

    return isServiceRunning;
  }

  /// This method is used to add a geofence area
  @override
  Future<bool> addGeofence({
    required Zone zone,
  }) async {
    bool isGeofenceAdded = false;

    try {
      isGeofenceAdded = await foregroundChannel.invokeMethod<bool?>(
            'addGeofence',
            zone.toJson(),
          ) ??
          false;
    } catch (e) {
      log(
        e.toString(),
        name: 'addGeofence_failure',
      );
    }

    return isGeofenceAdded;
  }

  /// This method is used to remove a geofence area
  @override
  Future<bool> removeGeofence({
    required String zoneId,
  }) async {
    bool isGeofenceRemoved = false;

    try {
      isGeofenceRemoved = await foregroundChannel.invokeMethod<bool?>(
            'removeGeofence',
            {
              JsonKeys.zoneId: zoneId,
            },
          ) ??
          false;
    } catch (e) {
      log(
        e.toString(),
        name: 'removeGeofence_failure',
      );
    }

    return isGeofenceRemoved;
  }

  /// This method is used to remove all geofence areas
  @override
  Future<bool> removeAllGeoFences() async {
    bool areAllAreasRemoved = false;

    try {
      areAllAreasRemoved =
          await foregroundChannel.invokeMethod<bool?>('removeAllGeoFences') ??
              false;
    } catch (e) {
      log(
        e.toString(),
        name: 'removeAllGeoFences_failure',
      );
    }

    return areAllAreasRemoved;
  }
}
