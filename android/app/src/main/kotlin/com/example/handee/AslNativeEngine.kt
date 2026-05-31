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
            NativeAslState.eventSink = events
            NativeAslState.sendStatus("Native stream connected")
        }

        override fun onCancel(arguments: Any?) {
            NativeAslState.eventSink = null
        }
    }

    fun initialize(): String {
        return try {
            val landmarker = HolisticLandmarker.createFromFile(
                context,
                "holistic_landmarker.task"
            )

            NativeAslState.setHolisticLandmarker(landmarker)
            ensureYoloClassifierLoaded()

            val msg = "Holistic + YOLO engines ready"
            NativeAslState.sendStatus(msg)
            msg
        } catch (e: Exception) {
            Log.e(TAG, "initialize() failed", e)
            val msg = "Failed to load native models: ${e.message}"
            NativeAslState.sendStatus(msg)
            msg
        }
    }

    fun setRecognitionSettings(
        pipeline: String?,
        classFilter: String?,
        confThreshold: Double?,
    ): String {
        return try {
            val pipelineEnum = when (pipeline?.lowercase()) {
                "yolo_app", "yolo_stable", "app" -> NativeAslState.RecognitionPipeline.YOLO_APP_STYLE
                "yolo_fast", "mediapipe_yolo" -> NativeAslState.RecognitionPipeline.YOLO_FAST_STYLE
                else -> NativeAslState.RecognitionPipeline.WORDS
            }

            val filterEnum = when (classFilter?.lowercase()) {
                "digits" -> YoloAslClassifier.ClassFilter.DIGITS
                "letters" -> YoloAslClassifier.ClassFilter.LETTERS
                else -> YoloAslClassifier.ClassFilter.BOTH
            }

            val threshold = confThreshold?.toFloat() ?: defaultThreshold(filterEnum)

            NativeAslState.configureRecognition(pipelineEnum, filterEnum, threshold)
            ensureYoloClassifierLoaded()

            val msg =
                "Recognition: ${pipelineEnum.name}, filter=$classFilter, conf=$threshold"
            NativeAslState.sendStatus(msg)
            msg
        } catch (e: Exception) {
            Log.e(TAG, "setRecognitionSettings() failed", e)
            "Failed to apply recognition settings: ${e.message}"
        }
    }

    fun startRecognition(): String {
        return try {
            if (!NativeAslState.hasHolisticLandmarker()) {
                val msg = "Recognition engine is not ready"
                NativeAslState.sendStatus(msg)
                return msg
            }
            if (NativeAslState.recognitionPipeline != NativeAslState.RecognitionPipeline.WORDS &&
                !NativeAslState.hasYoloClassifier()
            ) {
                ensureYoloClassifierLoaded()
            }
            NativeAslState.reset()
            NativeAslState.recognitionStarted = true
            val msg = "Recognition started (${NativeAslState.recognitionPipeline.name})"
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
        NativeAslState.recognitionStarted = false
        val msg = "Recognition stopped"
        NativeAslState.sendStatus(msg)
        return msg
    }

    fun release() {
        NativeAslState.recognitionStarted = false
        NativeAslState.eventSink = null
        NativeAslState.clearHolisticLandmarker()
        NativeAslState.setYoloClassifier(null)
    }

    private fun ensureYoloClassifierLoaded() {
        val pipeline = NativeAslState.recognitionPipeline
        if (pipeline == NativeAslState.RecognitionPipeline.WORDS) {
            return
        }

        val modelKey = when (pipeline) {
            NativeAslState.RecognitionPipeline.YOLO_APP_STYLE ->
                YoloAslClassifier.ModelKey.FULL_COMBINED
            NativeAslState.RecognitionPipeline.YOLO_FAST_STYLE ->
                YoloAslClassifier.ModelKey.LETTERS_DIGITS
            else -> return
        }

        val tightCrop = pipeline == NativeAslState.RecognitionPipeline.YOLO_FAST_STYLE
        val classifier = YoloAslClassifier(context)
        classifier.load(
            modelKey = modelKey,
            classFilter = NativeAslState.yoloClassFilter,
            confThreshold = NativeAslState.yoloConfThreshold,
            tightCrop = tightCrop,
        )
        NativeAslState.setYoloClassifier(classifier)
    }

    private fun defaultThreshold(filter: YoloAslClassifier.ClassFilter): Float {
        return when (filter) {
            YoloAslClassifier.ClassFilter.DIGITS -> 0.35f
            YoloAslClassifier.ClassFilter.LETTERS -> 0.6f
            YoloAslClassifier.ClassFilter.BOTH -> 0.6f
        }
    }
}
