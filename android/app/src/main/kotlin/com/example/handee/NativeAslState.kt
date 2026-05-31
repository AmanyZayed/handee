package com.example.handee

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarker
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarkerResult
import io.flutter.plugin.common.EventChannel

object NativeAslState {
    private const val TAG = "ASL_NATIVE"
    private const val FACE_LANDMARK_COUNT = 468
    private const val POSE_LANDMARK_COUNT = 33
    private const val HAND_LANDMARK_COUNT = 21
    private const val MAX_BITMAP_WIDTH = 360

    enum class RecognitionPipeline {
        WORDS,
        YOLO_APP_STYLE,
        YOLO_FAST_STYLE,
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    var eventSink: EventChannel.EventSink? = null
    var recognitionStarted: Boolean = false
    var frameCounter: Int = 0

    var recognitionPipeline: RecognitionPipeline = RecognitionPipeline.WORDS
    var yoloClassFilter: YoloAslClassifier.ClassFilter = YoloAslClassifier.ClassFilter.BOTH
    var yoloConfThreshold: Float = 0.6f

    private var holisticLandmarker: HolisticLandmarker? = null
    private var yoloClassifier: YoloAslClassifier? = null

    fun setHolisticLandmarker(landmarker: HolisticLandmarker?) {
        holisticLandmarker?.close()
        holisticLandmarker = landmarker
    }

    fun clearHolisticLandmarker() {
        holisticLandmarker?.close()
        holisticLandmarker = null
    }

    fun setYoloClassifier(classifier: YoloAslClassifier?) {
        yoloClassifier?.release()
        yoloClassifier = classifier
    }

    fun configureRecognition(
        pipeline: RecognitionPipeline,
        classFilter: YoloAslClassifier.ClassFilter,
        confThreshold: Float,
    ) {
        recognitionPipeline = pipeline
        yoloClassFilter = classFilter
        yoloConfThreshold = confThreshold
    }

    fun hasHolisticLandmarker(): Boolean {
        return holisticLandmarker != null
    }

    fun hasYoloClassifier(): Boolean {
        return yoloClassifier != null
    }

    fun reset() {
        frameCounter = 0
    }

    fun sendStatus(message: String) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "status",
                    "message" to message
                )
            )
        }
    }

    fun sendFrameUpdate(frameCount: Int) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "frame_update",
                    "frameCount" to frameCount,
                    "message" to "Native frames analyzed: $frameCount"
                )
            )
        }
    }

    fun sendLandmarkUpdate(
        frameCount: Int,
        faceCount: Int,
        poseCount: Int,
        leftHandCount: Int,
        rightHandCount: Int,
        landmarks: List<Double>
    ) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "landmark_update",
                    "frameCount" to frameCount,
                    "faceCount" to faceCount,
                    "poseCount" to poseCount,
                    "leftHandCount" to leftHandCount,
                    "rightHandCount" to rightHandCount,
                    "landmarks" to landmarks,
                    "faceDetected" to (faceCount > 0),
                    "poseDetected" to (poseCount > 0),
                    "leftHandDetected" to (leftHandCount > 0),
                    "rightHandDetected" to (rightHandCount > 0),
                    "pipeline" to recognitionPipeline.name,
                )
            )
        }
    }

    fun sendYoloPrediction(
        frameCount: Int,
        rawLabel: String?,
        rawConfidence: Double,
        topLabel: String,
        cropStyle: String,
    ) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "yolo_prediction",
                    "frameCount" to frameCount,
                    "rawLabel" to rawLabel,
                    "rawConfidence" to rawConfidence,
                    "topLabel" to topLabel,
                    "cropStyle" to cropStyle,
                    "pipeline" to recognitionPipeline.name,
                )
            )
        }
    }

    fun processBitmap(bitmap: Bitmap, frameNumber: Int) {
        val landmarker = holisticLandmarker

        if (landmarker == null) {
            return
        }

        try {
            val argbBitmap =
                if (bitmap.config == Bitmap.Config.ARGB_8888) bitmap
                else bitmap.copy(Bitmap.Config.ARGB_8888, false)
            val scaledBitmap = downscaleBitmap(argbBitmap)

            val mpImage = BitmapImageBuilder(scaledBitmap).build()
            val result = landmarker.detect(mpImage)
            mpImage.close()

            val faceCount = result.faceLandmarks().size
            val poseCount = result.poseLandmarks().size
            val leftHandCount = result.leftHandLandmarks().size
            val rightHandCount = result.rightHandLandmarks().size
            val flattenedLandmarks = flattenHolisticLandmarks(result)

            if (recognitionPipeline == RecognitionPipeline.WORDS) {
                sendLandmarkUpdate(
                    frameCount = frameNumber,
                    faceCount = faceCount,
                    poseCount = poseCount,
                    leftHandCount = leftHandCount,
                    rightHandCount = rightHandCount,
                    landmarks = flattenedLandmarks,
                )
            } else {
                val handLandmarks = pickHandLandmarks(result)
                val classifier = yoloClassifier
                if (handLandmarks != null && classifier != null) {
                    val prediction = classifier.predict(argbBitmap, handLandmarks)
                    if (prediction != null) {
                        val cropStyle = when (recognitionPipeline) {
                            RecognitionPipeline.YOLO_APP_STYLE -> "margin"
                            RecognitionPipeline.YOLO_FAST_STYLE -> "tight"
                            else -> "none"
                        }
                        sendYoloPrediction(
                            frameCount = frameNumber,
                            rawLabel = prediction.acceptedLabel,
                            rawConfidence = prediction.confidence.toDouble(),
                            topLabel = prediction.topLabel,
                            cropStyle = cropStyle,
                        )
                    }
                }
            }

            if (frameNumber == 30) {
                sendStatus("30 native frames analyzed (${recognitionPipeline.name})")
            }
        } catch (e: Exception) {
            Log.e(TAG, "processBitmap() failed", e)
            sendStatus("Holistic detection error: ${e.message}")
        }
    }

    private fun flattenHolisticLandmarks(result: HolisticLandmarkerResult): List<Double> {
        val values = mutableListOf<Double>()

        appendLandmarkList(values, result.faceLandmarks(), FACE_LANDMARK_COUNT)
        appendLandmarkList(values, result.leftHandLandmarks(), HAND_LANDMARK_COUNT)
        appendLandmarkList(values, result.poseLandmarks(), POSE_LANDMARK_COUNT)
        appendLandmarkList(values, result.rightHandLandmarks(), HAND_LANDMARK_COUNT)

        return values
    }

    private fun appendLandmarkList(
        values: MutableList<Double>,
        landmarks: List<NormalizedLandmark>?,
        expectedCount: Int
    ) {
        if (landmarks == null) {
            repeat(expectedCount) {
                values.add(Double.NaN)
                values.add(Double.NaN)
                values.add(Double.NaN)
            }
            return
        }

        for (index in 0 until expectedCount) {
            val landmark = landmarks.getOrNull(index)
            values.add(landmark?.x()?.toDouble() ?: Double.NaN)
            values.add(landmark?.y()?.toDouble() ?: Double.NaN)
            values.add(landmark?.z()?.toDouble() ?: Double.NaN)
        }
    }

    private fun pickHandLandmarks(result: HolisticLandmarkerResult): List<NormalizedLandmark>? {
        val left = result.leftHandLandmarks()
        if (!left.isNullOrEmpty()) {
            return left
        }
        val right = result.rightHandLandmarks()
        if (!right.isNullOrEmpty()) {
            return right
        }
        return null
    }

    private fun downscaleBitmap(bitmap: Bitmap): Bitmap {
        if (bitmap.width <= MAX_BITMAP_WIDTH) {
            return bitmap
        }

        val scale = MAX_BITMAP_WIDTH.toDouble() / bitmap.width.toDouble()
        val targetWidth = MAX_BITMAP_WIDTH
        val targetHeight = (bitmap.height * scale).toInt().coerceAtLeast(1)

        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

}
