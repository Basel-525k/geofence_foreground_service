/// Function that executes your background work.
/// You should return whether the task ran successfully or not.
///
/// [zoneId] Returns the value you provided when registering the geofence.
/// iOS will pass [Workmanager.iOSBackgroundTask] (for background-fetch) or
/// custom task IDs for BGTaskScheduler based tasks.
///
/// The behavior for retries is different on each platform:
/// - Android: return `false` from the this method will reschedule the work
///   based on the policy given in [Workmanager.registerOneOffTask], for example
/// - iOS: The return value is ignored, but if work has failed, you can schedule
///   another attempt using [Workmanager.registerOneOffTask]. This depends on
///   BGTaskScheduler being set up correctly. Please follow the README for
///   instructions.
typedef BackgroundTriggerHandler = Future<bool> Function(
  String zoneId,
  int triggerType,
);
