import 'package:latlng/latlng.dart';

import '../constants/json_keys.dart';

class Zone {
  final String id;
  final double radius;
  final List<LatLng> coordinates;

  Zone({
    required this.id,
    required this.radius,
    required this.coordinates,
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
    };
  }
}
