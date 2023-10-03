# geofence_foreground_service

![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.3.0-blue.svg)
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-android-lightgrey.svg)

A Flutter plugin that enables you to easily handle geofencing events in your Flutter app by creating a foreground service.

## Features

- **Geofence a circular area** 🗺️: You can add an ordinary geofence which is a point surrounded by a given radius.
- **Geofence a polygon** 🤯: You can add a geofence using a list of coordinates, the system will calculate the center of them and register it, having full polygon support is a WIP 🚧
- **Notification customization** 🔔: Displaying a notification when running a foreground service is mandatory, we can customize what is being displayed on it (title and content), the plugin displays the app icon by default.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
geofence_foreground_service: ^1.0.0
```

## Setup

### 🔧 Android Setup

- Enable MultiDex, you can check how to do so [here](https://docs.flutter.dev/deployment/android#enabling-multidex-support)
- Add the service to the 

```xml
<service android:name="com.f2fk.geofence_foreground_service.GeofenceForegroundService" />
```

## Example

Define the method that will handle the Geofence triggers
```dart
import 'package:geofence_foreground_service/exports.dart';
import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/models/zone.dart';

// This method is a top level method
@pragma('vm:entry-point')
void callbackDispatcher() async {
  GeofenceForegroundService().handleTrigger(
    backgroundTriggerHandler: (zoneID, triggerType) {
      log(zoneID, name: 'zoneID');
      log('$triggerType', name: 'triggerType');

      return Future.value(true);
    },
  );
}
```

Then create an instance of the plugin to initiate it and assign GeoFences to it
```dart
final GeofenceForegroundService _geofenceForegroundServicePlugin = GeofenceForegroundService();

final List<LatLng> timesSquarePolygon = [
  const LatLng(40.758078, -73.985640),
  const LatLng(40.757983, -73.985417),
  const LatLng(40.757881, -73.985493),
  const LatLng(40.757956, -73.985688),
];

Future<void> initPlatformState() async {
  // Remember to handle permissions before initiating the plugin

  bool hasServiceStarted = await _geofenceForegroundServicePlugin.startGeofencingService(
    contentTitle: 'Test app is running in the background',
    contentText: 'Test app will be running to ensure seamless integration with ops team',
    notificationChannelId: 'com.app.geofencing_notifications_channel',
    serviceId: 525600,
    callbackDispatcher: callbackDispatcher,
  );

  if (hasServiceStarted) {
    await _geofenceForegroundServicePlugin.addGeofenceZone(
      zone: Zone(
        id: 'zone#1_id',
        radius: 10000,
        coordinates: timesSquarePolygon,
      ),
    );
  }
}
```

## Notes

Handling permissions is not a part of the package, so please refer to [permission_handler](https://pub.dev/packages/permission_handler) plugin to grat the required permissions (it's used in the example too)
- location
- locationAlways
- notification

## Contributing Guidelines
We welcome contributions from the community. If you'd like to contribute to the development of this plugin, please feel free to submit q PR to our GitHub repository.