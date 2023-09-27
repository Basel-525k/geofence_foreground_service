#include "include/geofence_foreground_service/geofence_foreground_service_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "geofence_foreground_service_plugin.h"

void GeofenceForegroundServicePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  geofence_foreground_service::GeofenceForegroundServicePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
