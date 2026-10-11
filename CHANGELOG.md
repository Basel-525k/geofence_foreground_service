## 1.3.0
* Dart: `Zone.initialTriggers` accepts several initial triggers; `[enter, exit]` reports `exit` when the device starts outside the zone (Android: Play services bitmask, iOS: `requestState`). `initialTrigger` keeps working
* Dart: `startGeofencingService(locationUpdateMode: ...)` with `highAccuracy` (default, unchanged), `balanced` and `off` to reduce the battery cost of the service's location request
* Android: a custom `serviceId` is now honoured (it was always replaced by the default id)
* iOS: honour `locationUpdateMode`
* Docs: document that polygon zones are circles on the device and the iOS initial-state behaviour
* Platform interface: `startGeofencingService` gained the `locationUpdateMode` parameter, so third party implementations must add it
* Tests: bitmask round trips, location mode forwarding; verified on an Android 16 emulator (initial exit, both modes, a real reboot restoring zones, two overlapping zones, Dart handler timeout) and an iOS 26.5 simulator

## 1.2.0
* Android: fix a crash (`ForegroundServiceDidNotStartInTimeException`) when the service was started and then stopped early (missing permission, bad extras, invalid action); the service now always enters the foreground first
* Android: a geofence transition that cold-starts the service restores the foreground notification from the stored configuration
* Android: fix a crash on Android 12+ when the system restarted the service from the background (`ForegroundServiceStartNotAllowedException`); the service now stops cleanly
* Android: deliver an event for **every** geofence that fires in one transition instead of only the first
* Android: persist registered zones and re-register them after a reboot or an app update (new boot receiver); restart the service afterwards when it was running
* Android: stable per-zone `PendingIntent` request codes (no more `hashCode()` collisions)
* Android: `BackgroundWorker` fails fast when the Dart callback cannot be found and enforces a 3 minute timeout on the Dart handler
* Android: the plugin manifest now declares the service, the boot receiver and the required permissions; the host no longer has to
* Android: stop logging the user's coordinates; method-call payload errors come back as `PlatformException`s
* Android: raise `compileSdk` to 34 and update play-services-location, play-services-maps and WorkManager
* iOS: `addGeofence` no longer crashes or hangs on malformed arguments and always answers
* iOS: multi-coordinate zones are monitored around their center, matching Android
* iOS: honour `triggers` (enter/exit) and `initialTrigger`
* iOS: report the 20 region limit, unavailable monitoring and denied permission as errors; clamp the radius to the OS maximum
* iOS: ask for "Always" authorization when the service starts instead of at plugin registration
* iOS: fix the `notification_responsiveness_ms` key mismatch, implement `addGeoFences`, add missing `import UIKit` for Swift Package Manager builds
* Dart: new `addGeofenceZones` for batch registration
* Dart: validate coordinates (range and finiteness), radius and ids; log why a call was rejected
* Dart: `Zone.fromJson` accepts the loosely typed maps produced by platform channels
* Dart: `callbackDispatcher` is typed `void Function()`, and a non top-level callback now returns `false` instead of failing only in debug mode
* Dart: malformed background channel calls are ignored instead of throwing
* Tests: Android unit tests for zone persistence and number handling, an instrumented test for the background worker, expanded Dart tests for validation, batch registration and channel errors
* Example: update Gradle (8.14), Android Gradle Plugin (8.11.1) and Kotlin (2.2.20), raise the Gradle heap and stop pinning a beta NDK

## 1.1.7
* Dart API: add input validation to reject invalid `startGeofencingService` and `addGeofenceZone` calls before they reach platform channels
* Android: harden geofence center calculation/building with explicit non-empty coordinate preconditions
* Tests: replace outdated Android plugin test, add focused Android model/utility unit tests, and expand Dart method-channel/integration coverage (including fake-platform flows and event-type mapping)
* iOS/example: modernize example runner setup (deployment target 13, scene/engine registration updates, permission-handler flags) and improve permission logging/behavior in the Flutter example app
* Build/setup: update Android test dependencies/config, resolve Flutter SDK jar for compile-only imports, and clean example ignore/build artifacts

## 1.1.6
* Android: handle a missing or null start `Intent` by persisting extras, reusing saved data, or stopping the service when neither is available
* Android: fix crashes on Android 10+ with background location checks, `FOREGROUND_SERVICE_TYPE_LOCATION` for `startForeground`, and clean stop (service + notification) on STOP
* Android: monitor background location permission and stop the service when it is revoked; extend `GeofenceServiceAction` with STOP for service control
* Example app and docs: clearer permission handling across lifecycle (e.g. on resume) and README updates
* iOS: implement `removeAllGeoFences` on the method channel (stop monitoring for all regions)
* Android: implement `removeAllGeoFences` and use a single consistent geofence trigger `PendingIntent` so `removeGeofences` can clear every registration
* iOS: fix `removeGeofence` (match by zone id, stop the region, return a proper result); Android: per-zone `PendingIntent` request codes and SharedPreferences tracking of registered zone IDs
* Android: refactor geofence addition for asynchronous registration with clearer success/error handling; iOS: fix `removeAllGeoFences` result callback semantics
* Persist debug mode via `SharedPreferenceHelper` (service and plugin) instead of relying only on intent extras
* Align iOS CocoaPods `podspec` version with the Dart package
* iOS: add Swift Package Manager support (`ios/geofence_foreground_service/Package.swift`); native sources live under `Sources/geofence_foreground_service/`

## 1.1.5
* Remove Shim package from Android to support newer Flutter versions

## 1.1.4
* Added new fields to Zone class
* Updated the list of constants for the new zone fields
* Methods called on both Kotlin and Dart sides will be identified by String constants
* Added GeofenceEventType.findById static function
* Updated GeofenceEventTypeIntX.toGeofenceEventType to use GeofenceEventType.findById
* Updated GeofenceForegroundService.subscribeToLocationUpdates to include permissions checking
* Refactored GeofenceForegroundServicePlugin

## 1.1.3

* Handle error responses

## 1.1.2

* Handle error responses

## 1.1.1

* Add Android setNotificationResponsiveness support

## 1.1.0

* Add iOS support

## 1.0.9

* Pass static analysis

## 1.0.8

* Support android 14 new permissions
* Add the service type to the code

## 1.0.7

* Pass notification icon from flutter side
* Add more useful extensions

## 1.0.6

* Make the GeofenceForegroundService a singleton class

## 1.0.5

* Create GeofenceEventType enum to make handling events easier to understand

## 1.0.3

* README.md enhancements

## 1.0.1

* Add the ability to control the debug mode (enable/disable)
* Add the ability remove a geofence

## 1.0.0

* The API provides the following functionality
  * Initialize the service with their own channel id, title, text and service id
  * Add GeoFences with each having a list of coordinates
