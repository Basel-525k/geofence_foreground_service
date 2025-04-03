enum GeofenceEventType {
  enter(1),
  exit(2),
  dwell(4),
  unKnown(-1);

  final int value;

  const GeofenceEventType(this.value);

  /// Return a value based on the [id].
  ///
  /// If no value is found, or [id] is null, it will return [GeofenceEventType.unKnown].
  static GeofenceEventType findById([int? id]) =>
      GeofenceEventType.values.firstWhere(
        (element) => element.value == id,
        orElse: () => GeofenceEventType.unKnown,
      );
}

extension GeofenceEventTypeIntX on int {
  /// Convert an integer to a [GeofenceEventType].
  ///
  /// If the value doesn't match any [GeofenceEventType], it will
  /// return [GeofenceEventType.unKnown].
  ///
  /// This method is a shorthand for [GeofenceEventType.findById].
  GeofenceEventType toGeofenceEventType() => GeofenceEventType.findById(this);
}

extension GeofenceEventTypeX on GeofenceEventType {
  bool get isEnter => this == GeofenceEventType.enter;

  bool get isExit => this == GeofenceEventType.exit;

  bool get isDwell => this == GeofenceEventType.dwell;

  bool get isUnKnown => this == GeofenceEventType.unKnown;
}

extension GeofenceEventTypeStringX on String {
  GeofenceEventType toGeofenceEventType() {
    switch (this) {
      case 'enter':
        return GeofenceEventType.enter;
      case 'exit':
        return GeofenceEventType.exit;
      case 'dwell':
        return GeofenceEventType.dwell;
      default:
        return GeofenceEventType.unKnown;
    }
  }
}
