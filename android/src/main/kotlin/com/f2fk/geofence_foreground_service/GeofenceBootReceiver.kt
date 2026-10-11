package com.f2fk.geofence_foreground_service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Re-registers geofences after a device reboot or an app update. */
class GeofenceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                val pendingResult = goAsync()
                GeofenceRestorer.restore(context) { pendingResult.finish() }
            }
        }
    }
}
