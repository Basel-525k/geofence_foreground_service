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
