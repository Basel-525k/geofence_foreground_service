package com.f2fk.geofence_foreground_service.utils

import com.google.android.gms.maps.model.LatLng
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt

/** A circle on the ground: a center and a radius in meters. */
data class GroundCircle(val center: LatLng, val radiusMeters: Double)

private const val EARTH_RADIUS_M = 6_371_008.8
private const val EPSILON = 1e-9

/**
 * The circle the OS is asked to monitor for a zone.
 *
 * One coordinate is a circle of [radius] around it. Two or more are a polygon, which the OS
 * cannot monitor: the smallest circle covering every coordinate is used, widened by
 * [marginMeters]. [radius] is ignored then.
 *
 * The same rule is implemented in Swift (`zoneCircle`); keep the two in step.
 */
fun zoneCircle(coordinates: List<LatLng>, radius: Double, marginMeters: Double): GroundCircle {
    require(coordinates.isNotEmpty()) { "coordinates must not be empty" }
    if (coordinates.size == 1) {
        return GroundCircle(coordinates.first(), radius)
    }
    val cover = enclosingCircle(coordinates)
    return GroundCircle(cover.center, cover.radiusMeters + max(marginMeters, 0.0))
}

/**
 * The smallest circle that contains every coordinate.
 *
 * Points are projected to a local flat plane (meters) around their mean, solved with the
 * incremental minimum-enclosing-circle algorithm, then the radius is re-measured on the sphere
 * with haversine so every vertex is covered whatever the projection error.
 */
fun enclosingCircle(coordinates: List<LatLng>): GroundCircle {
    require(coordinates.isNotEmpty()) { "coordinates must not be empty" }
    if (coordinates.size == 1) return GroundCircle(coordinates.first(), 0.0)

    val lat0 = coordinates.sumOf { it.latitude } / coordinates.size
    // Longitudes are taken relative to the first point so a zone across the antimeridian works.
    val lngRef = coordinates.first().longitude
    val lng0 = lngRef + coordinates.sumOf { wrap(it.longitude - lngRef) } / coordinates.size
    val metersPerDegreeLat = Math.PI / 180.0 * EARTH_RADIUS_M
    val metersPerDegreeLng = metersPerDegreeLat * cos(Math.toRadians(lat0))

    val points = coordinates.map {
        doubleArrayOf(
            wrap(it.longitude - lng0) * metersPerDegreeLng,
            (it.latitude - lat0) * metersPerDegreeLat,
        )
    }
    val flat = minimumEnclosing(points)

    val center = LatLng(
        lat0 + flat[1] / metersPerDegreeLat,
        normalizeLng(lng0 + flat[0] / metersPerDegreeLng),
    )
    var radius = flat[2]
    for (c in coordinates) radius = max(radius, haversineMeters(center, c))
    return GroundCircle(center, radius)
}

/** Returns `[x, y, r]` of the smallest circle containing [p]. */
private fun minimumEnclosing(p: List<DoubleArray>): DoubleArray {
    var c = doubleArrayOf(p[0][0], p[0][1], 0.0)
    for (i in 1 until p.size) {
        if (inside(c, p[i])) continue
        c = doubleArrayOf(p[i][0], p[i][1], 0.0)
        for (j in 0 until i) {
            if (inside(c, p[j])) continue
            c = diameter(p[i], p[j])
            for (k in 0 until j) {
                if (inside(c, p[k])) continue
                c = circumcircle(p[i], p[j], p[k])
            }
        }
    }
    return c
}

private fun inside(c: DoubleArray, p: DoubleArray): Boolean {
    val dx = p[0] - c[0]
    val dy = p[1] - c[1]
    return sqrt(dx * dx + dy * dy) <= c[2] * (1 + EPSILON) + EPSILON
}

private fun diameter(a: DoubleArray, b: DoubleArray): DoubleArray {
    val x = (a[0] + b[0]) / 2
    val y = (a[1] + b[1]) / 2
    return doubleArrayOf(x, y, distance(a, b) / 2)
}

private fun circumcircle(a: DoubleArray, b: DoubleArray, c: DoubleArray): DoubleArray {
    val bx = b[0] - a[0]
    val by = b[1] - a[1]
    val cx = c[0] - a[0]
    val cy = c[1] - a[1]
    val d = 2 * (bx * cy - by * cx)
    if (kotlin.math.abs(d) < EPSILON) {
        // Collinear: the widest pair decides.
        val pairs = listOf(diameter(a, b), diameter(a, c), diameter(b, c))
        return pairs.maxByOrNull { it[2] }!!
    }
    val b2 = bx * bx + by * by
    val c2 = cx * cx + cy * cy
    val ux = (cy * b2 - by * c2) / d
    val uy = (bx * c2 - cx * b2) / d
    return doubleArrayOf(a[0] + ux, a[1] + uy, sqrt(ux * ux + uy * uy))
}

private fun distance(a: DoubleArray, b: DoubleArray): Double {
    val dx = a[0] - b[0]
    val dy = a[1] - b[1]
    return sqrt(dx * dx + dy * dy)
}

private fun wrap(deltaDegrees: Double): Double {
    var d = deltaDegrees % 360.0
    if (d > 180.0) d -= 360.0
    if (d < -180.0) d += 360.0
    return d
}

private fun normalizeLng(lng: Double): Double {
    var v = lng % 360.0
    if (v > 180.0) v -= 360.0
    if (v < -180.0) v += 360.0
    return v
}

/** Great-circle distance in meters. */
fun haversineMeters(a: LatLng, b: LatLng): Double {
    val dLat = Math.toRadians(b.latitude - a.latitude)
    val dLng = Math.toRadians(wrap(b.longitude - a.longitude))
    val h = sin(dLat / 2) * sin(dLat / 2) +
        cos(Math.toRadians(a.latitude)) * cos(Math.toRadians(b.latitude)) *
        sin(dLng / 2) * sin(dLng / 2)
    return 2 * EARTH_RADIUS_M * asin(sqrt(h.coerceIn(0.0, 1.0)))
}
