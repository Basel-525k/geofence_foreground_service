package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.utils.calculateCenter
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.model.LatLng

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** GeofenceForegroundServicePlugin */
class GeofenceForegroundServicePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "geofence_foreground_service")
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startGeofencingService" -> {
                try {
                    val serviceIntent = Intent(context, GeofenceForegroundService::class.java)

                    val channelId: String? = call.argument<String>("channel_id")

                    serviceIntent.putExtra(Constants.channelId, channelId)
                    serviceIntent.putExtra(
                        Constants.contentTitle,
                        call.argument<String>("content_title")
                    )
                    serviceIntent.putExtra(
                        Constants.contentText,
                        call.argument<String>("content_text")
                    )
                    serviceIntent.putExtra(Constants.serviceId, call.argument<Int?>("service_id"))

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channelName = "Geofence foreground service"
                        val channel = NotificationChannel(
                            channelId,
                            channelName,
                            NotificationManager.IMPORTANCE_HIGH
                        )

                        channel.description = "A channel for receiving geofencing notifications"

                        val notificationManager =
                            activity?.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                        notificationManager.createNotificationChannel(channel)
                    }

                    ContextCompat.startForegroundService(context, serviceIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            "addGeofence" -> {
                val rawZonesArray =
                    (call.argument("coordinates") ?: emptyList<Map<String, Double>>())
                val coordinates: ArrayList<LatLng> = ArrayList()

                rawZonesArray.forEach {
                    coordinates.add(
                        LatLng(
                            it["latitude"]!!,
                            it["longitude"]!!
                        )
                    )
                }

                val zone = Zone(
                    call.argument<String>("")!!,
                    call.argument<Float>("")!!,
                    coordinates,
                )

                addGeofence(zone)

                result.success("Android")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    fun stopGeofencingService() {}

    fun isForegroundServiceRunning() {}

    fun addGeofence(zone: Zone) {
        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)

        val centerCoordinate: LatLng =
            calculateCenter(zone.coordinates ?: emptyList())

        val geofence = Geofence.Builder()
            .setRequestId(zone.zoneId)
            .setCircularRegion(
                centerCoordinate.latitude,
                centerCoordinate.longitude,
                zone.radius
            )
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .setNotificationResponsiveness(1000)
            .build()

        geofencingRequest.addGeofence(geofence)

        val pendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                context,
                0,
                Intent(context, this::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            TODO("VERSION.SDK_INT < O")
        }

        val geofencingClient =
            LocationServices.getGeofencingClient(context)
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
//            return
        }

        geofencingClient.addGeofences(geofencingRequest.build(), pendingIntent)
            .addOnSuccessListener {
                println("Geofences added successfully")
            }
            .addOnFailureListener {
                println("Failed to add geofences")
            }
    }

    fun addGeoFences(zones: ArrayList<Zone>) {
        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)

        zones.forEach {
            val centerCoordinate: LatLng =
                calculateCenter(it.coordinates ?: emptyList())

            val geofence = Geofence.Builder()
                .setRequestId(it.zoneId)
                .setCircularRegion(
                    centerCoordinate.latitude,
                    centerCoordinate.longitude,
                    it.radius
                )
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                .setNotificationResponsiveness(1000)
                .build()

            geofencingRequest.addGeofence(geofence)
        }

        val pendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                context,
                0,
                Intent(context, this::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            TODO("VERSION.SDK_INT < O")
        }

        val geofencingClient =
            LocationServices.getGeofencingClient(context)
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
//            return
        }

        geofencingClient.addGeofences(geofencingRequest.build(), pendingIntent)
            .addOnSuccessListener {
                println("Geofences added successfully")
            }
            .addOnFailureListener {
                println("Failed to add geofences")
            }
    }

    fun removeGeofence() {}

    fun removeAllGeoFences() {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
