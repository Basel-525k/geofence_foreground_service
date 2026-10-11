package com.f2fk.geofence_foreground_service.utils

import com.google.android.gms.maps.model.LatLng
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class EnclosingCircleTest {

    private val square = listOf(
        LatLng(25.2000, 55.2700),
        LatLng(25.2000, 55.2720),
        LatLng(25.2020, 55.2720),
        LatLng(25.2020, 55.2700),
    )

    private fun assertCovers(circle: GroundCircle, points: List<LatLng>) {
        for (p in points) {
            val d = haversineMeters(circle.center, p)
            assertTrue("vertex $p is $d m away, radius ${circle.radiusMeters}", d <= circle.radiusMeters + 1e-6)
        }
    }

    @Test
    fun singlePoint_usesTheGivenRadiusAndIgnoresTheMargin() {
        val p = LatLng(1.0, 2.0)
        val c = zoneCircle(listOf(p), radius = 150.0, marginMeters = 40.0)
        assertEquals(p, c.center)
        assertEquals(150.0, c.radiusMeters, 0.0)
    }

    @Test
    fun polygon_ignoresTheGivenRadius() {
        val a = zoneCircle(square, radius = 10.0, marginMeters = 0.0)
        val b = zoneCircle(square, radius = 9000.0, marginMeters = 0.0)
        assertEquals(a.radiusMeters, b.radiusMeters, 1e-9)
    }

    @Test
    fun polygon_coversEveryVertex() {
        assertCovers(zoneCircle(square, 1.0, 0.0), square)
    }

    @Test
    fun polygon_isTheSmallestCircle_halfTheDiagonalForASquare() {
        val c = enclosingCircle(square)
        val diagonal = haversineMeters(square[0], square[2])
        assertEquals(diagonal / 2, c.radiusMeters, 0.5)
        // The center is the middle of the square.
        assertEquals(25.2010, c.center.latitude, 1e-6)
        assertEquals(55.2710, c.center.longitude, 1e-6)
    }

    @Test
    fun polygon_isNoLargerThanTheCircleAroundTheMean() {
        val clustered = listOf(
            LatLng(25.2000, 55.2700),
            LatLng(25.2001, 55.2700),
            LatLng(25.2000, 55.2701),
            LatLng(25.2001, 55.2701),
            LatLng(25.2100, 55.2800),
        )
        val mean = LatLng(
            clustered.map { it.latitude }.average(),
            clustered.map { it.longitude }.average(),
        )
        val meanRadius = clustered.maxOf { haversineMeters(mean, it) }
        val c = enclosingCircle(clustered)
        assertTrue(c.radiusMeters <= meanRadius + 1e-6)
        assertCovers(c, clustered)
    }

    @Test
    fun margin_isAddedToTheCoveringRadius() {
        val base = zoneCircle(square, 1.0, 0.0)
        val wide = zoneCircle(square, 1.0, 35.0)
        assertEquals(base.radiusMeters + 35.0, wide.radiusMeters, 1e-9)
        assertEquals(base.center, wide.center)
    }

    @Test
    fun negativeMargin_isTreatedAsZero() {
        val base = zoneCircle(square, 1.0, 0.0)
        assertEquals(base.radiusMeters, zoneCircle(square, 1.0, -10.0).radiusMeters, 1e-9)
    }

    @Test
    fun twoPoints_isTheCircleOnTheirDiameter() {
        val a = LatLng(25.2, 55.27)
        val b = LatLng(25.2, 55.28)
        val c = enclosingCircle(listOf(a, b))
        assertEquals(haversineMeters(a, b) / 2, c.radiusMeters, 0.5)
    }

    @Test
    fun collinearPoints_doNotBreakIt() {
        val line = listOf(
            LatLng(25.2, 55.27),
            LatLng(25.2, 55.275),
            LatLng(25.2, 55.28),
        )
        assertCovers(enclosingCircle(line), line)
    }

    @Test
    fun aClosedRing_isTheSameAsTheOpenOne() {
        val closed = square + square.first()
        assertEquals(
            enclosingCircle(square).radiusMeters,
            enclosingCircle(closed).radiusMeters,
            1e-6,
        )
    }

    @Test
    fun highLatitude_stillCoversEveryVertex() {
        val pts = listOf(
            LatLng(64.1400, -21.9400),
            LatLng(64.1400, -21.9300),
            LatLng(64.1450, -21.9350),
        )
        assertCovers(enclosingCircle(pts), pts)
    }

    @Test
    fun acrossTheAntimeridian_staysSmall() {
        val pts = listOf(
            LatLng(-17.00, 179.995),
            LatLng(-17.00, -179.995),
            LatLng(-17.01, 180.0),
        )
        val c = enclosingCircle(pts)
        assertCovers(c, pts)
        assertTrue("radius ${c.radiusMeters}", c.radiusMeters < 2_000.0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun empty_throws() {
        zoneCircle(emptyList(), 100.0, 0.0)
    }
}
