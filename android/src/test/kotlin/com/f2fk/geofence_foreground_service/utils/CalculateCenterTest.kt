package com.f2fk.geofence_foreground_service.utils

import com.google.android.gms.maps.model.LatLng
import org.junit.Assert.assertEquals
import org.junit.Test

class CalculateCenterTest {

    @Test
    fun singleCoordinate_returnsSamePoint() {
        val p = LatLng(1.0, 2.0)
        assertEquals(p, calculateCenter(listOf(p)))
    }

    @Test
    fun multipleCoordinates_returnsArithmeticMean() {
        val c = calculateCenter(
            listOf(
                LatLng(0.0, 0.0),
                LatLng(2.0, 4.0),
            ),
        )
        assertEquals(1.0, c.latitude, 1e-9)
        assertEquals(2.0, c.longitude, 1e-9)
    }

    @Test(expected = IllegalArgumentException::class)
    fun emptyList_throws() {
        calculateCenter(emptyList())
    }
}
