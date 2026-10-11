package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.ForegroundServiceStartNotAllowedException
import android.app.Service
import android.app.Service.STOP_FOREGROUND_DETACH
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.content.pm.ServiceInfo
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
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

class GeofenceForegroundService : Service() {
    private lateinit var fusedLocationProviderClient: FusedLocationProviderClient
    // Null when the app asked for no location updates (LocationUpdateMode.off).
    private var locationRequest: LocationRequest? = null
    private lateinit var locationCallback: LocationCallback

    private var permissionReceiverRegistered: Boolean = false
    private var stoppingForMissingBackgroundPermission: Boolean = false

    // The service is always started through startForegroundService (directly or via the geofence
    // PendingIntent), so every start must reach startForeground() within a few seconds or the
    // system throws ForegroundServiceDidNotStartInTimeException.
    private var isForegroundStarted: Boolean = false

    private val permissionChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // Best-effort only; PROVIDERS_CHANGED does not cover all revocation paths.
            if (!hasBackgroundLocationPermission()) {
                handleBackgroundPermissionLost("BroadcastReceiver (${intent?.action})")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()

        fusedLocationProviderClient =
            LocationServices.getFusedLocationProviderClient(this)

        locationRequest = when (SharedPreferenceHelper.getLocationUpdateMode(this)) {
            "off" -> null
            "balanced" -> LocationRequest.Builder(
                Priority.PRIORITY_BALANCED_POWER_ACCURACY,
                TimeUnit.SECONDS.toMillis(60)
            ).apply {
                setMinUpdateDistanceMeters(100f)
                setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
            }.build()
            else -> LocationRequest.Builder(
                Priority.PRIORITY_HIGH_ACCURACY,
                TimeUnit.SECONDS.toMillis(20)
            ).apply {
                setMinUpdateDistanceMeters(100f)
                setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
                setWaitForAccurateLocation(true)
            }.build()
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)
                if (!hasBackgroundLocationPermission()) {
                    handleBackgroundPermissionLost("LocationCallback")
                    return
                }
            }
        }

        val filter = IntentFilter("android.location.PROVIDERS_CHANGED")
        try {
            ContextCompat.registerReceiver(
                this,
                permissionChangeReceiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
            permissionReceiverRegistered = true
        } catch (e: Exception) {
            Log.w("GeofenceService", "Could not register PROVIDERS_CHANGED receiver", e)
        }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!hasBackgroundLocationPermission()) {
            ensureForegroundStarted()
            handleBackgroundPermissionLost("onStartCommand")
            return START_NOT_STICKY
        }

        // Retrieve the intent or recreate it using stored configuration if the intent is null.
        val actualIntent = intent ?: run {
            val storedConfig = SharedPreferenceHelper.getServiceConfig(applicationContext)
            if (storedConfig == null) {
                return stopSelfAndNotSticky()
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
        if (actionStr.isNullOrBlank()) {
            Log.e("GeofenceService", "Missing geofence action extra")
            return stopSelfAndNotSticky()
        }
        val geofenceAction = try {
            GeofenceServiceAction.valueOf(actionStr)
        } catch (e: IllegalArgumentException) {
            Log.e("GeofenceService", "Invalid geofence action: $actionStr", e)
            return stopSelfAndNotSticky()
        }

        when (geofenceAction) {
            GeofenceServiceAction.SETUP -> {
                // Extract notification and service configuration details from the intent
                val appIcon: Int = actualIntent.getIntExtra(
                    applicationContext.extraNameGen(Constants.appIcon), 0
                )
                val notificationChannelId = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.channelId)
                ) ?: return stopSelfAndNotSticky()
                val notificationContentTitle = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.contentTitle)
                ) ?: return stopSelfAndNotSticky()
                val notificationContentText = actualIntent.getStringExtra(
                    applicationContext.extraNameGen(Constants.contentText)
                ) ?: return stopSelfAndNotSticky()
                // The plugin sends the id under a package-prefixed name; the stored-config rebuild
                // uses the bare one.
                val serviceId: Int = actualIntent.getIntExtra(
                    applicationContext.extraNameGen(Constants.serviceId),
                    actualIntent.getIntExtra(Constants.serviceId, 525600)
                )

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

                val startedInForeground = startAsForeground(
                    notificationChannelId,
                    notificationContentTitle,
                    notificationContentText,
                    appIcon,
                    serviceId
                )
                if (!startedInForeground) {
                    stopSelf()
                    return START_NOT_STICKY
                }
            }

            GeofenceServiceAction.TRIGGER -> {
                // A trigger can cold-start this service after the system killed it, in which case
                // there is no SETUP delivery to promote it to the foreground first.
                if (!isForegroundStarted) {
                    startForegroundFromStoredConfig()
                }
                handleGeofenceEvent(actualIntent)

                // The event is handed to WorkManager above, which does not need this service.
                // Do not leave a service running that the system refused to promote.
                if (!isForegroundStarted) {
                    stopSelf()
                    return START_NOT_STICKY
                }
            }

            GeofenceServiceAction.STOP -> {
                // Stop the foreground service and clean up resources
                Log.d("GeofenceService", "STOP action received")
                SharedPreferenceHelper.setServiceActive(applicationContext, false)
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        // Return START_STICKY to ensure the service is restarted if killed by the system
        return START_STICKY
    }

    private fun handleGeofenceEvent(intent: Intent) {
        if (!hasBackgroundLocationPermission()) {
            handleBackgroundPermissionLost("handleGeofenceEvent")
            return
        }
        try {
            val isInDebugMode =
                SharedPreferenceHelper.getIsInDebugMode(applicationContext)

            val geofencingEvent = GeofencingEvent.fromIntent(intent)
            Log.d(
                "GeofenceService",
                "Geofence trigger: event=${geofencingEvent != null}, " +
                    "error=${geofencingEvent?.errorCode}, " +
                    "transition=${geofencingEvent?.geofenceTransition}, " +
                    "zones=${geofencingEvent?.triggeringGeofences?.map { it.requestId }}"
            )
            if (geofencingEvent?.hasError() == false) {
                val geofenceTransition = geofencingEvent.geofenceTransition

                // Several geofences can fire for one transition (overlapping zones); every one
                // of them must reach Dart, not only the first.
                val triggeringGeoFences = geofencingEvent.triggeringGeofences.orEmpty()

                triggeringGeoFences.map { it.requestId }.distinct().forEach { zoneID ->
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
            Log.e("GeofenceService", "Failed to handle geofence event", e)
        }
    }

    override fun onDestroy() {
        Log.d("GeofenceService", "Cleaning up Geofence service...")
        unsubscribeToLocationUpdates()
        stopForeground(true)

        if (permissionReceiverRegistered) {
            try {
                unregisterReceiver(permissionChangeReceiver)
            } catch (e: IllegalArgumentException) {
                Log.w("GeofenceService", "Receiver already unregistered", e)
            }
            permissionReceiverRegistered = false
        }

        super.onDestroy()
    }

    private fun handleBackgroundPermissionLost(source: String) {
        if (stoppingForMissingBackgroundPermission) return
        stoppingForMissingBackgroundPermission = true
        Log.w("GeofenceService", "Background location permission missing ($source). Stopping service.")
        SharedPreferenceHelper.setServiceActive(applicationContext, false)
        notifyPermissionRequired()
        stopSelf()
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
        val channelId = "${packageName}.geofence_permission_required"
        val notificationId = 500_000 + (packageName.hashCode() and 0x7FFF)
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

        notificationManager.notify(notificationId, notification)
    }

    /**
     * Returns false when the system refuses to promote the service. That happens on Android 12+
     * when the service is restarted from the background (a sticky restart delivers a null intent
     * and has no foreground-start exemption); geofence PendingIntent deliveries are exempt.
     */
    private fun startAsForeground(
        notificationChannelId: String,
        contentTitle: String,
        contentText: String,
        appIcon: Int,
        serviceId: Int
    ): Boolean {
        // Build and configure the foreground service notification
        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSmallIcon(appIcon)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .build()

        // Reset foreground state so repeated SETUP deliveries replace the notification cleanly
        stopForeground(STOP_FOREGROUND_DETACH)

        try {
            // Start the service in the foreground with the notification
            startForeground(serviceId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } catch (e: Exception) {
            if (isForegroundStartNotAllowed(e)) {
                Log.w("GeofenceService", "Not allowed to start in the foreground from the background; stopping", e)
                return false
            }
            throw e
        }
        isForegroundStarted = true
        SharedPreferenceHelper.setServiceActive(applicationContext, true)

        // Start location updates for geofencing
        subscribeToLocationUpdates()
        return true
    }

    private fun isForegroundStartNotAllowed(e: Exception): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            e is ForegroundServiceStartNotAllowedException

    private fun startForegroundFromStoredConfig() {
        val config = SharedPreferenceHelper.getServiceConfig(applicationContext)
        if (config == null) {
            ensureForegroundStarted()
            return
        }
        try {
            startAsForeground(
                config.channelId,
                config.contentTitle,
                config.contentText,
                config.appIcon,
                config.serviceId
            )
        } catch (e: Exception) {
            Log.w("GeofenceService", "Could not restore foreground notification from stored config", e)
            ensureForegroundStarted()
        }
    }

    /**
     * Promotes the service to the foreground with a minimal notification. Used on paths that are
     * about to stop the service, so that the pending startForegroundService() call is satisfied
     * instead of crashing the app.
     */
    private fun ensureForegroundStarted() {
        if (isForegroundStarted) return

        val channelId = "${packageName}.geofence_permission_required"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(
            NotificationChannel(channelId, "Permission Required", NotificationManager.IMPORTANCE_HIGH)
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Geofence service")
            .setContentText("Geofence service is stopping.")
            .build()

        val placeholderId = 500_000 + (packageName.hashCode() and 0x7FFF) + 1
        try {
            startForeground(placeholderId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            isForegroundStarted = true
        } catch (e: Exception) {
            // e.g. SecurityException when the location permission was revoked; the typeless
            // overload still satisfies the startForegroundService() contract on most versions.
            try {
                startForeground(placeholderId, notification)
                isForegroundStarted = true
            } catch (inner: Exception) {
                Log.e("GeofenceService", "Could not enter the foreground before stopping", inner)
            }
        }
    }

    private fun stopSelfAndNotSticky(): Int {
        ensureForegroundStarted()
        stopSelf()
        return START_NOT_STICKY
    }

    private fun subscribeToLocationUpdates() {
        val request = locationRequest ?: return
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
            request,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    private fun unsubscribeToLocationUpdates() {
        val removeTask = fusedLocationProviderClient.removeLocationUpdates(locationCallback)
        removeTask.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d("Unsubscribe", "Location Callback removed.")
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