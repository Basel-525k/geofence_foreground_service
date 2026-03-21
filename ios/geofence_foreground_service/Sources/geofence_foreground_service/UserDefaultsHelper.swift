import Foundation

struct UserDefaultsHelper {

    // MARK: Properties

    private static let userDefaults = UserDefaults(suiteName: "\(GeofenceForegroundServicePlugin.identifier).userDefaults")!

    enum Key {
        case callbackHandle
        case isDebug

        var stringValue: String {
            return "\(GeofenceForegroundServicePlugin.identifier).\(self)"
        }
    }

    // MARK: callbackHandle

    static func storeCallbackHandle(_ handle: Int64) {
       store(handle, key: .callbackHandle)
    }

    static func getStoredCallbackHandle() -> Int64? {
        return getValue(for: .callbackHandle)
    }

    // MARK: isDebug

    static func storeIsDebug(_ isDebug: Bool) {
        store(isDebug, key: .isDebug)
    }

    static func getIsDebug() -> Bool {
        return getValue(for: .isDebug) ?? false
    }

    // MARK: Private helper functions

    private static func store<T>(_ value: T, key: Key) {
        userDefaults.setValue(value, forKey: key.stringValue)
    }

    private static func getValue<T>(for key: Key) -> T? {
        return userDefaults.value(forKey: key.stringValue) as? T
    }

}
