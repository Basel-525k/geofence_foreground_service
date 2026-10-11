import 'dart:developer';

import 'geofence_foreground_service_platform_interface.dart';
import 'constants/location_update_mode.dart';
import 'models/background_task_handlers.dart';
import 'models/notification_icon_data.dart';
import 'models/zone.dart';

class GeofenceForegroundService {
  factory GeofenceForegroundService() => _instance;

  GeofenceForegroundService._internal();

  static final GeofenceForegroundService _instance =
      GeofenceForegroundService._internal();

  /// Starts the geofencing service
  /// This method initiates a geofencing service that monitors the provided geographic areas by [addGeofenceZone].
  /// Parameters:
  ///   - notificationChannelId (String, required): The ID of the notification channel for geofencing notifications.
  ///   - contentTitle (String, required): The title of geofencing-related notifications.
  ///   - contentText (String, required): The content text of geofencing-related notifications.
  ///   - serviceId (int, optional): An optional ID for the geofencing service.
  ///   - notificationIconData ([NotificationIconData], optional): An optional object for specifying the icon used in the mandatory geofencing service foreground notification.
  ///   - locationUpdateMode ([LocationUpdateMode], optional): how much location work the service does while running. Defaults to [LocationUpdateMode.highAccuracy]; use [LocationUpdateMode.balanced] or [LocationUpdateMode.off] to save battery.
  /// Returns:
  ///   A `Future<bool>` that resolves to true if the service was started successfully; otherwise, false.
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required void Function() callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
    LocationUpdateMode locationUpdateMode = LocationUpdateMode.highAccuracy,
  }) {
    if (notificationChannelId.trim().isEmpty ||
        contentTitle.trim().isEmpty ||
        contentText.trim().isEmpty) {
      log(
        'notificationChannelId, contentTitle and contentText must not be blank',
        name: 'startGeofencingService_invalid',
      );
      return Future<bool>.value(false);
    }
    return GeofenceForegroundServicePlatform.instance.startGeofencingService(
      notificationChannelId: notificationChannelId,
      contentTitle: contentTitle,
      contentText: contentText,
      serviceId: serviceId,
      callbackDispatcher: callbackDispatcher,
      isInDebugMode: isInDebugMode,
      notificationIconData: notificationIconData,
      locationUpdateMode: locationUpdateMode,
    );
  }

  void handleTrigger({
    required BackgroundTriggerHandler backgroundTriggerHandler,
  }) {
    GeofenceForegroundServicePlatform.instance.handleTrigger(
      backgroundTriggerHandler: backgroundTriggerHandler,
    );
  }

  /// Stops the geofencing service
  ///
  /// Parameters: None.
  /// Returns: A `Future<bool>` that resolves to true if the service was stopped successfully; otherwise, false.
  Future<bool> stopGeofencingService() {
    return GeofenceForegroundServicePlatform.instance.stopGeofencingService();
  }

  /// Checks if the geofencing service is running
  ///
  /// Parameters: None.
  /// Returns: A `Future<bool>` that resolves to true if the service is running; otherwise, false.
  Future<bool> isForegroundServiceRunning() {
    return GeofenceForegroundServicePlatform.instance
        .isForegroundServiceRunning();
  }

  /// Adds a geofence zone for monitoring
  /// This method adds a geofence zone to be monitored by the geofencing service.
  /// Each zone can have more than 1 coordinate, the plugin will calculate the center
  /// and assign a geofence for it
  /// Parameters:
  ///   - zone (Zone, required): The geofence zone configuration to add.
  /// Returns: A `Future<bool>` that resolves to true if the zone was added successfully; otherwise, false.
  Future<bool> addGeofenceZone({
    required Zone zone,
  }) {
    final problem = _validateZone(zone);
    if (problem != null) {
      log(problem, name: 'addGeofenceZone_invalid');
      return Future<bool>.value(false);
    }
    return GeofenceForegroundServicePlatform.instance.addGeofence(
      zone: zone,
    );
  }

  /// Adds several geofence zones in one call.
  ///
  /// Every zone is validated first; if any is invalid, or two zones share an
  /// id, nothing is registered and the future resolves to false. An empty list
  /// is a no-op that resolves to true.
  ///
  /// Parameters:
  ///   - zones (`List<Zone>`, required): The geofence zones to add.
  /// Returns: A `Future<bool>` that resolves to true if all zones were added successfully; otherwise, false.
  Future<bool> addGeofenceZones({
    required List<Zone> zones,
  }) {
    if (zones.isEmpty) {
      return Future<bool>.value(true);
    }

    final seenIds = <String>{};
    for (final zone in zones) {
      final problem = _validateZone(zone);
      if (problem != null) {
        log(problem, name: 'addGeofenceZones_invalid');
        return Future<bool>.value(false);
      }
      if (!seenIds.add(zone.id)) {
        log('Duplicate zone id "${zone.id}"', name: 'addGeofenceZones_invalid');
        return Future<bool>.value(false);
      }
    }

    return GeofenceForegroundServicePlatform.instance.addGeoFences(
      zones: zones,
    );
  }

  /// Removes a geofence zone
  ///
  /// Parameters:
  ///   - zoneId (String, required): The ID of the geofence zone to remove.
  /// Returns: A `Future<bool>` that resolves to true if the zone was removed successfully; otherwise, false.
  Future<bool> removeGeofenceZone({
    required String zoneId,
  }) {
    if (zoneId.trim().isEmpty) {
      log('zoneId must not be blank', name: 'removeGeofenceZone_invalid');
      return Future<bool>.value(false);
    }
    return GeofenceForegroundServicePlatform.instance.removeGeofence(
      zoneId: zoneId,
    );
  }

  /// Removes all geofence zones
  ///
  /// Parameters: None.
  /// Returns: A `Future<bool>` that resolves to true if all zones were removed successfully; otherwise, false.
  Future<bool> removeAllGeoFences() {
    return GeofenceForegroundServicePlatform.instance.removeAllGeoFences();
  }
}

/// Returns why [zone] cannot be monitored, or null when it is valid.
String? _validateZone(Zone zone) {
  if (zone.id.trim().isEmpty) {
    return 'Zone id must not be blank';
  }
  if (!zone.radius.isFinite || zone.radius <= 0) {
    return 'Zone "${zone.id}" radius must be a finite number greater than 0';
  }
  if (zone.coordinates.isEmpty) {
    return 'Zone "${zone.id}" must have at least one coordinate';
  }
  for (final coordinate in zone.coordinates) {
    final latitude = coordinate.latitude.degrees;
    final longitude = coordinate.longitude.degrees;
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      return 'Zone "${zone.id}" has a latitude outside -90..90: $latitude';
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      return 'Zone "${zone.id}" has a longitude outside -180..180: $longitude';
    }
  }
  return null;
}
