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
  /// Android supports enter, exit and dwell. iOS supports enter and exit only;
  /// dwell is ignored there, and a list with only dwell is rejected.
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
  /// Supported on Android and iOS. On iOS only [GeofenceEventType.enter] and
  /// [GeofenceEventType.exit] are meaningful.
  ///
  /// To also learn that the device is *outside* the zone when it is added, use
  /// [initialTriggers] with both [GeofenceEventType.enter] and
  /// [GeofenceEventType.exit]. When [initialTriggers] is set, it takes
  /// precedence and this getter returns its first element.
  GeofenceEventType get initialTrigger => initialTriggers.first;

  /// The set of initial triggers for the geofence zone.
  ///
  /// Each entry that matches the device's state at the moment of adding the
  /// zone is reported: [GeofenceEventType.enter] fires if the device is already
  /// inside, [GeofenceEventType.exit] fires if it is already outside.
  /// Passing both therefore always yields exactly one event, which lets an app
  /// seed an inside/outside state without computing geometry itself.
  ///
  /// Defaults to `[initialTrigger]` as given to the constructor, which defaults
  /// to [GeofenceEventType.enter].
  final List<GeofenceEventType> initialTriggers;

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
    GeofenceEventType initialTrigger = GeofenceEventType.enter,
    List<GeofenceEventType>? initialTriggers,
  }) : initialTriggers = List.unmodifiable(
          initialTriggers == null || initialTriggers.isEmpty
              ? [initialTrigger]
              : initialTriggers,
        );

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json[JsonKeys.id] as String,
        radius: (json[JsonKeys.radius] as num).toDouble(),
        coordinates: _coordinatesFromJson(json[JsonKeys.coordinates]),
        notificationResponsivenessMs:
            (json[JsonKeys.notificationResponsivenessMs] as num?)?.toInt(),
        triggers: _triggersFromJson(json[JsonKeys.fenceTriggers]),
        expirationDuration: json[JsonKeys.fenceExpirationDuration] != null
            ? Duration(
                milliseconds:
                    (json[JsonKeys.fenceExpirationDuration] as num).toInt())
            : null,
        dwellLoiteringDelay: json[JsonKeys.dwellLoiteringDelay] != null
            ? Duration(
                milliseconds:
                    (json[JsonKeys.dwellLoiteringDelay] as num).toInt())
            : null,
        initialTriggers: _initialTriggersFromBitmask(
            (json[JsonKeys.initialTrigger] as num?)?.toInt()),
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
        // A bitmask in the same key the single value used, so a native side
        // that only understands one trigger keeps working.
        JsonKeys.initialTrigger: _initialTriggerMask(initialTriggers),
      };
}

List<LatLng> _coordinatesFromJson(List<dynamic>? coordinatesJsonList) =>
    List.generate(
      coordinatesJsonList?.length ?? 0,
      (index) {
        // Platform channels and JSON decoding yield `Map<dynamic, dynamic>` (or
        // `Map<String, dynamic>`), never `Map<String, double>`, and may carry
        // ints for whole-number coordinates.
        final coordinates = coordinatesJsonList![index] as Map;
        return LatLng.degree(
          (coordinates[JsonKeys.latitude] as num).toDouble(),
          (coordinates[JsonKeys.longitude] as num).toDouble(),
        );
      },
    );

List<GeofenceEventType> _triggersFromJson(List<dynamic>? triggersJsonList) =>
    List.generate(
      triggersJsonList?.length ?? 0,
      (index) => GeofenceEventType.findById(
          (triggersJsonList![index] as num?)?.toInt()),
    );

/// Decodes the `fence_initial_trigger` bitmask (1 = enter, 2 = exit, 4 = dwell).
List<GeofenceEventType>? _initialTriggersFromBitmask(int? mask) {
  if (mask == null) return null;
  final triggers = [
    GeofenceEventType.enter,
    GeofenceEventType.exit,
    GeofenceEventType.dwell,
  ].where((t) => mask & t.value != 0).toList();
  return triggers.isEmpty ? [GeofenceEventType.unKnown] : triggers;
}

int _initialTriggerMask(List<GeofenceEventType> triggers) {
  final mask = triggers
      .where((t) => t.value > 0)
      .fold<int>(0, (mask, t) => mask | t.value);
  return mask == 0 ? triggers.first.value : mask;
}
