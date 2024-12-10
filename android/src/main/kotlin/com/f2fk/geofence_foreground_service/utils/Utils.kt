package com.f2fk.geofence_foreground_service.utils

import com.google.android.gms.location.Geofence

/// Contains multiple utilities
class Utils {
    companion object {
        // Us it to cast to different types without warnings showing.
        @Suppress("UNCHECKED_CAST")
        fun <T> cast(value: Any?) : T = value as T

        // The list of available triggers for geofences
        //
        // Currently is used to combine the triggers into a single value using bitwise OR, 
        // aswell as to retrieve the triggers from a bitwise OR value. 
        //
        // It can also be used for other purposes.
        val availableTriggers: List<Int> = listOf(
            Geofence.GEOFENCE_TRANSITION_ENTER,
            Geofence.GEOFENCE_TRANSITION_EXIT,
            Geofence.GEOFENCE_TRANSITION_DWELL,
        )
    }
}