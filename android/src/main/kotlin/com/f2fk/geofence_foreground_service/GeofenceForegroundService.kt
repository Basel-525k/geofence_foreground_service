package com.f2fk.geofence_foreground_service

import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class GeofenceForegroundService : Service() {
    private var serviceId: Int = 525000

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val pm = applicationContext.packageManager

        val notificationChannelId: String = intent.getStringExtra(Constants.channelId)!!
        val notificationContentTitle: String = intent.getStringExtra(Constants.contentTitle)!!
        val notificationContentText: String = intent.getStringExtra(Constants.contentText)!!
        serviceId = intent.getIntExtra(Constants.serviceId, serviceId)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        }

        val notification: NotificationCompat.Builder = NotificationCompat
            .Builder(
                this.baseContext,
                notificationChannelId,
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSmallIcon(getIconResIdFromAppInfo(pm))
            .setContentTitle(notificationContentTitle)
            .setContentText(notificationContentText)

        startForeground(serviceId, notification.build())

        handleGeofenceEvent(notification, intent)

        return super.onStartCommand(intent, flags, startId)
    }



    private fun handleGeofenceEvent(notification: NotificationCompat.Builder, intent: Intent) {
        try {
            val geofencingEvent = GeofencingEvent.fromIntent(intent)
            if (geofencingEvent?.hasError() == false) {
                val geofenceTransition = geofencingEvent.geofenceTransition

                if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) {
                    notification.setContentText("Entered the zone, IN")
                    /**
                     * The user is inside a geofence now
                     */
//                    requestTripUseCase.execute(
//                        Triple(
//                            geofencingEvent.triggeringGeofences!!.first().requestId,
//                            geofencingEvent.triggeringLocation!!.latitude,
//                            geofencingEvent.triggeringLocation!!.longitude
//                        )
//                    )
                } else if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
                    notification.setContentText("Exited the zone, OUT")
                }

                startForeground(serviceId, notification.build())
            }
        } catch (e: Exception) {
            println(e.message)
            println(e.toString())
        }
    }

    private fun getIconResIdFromAppInfo(pm: PackageManager): Int {
        return try {
            val appInfo =
                pm.getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
            appInfo.icon
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("getIconResIdFromAppInfo", "getIconResIdFromAppInfo", e)
            0
        }
    }
}