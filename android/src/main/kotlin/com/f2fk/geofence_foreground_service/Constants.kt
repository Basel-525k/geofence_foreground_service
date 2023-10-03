package com.f2fk.geofence_foreground_service

class Constants {
    companion object {
        const val zones: String = "zones"
        const val zoneId: String = "zone_id"
        const val id: String = "id"
        const val radius: String = "radius"
        const val coordinates: String = "coordinates"
        const val latitude: String = "latitude"
        const val longitude: String = "longitude"

        const val geofenceAction: String = "geofence_action"

        const val appIcon: String = "app_icon"
        const val channelId: String = "channel_id"
        const val contentTitle: String = "content_title"
        const val contentText: String = "content_text"
        const val serviceId: String = "service_id"
        const val callbackHandle: String = "callback_handle"
        const val isInDebugMode: String = "is_in_debug_mode"

        const val bgTaskUniqueName = "GeofenceForegroundServiceTask"
    }
}