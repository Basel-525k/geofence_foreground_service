package com.f2fk.geofence_foreground_service.models

import com.google.android.gms.maps.model.LatLng
import java.io.Serializable
import java.util.ArrayList

class Zone(
    val zoneId: String,
    val radius: Float,
    val coordinates: ArrayList<LatLng>?
) : Serializable