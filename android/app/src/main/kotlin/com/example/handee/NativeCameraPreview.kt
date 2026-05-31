package com.example.handee

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
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
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
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
        private const val ANALYZE_EVERY_NTH_FRAME = 3
    }

    init {
        previewView.scaleType = PreviewView.ScaleType.FILL_CENTER
        previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        previewView.setBackgroundColor(android.graphics.Color.BLACK)
        startCamera()
    }

    override fun getView() = previewView

    override fun dispose() {
        try {
            cameraProvider?.unbindAll()
            analysisExecutor.shutdown()
        } catch (_: Exception) {
        }
    }

    private fun startCamera() {
        val hasPermission =
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.CAMERA
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED

        if (!hasPermission) {
            Log.e(TAG, "Camera permission not granted")
            NativeAslState.sendStatus("Camera permission not granted")
            return
        }

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()

                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
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

                NativeAslState.sendStatus("Native camera preview started")
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
                return
            }

            NativeAslState.frameCounter++
            val currentFrame = NativeAslState.frameCounter

            if (currentFrame % ANALYZE_EVERY_NTH_FRAME != 0) {
                return
            }

            NativeAslState.sendFrameUpdate(currentFrame)

            val bitmap = imageProxyToBitmap(imageProxy)
            if (bitmap == null) {
                NativeAslState.sendStatus("Camera frame conversion failed")
                return
            }

            NativeAslState.processBitmap(bitmap, currentFrame)
        } catch (e: Exception) {
            Log.e(TAG, "analyzeFrame() failed", e)
            NativeAslState.sendStatus("Native frame analysis error: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }

    private fun imageProxyToBitmap(imageProxy: ImageProxy): Bitmap? {
        if (imageProxy.format != ImageFormat.YUV_420_888) {
            Log.w(TAG, "Unsupported image format: ${imageProxy.format}")
            return null
        }

        val nv21 = yuv420888ToNv21(imageProxy)
        val yuvImage = YuvImage(
            nv21,
            ImageFormat.NV21,
            imageProxy.width,
            imageProxy.height,
            null
        )

        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(
            Rect(0, 0, imageProxy.width, imageProxy.height),
            85,
            out
        )
        val imageBytes = out.toByteArray()
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return null

        val rotationDegrees = imageProxy.imageInfo.rotationDegrees.toFloat()
        if (rotationDegrees == 0f) {
            return bitmap
        }

        val matrix = Matrix().apply {
            postRotate(rotationDegrees)
        }

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }

    private fun yuv420888ToNv21(imageProxy: ImageProxy): ByteArray {
        val width = imageProxy.width
        val height = imageProxy.height

        val ySize = width * height
        val uvSize = width * height / 4
        val nv21 = ByteArray(ySize + uvSize * 2)

        imageProxy.planes[0].buffer.toByteArray(
            nv21,
            0,
            width,
            height,
            imageProxy.planes[0].rowStride,
            imageProxy.planes[0].pixelStride
        )

        val uBuffer = imageProxy.planes[1].buffer
        val vBuffer = imageProxy.planes[2].buffer
        val uRowStride = imageProxy.planes[1].rowStride
        val vRowStride = imageProxy.planes[2].rowStride
        val uPixelStride = imageProxy.planes[1].pixelStride
        val vPixelStride = imageProxy.planes[2].pixelStride

        var outputOffset = ySize
        val chromaHeight = height / 2
        val chromaWidth = width / 2

        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val uIndex = row * uRowStride + col * uPixelStride
                val vIndex = row * vRowStride + col * vPixelStride
                nv21[outputOffset++] = vBuffer.get(vIndex)
                nv21[outputOffset++] = uBuffer.get(uIndex)
            }
        }

        return nv21
    }

    private fun ByteBuffer.toByteArray(
        output: ByteArray,
        outputOffset: Int,
        width: Int,
        height: Int,
        rowStride: Int,
        pixelStride: Int
    ) {
        val buffer = duplicate()
        var offset = outputOffset

        for (row in 0 until height) {
            val rowStart = row * rowStride
            for (col in 0 until width) {
                output[offset++] = buffer.get(rowStart + col * pixelStride)
            }
        }
    }

}
