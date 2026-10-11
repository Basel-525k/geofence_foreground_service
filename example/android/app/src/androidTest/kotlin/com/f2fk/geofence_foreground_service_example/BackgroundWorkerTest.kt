package com.f2fk.geofence_foreground_service_example

import android.content.Context
import androidx.test.platform.app.InstrumentationRegistry
import androidx.work.ListenableWorker
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import com.f2fk.geofence_foreground_service.BackgroundWorker
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

/**
 * Runs the plugin's [BackgroundWorker] inside the example app, where the Flutter engine is
 * available (the plugin module itself only compiles against flutter.jar).
 */
class BackgroundWorkerTest {
    private val context: Context
        get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Before
    fun clearPluginPreferences() {
        context.getSharedPreferences("geofence_foreground_service_plugin", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
    }

    @Test
    fun failsFastWhenNoDartCallbackIsRegistered() {
        val worker = TestListenableWorkerBuilder<BackgroundWorker>(context)
            .setInputData(
                workDataOf(
                    BackgroundWorker.ZONE_ID to "zone-1",
                    BackgroundWorker.PAYLOAD_KEY to "1",
                    BackgroundWorker.IS_IN_DEBUG_MODE_KEY to false,
                )
            )
            .build()

        // The worker creates a FlutterEngine, which must happen on the main thread (WorkManager
        // starts workers there too).
        var future: java.util.concurrent.Future<ListenableWorker.Result>? = null
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            future = worker.startWork()
        }

        // Before the fix this future never completed. A 30s ceiling is generous: the worker has
        // to wait for FlutterLoader initialisation, then it must give up immediately.
        val result = try {
            future!!.get(30, TimeUnit.SECONDS)
        } catch (e: TimeoutException) {
            fail("BackgroundWorker hung when no Dart callback was registered: $e")
            return
        }

        assertTrue(
            "Expected failure but was $result",
            result is ListenableWorker.Result.Failure
        )
    }
}
