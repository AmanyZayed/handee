package com.example.handee

import android.content.Context
import android.util.Log
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarker
import io.flutter.plugin.common.EventChannel

class AslNativeEngine(private val context: Context) {

    companion object {
        private const val TAG = "ASL_ENGINE"
    }

    val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            Log.d(TAG, "EventChannel onListen()")
            NativeAslState.eventSink = events
            NativeAslState.sendStatus("Native stream connected ✅")
        }

        override fun onCancel(arguments: Any?) {
            Log.d(TAG, "EventChannel onCancel()")
            NativeAslState.eventSink = null
        }
    }

    fun initialize(): String {
        return try {
            Log.d(TAG, "initialize() called")

            val landmarker = HolisticLandmarker.createFromFile(
                context,
                "holistic_landmarker.task"
            )

            NativeAslState.setHolisticLandmarker(landmarker)

            val msg = "Holistic model loaded successfully ✅"
            Log.d(TAG, msg)
            NativeAslState.sendStatus(msg)
            msg
        } catch (e: Exception) {
            Log.e(TAG, "initialize() failed", e)
            val msg = "Failed to load holistic model: ${e.message}"
            NativeAslState.sendStatus(msg)
            msg
        }
    }

    fun startRecognition(): String {
        return try {
            Log.d(TAG, "startRecognition() called")
            NativeAslState.reset()
            NativeAslState.recognitionStarted = true
            val msg = "Real landmark detection started ✅"
            NativeAslState.sendStatus(msg)
            msg
        } catch (e: Exception) {
            Log.e(TAG, "startRecognition() failed", e)
            val msg = "Failed to start recognition: ${e.message}"
            NativeAslState.sendStatus(msg)
            msg
        }
    }

    fun stopRecognition(): String {
        Log.d(TAG, "stopRecognition() called")
        NativeAslState.recognitionStarted = false
        val msg = "Recognition stopped ✅"
        NativeAslState.sendStatus(msg)
        return msg
    }

    fun release() {
        Log.d(TAG, "release() called")
        NativeAslState.recognitionStarted = false
        NativeAslState.eventSink = null
        NativeAslState.clearHolisticLandmarker()
    }
}