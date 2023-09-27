import 'geofence_foreground_service_platform_interface.dart';
import 'models/zone.dart';

class GeofenceForegroundService {
  Future<bool> startGeofencingService({
    required String notificationChannelId,
    required String contentTitle,
    required String contentText,
    int? serviceId,
  }) {
    return GeofenceForegroundServicePlatform.instance.startGeofencingService(
      notificationChannelId: notificationChannelId,
      contentTitle: contentTitle,
      contentText: contentText,
      serviceId: serviceId,
    );
  }

  Future<bool> stopGeofencingService() {
    return GeofenceForegroundServicePlatform.instance.stopGeofencingService();
  }

  Future<bool> isForegroundServiceRunning() {
    return GeofenceForegroundServicePlatform.instance.isForegroundServiceRunning();
  }

  Future<bool> addGeofenceZone({
    required Zone zone,
  }) {
    return GeofenceForegroundServicePlatform.instance.addGeofence(
      zone: zone,
    );
  }

  Future<bool> removeGeofenceZone({
    required String zoneId,
  }) {
    return GeofenceForegroundServicePlatform.instance.removeGeofence(
      zoneId: zoneId,
    );
  }

  Future<bool> removeAllGeoFences() {
    return GeofenceForegroundServicePlatform.instance.removeAllGeoFences();
  }
}
