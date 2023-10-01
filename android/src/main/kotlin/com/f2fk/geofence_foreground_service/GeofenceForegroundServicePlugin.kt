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
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.models.ZonesList
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.f2fk.geofence_foreground_service.utils.calculateCenter
import com.f2fk.geofence_foreground_service.utils.extraNameGen
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
import io.flutter.plugin.common.PluginRegistry

/** GeofenceForegroundServicePlugin */
class GeofenceForegroundServicePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        const val geofenceRegisterFailure: Int = 525601

        var pluginRegistryCallback: PluginRegistry.PluginRegistrantCallback? = null
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var serviceIntent: Intent

    private var channelId: String? = null
    private var contentTitle: String? = null
    private var contentText: String? = null
    private var serviceId: Int? = null

    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "be.byshy.geofence/foreground_geofence_foreground_service"
        )

        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startGeofencingService" -> {
                try {
                    SharedPreferenceHelper.saveCallbackDispatcherHandleKey(
                        context,
                        call.argument<Long>(Constants.callbackHandle)!!
                    )

                    serviceIntent = Intent(context, GeofenceForegroundService::class.java)

                    channelId = call.argument<String>(Constants.channelId)
                    contentTitle = call.argument<String>(Constants.contentTitle)
                    contentText = call.argument<String>(Constants.contentText)
                    serviceId = call.argument<Int>(Constants.serviceId)

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.geofenceAction),
                        GeofenceServiceAction.SETUP.toString()
                    )

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.appIcon),
                        getIconResIdFromAppInfo()
                    )

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.channelId),
                        channelId
                    )

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.contentTitle),
                        contentTitle
                    )

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.contentText),
                        contentText
                    )

                    serviceIntent.putExtra(
                        activity!!.extraNameGen(Constants.serviceId),
                        serviceId
                    )

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
                val zone: Zone = Zone.fromJson(call.arguments as Map<String, Any>)

                addGeofence(zone, result)
            }

            "addGeoFences" -> {
                val zonesList: ZonesList = ZonesList.fromJson(call.arguments as Map<String, Any>)

                addGeoFences(zonesList, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    fun stopGeofencingService() {}

    fun isForegroundServiceRunning() {}

    private fun addGeofence(zone: Zone, result: Result) {
        if (!SharedPreferenceHelper.hasCallbackHandle(context)) {
            result.error(
                "1",
                "You have not properly initialized the Flutter Geofence foreground service Plugin. " +
                        "You should ensure you have called the 'startGeofencingService' function first! " +
                        "The `callbackDispatcher` is a top level function. See example in repository.",
                null
            )
            return
        }

        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)

        val centerCoordinate: LatLng = calculateCenter(
            zone.coordinates ?: emptyList()
        )

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

        val geofenceIntent = Intent(context, GeofenceForegroundService::class.java)

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.geofenceAction),
            GeofenceServiceAction.TRIGGER.toString()
        )

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.appIcon),
            getIconResIdFromAppInfo()
        )

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.channelId),
            channelId
        )

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.contentTitle),
            contentTitle
        )

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.contentText),
            contentText
        )

        geofenceIntent.putExtra(
            activity!!.extraNameGen(Constants.serviceId),
            serviceId
        )

        val xId: String = System.currentTimeMillis().toString()
        geofenceIntent.action = xId

        val pendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                context,
                0,
                geofenceIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
        } else {
            PendingIntent.getService(
                context,
                0,
                geofenceIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
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
                result.success(true)
            }
            .addOnFailureListener {
                result.error(
                    geofenceRegisterFailure.toString(),
                    it.message,
                    it.stackTrace
                )
            }
    }

    private fun addGeoFences(zones: ZonesList, result: Result) {
        (zones.zones ?: emptyList()).forEach {
            addGeofence(it, result)
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

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {}

    private fun getIconResIdFromAppInfo(): Int {
        return try {
            val appInfo =
                activity!!.packageManager.getApplicationInfo(
                    activity!!.packageName,
                    PackageManager.GET_META_DATA
                )

            appInfo.icon
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("getIconResIdFromAppInfo", "getIconResIdFromAppInfo", e)
            0
        }
    }
}
