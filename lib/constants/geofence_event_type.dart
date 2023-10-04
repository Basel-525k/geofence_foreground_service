enum GeofenceEventType {
  enter(1),
  exit(2),
  dwell(4),
  unKnown(-1);

  final int value;

  const GeofenceEventType(this.value);
}

extension GeofenceEventTypeX on int {
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
