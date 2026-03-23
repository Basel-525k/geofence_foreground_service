package com.f2fk.geofence_foreground_service.models

import com.f2fk.geofence_foreground_service.Constants
import com.f2fk.geofence_foreground_service.utils.Utils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class ZoneModelTest {

    @Test
    fun zoneFromJson_toJson_roundTrip() {
        val map = mapOf<String, Any>(
            Constants.id to "zone-1",
            Constants.radius to 25.5,
            Constants.coordinates to listOf(
                mapOf(Constants.latitude to 10.0, Constants.longitude to 20.0),
            ),
            Constants.fenceTriggers to Utils.availableTriggers,
            Constants.initialTrigger to 1,
            Constants.notificationResponsivenessMs to 5000,
            Constants.fenceExpirationDuration to 60_000L,
            Constants.dwellLoiteringDelay to 10_000,
        )

        val zone = Zone.fromJson(map)
        assertEquals("zone-1", zone.zoneId)
        assertEquals(25.5f, zone.radius)
        assertNotNull(zone.coordinates)
        assertEquals(1, zone.coordinates!!.size)
        assertEquals(10.0, zone.coordinates!![0].latitude, 1e-9)
        assertEquals(20.0, zone.coordinates!![0].longitude, 1e-9)

        val out = zone.toJson()
        assertEquals("zone-1", out[Constants.id])
        assertEquals(5000, (out[Constants.notificationResponsivenessMs] as Int))
    }

    @Test
    fun zonesListFromJson_readsZonesArray() {
        val inner = mapOf<String, Any>(
            Constants.id to "a",
            Constants.radius to 1.0,
            Constants.coordinates to listOf(
                mapOf(Constants.latitude to 0.0, Constants.longitude to 0.0),
            ),
            Constants.fenceTriggers to Utils.availableTriggers,
        )
        val root = mapOf<String, Any>(
            Constants.zones to listOf(inner),
        )
        val list = ZonesList.fromJson(root)
        assertEquals(1, list.zones?.size)
        assertEquals("a", list.zones!![0].zoneId)
    }
}
