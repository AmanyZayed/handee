package com.example.handee

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "handee/asl_native"
    private val EVENT_CHANNEL = "handee/asl_stream"

    private lateinit var aslNativeEngine: AslNativeEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        aslNativeEngine = AslNativeEngine(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeAslEngine" -> {
                        result.success(aslNativeEngine.initialize())
                    }
                    "startRecognition" -> {
                        result.success(aslNativeEngine.startRecognition())
                    }
                    "stopRecognition" -> {
                        result.success(aslNativeEngine.stopRecognition())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(aslNativeEngine.streamHandler)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "handee/native_camera_preview",
            NativeCameraPreviewFactory(this)
        )
    }

    override fun onDestroy() {
        if (::aslNativeEngine.isInitialized) {
            aslNativeEngine.release()
        }
        super.onDestroy()
    }
}