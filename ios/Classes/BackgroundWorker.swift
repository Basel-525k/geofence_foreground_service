import Foundation
import Flutter

class BackgroundWorker {
    let flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    private let zoneID: String
    private let triggerType: Int

    init(
        zoneID: String,
        triggerType: Int,
        flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    ) {
        self.zoneID = zoneID
        self.triggerType = triggerType
        self.flutterPluginRegistrantCallback = flutterPluginRegistrantCallback
    }

    private struct BackgroundChannel {
        static let name = "\(GeofenceForegroundServicePlugin.identifier)/background_geofence_foreground_service"
        static let initialized = "backgroundChannelInitialized"
        static let onResultSendCommand = "onResultSend"
    }

    /// The result is discardable due to how [BackgroundTaskOperation] works.
    @discardableResult
    func performBackgroundRequest(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard let callbackHandle = UserDefaultsHelper.getStoredCallbackHandle(),
            let flutterCallbackInformation = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
            else {
//                logError("[\(String(describing: self))] \(GFSError.pluginNotInitialized.message)")
                completionHandler(.failed)
                return false
        }

        let taskSessionStart = Date()
        let taskSessionIdentifier = UUID()

        let debugHelper = DebugNotificationHelper(taskSessionIdentifier)

        debugHelper.showStartFetchNotification(
            startDate: taskSessionStart,
            callBackHandle: callbackHandle,
            callbackInfo: flutterCallbackInformation
        )

        var flutterEngine: FlutterEngine? = FlutterEngine(
            name: "\(GeofenceForegroundServicePlugin.identifier).BackgroundFetch",
            project: nil,
            allowHeadlessExecution: true
        )

        flutterEngine!.run(
            withEntrypoint: flutterCallbackInformation.callbackName,
            libraryURI: flutterCallbackInformation.callbackLibraryPath
        )

        flutterPluginRegistrantCallback?(flutterEngine!)

        var backgroundMethodChannel: FlutterMethodChannel? = FlutterMethodChannel(
            name: BackgroundChannel.name,
            binaryMessenger: flutterEngine!.binaryMessenger
        )

        func cleanupFlutterResources() {
            flutterEngine?.destroyContext()
            backgroundMethodChannel = nil
            flutterEngine = nil
        }

        backgroundMethodChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case BackgroundChannel.initialized:
                result(true)    // Agree to Flutter's method invocation

                let arguments = [
                    "ps.byshy.geofence.ZONE_ID": self.zoneID,
                    "ps.byshy.geofence.INPUT_DATA": "\(self.triggerType)"
                ]

                backgroundMethodChannel?.invokeMethod(
                    BackgroundChannel.onResultSendCommand,
                    arguments: arguments,
                    result: { flutterResult in
                        cleanupFlutterResources()
                        let taskSessionCompleter = Date()
                        let result: UIBackgroundFetchResult = (flutterResult as? Bool ?? false) ? .newData : .failed
                        let taskDuration = taskSessionCompleter.timeIntervalSince(taskSessionStart)
//                        logInfo("[\(String(describing: self))] \(#function) -> performBackgroundRequest.\(result) (finished in \(taskDuration.formatToSeconds()))")

                        debugHelper.showCompletedFetchNotification(
                            completedDate: taskSessionCompleter,
                            result: result,
                            elapsedTime: taskDuration
                        )
                        completionHandler(result)
                    })
            default:
                result(GFSError.unhandledMethod(call.method).asFlutterError)
                cleanupFlutterResources()
                completionHandler(UIBackgroundFetchResult.failed)
            }
        }

        return true
    }
}
