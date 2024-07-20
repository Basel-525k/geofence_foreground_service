import Flutter
import UIKit
import CoreLocation

public class GeofenceForegroundServicePlugin: NSObject, FlutterPlugin {
    private var locationManager = CLLocationManager()
    private var result: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = GeofenceForegroundServicePlugin()

        // Set the delegate of locationManager to the instance
        instance.locationManager.delegate = instance

        instance.locationManager.requestAlwaysAuthorization()

        instance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        instance.locationManager.distanceFilter = 1.0

        instance.locationManager.startUpdatingLocation()

        let channel = FlutterMethodChannel(
            name: "ps.byshy.geofence/foreground_geofence_foreground_service",
            binaryMessenger: registrar.messenger()
        )

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result

        switch call.method {
        case "startGeofencingService":
            result(true)
        case "stopGeofencingService":
            result(false)
        case "isForegroundServiceRunning":
            result(false)
        case "addGeofence":
            let jsonData = try! JSONSerialization.data(withJSONObject: call.arguments as! [String: Any], options: [])

            // Decode JSON data into Zone object
            do {
                let zone = try JSONDecoder().decode(Zone.self, from: jsonData)

                addGeoFence(zone: zone, result: result)
            } catch {
                print("Error decoding Zone: \(error)")
            }
        case "addGeoFences":
            result(false)
//            let zonesList: ZonesList = ZonesList(fromJson: call.arguments as! [String : Any])

//            addGeoFences(zonesList, result)
        case "removeGeofence":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func addGeoFences(zones: ZonesList, result: @escaping FlutterResult) {
        for zone in zones.zones ?? [] {
            addGeoFence(zone: zone, result: result)
        }
    }

    private func addGeoFence(zone: Zone, result: @escaping FlutterResult) {
        guard let coordinates = zone.coordinates, !coordinates.isEmpty else {
            result(
                FlutterError(
                    code: "INVALID_COORDINATES",
                    message: "Zone coordinates are invalid",
                    details: nil
                )
            )

            return
        }

        let firstCoordinate = coordinates[0]

        let geofenceRegion = CLCircularRegion(
            center: firstCoordinate.asCLLocationCoordinate2D,
            radius: zone.radius,
            identifier: zone.id
        )

        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true

        locationManager.startMonitoring(for: geofenceRegion)
        
        result(true)
    }
}

extension GeofenceForegroundServicePlugin: CLLocationManagerDelegate {
    // Implement CLLocationManagerDelegate methods here
    // For example:

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates here
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location manager errors here
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered geofence: \(region.identifier)")
        // Perform actions when entering the geofence
        result?("Entered geofence: \(region.identifier)")
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited geofence: \(region.identifier)")
        // Perform actions when exiting the geofence
        result?("Exited geofence: \(region.identifier)")
    }
}
