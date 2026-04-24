package com.example.handee

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarker
import io.flutter.plugin.common.EventChannel

object NativeAslState {
    private const val TAG = "ASL_NATIVE"
    private val mainHandler = Handler(Looper.getMainLooper())

    var eventSink: EventChannel.EventSink? = null
    var recognitionStarted: Boolean = false
    var frameCounter: Int = 0

    private var holisticLandmarker: HolisticLandmarker? = null

    fun setHolisticLandmarker(landmarker: HolisticLandmarker?) {
        Log.d(TAG, "setHolisticLandmarker()")
        holisticLandmarker?.close()
        holisticLandmarker = landmarker
    }

    fun clearHolisticLandmarker() {
        Log.d(TAG, "clearHolisticLandmarker()")
        holisticLandmarker?.close()
        holisticLandmarker = null
    }

    fun reset() {
        frameCounter = 0
        Log.d(TAG, "reset() -> frameCounter=0")
    }

    fun sendStatus(message: String) {
        Log.d(TAG, "STATUS -> $message")
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
        Log.d(TAG, "FRAME_UPDATE -> $frameCount")
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
        rightHandCount: Int
    ) {
        Log.d(
            TAG,
            "LANDMARK_UPDATE -> frame=$frameCount face=$faceCount pose=$poseCount lh=$leftHandCount rh=$rightHandCount"
        )

        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "landmark_update",
                    "frameCount" to frameCount,
                    "faceCount" to faceCount,
                    "poseCount" to poseCount,
                    "leftHandCount" to leftHandCount,
                    "rightHandCount" to rightHandCount,
                    "faceDetected" to (faceCount > 0),
                    "poseDetected" to (poseCount > 0),
                    "leftHandDetected" to (leftHandCount > 0),
                    "rightHandDetected" to (rightHandCount > 0)
                )
            )
        }
    }

    fun processBitmap(bitmap: Bitmap, frameNumber: Int) {
        val landmarker = holisticLandmarker

        if (landmarker == null) {
            Log.d(TAG, "processBitmap() skipped: holisticLandmarker is null")
            return
        }

        try {
            val argbBitmap =
                if (bitmap.config == Bitmap.Config.ARGB_8888) bitmap
                else bitmap.copy(Bitmap.Config.ARGB_8888, false)

            Log.d(TAG, "processBitmap() frame=$frameNumber size=${argbBitmap.width}x${argbBitmap.height}")

            val mpImage = BitmapImageBuilder(argbBitmap).build()
            val result = landmarker.detect(mpImage)
            mpImage.close()

            val faceCount = result.faceLandmarks().size
            val poseCount = result.poseLandmarks().size
            val leftHandCount = result.leftHandLandmarks().size
            val rightHandCount = result.rightHandLandmarks().size

            sendLandmarkUpdate(
                frameCount = frameNumber,
                faceCount = faceCount,
                poseCount = poseCount,
                leftHandCount = leftHandCount,
                rightHandCount = rightHandCount
            )

            if (frameNumber == 30) {
                sendStatus("30 native landmark frames collected ✅")
            }
        } catch (e: Exception) {
            Log.e(TAG, "processBitmap() failed", e)
            sendStatus("Holistic detection error: ${e.message}")
        }
    }
}