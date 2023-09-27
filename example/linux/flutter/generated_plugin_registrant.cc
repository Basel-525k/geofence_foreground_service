//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <geofence_foreground_service/geofence_foreground_service_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) geofence_foreground_service_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "GeofenceForegroundServicePlugin");
  geofence_foreground_service_plugin_register_with_registrar(geofence_foreground_service_registrar);
}
