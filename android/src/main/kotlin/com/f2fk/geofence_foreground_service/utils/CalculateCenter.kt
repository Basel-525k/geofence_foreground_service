package com.f2fk.geofence_foreground_service.utils

import com.google.android.gms.maps.model.LatLng

fun calculateCenter(coordinates: List<LatLng>): LatLng {
    if (coordinates.size == 1) {
        return coordinates.first()
    }

    var sumLatitude = 0.0
    var sumLongitude = 0.0

    for (coordinate in coordinates) {
        sumLatitude += coordinate.latitude
        sumLongitude += coordinate.longitude
    }

    val centerLatitude = sumLatitude / coordinates.size
    val centerLongitude = sumLongitude / coordinates.size

    return LatLng(centerLatitude, centerLongitude)
}