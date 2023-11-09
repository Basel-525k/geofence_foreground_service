enum GeofenceEventType {
  enter(1),
  exit(2),
  dwell(4),
  unKnown(-1);

  final int value;

  const GeofenceEventType(this.value);
}

extension GeofenceEventTypeIntX on int {
  GeofenceEventType toGeofenceEventType() {
    switch (this) {
      case 1:
        return GeofenceEventType.enter;
      case 2:
        return GeofenceEventType.exit;
      case 3:
        return GeofenceEventType.dwell;
      default:
        return GeofenceEventType.unKnown;
    }
  }
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
