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

    /// iOS never delivers an event for the state a region is already in when monitoring starts.
    /// Zones added with an initial trigger are parked here until `didDetermineState` answers.
    private var pendingInitialTriggers: [String: Int] = [:]

    /// `didDetermineState` answers `.unknown` while Core Location has no fix yet. Such a zone stays
    /// pending and is asked again on the next location update and on a short timer (for
    /// `locationUpdateMode: off`, where there are no updates), a bounded number of times.
    private var initialStateAttemptsLeft: [String: Int] = [:]
    private var initialStateTimer: Timer?
    private static let initialStateRetryInterval: TimeInterval = 2
    private static let initialStateMaxAttempts = 10

    /// Zones this instance started monitoring. `monitoredRegions` is updated asynchronously by the
    /// OS, so right after an add it can still miss the new region; the union of both is the truth.
    private var startedZoneIds: Set<String> = []

    private var monitoredZoneIds: Set<String> {
        startedZoneIds.union(locationManager.monitoredRegions.map { $0.identifier })
    }

    /// iOS allows at most 20 monitored regions per app.
    private static let maxMonitoredRegions = 20

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = GeofenceForegroundServicePlugin()

        instance.locationManager.delegate = instance

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

            // Asked here, not at plugin registration, so the prompt appears in the context of the
            // app starting the service rather than at launch.
            switch currentAuthorizationStatus {
            case .notDetermined, .authorizedWhenInUse:
                locationManager.requestAlwaysAuthorization()
            default:
                break
            }

            // Region monitoring wakes the app on its own; continuous updates are optional.
            let mode = arguments[Constants.locationUpdateMode] as? String ?? "highAccuracy"
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            switch mode {
            case "off":
                locationManager.stopUpdatingLocation()
            case "balanced":
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.distanceFilter = 100
                locationManager.startUpdatingLocation()
            default:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.distanceFilter = kCLDistanceFilterNone
                locationManager.startUpdatingLocation()
            }

            result(true)
        case "stopGeofencingService":
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.stopUpdatingLocation()
            clearPendingInitialStates()

            result(true)
        case "isForegroundServiceRunning":
            result(locationManager.allowsBackgroundLocationUpdates)
        case "addGeofence":
            guard
                let arguments = call.arguments as? [String: Any],
                JSONSerialization.isValidJSONObject(arguments),
                let jsonData = try? JSONSerialization.data(withJSONObject: arguments, options: [])
            else {
                result(GFSError.invalidParameters.asFlutterError)
                return
            }

            do {
                let zone = try JSONDecoder().decode(Zone.self, from: jsonData)

                addGeoFence(zone: zone, result: result)
            } catch {
                result(
                    FlutterError(
                        code: "INVALID_ZONE",
                        message: "Unable to decode zone: \(error)",
                        details: nil
                    )
                )
            }
        case "addGeoFences":
            guard
                let arguments = call.arguments as? [String: Any],
                JSONSerialization.isValidJSONObject(arguments),
                let jsonData = try? JSONSerialization.data(withJSONObject: arguments, options: [])
            else {
                result(GFSError.invalidParameters.asFlutterError)
                return
            }

            do {
                let zonesList = try JSONDecoder().decode(ZonesList.self, from: jsonData)

                addGeoFences(zones: zonesList, result: result)
            } catch {
                result(
                    FlutterError(
                        code: "INVALID_ZONE",
                        message: "Unable to decode zones: \(error)",
                        details: nil
                    )
                )
            }
        case "removeGeofence":
            guard
                let arguments = call.arguments as? [String: Any],
                let zoneId = arguments[Constants.zoneId] as? String
            else {
                result(GFSError.invalidParameters.asFlutterError)
                return
            }

            clearPendingInitialState(for: zoneId)
            startedZoneIds.remove(zoneId)

            for region in locationManager.monitoredRegions where region.identifier == zoneId {
                locationManager.stopMonitoring(for: region)
                result(true)
                return
            }

            result(false)
        case "removeAllGeoFences":
            clearPendingInitialStates()
            startedZoneIds.removeAll()

            for region in locationManager.monitoredRegions {
                locationManager.stopMonitoring(for: region)
            }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Validates every zone before registering any, so a bad zone does not leave the batch
    /// half-applied.
    private func addGeoFences(zones: ZonesList, result: @escaping FlutterResult) {
        let list = zones.zones ?? []

        // Zones that replace an already monitored id do not take a new region slot.
        let monitoredIds = monitoredZoneIds
        let newIds = Set(list.map { $0.id }).subtracting(monitoredIds)
        if monitoredIds.count + newIds.count > GeofenceForegroundServicePlugin.maxMonitoredRegions {
            result(regionLimitError)
            return
        }

        var regions: [(Zone, CLCircularRegion)] = []
        for zone in list {
            switch makeRegion(for: zone) {
            case .success(let region):
                regions.append((zone, region))
            case .failure(let error):
                result(error)
                return
            }
        }

        for (zone, region) in regions {
            startMonitoring(zone: zone, region: region)
        }
        result(true)
    }

    private func addGeoFence(zone: Zone, result: @escaping FlutterResult) {
        let monitoredIds = monitoredZoneIds
        if !monitoredIds.contains(zone.id),
           monitoredIds.count >= GeofenceForegroundServicePlugin.maxMonitoredRegions {
            result(regionLimitError)
            return
        }

        switch makeRegion(for: zone) {
        case .success(let region):
            startMonitoring(zone: zone, region: region)
            result(true)
        case .failure(let error):
            result(error)
        }
    }

    /// `CLLocationManager.authorizationStatus` (instance) needs iOS 14; the plugin supports 13.
    private var currentAuthorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }

    private var regionLimitError: FlutterError {
        FlutterError(
            code: "REGION_LIMIT_REACHED",
            message: "iOS can monitor at most \(GeofenceForegroundServicePlugin.maxMonitoredRegions) regions per app",
            details: nil
        )
    }

    private func makeRegion(for zone: Zone) -> Result<CLCircularRegion, FlutterError> {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            return .failure(
                FlutterError(
                    code: "MONITORING_UNAVAILABLE",
                    message: "Region monitoring is not available on this device",
                    details: nil
                )
            )
        }

        switch currentAuthorizationStatus {
        case .denied, .restricted:
            return .failure(
                FlutterError(
                    code: "permission_denied",
                    message: "Location permission is denied or restricted",
                    details: nil
                )
            )
        default:
            break
        }

        guard let coordinates = zone.coordinates, !coordinates.isEmpty else {
            return .failure(
                FlutterError(
                    code: "INVALID_COORDINATES",
                    message: "Zone coordinates are invalid",
                    details: nil
                )
            )
        }

        guard zone.radius > 0 else {
            return .failure(
                FlutterError(
                    code: "INVALID_RADIUS",
                    message: "Zone radius must be greater than 0",
                    details: nil
                )
            )
        }

        // Same rule as Android: one point is a circle of `radius`; several are monitored as the
        // smallest circle covering all of them plus `polygonMarginMeters` (`radius` is ignored).
        let circle = zoneCircle(
            coordinates: coordinates.map { $0.asCLLocationCoordinate2D },
            radius: zone.radius,
            marginMeters: zone.polygonMarginMeters
        )
        let center = circle.center

        // iOS silently refuses regions larger than this. A polygon that does not fit would be
        // monitored smaller than its outline, so it is reported instead of clamped.
        let maximum = locationManager.maximumRegionMonitoringDistance
        if coordinates.count > 1 && circle.radiusMeters > maximum {
            return .failure(
                FlutterError(
                    code: "ZONE_TOO_LARGE",
                    message: "The zone needs a \(Int(circle.radiusMeters)) m circle; iOS monitors at most \(Int(maximum)) m",
                    details: nil
                )
            )
        }
        let radius = min(circle.radiusMeters, maximum)

        let region = CLCircularRegion(center: center, radius: radius, identifier: zone.id)
        region.notifyOnEntry = zone.triggers?.contains(GeofenceTrigger.enter) ?? true
        region.notifyOnExit = zone.triggers?.contains(GeofenceTrigger.exit) ?? true

        guard region.notifyOnEntry || region.notifyOnExit else {
            return .failure(
                FlutterError(
                    code: "UNSUPPORTED_TRIGGERS",
                    message: "iOS only supports enter and exit triggers; dwell is not available",
                    details: nil
                )
            )
        }

        return .success(region)
    }

    private func startMonitoring(zone: Zone, region: CLCircularRegion) {
        locationManager.startMonitoring(for: region)
        startedZoneIds.insert(zone.id)

        // Mirror Android: report the state the device is already in when the zone is added.
        // `initialTrigger` is a bitmask, so enter | exit reports whichever state the device is in.
        if let initialTrigger = zone.initialTrigger {
            let relevant = initialTrigger & (GeofenceTrigger.enter | GeofenceTrigger.exit)
            if relevant != 0 {
                pendingInitialTriggers[zone.id] = relevant
                initialStateAttemptsLeft[zone.id] = GeofenceForegroundServicePlugin.initialStateMaxAttempts
                locationManager.requestState(for: region)
                scheduleInitialStateRetry()
            }
        }
    }

    private func clearPendingInitialState(for zoneId: String) {
        pendingInitialTriggers.removeValue(forKey: zoneId)
        initialStateAttemptsLeft.removeValue(forKey: zoneId)
        if pendingInitialTriggers.isEmpty {
            initialStateTimer?.invalidate()
            initialStateTimer = nil
        }
    }

    private func clearPendingInitialStates() {
        pendingInitialTriggers.removeAll()
        initialStateAttemptsLeft.removeAll()
        initialStateTimer?.invalidate()
        initialStateTimer = nil
    }

    /// Asks Core Location again for every zone still waiting for its initial state.
    private func retryPendingInitialStates() {
        guard !pendingInitialTriggers.isEmpty else { return }
        for region in locationManager.monitoredRegions where pendingInitialTriggers[region.identifier] != nil {
            locationManager.requestState(for: region)
        }
    }

    private func scheduleInitialStateRetry() {
        guard initialStateTimer == nil else { return }
        initialStateTimer = Timer.scheduledTimer(
            withTimeInterval: GeofenceForegroundServicePlugin.initialStateRetryInterval,
            repeats: true
        ) { [weak self] _ in
            self?.initialStateRetryTick()
        }
    }

    private func initialStateRetryTick() {
        for zoneId in Array(pendingInitialTriggers.keys) {
            let left = (initialStateAttemptsLeft[zoneId] ?? 0) - 1
            if left <= 0 {
                // Give up: the state stays unknown until the first enter or exit.
                clearPendingInitialState(for: zoneId)
            } else {
                initialStateAttemptsLeft[zoneId] = left
            }
        }
        retryPendingInitialStates()
    }
}

private enum GeofenceTrigger {
    static let enter = 1
    static let exit = 2
}

extension GeofenceForegroundServicePlugin: CLLocationManagerDelegate {
    // Implement CLLocationManagerDelegate methods here
    // For example:

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // A first fix may be what a zone was waiting for to learn whether the device is inside.
        retryPendingInitialStates()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }

    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        // Raised asynchronously (e.g. region limit, no authorization), after addGeofence has
        // already answered, so the best we can do is stop waiting on its initial trigger.
        print("Region monitoring failed for \(region?.identifier ?? "unknown"): \(error)")
        if let identifier = region?.identifier {
            clearPendingInitialState(for: identifier)
            startedZoneIds.remove(identifier)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let initialTrigger = pendingInitialTriggers[region.identifier],
              let circular = region as? CLCircularRegion else {
            return
        }

        // `.unknown` means no answer yet: keep waiting instead of dropping the initial state.
        if state == .unknown {
            return
        }
        clearPendingInitialState(for: region.identifier)

        if state == .inside && initialTrigger & GeofenceTrigger.enter != 0 && circular.notifyOnEntry {
            eventHandler(zoneID: region.identifier, triggerType: GeofenceTrigger.enter)
        } else if state == .outside && initialTrigger & GeofenceTrigger.exit != 0 && circular.notifyOnExit {
            eventHandler(zoneID: region.identifier, triggerType: GeofenceTrigger.exit)
        }
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
