import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:latlng/latlng.dart';

import '../constants/json_keys.dart';

class Zone {
  /// A unique identifier for the geofence zone.
  final String id;

  /// The radius of the geofence zone in meters.
  final double radius;

  /// List of coordinates of the geofence zone.
  final List<LatLng> coordinates;

  /// The millisecond delay between entering the zone and receiving the
  /// notification.
  ///
  /// Only supported on Android. Ignored on iOS.
  ///
  /// Defaults to 0. Setting a big responsiveness value, for example 5 minutes,
  /// can save power significantly. However, setting a very small responsiveness
  /// value, for example 5 seconds, doesn't necessarily mean you will get
  /// notified right after the user enters or exits a geofence: internally, the
  /// geofence might adjust the responsiveness value to save power when needed.
  final int? notificationResponsivenessMs;

  /// The list of triggers that will be used to monitor the geofence zone.
  ///
  /// The default value contains all available triggers. Which are: enter, exit, and dwell.
  ///
  /// The current implementation for this field is only supported on Android devices.
  ///
  /// There is no ETA for iOS support.
  final List<GeofenceEventType> triggers;

  /// The duration after which the geofence will expire.
  ///
  /// If the value is not provided the geofence will have no expiration duration.
  ///
  /// The current implementation for this field is only supported on Android devices.
  final Duration? expirationDuration;

  /// The time it will take to trigger the dwell event after the user enters the geofence zone.
  ///
  /// If not provided, it means that the event should be triggered immediately.
  ///
  /// The current implementation for this field is only supported on Android devices.
  final Duration? dwellLoiteringDelay;

  /// The initial trigger for the geofence zone.
  ///
  /// If, at the moment of adding the geofence, the initial trigger matches one of the triggers,
  /// the event will be triggered.
  ///
  /// For example: if the initial trigger is set to [GeofenceEventType.enter] and the user is
  /// inside the geofence zone when the zone is added, the [GeofenceEventType.enter] event will
  /// be triggered.
  ///
  /// The default value is [GeofenceEventType.enter].
  ///
  /// The current implementation for this field is only supported on Android devices.
  final GeofenceEventType initialTrigger;

  Zone({
    required this.id,
    required this.radius,
    required this.coordinates,
    this.notificationResponsivenessMs,
    this.triggers = const [
      GeofenceEventType.enter,
      GeofenceEventType.exit,
      GeofenceEventType.dwell,
    ],
    this.expirationDuration,
    this.dwellLoiteringDelay,
    this.initialTrigger = GeofenceEventType.enter,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json[JsonKeys.id] as String,
        radius: json[JsonKeys.radius] as double,
        coordinates: _coordinatesFromJson(json[JsonKeys.coordinates]),
        notificationResponsivenessMs:
            json[JsonKeys.notificationResponsivenessMs],
        triggers: _triggersFromJson(json[JsonKeys.fenceTriggers]),
        expirationDuration: json[JsonKeys.fenceExpirationDuration] != null
            ? Duration(
                milliseconds: json[JsonKeys.fenceExpirationDuration] as int)
            : null,
        dwellLoiteringDelay: json[JsonKeys.dwellLoiteringDelay] != null
            ? Duration(milliseconds: json[JsonKeys.dwellLoiteringDelay] as int)
            : null,
        initialTrigger:
            GeofenceEventType.findById(json[JsonKeys.initialTrigger] as int?),
      );

  Map<String, dynamic> toJson() => {
        JsonKeys.id: id,
        JsonKeys.radius: radius,
        JsonKeys.coordinates: coordinates
            .map((e) => {
                  JsonKeys.latitude: e.latitude.degrees,
                  JsonKeys.longitude: e.longitude.degrees,
                })
            .toList(),
        JsonKeys.notificationResponsivenessMs: notificationResponsivenessMs,
        JsonKeys.fenceTriggers: triggers.map((e) => e.value).toList(),
        JsonKeys.fenceExpirationDuration: expirationDuration?.inMilliseconds,
        JsonKeys.dwellLoiteringDelay: dwellLoiteringDelay?.inMilliseconds,
        JsonKeys.initialTrigger: initialTrigger.value,
      };
}

List<LatLng> _coordinatesFromJson(List<dynamic>? coordinatesJsonList) =>
    List.generate(
      coordinatesJsonList?.length ?? 0,
      (index) {
        final coordinates = coordinatesJsonList![index] as Map<String, double>;
        return LatLng.degree(
            coordinates[JsonKeys.latitude]!, coordinates[JsonKeys.longitude]!);
      },
    );

List<GeofenceEventType> _triggersFromJson(List<dynamic>? triggersJsonList) =>
    List.generate(
      triggersJsonList?.length ?? 0,
      (index) => GeofenceEventType.findById(triggersJsonList![index] as int?),
    );
