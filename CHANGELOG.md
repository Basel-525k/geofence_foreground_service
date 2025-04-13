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
