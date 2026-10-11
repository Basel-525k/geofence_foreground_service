/// How the Android foreground service requests location updates while it runs.
///
/// Geofence transitions are delivered by Google Play services regardless of
/// this setting; this only controls the extra location request the service
/// keeps open, which is the main source of its battery cost.
///
/// On iOS [off] skips `startUpdatingLocation`; region monitoring still works.
enum LocationUpdateMode {
  /// High accuracy, every 20 seconds. This is the behavior of versions up to
  /// 1.2.x and the default.
  highAccuracy,

  /// Balanced power and accuracy, every 60 seconds.
  balanced,

  /// No location request at all. Only geofence transitions wake the app.
  off;

  /// The name sent over the platform channel.
  String get wireName => name;

  static LocationUpdateMode fromWireName(String? name) =>
      LocationUpdateMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => LocationUpdateMode.highAccuracy,
      );
}
