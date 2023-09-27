#ifndef FLUTTER_PLUGIN_GEOFENCE_FOREGROUND_SERVICE_PLUGIN_H_
#define FLUTTER_PLUGIN_GEOFENCE_FOREGROUND_SERVICE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace geofence_foreground_service {

class GeofenceForegroundServicePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GeofenceForegroundServicePlugin();

  virtual ~GeofenceForegroundServicePlugin();

  // Disallow copy and assign.
  GeofenceForegroundServicePlugin(const GeofenceForegroundServicePlugin&) = delete;
  GeofenceForegroundServicePlugin& operator=(const GeofenceForegroundServicePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace geofence_foreground_service

#endif  // FLUTTER_PLUGIN_GEOFENCE_FOREGROUND_SERVICE_PLUGIN_H_
