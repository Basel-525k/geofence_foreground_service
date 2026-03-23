import CoreLocation
import XCTest

@testable import geofence_foreground_service

/// Exercises plugin Swift models and helpers linked via CocoaPods (Flutter available).
/// Android-style JVM unit tests for similar logic live under `android/src/test/`.
final class RunnerTests: XCTestCase {

  func testZoneDecodesFromPluginModelJson() throws {
    let json = """
    {
      "id": "host_check",
      "radius": 50,
      "coordinates": [{"latitude": 1.0, "longitude": 2.0}],
      "notification_responsiveness_ms": 5000
    }
    """.data(using: .utf8)!

    let zone = try JSONDecoder().decode(Zone.self, from: json)
    XCTAssertEqual(zone.id, "host_check")
    XCTAssertEqual(zone.radius, 50.0, accuracy: 1e-9)
    XCTAssertEqual(zone.coordinates?.count, 1)
    XCTAssertEqual(zone.notificationResponsivenessMs, 5000)
  }

  func testCalculateCenterAveragesCoordinates() {
    let c = calculateCenter(
      coordinates: [
        CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        CLLocationCoordinate2D(latitude: 2.0, longitude: 4.0),
      ])
    XCTAssertEqual(c.latitude, 1.0, accuracy: 1e-9)
    XCTAssertEqual(c.longitude, 2.0, accuracy: 1e-9)
  }

  func testCalculateCenterSinglePoint() {
    let p = CLLocationCoordinate2D(latitude: 3.0, longitude: 5.0)
    let c = calculateCenter(coordinates: [p])
    XCTAssertEqual(c.latitude, p.latitude, accuracy: 1e-9)
    XCTAssertEqual(c.longitude, p.longitude, accuracy: 1e-9)
  }

  func testCodableCoordinateBridge() {
    let coord = CodableCoordinate(latitude: 9.0, longitude: 8.0)
    let cl = coord.asCLLocationCoordinate2D
    XCTAssertEqual(cl.latitude, 9.0, accuracy: 1e-9)
    XCTAssertEqual(cl.longitude, 8.0, accuracy: 1e-9)
  }
}
