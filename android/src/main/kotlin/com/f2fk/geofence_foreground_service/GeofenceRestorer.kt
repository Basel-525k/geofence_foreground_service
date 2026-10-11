package com.f2fk.geofence_foreground_service

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.f2fk.geofence_foreground_service.utils.ZoneCodec
import com.f2fk.geofence_foreground_service.utils.extraNameGen
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * Re-registers persisted zones. Google Play services drops geofences on reboot and on app
 * update, so without this a device restart silently stops all geofencing.
 */
object GeofenceRestorer {
    private const val TAG = "GeofenceRestorer"

    // BroadcastReceiver.goAsync() gives roughly 10 seconds; stay safely under it.
    private const val TIMEOUT_MS = 8_000L

    fun restore(context: Context, onComplete: () -> Unit) {
        val appContext = context.applicationContext
        val finished = AtomicBoolean(false)
        val finish = {
            if (finished.compareAndSet(false, true)) onComplete()
        }

        val zones = SharedPreferenceHelper.getStoredZones(appContext)
        if (zones.isEmpty()) {
            restartServiceIfNeeded(appContext)
            finish()
            return
        }

        Handler(Looper.getMainLooper()).postDelayed({
            if (!finished.get()) {
                Log.w(TAG, "Timed out while restoring geofences")
                finish()
            }
        }, TIMEOUT_MS)

        val remaining = AtomicInteger(zones.size)
        zones.forEach { (zoneId, json) ->
            val zone = try {
                ZoneCodec.decode(json)
            } catch (e: Exception) {
                Log.e(TAG, "Dropping unreadable stored zone $zoneId", e)
                SharedPreferenceHelper.removeStoredZone(appContext, zoneId)
                if (remaining.decrementAndGet() == 0) {
                    restartServiceIfNeeded(appContext)
                    finish()
                }
                return@forEach
            }

            GeofenceRegistrar.register(appContext, zone) { success, code, message, _ ->
                if (success) {
                    Log.i(TAG, "Restored geofence $zoneId")
                } else {
                    Log.w(TAG, "Could not restore zone $zoneId ($code): $message")
                }
                if (remaining.decrementAndGet() == 0) {
                    restartServiceIfNeeded(appContext)
                    finish()
                }
            }
        }
    }

    /**
     * Best effort: bring the service back if the user had it running. Android may refuse a
     * foreground start from the background; the service handles that and stops cleanly, and
     * geofence transitions will start it again.
     */
    private fun restartServiceIfNeeded(context: Context) {
        if (!SharedPreferenceHelper.isServiceActive(context)) return
        val config = SharedPreferenceHelper.getServiceConfig(context) ?: return
        try {
            val intent = Intent(context, GeofenceForegroundService::class.java)
                .putExtra(context.extraNameGen(Constants.geofenceAction), GeofenceServiceAction.SETUP.toString())
                .putExtra(context.extraNameGen(Constants.appIcon), config.appIcon)
                .putExtra(context.extraNameGen(Constants.channelId), config.channelId)
                .putExtra(context.extraNameGen(Constants.contentTitle), config.contentTitle)
                .putExtra(context.extraNameGen(Constants.contentText), config.contentText)
                .putExtra(Constants.serviceId, config.serviceId)
            ContextCompat.startForegroundService(context, intent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not restart the geofence service", e)
        }
    }
}
