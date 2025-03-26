package com.f2fk.geofence_foreground_service.builders

import android.util.Log
import com.f2fk.geofence_foreground_service.interfaces.Builder
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.utils.calculateCenter
import com.google.android.gms.location.Geofence
import com.google.android.gms.maps.model.LatLng

class GeofenceBuilder(private val zone: Zone) : Builder<Geofence> {
    override fun build(): Geofence {
        val centerCoordinate: LatLng = calculateCenter(zone.coordinates ?: emptyList())
        val builder = Geofence.Builder()
            .setRequestId(zone.zoneId)
            .setCircularRegion(
                centerCoordinate.latitude,
                centerCoordinate.longitude,
                zone.radius,
                )
            .setExpirationDuration(zone.expirationDuration ?: Geofence.NEVER_EXPIRE)
            .setTransitionTypes(zone.triggers)
            .setLoiteringDelay(zone.dwellLoiteringDelay ?: 0)
        if (zone.notificationResponsivenessMs != null) {
            Log.v("addGeofence", "Setting notification responsiveness to ${zone.notificationResponsivenessMs}")
            builder.setNotificationResponsiveness(zone.notificationResponsivenessMs)
        }
        return builder.build()
    }
}