package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import com.f2fk.geofence_foreground_service.builders.GeofenceBuilder
import com.f2fk.geofence_foreground_service.builders.GeofencingRequestBuilder
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.f2fk.geofence_foreground_service.utils.ZoneCodec
import com.f2fk.geofence_foreground_service.utils.extraNameGen
import com.google.android.gms.location.LocationServices

/**
 * Single place that registers a [Zone] with Google Play services. Used by the method channel
 * handler and by [GeofenceRestorer] so both produce identical registrations.
 */
object GeofenceRegistrar {
    const val ERROR_NOT_INITIALIZED = "1"
    const val ERROR_PERMISSION_DENIED = "permission_denied"
    const val ERROR_INVALID_ZONE = "invalid_zone"
    const val ERROR_REGISTER_FAILURE = "525601"

    /** Invoked exactly once with (success, errorCode, message, details). */
    fun register(
        context: Context,
        zone: Zone,
        done: (success: Boolean, code: String, message: String?, details: Any?) -> Unit
    ) {
        if (!SharedPreferenceHelper.hasCallbackHandle(context)) {
            done(
                false,
                ERROR_NOT_INITIALIZED,
                "You have not properly initialized the Flutter Geofence foreground service Plugin. " +
                    "You should ensure you have called the 'startGeofencingService' function first! " +
                    "The `callbackDispatcher` is a top level function. See example in repository.",
                null
            )
            return
        }

        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            done(false, ERROR_PERMISSION_DENIED, "ACCESS_FINE_LOCATION permission is not granted.", null)
            return
        }

        val geofence = try {
            GeofenceBuilder(zone).build()
        } catch (e: IllegalArgumentException) {
            done(false, ERROR_INVALID_ZONE, e.message, null)
            return
        }

        val request = GeofencingRequestBuilder(geofence, zone.initialTrigger).build()
        val pendingIntent = pendingIntent(context, zone.zoneId)

        LocationServices.getGeofencingClient(context)
            .addGeofences(request, pendingIntent)
            .addOnSuccessListener {
                SharedPreferenceHelper.addRegisteredGeofenceZoneId(context, zone.zoneId)
                SharedPreferenceHelper.saveStoredZone(context, zone.zoneId, ZoneCodec.encode(zone))
                done(true, "", null, null)
            }
            .addOnFailureListener { e ->
                done(false, ERROR_REGISTER_FAILURE, e.message, e.stackTraceToString())
            }
    }

    /** Intent delivered to [GeofenceForegroundService] when a transition fires. */
    private fun triggerIntent(context: Context): Intent =
        Intent(context, GeofenceForegroundService::class.java)
            .putExtra(context.extraNameGen(Constants.geofenceAction), GeofenceServiceAction.TRIGGER.toString())

    // The request code must be stable per zone so each registration owns its PendingIntent;
    // requestCode 0 with identical Intents would collapse under FLAG_UPDATE_CURRENT.
    private fun pendingIntent(context: Context, zoneId: String): PendingIntent =
        PendingIntent.getForegroundService(
            context,
            SharedPreferenceHelper.getOrCreateRequestCode(context, zoneId),
            triggerIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
}
