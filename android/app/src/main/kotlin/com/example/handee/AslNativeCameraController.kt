package com.example.handee

import android.annotation.SuppressLint
import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class AslNativeCameraController(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onFrameAnalyzed: (Int) -> Unit,
    private val onStatus: (String) -> Unit
) {
    private var cameraProvider: ProcessCameraProvider? = null
    private var analysisExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var imageAnalysis: ImageAnalysis? = null
    private var isStarted = false
    private var frameCounter = 0

    fun startCamera(): String {
        if (isStarted) return "Native camera already started ✅"

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()

                imageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                    .also { analysis ->
                        analysis.setAnalyzer(analysisExecutor) { imageProxy ->
                            processFrame(imageProxy)
                        }
                    }

                val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    imageAnalysis
                )

                isStarted = true
                onStatus("Native CameraX analysis started ✅")
            } catch (e: Exception) {
                onStatus("Failed to start native camera: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(context))

        return "Starting native camera..."
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun processFrame(imageProxy: ImageProxy) {
        try {
            frameCounter++

            if (frameCounter % 10 == 0) {
                onFrameAnalyzed(frameCounter)
            }
        } catch (e: Exception) {
            onStatus("Frame analysis error: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }

    fun stopCamera(): String {
        return try {
            cameraProvider?.unbindAll()
            isStarted = false
            frameCounter = 0
            onStatus("Native camera stopped ✅")
            "Native camera stopped ✅"
        } catch (e: Exception) {
            "Failed to stop native camera: ${e.message}"
        }
    }

    fun release() {
        try {
            cameraProvider?.unbindAll()
            analysisExecutor.shutdown()
            isStarted = false
        } catch (_: Exception) {
        }
    }
}