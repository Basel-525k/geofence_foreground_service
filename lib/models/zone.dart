import 'package:latlng/latlng.dart';

import '../constants/json_keys.dart';

class Zone {
  final String id;
  final double radius;
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

  Zone({
    required this.id,
    required this.radius,
    required this.coordinates,
    this.notificationResponsivenessMs,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    List<LatLng> jsonCoordinates = [];

    if (json[JsonKeys.coordinates] != null) {
      List coordinatesJsonList = json[JsonKeys.coordinates] as List;

      for (Map<String, double> coordinates in coordinatesJsonList) {
        jsonCoordinates.add(LatLng.degree(
          coordinates[JsonKeys.latitude]!,
          coordinates[JsonKeys.longitude]!,
        ));
      }
    }

    return Zone(
      id: json[JsonKeys.id],
      radius: json[JsonKeys.radius],
      coordinates: jsonCoordinates,
      notificationResponsivenessMs: json[JsonKeys.notificationResponsivenessMs],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      JsonKeys.id: id,
      JsonKeys.radius: radius,
      JsonKeys.coordinates: coordinates
          .map((e) => {
                JsonKeys.latitude: e.latitude.degrees,
                JsonKeys.longitude: e.longitude.degrees,
              })
          .toList(),
      JsonKeys.notificationResponsivenessMs: notificationResponsivenessMs,
    };
  }
}
