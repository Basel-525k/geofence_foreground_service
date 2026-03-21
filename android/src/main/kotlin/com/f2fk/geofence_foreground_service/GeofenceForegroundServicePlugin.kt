package com.f2fk.geofence_foreground_service

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Context.ACTIVITY_SERVICE
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
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
    private var activityBinding: ActivityPluginBinding? = null

    private var activityLifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null

    private fun ensureResumePermissionCallbacksRegistered() {
        if (activityLifecycleCallbacks != null) return
        val app = context.applicationContext as Application
        activityLifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(activity: Activity) {
                if (activity === activityBinding?.activity) {
                    maybeStopServiceIfBackgroundLocationRevoked()
                }
            }

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        }
        app.registerActivityLifecycleCallbacks(activityLifecycleCallbacks!!)
    }

    private fun unregisterResumePermissionCallbacks() {
        val cb = activityLifecycleCallbacks ?: return
        (context.applicationContext as Application).unregisterActivityLifecycleCallbacks(cb)
        activityLifecycleCallbacks = null
    }

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
        ApiMethods.removeAllGeoFences -> removeAllGeoFences(result)
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
            SharedPreferenceHelper.saveIsInDebugMode(context, isInDebugMode)

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
            sendStopServiceIntent()
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun sendStopServiceIntent() {
        val stopIntent = Intent(context, GeofenceForegroundService::class.java).apply {
            putExtra(context.extraNameGen(Constants.geofenceAction), GeofenceServiceAction.STOP.name)
        }
        context.startService(stopIntent)
    }

    private fun maybeStopServiceIfBackgroundLocationRevoked() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        if (!context.isServiceRunning(GeofenceForegroundService::class.java)) return
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            try {
                sendStopServiceIntent()
            } catch (_: Exception) {
            }
        }
    }

    private fun serviceIntent(geofenceAction: String) : Intent =
        Intent(context, GeofenceForegroundService::class.java)
            .putExtra(context.extraNameGen(Constants.geofenceAction), geofenceAction)
            .putExtra(context.extraNameGen(Constants.appIcon), getIconResId(iconData))
            .putExtra(context.extraNameGen(Constants.channelId), channelId)
            .putExtra(context.extraNameGen(Constants.contentTitle), contentTitle)
            .putExtra(context.extraNameGen(Constants.contentText), contentText)
            .putExtra(context.extraNameGen(Constants.serviceId), serviceId)

    // Build the pending intent for the intent service. [requestCode] must be stable per zone so each
    // geofence registration gets its own PendingIntent; requestCode 0 with identical Intents would
    // collapse under FLAG_UPDATE_CURRENT.
    private fun servicePendingIntent(intent: Intent, requestCode: Int) : PendingIntent =
        PendingIntent.getForegroundService(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

    private fun addGeofence(zone: Zone, result: Result) {
        addGeofenceAsync(zone) { success, code, message, details ->
            if (success) {
                result.success(true)
            } else {
                result.error(code, message, details)
            }
        }
    }

    /**
     * Registers one geofence; invokes [done] exactly once with (success, errorCode, message, details).
     * Used by both [addGeofence] and [addGeoFences] so the method channel [Result] is only completed once.
     */
    private fun addGeofenceAsync(
        zone: Zone,
        done: (success: Boolean, code: String, message: String?, details: Any?) -> Unit
    ) {
        if (!SharedPreferenceHelper.hasCallbackHandle(context)) {
            done(
                false,
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
            done(
                false,
                "permission_denied",
                "ACCESS_FINE_LOCATION permission is not granted.",
                null
            )
            return
        }

        val geofence = GeofenceBuilder(zone).build()
        val request = GeofencingRequestBuilder(geofence, zone.initialTrigger).build()
        val intent = serviceIntent(GeofenceServiceAction.TRIGGER.toString())
        val pendingIntentRequestCode = zone.zoneId.hashCode()
        geofencingClient.addGeofences(request, servicePendingIntent(intent, pendingIntentRequestCode))
            .addOnSuccessListener {
                SharedPreferenceHelper.addRegisteredGeofenceZoneId(context, zone.zoneId)
                done(true, "", null, null)
            }.addOnFailureListener { e ->
                done(
                    false,
                    geofenceRegisterFailure.toString(),
                    e.message,
                    e.stackTraceToString()
                )
            }
    }

    private fun addGeoFences(zones: ZonesList, result: Result) {
        val list = zones.zones ?: emptyList()
        if (list.isEmpty()) {
            result.success(true)
            return
        }
        fun addAt(index: Int) {
            if (index >= list.size) {
                result.success(true)
                return
            }
            addGeofenceAsync(list[index]) { success, code, message, details ->
                if (success) {
                    addAt(index + 1)
                } else {
                    result.error(code, message, details)
                }
            }
        }
        addAt(0)
    }

    private fun removeGeofence(geofenceRequestIds: List<String>, result: Result) {
        geofencingClient().removeGeofences(geofenceRequestIds).addOnSuccessListener {
            geofenceRequestIds.forEach { id ->
                SharedPreferenceHelper.removeRegisteredGeofenceZoneId(context, id)
            }
            result.success(true)
        }.addOnFailureListener { e: java.lang.Exception? ->
            result.error(geofenceRemoveFailure.toString(), e?.message, e?.stackTrace)
        }
    }

    private fun removeAllGeoFences(result: Result) {
        val zoneIds = SharedPreferenceHelper.getRegisteredGeofenceZoneIds(context).toList()
        if (zoneIds.isEmpty()) {
            result.success(true)
            return
        }
        geofencingClient().removeGeofences(zoneIds)
            .addOnSuccessListener {
                SharedPreferenceHelper.clearRegisteredGeofenceZoneIds(context)
                result.success(true)
            }.addOnFailureListener { e: java.lang.Exception? ->
                result.error(geofenceRemoveFailure.toString(), e?.message, e?.stackTrace)
            }
    }

    private fun geofencingClient() : GeofencingClient = LocationServices.getGeofencingClient(context)

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        unregisterResumePermissionCallbacks()
        activity = binding.activity
        activityBinding = binding
        ensureResumePermissionCallbacksRegistered()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregisterResumePermissionCallbacks()
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        unregisterResumePermissionCallbacks()
        activity = binding.activity
        activityBinding = binding
        ensureResumePermissionCallbacksRegistered()
    }

    override fun onDetachedFromActivity() {
        unregisterResumePermissionCallbacks()
        activityBinding = null
        activity = null
    }

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

        return context.resources.getIdentifier(resName, resType, context.packageName)
    }

    private fun getIconResIdFromAppInfo(): Int {
        return context.applicationInfo.icon
    }

    private fun argumentsMap(arguments: Any?): Map<String, Any> {
        return arguments as? Map<String, Any> ?: emptyMap()
    }
}
