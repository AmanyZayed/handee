package com.example.handee

import android.content.Intent
import com.example.handee.unity.HandeeUnityRegistrar
import com.example.handee.unity.HandeeUnitySignActivity
import com.example.handee.unity.HandeeUnityUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ASL_METHOD_CHANNEL = "handee/asl_native"
    private val ASL_EVENT_CHANNEL = "handee/asl_stream"
    private val UNITY_CHANNEL = "handee_unity"

    private lateinit var aslNativeEngine: AslNativeEngine

    companion object {
        private const val UNITY_OBJECT = "HamadaAvatar"
        private const val UNITY_METHOD = "PlaySign"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        aslNativeEngine = AslNativeEngine(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ASL_METHOD_CHANNEL)
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
                    "setRecognitionSettings" -> {
                        val pipeline = call.argument<String>("pipeline")
                        val classFilter = call.argument<String>("classFilter")
                        val confThreshold = call.argument<Double>("confThreshold")
                        result.success(
                            aslNativeEngine.setRecognitionSettings(
                                pipeline,
                                classFilter,
                                confThreshold,
                            )
                        )
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ASL_EVENT_CHANNEL)
            .setStreamHandler(aslNativeEngine.streamHandler)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "handee/native_camera_preview",
            NativeCameraPreviewFactory(this)
        )

        HandeeUnityRegistrar.register(flutterEngine, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "postMessage" -> {
                        val gameObject =
                            call.argument<String>("gameObject") ?: UNITY_OBJECT
                        val methodName =
                            call.argument<String>("methodName") ?: UNITY_METHOD
                        val message = call.argument<String>("message") ?: ""
                        HandeeUnityUtils.prepareForMessage()
                        HandeeUnityUtils.postMessage(gameObject, methodName, message)
                        result.success(true)
                    }
                    "prepareUnity" -> {
                        HandeeUnityUtils.prepareForMessage()
                        result.success(true)
                    }
                    "openSign" -> {
                        val word = call.argument<String>("word")?.trim().orEmpty()
                        if (word.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(this, HandeeUnitySignActivity::class.java)
                            intent.putExtra(HandeeUnitySignActivity.EXTRA_WORD, word)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "isReady" -> {
                        result.success(
                            HandeeUnityUtils.unityLoaded && HandeeUnityUtils.sceneReady,
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        HandeeUnityUtils.activity = this
        HandeeUnityUtils.resume()
        HandeeUnityUtils.focus()
    }

    override fun onStop() {
        // Keep Unity alive while the Flutter activity is still visible (e.g. keyboard).
        if (isFinishing) {
            HandeeUnityUtils.pause()
        }
        super.onStop()
    }

    override fun onDestroy() {
        if (::aslNativeEngine.isInitialized) {
            aslNativeEngine.release()
        }
        super.onDestroy()
    }
}
