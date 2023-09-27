#include <flutter_linux/flutter_linux.h>

#include "include/geofence_foreground_service/geofence_foreground_service_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Handles the getPlatformVersion method call.
FlMethodResponse *get_platform_version();
