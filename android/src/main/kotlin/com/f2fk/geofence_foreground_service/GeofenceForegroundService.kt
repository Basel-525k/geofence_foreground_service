package com.f2fk.geofence_foreground_service

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.IS_IN_DEBUG_MODE_KEY
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.PAYLOAD_KEY
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.ZONE_ID
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.utils.extraNameGen
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.Granularity
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.util.concurrent.TimeUnit

private fun Context.workManager() = WorkManager.getInstance(this)

class GeofenceForegroundService : Service() {
    private lateinit var fusedLocationProviderClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback

    override fun onCreate() {
        super.onCreate()

        fusedLocationProviderClient =
            LocationServices.getFusedLocationProviderClient(this)

        locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            TimeUnit.SECONDS.toMillis(20)
        ).apply {
            setMinUpdateDistanceMeters(100f)
            setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
            setWaitForAccurateLocation(true)
        }
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)

                Log.d(
                    "onLocationResult",
                    "${locationResult.lastLocation?.latitude}, ${locationResult.lastLocation?.longitude}"
                )
            }
        }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val geofenceAction: GeofenceServiceAction = GeofenceServiceAction.valueOf(
            intent.getStringExtra(
                applicationContext!!.extraNameGen(Constants.geofenceAction)
            )!!
        )

        val appIcon: Int = intent.getIntExtra(
            applicationContext!!.extraNameGen(Constants.appIcon),
            0
        )

        val notificationChannelId: String = intent.getStringExtra(
            applicationContext!!.extraNameGen(Constants.channelId)
        )!!

        val notificationContentTitle: String = intent.getStringExtra(
            applicationContext!!.extraNameGen(Constants.contentTitle)
        )!!

        val notificationContentText: String = intent.getStringExtra(
            applicationContext!!.extraNameGen(Constants.contentText)
        )!!

        val notification: NotificationCompat.Builder = NotificationCompat
            .Builder(
                this.baseContext,
                notificationChannelId,
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSmallIcon(appIcon)
            .setContentTitle(notificationContentTitle)
            .setContentText(notificationContentText)

        if (geofenceAction == GeofenceServiceAction.SETUP) {
            subscribeToLocationUpdates()

            val serviceId: Int = intent.getIntExtra(
                Constants.serviceId,
                525600
            )

            stopForeground(STOP_FOREGROUND_DETACH)

            startForeground(
                serviceId,
                notification.build(),
                FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else if (geofenceAction == GeofenceServiceAction.TRIGGER) {
            handleGeofenceEvent(intent)
        }

        return START_STICKY
    }

    private fun handleGeofenceEvent(intent: Intent) {
        try {
            val isInDebugMode: Boolean = intent.getBooleanExtra(
                applicationContext!!.extraNameGen(Constants.isInDebugMode),
                false
            )

            val geofencingEvent = GeofencingEvent.fromIntent(intent)
            if (geofencingEvent?.hasError() == false) {
                val geofenceTransition = geofencingEvent.geofenceTransition

                val triggeringGeoFences = geofencingEvent.triggeringGeofences

                val zoneID: String? = triggeringGeoFences?.first()?.requestId

                if (zoneID != null) {
                    val oneOffTaskRequest =
                        OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
                            .setInputData(buildTaskInputData(
                                zoneID,
                                isInDebugMode,
                                geofenceTransition.toString()
                            ))
                            .build()

                    this.baseContext!!.workManager().enqueueUniqueWork(
                        Constants.bgTaskUniqueName,
                        ExistingWorkPolicy.APPEND_OR_REPLACE,
                        oneOffTaskRequest
                    )
                }
            }
        } catch (e: Exception) {
            println(e.message)
            println(e.toString())
        }
    }

    override fun onDestroy() {
        unsubscribeToLocationUpdates()

        super.onDestroy()
    }

    private fun subscribeToLocationUpdates() {
        fusedLocationProviderClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    private fun unsubscribeToLocationUpdates() {
        val removeTask = fusedLocationProviderClient.removeLocationUpdates(locationCallback)
        removeTask.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d("Unsubscribe", "Location Callback removed.")
                stopSelf()
            } else {
                Log.d("Unsubscribe", "Failed to remove Location Callback.")
            }
        }
    }

    private fun buildTaskInputData(
        zoneID: String,
        isInDebugMode: Boolean,
        payload: String?
    ): Data {
        return Data.Builder()
            .putString(ZONE_ID, zoneID)
            .putBoolean(IS_IN_DEBUG_MODE_KEY, isInDebugMode)
            .apply {
                payload?.let {
                    putString(PAYLOAD_KEY, payload)
                }
            }
            .build()
    }
}