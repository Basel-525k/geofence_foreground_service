package com.f2fk.geofence_foreground_service.models

import com.f2fk.geofence_foreground_service.Constants
import java.io.Serializable

class NotificationIconData(
    val resType: String,
    val resPrefix: String,
    val name: String,
    val backgroundColorRgb: String?
) : Serializable {
    companion object {
        fun fromJson(json: Map<String, Any>): NotificationIconData {
            return NotificationIconData(
                json[Constants.resType] as String,
                json[Constants.resPrefix] as String,
                json[Constants.name] as String,
                json[Constants.backgroundColorRgb] as String?
            )
        }
    }
}