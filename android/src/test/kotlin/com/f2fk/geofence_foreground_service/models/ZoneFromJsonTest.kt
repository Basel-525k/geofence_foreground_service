package com.f2fk.geofence_foreground_service.models

import org.junit.Assert.assertEquals
import org.junit.Test

class ZoneFromJsonTest {
    @Test
    fun acceptsIntegerNumbersFromTheChannel() {
        val zone = Zone.fromJson(
            mapOf(
                "id" to "z",
                "radius" to 100,
                "coordinates" to listOf(mapOf("latitude" to 10, "longitude" to 20)),
                "fence_triggers" to listOf(1, 4),
            )
        )

        assertEquals(100f, zone.radius)
        assertEquals(10.0, zone.coordinates!![0].latitude, 0.0)
        assertEquals(20.0, zone.coordinates!![0].longitude, 0.0)
        assertEquals(1 or 4, zone.triggers)
    }
}
