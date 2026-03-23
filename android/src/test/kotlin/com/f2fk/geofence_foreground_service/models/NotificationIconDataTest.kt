package com.f2fk.geofence_foreground_service.models

import com.f2fk.geofence_foreground_service.Constants
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NotificationIconDataTest {

    @Test
    fun fromJson_mapsFields() {
        val json = mapOf<String, Any>(
            Constants.resType to "mipmap",
            Constants.resPrefix to "ic",
            Constants.name to "launcher",
            Constants.backgroundColorRgb to "1,2,3",
        )
        val data = NotificationIconData.fromJson(json)
        assertEquals("mipmap", data.resType)
        assertEquals("ic", data.resPrefix)
        assertEquals("launcher", data.name)
        assertEquals("1,2,3", data.backgroundColorRgb)
    }

    @Test
    fun fromJson_nullBackgroundColor() {
        val json = mapOf<String, Any>(
            Constants.resType to "drawable",
            Constants.resPrefix to "img",
            Constants.name to "bell",
        )
        val data = NotificationIconData.fromJson(json)
        assertNull(data.backgroundColorRgb)
    }
}
