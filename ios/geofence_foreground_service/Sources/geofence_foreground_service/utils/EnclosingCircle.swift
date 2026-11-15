import Foundation
import CoreLocation

/// A circle on the ground: a center and a radius in meters.
struct GroundCircle {
    let center: CLLocationCoordinate2D
    let radiusMeters: Double
}

private let earthRadiusMeters = 6_371_008.8
private let epsilon = 1e-9

/// The circle the OS is asked to monitor for a zone.
///
/// One coordinate is a circle of `radius` around it. Two or more are a polygon, which the OS
/// cannot monitor: the smallest circle covering every coordinate is used, widened by
/// `marginMeters`. `radius` is ignored then.
///
/// The same rule is implemented in Kotlin (`zoneCircle`); keep the two in step.
func zoneCircle(
    coordinates: [CLLocationCoordinate2D],
    radius: Double,
    marginMeters: Double
) -> GroundCircle {
    precondition(!coordinates.isEmpty, "coordinates must not be empty")
    if coordinates.count == 1 {
        return GroundCircle(center: coordinates[0], radiusMeters: radius)
    }
    let cover = enclosingCircle(coordinates: coordinates)
    return GroundCircle(
        center: cover.center,
        radiusMeters: cover.radiusMeters + max(marginMeters, 0)
    )
}

/// The smallest circle that contains every coordinate.
///
/// Points are projected to a local flat plane (meters) around their mean, solved with the
/// incremental minimum-enclosing-circle algorithm, then the radius is re-measured on the sphere
/// with haversine so every vertex is covered whatever the projection error.
func enclosingCircle(coordinates: [CLLocationCoordinate2D]) -> GroundCircle {
    precondition(!coordinates.isEmpty, "coordinates must not be empty")
    if coordinates.count == 1 {
        return GroundCircle(center: coordinates[0], radiusMeters: 0)
    }

    let count = Double(coordinates.count)
    let lat0 = coordinates.reduce(0.0) { $0 + $1.latitude } / count
    // Longitudes are taken relative to the first point so a zone across the antimeridian works.
    let lngRef = coordinates[0].longitude
    let lng0 = lngRef + coordinates.reduce(0.0) { $0 + wrapDegrees($1.longitude - lngRef) } / count
    let metersPerDegreeLat = Double.pi / 180.0 * earthRadiusMeters
    let metersPerDegreeLng = metersPerDegreeLat * cos(lat0 * Double.pi / 180.0)

    let points = coordinates.map {
        (x: wrapDegrees($0.longitude - lng0) * metersPerDegreeLng,
         y: ($0.latitude - lat0) * metersPerDegreeLat)
    }
    let flat = minimumEnclosing(points)

    let center = CLLocationCoordinate2D(
        latitude: lat0 + flat.y / metersPerDegreeLat,
        longitude: normalizeLongitude(lng0 + flat.x / metersPerDegreeLng)
    )
    var radius = flat.r
    for coordinate in coordinates {
        radius = max(radius, haversineMeters(center, coordinate))
    }
    return GroundCircle(center: center, radiusMeters: radius)
}

private typealias Point = (x: Double, y: Double)
private typealias PlaneCircle = (x: Double, y: Double, r: Double)

private func minimumEnclosing(_ p: [Point]) -> PlaneCircle {
    var c: PlaneCircle = (p[0].x, p[0].y, 0)
    for i in 1..<p.count {
        if contains(c, p[i]) { continue }
        c = (p[i].x, p[i].y, 0)
        for j in 0..<i {
            if contains(c, p[j]) { continue }
            c = diameter(p[i], p[j])
            for k in 0..<j {
                if contains(c, p[k]) { continue }
                c = circumcircle(p[i], p[j], p[k])
            }
        }
    }
    return c
}

private func contains(_ c: PlaneCircle, _ p: Point) -> Bool {
    let dx = p.x - c.x
    let dy = p.y - c.y
    return (dx * dx + dy * dy).squareRoot() <= c.r * (1 + epsilon) + epsilon
}

private func diameter(_ a: Point, _ b: Point) -> PlaneCircle {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return ((a.x + b.x) / 2, (a.y + b.y) / 2, (dx * dx + dy * dy).squareRoot() / 2)
}

private func circumcircle(_ a: Point, _ b: Point, _ c: Point) -> PlaneCircle {
    let bx = b.x - a.x
    let by = b.y - a.y
    let cx = c.x - a.x
    let cy = c.y - a.y
    let d = 2 * (bx * cy - by * cx)
    if abs(d) < epsilon {
        // Collinear: the widest pair decides.
        return [diameter(a, b), diameter(a, c), diameter(b, c)].max { $0.r < $1.r }!
    }
    let b2 = bx * bx + by * by
    let c2 = cx * cx + cy * cy
    let ux = (cy * b2 - by * c2) / d
    let uy = (bx * c2 - cx * b2) / d
    return (a.x + ux, a.y + uy, (ux * ux + uy * uy).squareRoot())
}

private func wrapDegrees(_ delta: Double) -> Double {
    var d = delta.truncatingRemainder(dividingBy: 360)
    if d > 180 { d -= 360 }
    if d < -180 { d += 360 }
    return d
}

private func normalizeLongitude(_ longitude: Double) -> Double {
    wrapDegrees(longitude)
}

/// Great-circle distance in meters.
func haversineMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let dLat = (b.latitude - a.latitude) * Double.pi / 180
    let dLng = wrapDegrees(b.longitude - a.longitude) * Double.pi / 180
    let h = sin(dLat / 2) * sin(dLat / 2)
        + cos(a.latitude * Double.pi / 180) * cos(b.latitude * Double.pi / 180)
        * sin(dLng / 2) * sin(dLng / 2)
    return 2 * earthRadiusMeters * asin(min(1, max(0, h)).squareRoot())
}
