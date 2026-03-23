import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';

void main() {
  group('GeofenceEventType.findById', () {
    test('maps known ids', () {
      expect(GeofenceEventType.findById(1), GeofenceEventType.enter);
      expect(GeofenceEventType.findById(2), GeofenceEventType.exit);
      expect(GeofenceEventType.findById(4), GeofenceEventType.dwell);
    });

    test('null and unknown map to unKnown', () {
      expect(GeofenceEventType.findById(null), GeofenceEventType.unKnown);
      expect(GeofenceEventType.findById(999), GeofenceEventType.unKnown);
    });
  });

  group('extensions', () {
    test('int toGeofenceEventType', () {
      expect(1.toGeofenceEventType(), GeofenceEventType.enter);
    });

    test('string toGeofenceEventType', () {
      expect('enter'.toGeofenceEventType(), GeofenceEventType.enter);
      expect('unknown'.toGeofenceEventType(), GeofenceEventType.unKnown);
    });

    test('flags on enum', () {
      expect(GeofenceEventType.enter.isEnter, true);
      expect(GeofenceEventType.exit.isExit, true);
      expect(GeofenceEventType.dwell.isDwell, true);
      expect(GeofenceEventType.unKnown.isUnKnown, true);
    });
  });
}
