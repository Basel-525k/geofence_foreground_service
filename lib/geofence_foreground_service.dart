import 'geofence_foreground_service_platform_interface.dart';
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
  /// Returns:
  ///   A Future<bool> that resolves to true if the service was started successfully; otherwise, false.
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
    required Function callbackDispatcher,
    bool isInDebugMode = false,
    NotificationIconData? notificationIconData,
  }) {
    return GeofenceForegroundServicePlatform.instance.startGeofencingService(
      notificationChannelId: notificationChannelId,
      contentTitle: contentTitle,
      contentText: contentText,
      serviceId: serviceId,
      callbackDispatcher: callbackDispatcher,
      isInDebugMode: isInDebugMode,
      notificationIconData: notificationIconData,
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
  /// Returns: A Future<bool> that resolves to true if the service was stopped successfully; otherwise, false.
  Future<bool> stopGeofencingService() {
    return GeofenceForegroundServicePlatform.instance.stopGeofencingService();
  }

  /// Checks if the geofencing service is running
  ///
  /// Parameters: None.
  /// Returns: A Future<bool> that resolves to true if the service is running; otherwise, false.
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
  /// Returns: A Future<bool> that resolves to true if the zone was added successfully; otherwise, false.
  Future<bool> addGeofenceZone({
    required Zone zone,
  }) {
    return GeofenceForegroundServicePlatform.instance.addGeofence(
      zone: zone,
    );
  }

  /// Removes a geofence zone
  ///
  /// Parameters:
  ///   - zoneId (String, required): The ID of the geofence zone to remove.
  /// Returns: A Future<bool> that resolves to true if the zone was removed successfully; otherwise, false.
  Future<bool> removeGeofenceZone({
    required String zoneId,
  }) {
    return GeofenceForegroundServicePlatform.instance.removeGeofence(
      zoneId: zoneId,
    );
  }

  /// Removes all geofence zones
  ///
  /// Parameters: None.
  /// Returns: A Future<bool> that resolves to true if all zones were removed successfully; otherwise, false.
  Future<bool> removeAllGeoFences() {
    return GeofenceForegroundServicePlatform.instance.removeAllGeoFences();
  }
}
