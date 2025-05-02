package com.f2fk.geofence_foreground_service.models

import com.f2fk.geofence_foreground_service.Constants
import com.f2fk.geofence_foreground_service.utils.Utils
import com.google.android.gms.maps.model.LatLng
import java.io.Serializable
import java.util.ArrayList

class ZonesList(
    val zones: ArrayList<Zone>?
) : Serializable {
    fun toJson(): Map<String, *> {
        val result = mutableMapOf<String, Any>()

        val zones = mutableListOf<Map<String, Any>>()

        (this.zones ?: emptyList()).forEach {
            zones.add(it.toJson())
        }

        result[Constants.zones] = zones

        return result
    }

    companion object {
        fun fromJson(json: Map<String, Any>): ZonesList {
            val zones = mutableListOf<Zone>()
            (Utils.cast<List<Map<String, Any>>>(json[Constants.zones])).forEach {
                zones.add(Zone.fromJson(it))
            }
            return ZonesList(zones.toCollection(ArrayList<Zone>()))
        }
    }
}

class Zone(
    val zoneId: String,
    val radius: Float,
    val coordinates: ArrayList<LatLng>?,
    val notificationResponsivenessMs: Int?,
    val triggers: Int,
    val expirationDuration: Long?,
    val dwellLoiteringDelay: Int?,
    val initialTrigger: Int?
) : Serializable {
    fun toJson(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()

        result[Constants.id] = zoneId
        result[Constants.radius] = radius
        result[Constants.coordinates] = (coordinates ?: emptyList()).map {
            mutableMapOf(
                Constants.latitude to it.latitude,
                Constants.longitude to it.longitude,
            )
        }
        if (notificationResponsivenessMs != null) {
            result[Constants.notificationResponsivenessMs] = notificationResponsivenessMs
        }
        // We will convert the event triggers back to a list of integers, just as we receive them
        // inside 'fromJson' function
        val triggersList = mutableListOf<Int>()
        Utils.availableTriggers.forEach { if ((it and triggers) != 0) triggersList.add(it) }
        result[Constants.fenceTriggers] = triggersList
        if (expirationDuration != null) {
            result[Constants.fenceExpirationDuration] = expirationDuration
        }
        if (dwellLoiteringDelay != null) {
            result[Constants.dwellLoiteringDelay] = dwellLoiteringDelay
        }
        if (initialTrigger != null) {
            result[Constants.initialTrigger] = initialTrigger
        }

        return result
    }

    companion object {
        fun fromJson(json: Map<String, Any>): Zone {
            val coordinates = mutableListOf<LatLng>()
            (Utils.cast<List<Map<String, Double>>>(json[Constants.coordinates])).forEach {
                coordinates.add(LatLng(it[Constants.latitude]!!, it[Constants.longitude]!!))
            }

            var fenceTriggers = Utils.cast<List<Int>?>(json[Constants.fenceTriggers])
            if (fenceTriggers == null) fenceTriggers = Utils.availableTriggers

            return Zone(
                json[Constants.id] as String,
                (json[Constants.radius] as Number).toFloat(),
                coordinates.toCollection(ArrayList<LatLng>()),
                (json[Constants.notificationResponsivenessMs] as Number?)?.toInt(),
                // The event triggers are passed as a bitwise-OR operation value.
                fenceTriggers.fold(0) { acc, trigger -> acc or trigger },
                (json[Constants.fenceExpirationDuration] as Number?)?.toLong(),
                (json[Constants.dwellLoiteringDelay] as Number?)?.toInt(),
                (json[Constants.initialTrigger] as Number?)?.toInt(),
            )
        }
    }
}