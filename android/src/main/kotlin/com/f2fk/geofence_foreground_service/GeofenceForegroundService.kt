package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.content.pm.ServiceInfo
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import androidx.core.content.ContextCompat
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.IS_IN_DEBUG_MODE_KEY
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.PAYLOAD_KEY
import com.f2fk.geofence_foreground_service.BackgroundWorker.Companion.ZONE_ID
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.utils.extraNameGen
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.f2fk.geofence_foreground_service.utils.ServiceConfig
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
private var _startId: Int = 0

class GeofenceForegroundService : Service() {
    private lateinit var fusedLocationProviderClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback

    private val permissionChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (!hasBackgroundLocationPermission()) {
                Log.w("GeofenceService", "Background location permission revoked. Stopping service.")
                notifyPermissionRequired()
                stopSelf()
            }
        }
    }

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
        }.build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)
                Log.d("onLocationResult", "${locationResult.lastLocation?.latitude}, ${locationResult.lastLocation?.longitude}")
            }
        }

        // Register permission change receiver
        val filter = IntentFilter().apply {
            addAction("android.location.PROVIDERS_CHANGED")
            addAction("android.intent.action.PERMISSION_CHANGED")
        }
        registerReceiver(permissionChangeReceiver, filter)
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        _startId = startId

        if (!hasBackgroundLocationPermission()) {
            Log.w("GeofenceService", "Background location permission not granted. Stopping service.")
            notifyPermissionRequired()
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Check if background location permission is granted (required for Android 10 and above)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val hasBackgroundLocation = ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasBackgroundLocation) {
                Log.w("GeofenceService", "Background location permission not granted. Stopping service.")
                stopSelf()
                return START_NOT_STICKY
            }
        }

        // Retrieve the intent or recreate it using stored configuration if the intent is null.
        val actualIntent = intent ?: run {
            val storedConfig = SharedPreferenceHelper.getServiceConfig(applicationContext)
            if (storedConfig == null) {
                stopSelf()
                return START_NOT_STICKY
            }

            Intent(this, GeofenceForegroundService::class.java).apply {
                putExtra(applicationContext.extraNameGen(Constants.geofenceAction), GeofenceServiceAction.SETUP.toString())
                putExtra(applicationContext.extraNameGen(Constants.channelId), storedConfig.channelId)
                putExtra(applicationContext.extraNameGen(Constants.contentTitle), storedConfig.contentTitle)
                putExtra(applicationContext.extraNameGen(Constants.contentText), storedConfig.contentText)
                putExtra(applicationContext.extraNameGen(Constants.appIcon), storedConfig.appIcon)
                putExtra(Constants.serviceId, storedConfig.serviceId)
            }
        }

        // Extract and validate the geofence action from the intent, logging an error if invalid.
        val actionStr = actualIntent.getStringExtra(applicationContext.extraNameGen(Constants.geofenceAction))
        val geofenceAction = try {
            GeofenceServiceAction.valueOf(actionStr ?: return START_NOT_STICKY)
        } catch (e: IllegalArgumentException) {
            Log.e("GeofenceService", "Invalid geofence action: $actionStr")
            return START_NOT_STICKY
        }

        when (geofenceAction) {
            GeofenceServiceAction.SETUP -> {
                // Extract notification and service configuration details from the intent
                val appIcon: Int = actualIntent.getIntExtra(
                    applicationContext.extraNameGen(Constants.appIcon), 0
                )
                val notificationChannelId = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.channelId)
                ) ?: return START_NOT_STICKY
                val notificationContentTitle = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.contentTitle)
                ) ?: return START_NOT_STICKY
                val notificationContentText = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.contentText)
                ) ?: return START_NOT_STICKY
                val serviceId: Int = actualIntent.getIntExtra(Constants.serviceId, 525600)

                // Save the service configuration to shared preferences for future use
                SharedPreferenceHelper.saveServiceConfig(
                    applicationContext,
                    ServiceConfig(
                        channelId = notificationChannelId,
                        contentTitle = notificationContentTitle,
                        contentText = notificationContentText,
                        appIcon = appIcon,
                        serviceId = serviceId
                    )
                )

                // Build and configure the foreground service notification
                val notification = NotificationCompat.Builder(this, notificationChannelId)
                    .setOngoing(true)
                    .setOnlyAlertOnce(true)
                    .setSmallIcon(appIcon)
                    .setContentTitle(notificationContentTitle)
                    .setContentText(notificationContentText)
                    .build()

                // Start location updates for geofencing
                subscribeToLocationUpdates()

                // Start the service in the foreground with the notification
                startForeground(serviceId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            }

            GeofenceServiceAction.TRIGGER -> {
                // Handle geofence trigger events
                handleGeofenceEvent(actualIntent)
            }

            GeofenceServiceAction.STOP -> {
                // Stop the foreground service and clean up resources
                Log.d("GeofenceService", "STOP action received")
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        // Return START_STICKY to ensure the service is restarted if killed by the system
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
        Log.d("GeofenceService", "Cleaning up Geofence service...")
        unsubscribeToLocationUpdates()
        stopForeground(true)

        // Unregister permission change receiver
        unregisterReceiver(permissionChangeReceiver)

        super.onDestroy()
    }

    // Background permission check utility
    private fun Context.hasBackgroundLocationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    // Notify user that background permission is required
    private fun notifyPermissionRequired() {
        val channelId = "permission_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Permission Required",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Permission Required")
            .setContentText("Background location permission is required for geofencing.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(1001, notification)
    }

    private fun subscribeToLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return
        }
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
                stopSelf(_startId)
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