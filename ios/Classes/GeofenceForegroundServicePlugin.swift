import Flutter
import UIKit
import CoreLocation

public class GeofenceForegroundServicePlugin: NSObject, FlutterPlugin {
    static let identifier = "ps.byshy.geofence"

    private static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?

    @objc
    public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
        flutterPluginRegistrantCallback = callback
    }

    private var locationManager = CLLocationManager()
    private var result: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = GeofenceForegroundServicePlugin()

        instance.locationManager.delegate = instance

        instance.locationManager.requestAlwaysAuthorization()

        instance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        instance.locationManager.distanceFilter = 1.0

        let channel = FlutterMethodChannel(
            name: "\(GeofenceForegroundServicePlugin.identifier)/foreground_geofence_foreground_service",
            binaryMessenger: registrar.messenger()
        )

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result

        switch call.method {
        case "startGeofencingService":
            guard
                let arguments = call.arguments as? [AnyHashable: Any],
                let isInDebug = arguments[Constants.isInDebugMode] as? Bool,
                let handle = arguments[Constants.callbackHandle] as? Int64
            else {
                result(GFSError.invalidParameters.asFlutterError)
                return
            }

            UserDefaultsHelper.storeCallbackHandle(handle)
            UserDefaultsHelper.storeIsDebug(isInDebug)

            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()

            result(true)
        case "stopGeofencingService":
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.stopUpdatingLocation()

            result(true)
        case "isForegroundServiceRunning":
            result(locationManager.allowsBackgroundLocationUpdates)
        case "addGeofence":
            let jsonData = try! JSONSerialization.data(withJSONObject: call.arguments as! [String: Any], options: [])

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
        eventHandler(zoneID: region.identifier, triggerType: 1)
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited geofence: \(region.identifier)")
        // Perform actions when exiting the geofence
        eventHandler(zoneID: region.identifier, triggerType: 2)
    }

    public func eventHandler(zoneID: String, triggerType: Int) {
        guard
            let callbackHandle = UserDefaultsHelper.getStoredCallbackHandle(),
            let _ = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
        else {
//            logError("[\(String(describing: self))] \(GFSError.pluginNotInitialized.message)")
            return
        }

        let operationQueue = OperationQueue()
        // Create an operation that performs the main part of the background task
        let operation = BackgroundTaskOperation(
            zoneID: zoneID,
            triggerType: triggerType,
            flutterPluginRegistrantCallback: GeofenceForegroundServicePlugin.flutterPluginRegistrantCallback
        )

        // Start the operation
        operationQueue.addOperation(operation)
    }
}
