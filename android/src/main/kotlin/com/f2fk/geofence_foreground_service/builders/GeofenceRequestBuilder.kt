package com.f2fk.geofence_foreground_service.builders

import com.f2fk.geofence_foreground_service.interfaces.Builder
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest

class GeofencingRequestBuilder(private val geofence: Geofence, private val initialTrigger: Int?): Builder<GeofencingRequest> {
    override fun build(): GeofencingRequest = GeofencingRequest.Builder()
    .setInitialTrigger(initialTrigger ?: GeofencingRequest.INITIAL_TRIGGER_ENTER)
    .addGeofence(geofence)
    .build()
}