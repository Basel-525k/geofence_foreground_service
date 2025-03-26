package com.f2fk.geofence_foreground_service

// Class which keeps the names of the plugin's available methods.
//
// This is to avoid writing literals when checking the method called.
class ApiMethods {
    companion object  {
        const val startGeofencingService: String = "startGeofencingService"
        const val stopGeofencingService: String = "stopGeofencingService"
        const val isForegroundServiceRunning: String = "isForegroundServiceRunning"
        const val addGeofence: String = "addGeofence"
        const val addGeoFences: String = "addGeoFences"
        const val removeGeofence: String = "removeGeofence"
    }
}