package com.f2fk.geofence_foreground_service.models

import com.f2fk.geofence_foreground_service.Constants
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

            (json[Constants.zones] as List<Map<String, Any>>).forEach {
                zones.add(
                    Zone.fromJson(it)
                )
            }

            return ZonesList(
                zones.toCollection(ArrayList<Zone>())
            )
        }
    }
}

class Zone(
    val zoneId: String,
    val radius: Float,
    val coordinates: ArrayList<LatLng>?,
    val notificationResponsivenessMs: Int?
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

        return result
    }

    companion object {
        fun fromJson(json: Map<String, Any>): Zone {
            val coordinates = mutableListOf<LatLng>()

            (json[Constants.coordinates] as List<Map<String, Double>>).forEach {
                coordinates.add(
                    LatLng(
                        it[Constants.latitude]!!,
                        it[Constants.longitude]!!
                    )
                )
            }

            return Zone(
                json[Constants.id] as String,
                (json[Constants.radius] as Number).toFloat(),
                coordinates.toCollection(ArrayList<LatLng>()),
                (json[Constants.notificationResponsivenessMs] as Number?)?.toInt()
            )
        }
    }
}