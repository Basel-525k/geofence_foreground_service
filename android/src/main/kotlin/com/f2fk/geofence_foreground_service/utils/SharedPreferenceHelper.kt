package com.f2fk.geofence_foreground_service.utils

import android.content.Context
import com.f2fk.geofence_foreground_service.Constants

data class ServiceConfig(
    val channelId: String,
    val contentTitle: String,
    val contentText: String,
    val appIcon: Int,
    val serviceId: Int
)

object SharedPreferenceHelper {
    private const val SHARED_PREFS_FILE_NAME = "geofence_foreground_service_plugin"
    private const val CALLBACK_DISPATCHER_HANDLE_KEY = "ps.byshy.geofence.CALLBACK_DISPATCHER_HANDLE_KEY"
    private const val SERVICE_CONFIG_KEY = "service_config"
    private const val REGISTERED_GEOFENCE_ZONE_IDS_KEY = "registered_geofence_zone_ids"
    private const val IS_IN_DEBUG_MODE_KEY = "is_in_debug_mode"
    private const val STORED_ZONES_KEY = "stored_zones"
    private const val NEXT_REQUEST_CODE_KEY = "next_request_code"
    private const val REQUEST_CODE_KEY_PREFIX = "request_code_"
    private const val SERVICE_ACTIVE_KEY = "service_active"
    private const val LOCATION_UPDATE_MODE_KEY = "location_update_mode"

    private fun Context.prefs() = getSharedPreferences(SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE)

    fun saveCallbackDispatcherHandleKey(ctx: Context, callbackHandle: Long) {
        ctx.prefs()
            .edit()
            .putLong(CALLBACK_DISPATCHER_HANDLE_KEY, callbackHandle)
            .apply()
    }

    fun getCallbackHandle(ctx: Context): Long {
        return ctx.prefs().getLong(CALLBACK_DISPATCHER_HANDLE_KEY, -1L)
    }

    fun hasCallbackHandle(ctx: Context) = ctx.prefs().contains(CALLBACK_DISPATCHER_HANDLE_KEY)

    fun saveIsInDebugMode(ctx: Context, value: Boolean) {
        ctx.prefs().edit().putBoolean(IS_IN_DEBUG_MODE_KEY, value).apply()
    }

    fun getIsInDebugMode(ctx: Context): Boolean =
        ctx.prefs().getBoolean(IS_IN_DEBUG_MODE_KEY, false)

    fun addRegisteredGeofenceZoneId(ctx: Context, zoneId: String) {
        val prefs = ctx.prefs()
        val current = prefs.getStringSet(REGISTERED_GEOFENCE_ZONE_IDS_KEY, null)?.toMutableSet() ?: mutableSetOf()
        current.add(zoneId)
        prefs.edit().putStringSet(REGISTERED_GEOFENCE_ZONE_IDS_KEY, current).apply()
    }

    fun removeRegisteredGeofenceZoneId(ctx: Context, zoneId: String) {
        val prefs = ctx.prefs()
        val current = prefs.getStringSet(REGISTERED_GEOFENCE_ZONE_IDS_KEY, null)?.toMutableSet() ?: mutableSetOf()
        current.remove(zoneId)
        prefs.edit().putStringSet(REGISTERED_GEOFENCE_ZONE_IDS_KEY, current).apply()
    }

    fun getRegisteredGeofenceZoneIds(ctx: Context): Set<String> =
        ctx.prefs().getStringSet(REGISTERED_GEOFENCE_ZONE_IDS_KEY, null) ?: emptySet()

    fun clearRegisteredGeofenceZoneIds(ctx: Context) {
        ctx.prefs().edit().remove(REGISTERED_GEOFENCE_ZONE_IDS_KEY).apply()
    }

    // ---- Persisted zones (re-registered after reboot / app update) -------------------------

    @Synchronized
    fun saveStoredZone(ctx: Context, zoneId: String, zoneJson: String) {
        val prefs = ctx.prefs()
        val zones = org.json.JSONObject(prefs.getString(STORED_ZONES_KEY, null) ?: "{}")
        zones.put(zoneId, zoneJson)
        prefs.edit().putString(STORED_ZONES_KEY, zones.toString()).apply()
    }

    @Synchronized
    fun removeStoredZone(ctx: Context, zoneId: String) {
        val prefs = ctx.prefs()
        val zones = org.json.JSONObject(prefs.getString(STORED_ZONES_KEY, null) ?: "{}")
        zones.remove(zoneId)
        prefs.edit()
            .putString(STORED_ZONES_KEY, zones.toString())
            .remove(REQUEST_CODE_KEY_PREFIX + zoneId)
            .apply()
    }

    fun clearStoredZones(ctx: Context) {
        val prefs = ctx.prefs()
        val editor = prefs.edit().remove(STORED_ZONES_KEY)
        prefs.all.keys.filter { it.startsWith(REQUEST_CODE_KEY_PREFIX) }.forEach { editor.remove(it) }
        editor.apply()
    }

    /** Zone id -> zone JSON for every zone registered through this plugin. */
    fun getStoredZones(ctx: Context): Map<String, String> {
        val raw = ctx.prefs().getString(STORED_ZONES_KEY, null) ?: return emptyMap()
        val zones = org.json.JSONObject(raw)
        val result = mutableMapOf<String, String>()
        val keys = zones.keys()
        while (keys.hasNext()) {
            val id = keys.next()
            result[id] = zones.getString(id)
        }
        return result
    }

    /**
     * A stable, collision-free PendingIntent request code per zone. `String.hashCode()` can
     * collide between two zones, which would make one registration silently replace the other.
     */
    @Synchronized
    fun getOrCreateRequestCode(ctx: Context, zoneId: String): Int {
        val prefs = ctx.prefs()
        val key = REQUEST_CODE_KEY_PREFIX + zoneId
        if (prefs.contains(key)) return prefs.getInt(key, 0)
        val next = prefs.getInt(NEXT_REQUEST_CODE_KEY, 1)
        prefs.edit().putInt(key, next).putInt(NEXT_REQUEST_CODE_KEY, next + 1).apply()
        return next
    }

    // ---- Whether the user asked for the service to be running -------------------------------

    fun setServiceActive(ctx: Context, active: Boolean) {
        ctx.prefs().edit().putBoolean(SERVICE_ACTIVE_KEY, active).apply()
    }

    fun saveLocationUpdateMode(ctx: Context, mode: String) {
        ctx.prefs().edit().putString(LOCATION_UPDATE_MODE_KEY, mode).apply()
    }

    /** One of `highAccuracy` (the default), `balanced` or `off`. */
    fun getLocationUpdateMode(ctx: Context): String =
        ctx.prefs().getString(LOCATION_UPDATE_MODE_KEY, null) ?: "highAccuracy"

    fun isServiceActive(ctx: Context): Boolean = ctx.prefs().getBoolean(SERVICE_ACTIVE_KEY, false)

    fun saveServiceConfig(context: Context, config: ServiceConfig) {
        val prefs = context.getSharedPreferences(Constants.sharedPrefs, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("${SERVICE_CONFIG_KEY}_channelId", config.channelId)
            putString("${SERVICE_CONFIG_KEY}_contentTitle", config.contentTitle)
            putString("${SERVICE_CONFIG_KEY}_contentText", config.contentText)
            putInt("${SERVICE_CONFIG_KEY}_appIcon", config.appIcon)
            putInt("${SERVICE_CONFIG_KEY}_serviceId", config.serviceId)
            apply()
        }
    }

    fun getServiceConfig(context: Context): ServiceConfig? {
        val prefs = context.getSharedPreferences(Constants.sharedPrefs, Context.MODE_PRIVATE)
        val channelId = prefs.getString("${SERVICE_CONFIG_KEY}_channelId", null)
        val contentTitle = prefs.getString("${SERVICE_CONFIG_KEY}_contentTitle", null)
        val contentText = prefs.getString("${SERVICE_CONFIG_KEY}_contentText", null)
        val appIcon = prefs.getInt("${SERVICE_CONFIG_KEY}_appIcon", 0)
        val serviceId = prefs.getInt("${SERVICE_CONFIG_KEY}_serviceId", 525600)

        return if (channelId != null && contentTitle != null && contentText != null) {
            ServiceConfig(channelId, contentTitle, contentText, appIcon, serviceId)
        } else {
            null
        }
    }
}
