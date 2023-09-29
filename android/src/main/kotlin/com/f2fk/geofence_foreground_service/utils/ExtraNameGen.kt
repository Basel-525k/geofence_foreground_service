package com.f2fk.geofence_foreground_service.utils

import android.content.Context

fun Context.extraNameGen(name: String): String {
    return "$packageName.$name"
}