package com.example.handee

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class NativeCameraPreview(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner
) : PlatformView {

    private val previewView: PreviewView = PreviewView(context)
    private var cameraProvider: ProcessCameraProvider? = null
    private val analysisExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    companion object {
        private const val TAG = "ASL_CAMERA"
    }

    init {
        previewView.scaleType = PreviewView.ScaleType.FILL_CENTER
        Log.d(TAG, "NativeCameraPreview init")
        startCamera()
    }

    override fun getView() = previewView

    override fun dispose() {
        Log.d(TAG, "dispose()")
        try {
            cameraProvider?.unbindAll()
            analysisExecutor.shutdown()
        } catch (_: Exception) {
        }
    }

    private fun startCamera() {
        Log.d(TAG, "startCamera() called")

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                Log.d(TAG, "cameraProvider ready")

                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                    .also { analysis ->
                        analysis.setAnalyzer(analysisExecutor) { imageProxy ->
                            analyzeFrame(imageProxy)
                        }
                    }

                val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    preview,
                    imageAnalysis
                )

                Log.d(TAG, "bindToLifecycle success")
                NativeAslState.sendStatus("Native camera preview started ✅")
            } catch (e: Exception) {
                Log.e(TAG, "startCamera() failed", e)
                NativeAslState.sendStatus("Failed to start native camera preview: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun analyzeFrame(imageProxy: ImageProxy) {
        try {
            if (!NativeAslState.recognitionStarted) {
                imageProxy.close()
                return
            }

            NativeAslState.frameCounter++
            val currentFrame = NativeAslState.frameCounter

            if (currentFrame % 5 == 0) {
                Log.d(TAG, "analyzeFrame() frame=$currentFrame")
                NativeAslState.sendFrameUpdate(currentFrame)

                val currentBitmap = previewView.bitmap
                if (currentBitmap != null) {
                    Log.d(TAG, "preview bitmap OK for frame=$currentFrame")
                    NativeAslState.processBitmap(currentBitmap, currentFrame)
                } else {
                    Log.d(TAG, "preview bitmap NULL for frame=$currentFrame")
                    NativeAslState.sendStatus("Preview bitmap not ready yet")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "analyzeFrame() failed", e)
            NativeAslState.sendStatus("Native frame analysis error: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }
}