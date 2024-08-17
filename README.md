# geofence_foreground_service

![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.3.0-blue.svg)
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-android-lightgrey.svg)
![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg)

A Flutter plugin that enables you to easily handle geofencing events in your Flutter app by utilizing native OS APIs on `Android` by creating a foreground service while being battery efficient since it uses the [Geofence](https://developer.android.com/training/location/geofencing) and [WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager) APIs. And on `iOS` by utilizing the [CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager)

It's important to note that the [workmanager](https://pub.dev/packages/workmanager)
and [flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task) plugins were a
great source of inspiration while creating this plugin.

Android|iOS
--|--
![Android Demo](https://github.com/Basel-525k/geofence_foreground_service/blob/main/assets/gifs/Geofencing_Android.gif)|![iOS Demo](https://github.com/Basel-525k/geofence_foreground_service/blob/main/assets/gifs/Geofencing_iOS.gif)

## Features

- **Supports geofencing in foreground as well as background** 💪
- **Geofence a circular area** 🗺️
- **Geofence a polygon** 🤯 You can add a geofence using a list of coordinates, the system will calculate the center of them and register it, having full polygon support is a WIP 🚧
- **Notification customization** 🔔: ⚠️**Android**⚠️ Displaying a notification when running a foreground service is mandatory, you can customize what is being displayed on it (title, content or the icon), the plugin displays your app icon by default.
- **Notification responsiveness** ⏱️: ⚠️**Android**⚠️ You can set the responsiveness of the android notifications as per the docs [here](https://developers.google.com/android/reference/com/google/android/gms/location/Geofence.Builder#public-geofence.builder-setnotificationresponsiveness-int-notificationresponsivenessms)

## Setup

### 🔧 Android Setup

- Enable MultiDex, you can check how to do
  so [here](https://docs.flutter.dev/deployment/android#enabling-multidex-support)
- Add the service to the AndroidManifest.xml inside the application tag

```xml
<service 
    android:name="com.f2fk.geofence_foreground_service.GeofenceForegroundService"
    android:foregroundServiceType="location">
</service>
```
- Add the permissions
```xml
<!--required-->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!--at least one of the follwoing-->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
- Make sure the `minSdkVersion` in the `app/build.gradle` file is 29+

### 🔧 iOS Setup

- Navigate to the Podfile and make sure to set the iOS version to 12+
```
platform :ios, '12.0'
```
- Make sure to add the following permission to your Info.plist
```
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app need your location to provide best feature based on location</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app need your location to provide best feature based on location</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app need your location to provide best feature based on location</string>
```
- Turn on the `Location updates` and `Background fetch` capabilities from XCode
  ![iOS capabilities](https://github.com/Basel-525k/geofence_foreground_service/blob/main/assets/images/ios_setup_steps.png?raw=true)

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

      if (triggerType == GeofenceEventType.enter) {
        log('enter', name: 'triggerType');
      } else if (triggerType == GeofenceEventType.exit) {
        log('exit', name: 'triggerType');
      } else if (triggerType == GeofenceEventType.dwell) {
        log('dwell', name: 'triggerType');
      } else {
        log('unknown', name: 'triggerType');
      }

      return Future.value(true);
    },
  );
}
```

Then create an instance of the plugin to initiate it and assign GeoFences to it

```dart
final List<LatLng> timesSquarePolygon = [
  const LatLng(40.758078, -73.985640),
  const LatLng(40.757983, -73.985417),
  const LatLng(40.757881, -73.985493),
  const LatLng(40.757956, -73.985688),
];

Future<void> initPlatformState() async {
  // Remember to handle permissions before initiating the plugin

  bool hasServiceStarted = await GeofenceForegroundService().startGeofencingService(
    contentTitle: 'Test app is running in the background',
    contentText: 'Test app will be running to ensure seamless integration with ops team',
    notificationChannelId: 'com.app.geofencing_notifications_channel',
    serviceId: 525600,
    callbackDispatcher: callbackDispatcher,
  );

  if (hasServiceStarted) {
    await GeofenceForegroundService().addGeofenceZone(
      zone: Zone(
        id: 'zone#1_id',
        radius: 10000, // measured in meters
        coordinates: timesSquarePolygon,
      ),
    );
  }
}
```

> Something important to point out is the callbackDispatcher method will run in an entirely
> different isolate than the actual app, so if you were to handle UI related code inside of it
> you'll
> need to use Ports, you can find more
> information
> [here](https://github.com/fluttercommunity/flutter_workmanager/issues/151#issuecomment-612637579)

You can pass a custom icon to the foreground service notification if you wish while initializing the
service, this icon will be placed inside the android/app/src/main/res folder, you can check the
example for more information, by default, it will take the app icon

```dart
const NotificationIconData(
  resType: ResourceType.mipmap,
  resPrefix: ResourcePrefix.ic,
  name: 'launcher',
)
```

## Notes

Handling permissions is not a part of the package, so please refer
to [permission_handler](https://pub.dev/packages/permission_handler) plugin to grant the required
permissions (it's used in the example too)

- location
- locationAlways
- notification

## Contributing Guidelines

We welcome contributions from the community. If you'd like to contribute to the development of this
plugin, please feel free to submit a PR to our GitHub repository._