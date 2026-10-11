package com.f2fk.geofence_foreground_service.utils

import com.f2fk.geofence_foreground_service.models.Zone
import com.google.android.gms.maps.model.LatLng
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ZoneCodecTest {
    private fun zone(
        id: String = "zone-1",
        coordinates: List<LatLng> = listOf(LatLng(51.5, -0.12)),
        triggers: Int = 1 or 2,
        expirationDuration: Long? = 60_000L,
        dwellLoiteringDelay: Int? = 5_000,
        initialTrigger: Int? = 2,
        responsiveness: Int? = 15_000,
    ) = Zone(
        id,
        150f,
        ArrayList(coordinates),
        responsiveness,
        triggers,
        expirationDuration,
        dwellLoiteringDelay,
        initialTrigger,
    )

    @Test
    fun roundTripPreservesEveryField() {
        val restored = ZoneCodec.decode(ZoneCodec.encode(zone()))

        assertEquals("zone-1", restored.zoneId)
        assertEquals(150f, restored.radius)
        assertEquals(1, restored.coordinates?.size)
        assertEquals(51.5, restored.coordinates!![0].latitude, 0.0)
        assertEquals(-0.12, restored.coordinates!![0].longitude, 0.0)
        assertEquals(15_000, restored.notificationResponsivenessMs)
        assertEquals(1 or 2, restored.triggers)
        assertEquals(60_000L, restored.expirationDuration)
        assertEquals(5_000, restored.dwellLoiteringDelay)
        assertEquals(2, restored.initialTrigger)
    }

    @Test
    fun initialTriggerBitmaskSurvivesRoundTrip() {
        // enter | exit asks Play services to report the state the device is already in.
        val restored = ZoneCodec.decode(ZoneCodec.encode(zone(initialTrigger = 1 or 2)))

        assertEquals(3, restored.initialTrigger)
    }

    @Test
    fun wholeNumberCoordinatesSurviveJson() {
        // org.json writes 51.0 as `51`, so it comes back as an Int rather than a Double.
        val restored = ZoneCodec.decode(
            ZoneCodec.encode(zone(coordinates = listOf(LatLng(51.0, 0.0), LatLng(52.0, 1.0))))
        )

        assertEquals(2, restored.coordinates?.size)
        assertEquals(51.0, restored.coordinates!![0].latitude, 0.0)
        assertEquals(1.0, restored.coordinates!![1].longitude, 0.0)
    }

    @Test
    fun optionalFieldsStayNull() {
        val restored = ZoneCodec.decode(
            ZoneCodec.encode(
                zone(
                    expirationDuration = null,
                    dwellLoiteringDelay = null,
                    initialTrigger = null,
                    responsiveness = null,
                )
            )
        )

        assertNull(restored.expirationDuration)
        assertNull(restored.dwellLoiteringDelay)
        assertNull(restored.initialTrigger)
        assertNull(restored.notificationResponsivenessMs)
    }

    @Test
    fun polygonMarginSurvivesPersistence() {
        val z = Zone(
            "p", 100f, arrayListOf(LatLng(1.0, 2.0), LatLng(1.0, 3.0), LatLng(2.0, 3.0)),
            null, 1 or 2, null, null, 3, 35.0,
        )
        assertEquals(35.0, ZoneCodec.decode(ZoneCodec.encode(z)).polygonMarginMeters, 0.0)
    }

    @Test
    fun aZonePersistedBeforeTheMarginExistedHasNone() {
        val legacy = """{"id":"old","radius":100.0,"coordinates":[{"latitude":1.0,"longitude":2.0}]}"""
        assertEquals(0.0, ZoneCodec.decode(legacy).polygonMarginMeters, 0.0)
    }
}
