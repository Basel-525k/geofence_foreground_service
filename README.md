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
![Android Demo](https://raw.githubusercontent.com/Basel-525k/geofence_foreground_service/main/assets/gifs/Geofencing_Android.gif)|![iOS Demo](https://raw.githubusercontent.com/Basel-525k/geofence_foreground_service/main/assets/gifs/Geofencing_iOS.gif)

## Features

- **Supports geofencing in foreground as well as background** 💪
- **Geofence a circular area** 🗺️
- **Geofence a polygon** 🤯 You can add a geofence using a list of coordinates, the plugin calculates their center and registers a **circle** of `radius` around it on both platforms. The device never evaluates the polygon's real outline, so near its edge the result can differ from a true point-in-polygon check done on a server (see [Behaviour worth knowing](#behaviour-worth-knowing))
- **Survives restarts** 🔁: ⚠️**Android**⚠️ Zones are persisted and re-registered after a device reboot or an app update, because Google Play services drops geofences in both cases
- **Notification customization** 🔔: ⚠️**Android**⚠️ Displaying a notification when running a foreground service is mandatory, you can customize what is being displayed on it (title, content or the icon), the plugin displays your app icon by default.
- **Notification responsiveness** ⏱️: ⚠️**Android**⚠️ You can set the responsiveness of the android notifications as per the docs [here](https://developers.google.com/android/reference/com/google/android/gms/location/Geofence.Builder#public-geofence.builder-setnotificationresponsiveness-int-notificationresponsivenessms)

## Setup

### 🔧 Android Setup

- Enable MultiDex, you can check how to do
  so [here](https://docs.flutter.dev/deployment/android#enabling-multidex-support)
- The plugin's manifest already declares the service, the boot receiver and the permissions
  (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `ACCESS_FINE_LOCATION`,
  `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `POST_NOTIFICATIONS`,
  `RECEIVE_BOOT_COMPLETED`), so there is nothing to add to your `AndroidManifest.xml`. You still
  have to **request** the location, background location and notification permissions at runtime.
  If you want to customise the service declaration, declaring it in your own manifest overrides
  the plugin's.
- Make sure the `minSdkVersion` in the `app/build.gradle` file is 29+
- Your app needs `compileSdk` 34 or newer.

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
  ![iOS capabilities](https://raw.githubusercontent.com/Basel-525k/geofence_foreground_service/main/assets/images/ios_setup_steps.png)

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
        triggers: [
          GeofenceEventType.dwell,
          GeofenceEventType.enter,
          GeofenceEventType.exit
        ], // Currently, only available on Android
        expirationDuration: const Duration(days: 1), // Currently, only available on Android
        dwellLoiteringDelay: const Duration(hours: 1), // Currently, only available on Android
        // Report the state the device is already in when the zone is added:
        // `enter` if it is inside, `exit` if it is outside.
        initialTriggers: [GeofenceEventType.enter, GeofenceEventType.exit],
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

## Knowing the starting state

By default only `initialTrigger: GeofenceEventType.enter` is reported, so a device that starts
*outside* a zone gets no event until it crosses the boundary. Pass both triggers to learn which
side it is on right away:

```dart
Zone(
  id: 'site',
  radius: 150,
  coordinates: [site],
  initialTriggers: [GeofenceEventType.enter, GeofenceEventType.exit],
)
```

Exactly one event arrives per zone: `enter` if the device is inside, `exit` if it is outside.
It is delivered through the same `handleTrigger` callback as any other transition. `initialTrigger`
(single value) keeps working and is equivalent to a one element `initialTriggers`.

## Reducing battery use (Android)

While the foreground service runs it keeps one location request open. Geofence transitions are
delivered by Google Play services regardless of it, so you can lower it:

```dart
await GeofenceForegroundService().startGeofencingService(
  // ...
  locationUpdateMode: LocationUpdateMode.balanced, // or .off
);
```

| Mode | Android | iOS |
|------|---------|-----|
| `highAccuracy` (default) | high accuracy, every 20 s | best accuracy updates |
| `balanced` | balanced power, every 60 s | 100 m accuracy and distance filter |
| `off` | no location request | no continuous updates; region monitoring only |

`balanced` and `off` were exercised on an emulator and still delivered transitions, but
transition *latency* was not measured, so check it against your own requirements before shipping
`off`.

## Adding several zones at once

```dart
final ok = await GeofenceForegroundService().addGeofenceZones(zones: [zoneA, zoneB]);
```

Every zone is validated first, so an invalid zone (or a duplicate id) means nothing is registered.

## Platform differences

| Feature                                              | Android | iOS                     |
|------------------------------------------------------|---------|-------------------------|
| Enter / exit events                                  | ✅      | ✅                      |
| Dwell event (`dwellLoiteringDelay`)                  | ✅      | ❌ ignored              |
| `triggers`                                           | ✅      | enter and exit only     |
| `initialTrigger` / `initialTriggers`                 | ✅      | ✅ (enter / exit)       |
| `locationUpdateMode`                                 | ✅      | ✅                      |
| `expirationDuration`                                 | ✅      | ❌ ignored              |
| `notificationResponsivenessMs`                       | ✅      | ❌ ignored              |
| Foreground notification (title, text, icon)          | ✅      | n/a                     |
| Max monitored zones                                  | 100     | 20 (`REGION_LIMIT_REACHED`) |
| Re-registered after reboot / app update              | ✅      | handled by the OS       |

## Behaviour worth knowing

- A zone with several coordinates is monitored as a circle around the **center** of those
  coordinates, with `radius` as its radius (same on both platforms). The polygon's outline is
  not used by the device, so a server that does an exact point-in-polygon test can disagree with
  the device near the edge. Choose a `radius` that covers the polygon, or treat the device result
  as an approximation.
- On iOS, if Core Location cannot yet determine whether the device is inside a region when the
  zone is added (for example no location fix yet), no initial event is reported. Later `enter`
  and `exit` events still arrive.
- On **Android 12+** the system does not let a killed service restart itself from the background,
  so the foreground notification and location updates only come back with the next geofence
  transition or when the app is opened. Geofence registrations themselves are unaffected.
- The background location permission is required on Android. If it is revoked, the service stops
  and posts a "Permission Required" notification.
- Methods resolve to `false` (and log the reason with `dart:developer`) for invalid input
  instead of throwing.

## Notes

Handling permissions is not a part of the package, so please refer
to [permission_handler](https://pub.dev/packages/permission_handler) plugin to grant the required
permissions (it's used in the example too)

- location
- locationAlways
- notification

## Contributing

We welcome contributions. Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** for pull request expectations (including **small PRs** and a **maximum of 15 files** per PR), testing, changelog updates, and review practices.