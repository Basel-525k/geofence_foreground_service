package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Context.ACTIVITY_SERVICE
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.f2fk.geofence_foreground_service.builders.GeofenceBuilder
import com.f2fk.geofence_foreground_service.builders.GeofencingRequestBuilder
import com.f2fk.geofence_foreground_service.enums.GeofenceServiceAction
import com.f2fk.geofence_foreground_service.models.NotificationIconData
import com.f2fk.geofence_foreground_service.models.Zone
import com.f2fk.geofence_foreground_service.models.ZonesList
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.f2fk.geofence_foreground_service.utils.Utils
import com.f2fk.geofence_foreground_service.utils.extraNameGen
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

@Suppress("DEPRECATION") // Deprecated for third party Services.
fun <T> Context.isServiceRunning(service: Class<T>) =
    (getSystemService(ACTIVITY_SERVICE) as ActivityManager)
        .getRunningServices(Integer.MAX_VALUE)
        .any { it.service.className == service.name }

/** GeofenceForegroundServicePlugin */
class GeofenceForegroundServicePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        const val geofenceRegisterFailure: Int = 525601
        const val geofenceRemoveFailure: Int = 525602
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var serviceIntent: Intent

    private var channelId: String? = null
    private var contentTitle: String? = null
    private var contentText: String? = null
    private var serviceId: Int? = null

    private var isInDebugMode: Boolean = false
    private var iconData: NotificationIconData? = null

    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "ps.byshy.geofence/foreground_geofence_foreground_service"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
        ApiMethods.startGeofencingService -> startGeofencingService(call, result)
        ApiMethods.stopGeofencingService -> stopGeofencingService(result)
        ApiMethods.isForegroundServiceRunning -> result.success(context.isServiceRunning(GeofenceForegroundService::class.java))
        ApiMethods.addGeofence -> addGeofence(Zone.fromJson(argumentsMap(call.arguments)), result)
        ApiMethods.addGeoFences -> addGeoFences(ZonesList.fromJson(argumentsMap(call.arguments)), result)
        ApiMethods.removeGeofence -> removeGeofence(listOf(call.argument(Constants.zoneId)!!), result)
        else -> result.notImplemented()
    }

    private fun startGeofencingService(call: MethodCall, result: Result) {
        try {
            SharedPreferenceHelper.saveCallbackDispatcherHandleKey(
                context,
                call.argument<Long>(Constants.callbackHandle)!!
            )

            channelId = call.argument<String>(Constants.channelId)
            contentTitle = call.argument<String>(Constants.contentTitle)
            contentText = call.argument<String>(Constants.contentText)
            serviceId = call.argument<Int>(Constants.serviceId)
            isInDebugMode = call.argument<Boolean>(Constants.isInDebugMode) ?: false

            val iconDataJson: Map<String, Any>? = call.argument<Map<String, Any>>(
                Constants.iconData
            )
            if (iconDataJson != null) {
                iconData = NotificationIconData.fromJson(iconDataJson)
            }
            serviceIntent = serviceIntent(GeofenceServiceAction.SETUP.toString())
            val channel = NotificationChannel(
                channelId,
                "Geofence foreground service",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "A channel for receiving geofencing notifications"

            val notificationManager =
                activity?.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            notificationManager.createNotificationChannel(channel)

            ContextCompat.startForegroundService(context, serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun stopGeofencingService(result: Result) {
        try {
            val stopIntent = Intent(context, GeofenceForegroundService::class.java).apply {
                putExtra(context.extraNameGen(Constants.geofenceAction), GeofenceServiceAction.STOP.name)
            }
            context.startService(stopIntent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun serviceIntent(geofenceAction: String) : Intent =
        Intent(context, GeofenceForegroundService::class.java)
            .putExtra(activity!!.extraNameGen(Constants.isInDebugMode), isInDebugMode)
            .putExtra(activity!!.extraNameGen(Constants.geofenceAction), geofenceAction)
            .putExtra(activity!!.extraNameGen(Constants.appIcon), getIconResId(iconData))
            .putExtra(activity!!.extraNameGen(Constants.channelId), channelId)
            .putExtra(activity!!.extraNameGen(Constants.contentTitle), contentTitle)
            .putExtra(activity!!.extraNameGen(Constants.contentText), contentText)
            .putExtra(activity!!.extraNameGen(Constants.serviceId), serviceId)

    // Build the pending intent for the intent service
    private fun servicePendingIntent(intent: Intent) : PendingIntent = PendingIntent.getForegroundService(
        context,
        0,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
    )

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
        val geofencingClient = LocationServices.getGeofencingClient(context)
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider the permission. See the documentation
            // for ActivityCompat#requestPermissions fr calling
            //            //    ActivityCompat#requestPermissions
            //            // here to request the missing permissions, and then overriding
            //            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //            //                                          int[] grantResults)
            //            // to handle the case where the user granor more details.
            return
        }

        val geofence = GeofenceBuilder(zone).build()
        val request = GeofencingRequestBuilder(geofence, zone.initialTrigger).build()
        val intent = serviceIntent(GeofenceServiceAction.TRIGGER.toString())
        intent.action = System.currentTimeMillis().toString()
        geofencingClient.addGeofences(request, servicePendingIntent(intent))
            .addOnSuccessListener {
                result.success(true)
            }.addOnFailureListener { e ->
                result.error(
                    geofenceRegisterFailure.toString(),
                    e.message,
                    e.stackTraceToString()
                )
            }
    }

    private fun addGeoFences(zones: ZonesList, result: Result) {
        (zones.zones ?: emptyList()).forEach { addGeofence(it, result) }
    }

    private fun removeGeofence(geofenceRequestIds: List<String>, result: Result) {
        geofencingClient().removeGeofences(geofenceRequestIds).addOnSuccessListener {
            result.success(true)
        }.addOnFailureListener { e: java.lang.Exception? ->
            result.error(geofenceRemoveFailure.toString(), e?.message, e?.stackTrace)
        }
    }

    private fun geofencingClient() : GeofencingClient = LocationServices.getGeofencingClient(context)

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

    private fun getIconResId(iconData: NotificationIconData?): Int {
        return if (iconData == null) {
            getIconResIdFromAppInfo()
        } else {
            getIconResIdFromIconData(iconData)
        }
    }

    private fun getIconResIdFromIconData(iconData: NotificationIconData): Int {
        val resType = iconData.resType
        val resPrefix = iconData.resPrefix
        val name = iconData.name
        if (resType.isEmpty() || resPrefix.isEmpty() || name.isEmpty()) {
            return 0
        }

        val resName = if (resPrefix.contains("ic")) {
            String.format("ic_%s", name)
        } else {
            String.format("img_%s", name)
        }

        return activity!!.resources.getIdentifier(resName, resType, activity!!.packageName)
    }

    private fun getIconResIdFromAppInfo(): Int {
        return activity!!.applicationInfo.icon
    }

    private fun argumentsMap(arguments: Any?): Map<String, Any> {
        return arguments as? Map<String, Any> ?: emptyMap()
    }
}