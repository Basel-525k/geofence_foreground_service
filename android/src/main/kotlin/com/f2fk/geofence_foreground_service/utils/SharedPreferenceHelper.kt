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
