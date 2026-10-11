package com.f2fk.geofence_foreground_service.utils

import com.f2fk.geofence_foreground_service.models.Zone
import org.json.JSONArray
import org.json.JSONObject

/**
 * Serialises a [Zone] to and from a JSON string so registered zones can be persisted and
 * re-registered later (reboot, app update).
 */
object ZoneCodec {
    fun encode(zone: Zone): String = JSONObject(zone.toJson()).toString()

    fun decode(json: String): Zone = Zone.fromJson(toMap(JSONObject(json)))

    private fun toMap(obj: JSONObject): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = unwrap(obj.get(key)) ?: continue
            result[key] = value
        }
        return result
    }

    private fun toList(array: JSONArray): List<Any> {
        val result = mutableListOf<Any>()
        for (i in 0 until array.length()) {
            unwrap(array.get(i))?.let { result.add(it) }
        }
        return result
    }

    private fun unwrap(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> toMap(value)
        is JSONArray -> toList(value)
        else -> value
    }
}
