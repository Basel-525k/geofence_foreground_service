package com.f2fk.geofence_foreground_service.builders

import android.util.Log
import com.f2fk.geofence_foreground_service.interfaces.Builder
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.utils.zoneCircle
import com.google.android.gms.location.Geofence

class GeofenceBuilder(private val zone: Zone) : Builder<Geofence> {
    override fun build(): Geofence {
        val coordinates = requireNotNull(zone.coordinates) {
            "Zone ${zone.zoneId} must include at least one coordinate"
        }
        require(coordinates.isNotEmpty()) {
            "Zone ${zone.zoneId} must include at least one coordinate"
        }
        // One point: a circle of zone.radius. Several: the smallest circle covering all of them
        // plus polygonMarginMeters; zone.radius is not used.
        val circle = zoneCircle(coordinates, zone.radius.toDouble(), zone.polygonMarginMeters)
        val builder = Geofence.Builder()
            .setRequestId(zone.zoneId)
            .setCircularRegion(
                circle.center.latitude,
                circle.center.longitude,
                circle.radiusMeters.toFloat(),
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