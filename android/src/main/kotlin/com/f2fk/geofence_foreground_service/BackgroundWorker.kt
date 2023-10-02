package com.f2fk.geofence_foreground_service

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import com.f2fk.geofence_foreground_service.utils.DebugHelper
import com.f2fk.geofence_foreground_service.utils.SharedPreferenceHelper
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import java.util.Random

/***
 * A simple worker that will post your input back to your Flutter application.
 *
 * It will block the background thread until a value of either true or false is received back from Flutter code.
 */
class BackgroundWorker(
    applicationContext: Context,
    private val workerParams: WorkerParameters
) : ListenableWorker(applicationContext, workerParams), MethodChannel.MethodCallHandler {

    private lateinit var backgroundChannel: MethodChannel

    companion object {
        const val TAG = "GeofenceService"

        const val PAYLOAD_KEY = "ps.byshy.geofence.INPUT_DATA"
        const val ZONE_ID = "ps.byshy.geofence.ZONE_ID"
        const val IS_IN_DEBUG_MODE_KEY = "ps.byshy.geofence.IS_IN_DEBUG_MODE_KEY"

        const val BACKGROUND_CHANNEL_NAME =
            "ps.byshy.geofence/background_geofence_foreground_service"
        const val BACKGROUND_CHANNEL_INITIALIZED = "backgroundChannelInitialized"

        private val flutterLoader = FlutterLoader()
    }

    private val payload
        get() = workerParams.inputData.getString(PAYLOAD_KEY)

    private val zoneId
        get() = workerParams.inputData.getString(ZONE_ID)!!

    private val isInDebug
        get() = workerParams.inputData.getBoolean(IS_IN_DEBUG_MODE_KEY, false)

    private val randomThreadIdentifier = Random().nextInt()
    private var engine: FlutterEngine? = null

    private var startTime: Long = 0

    private var completer: CallbackToFutureAdapter.Completer<Result>? = null

    private var resolvableFuture = CallbackToFutureAdapter.getFuture { completer ->
        this.completer = completer
        null
    }

    override fun startWork(): ListenableFuture<Result> {
        startTime = System.currentTimeMillis()

        engine = FlutterEngine(applicationContext)

        if (!flutterLoader.initialized()) {
            flutterLoader.startInitialization(applicationContext)
        }

        flutterLoader.ensureInitializationCompleteAsync(
            applicationContext,
            null,
            Handler(Looper.getMainLooper())
        ) {
            val callbackHandle = SharedPreferenceHelper.getCallbackHandle(applicationContext)
            val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
            val dartBundlePath = flutterLoader.findAppBundlePath()

            if (isInDebug) {
                DebugHelper.postTaskStarting(
                    applicationContext,
                    randomThreadIdentifier,
                    zoneId,
                    payload,
                    callbackHandle,
                    callbackInfo,
                    dartBundlePath
                )
            }

            // Backwards compatibility with v1. We register all the user's plugins.
            GeofenceForegroundServicePlugin.pluginRegistryCallback?.registerWith(
                ShimPluginRegistry(
                    engine!!
                )
            )

            engine?.let { engine ->
                backgroundChannel = MethodChannel(engine.dartExecutor, BACKGROUND_CHANNEL_NAME)
                backgroundChannel.setMethodCallHandler(this@BackgroundWorker)

                engine.dartExecutor.executeDartCallback(
                    DartExecutor.DartCallback(
                        applicationContext.assets,
                        dartBundlePath,
                        callbackInfo
                    )
                )
            }
        }

        return resolvableFuture
    }

    override fun onStopped() {
        stopEngine(null)
    }

    private fun stopEngine(result: Result?) {
        val fetchDuration = System.currentTimeMillis() - startTime

        if (isInDebug) {
            DebugHelper.postTaskCompleteNotification(
                applicationContext,
                randomThreadIdentifier,
                zoneId,
                payload,
                fetchDuration,
                result ?: Result.failure()
            )
        }

        // No result indicates we were signalled to stop by WorkManager.  The result is already
        // STOPPED, so no need to resolve another one.
        if (result != null) {
            this.completer?.set(result)
        }

        // If stopEngine is called from `onStopped`, it may not be from the main thread.
        Handler(Looper.getMainLooper()).post {
            engine?.destroy()
            engine = null
        }
    }

    override fun onMethodCall(call: MethodCall, r: MethodChannel.Result) {
        when (call.method) {
            BACKGROUND_CHANNEL_INITIALIZED -> {
                backgroundChannel.invokeMethod(
                    "onResultSend",
                    mapOf(ZONE_ID to zoneId, PAYLOAD_KEY to payload),
                    object : MethodChannel.Result {
                        override fun notImplemented() {
                            stopEngine(Result.failure())
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?
                        ) {
                            Log.e(TAG, "errorCode: $errorCode, errorMessage: $errorMessage")
                            stopEngine(Result.failure())
                        }

                        override fun success(receivedResult: Any?) {
                            val wasSuccessFul = receivedResult?.let { it as Boolean? } == true
                            stopEngine(if (wasSuccessFul) Result.success() else Result.retry())
                        }
                    }
                )
            }
        }
    }
}
