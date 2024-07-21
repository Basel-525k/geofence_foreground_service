import Foundation
import Flutter

class BackgroundTaskOperation: Operation {
    private let flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
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

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)

        let worker = BackgroundWorker(
            zoneID: self.zoneID,
            triggerType: self.triggerType,
            flutterPluginRegistrantCallback: self.flutterPluginRegistrantCallback
        )

        DispatchQueue.main.async {
            worker.performBackgroundRequest { _ in
                semaphore.signal()
            }
        }

        semaphore.wait()
    }
}
