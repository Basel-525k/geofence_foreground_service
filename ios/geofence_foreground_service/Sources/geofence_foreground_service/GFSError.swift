import Foundation
import Flutter

enum GFSError: Error {
    case invalidParameters
    case methodChannelNotSet
    case unhandledMethod(_ methodName: String)
    case unexpectedMethodArguments(_ argumentsDescription: String)
    case pluginNotInitialized

    var code: String {
        return "\(self) error"
    }

    var message: String {
        switch self {
        case .invalidParameters:
            return "Invalid parameters passed"
        case .methodChannelNotSet:
            return "Method channel not set"
        case .unhandledMethod(let methodName):
            return "Unhandled method \(methodName)"
        case .unexpectedMethodArguments(let argumentsDescription):
            return "Unexpected call arguments \(argumentsDescription)"
        case .pluginNotInitialized:
            return  """
            You should ensure you have called the 'startGeofencingService' function first!
            Example:
            `GeofenceForegroundService().startGeofencingService(
              callbackDispatcher: callbackDispatcher,
            )`

            The `callbackDispatcher` is a top level function. See example in repository.
            """
        }
    }

    var details: Any? {
        return nil
    }

    var asFlutterError: FlutterError {
        return FlutterError(code: code, message: message, details: details)
    }
}
