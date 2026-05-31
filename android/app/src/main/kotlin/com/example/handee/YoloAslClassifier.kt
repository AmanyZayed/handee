package com.example.handee

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import android.util.Log
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import org.json.JSONObject
import java.io.File
import java.nio.FloatBuffer
import kotlin.math.max
import kotlin.math.min

/**
 * YOLO11 classify (best.pt) via ONNX — same logic as app.py / mediapipe_yolo_mode.py.
 */
class YoloAslClassifier(private val context: Context) {

    enum class ModelKey(val assetFile: String) {
        FULL_COMBINED("yolo/full_combined_best.onnx"),
        LETTERS_DIGITS("yolo/letters_digits_best.onnx"),
    }

    enum class ClassFilter {
        DIGITS,
        LETTERS,
        BOTH,
    }

    data class Prediction(
        val acceptedLabel: String?,
        val confidence: Float,
        val topLabel: String,
    )

    companion object {
        private const val TAG = "YOLO_ASL"
        private const val INPUT_SIZE = 224
        private val DIGITS = (0..9).map { it.toString() }.toSet()
        private val LETTERS = ('A'..'Z').map { it.toString() }.toSet()
    }

    private val ortEnv: OrtEnvironment = OrtEnvironment.getEnvironment()
    private var session: OrtSession? = null
    private var classNames: List<String> = emptyList()
    private var allowedIndices: IntArray = intArrayOf()
    private var confThreshold: Float = 0.6f

    private var cropMarginRatio = 0.35f
    private var cropMarginTightPx = 20
    private var minCropSizePx = 80
    private var useTightCrop = false

    fun load(modelKey: ModelKey, classFilter: ClassFilter, confThreshold: Float, tightCrop: Boolean) {
        releaseSession()
        loadConfig(modelKey, classFilter, confThreshold, tightCrop)

        val modelPath = copyAssetToCache(modelKey.assetFile)
        session = ortEnv.createSession(modelPath, OrtSession.SessionOptions())
        Log.i(TAG, "Loaded ${modelKey.name}, classes=${classNames.size}, allowed=${allowedIndices.size}")
    }

    fun predict(bitmap: Bitmap, handLandmarks: List<NormalizedLandmark>): Prediction? {
        val activeSession = session ?: return null
        if (handLandmarks.isEmpty()) return null

        val box = if (useTightCrop) {
            tightCropBox(handLandmarks, bitmap.width, bitmap.height, cropMarginTightPx)
        } else {
            marginCropBox(handLandmarks, bitmap.width, bitmap.height, cropMarginRatio, minCropSizePx)
        } ?: return null

        val crop = Bitmap.createBitmap(
            bitmap,
            box.left,
            box.top,
            box.width(),
            box.height(),
        )
        val input = preprocess(crop) ?: return null
        crop.recycle()

        val tensor = OnnxTensor.createTensor(ortEnv, input, longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong()))
        tensor.use { inputTensor ->
            activeSession.run(mapOf("images" to inputTensor)).use { result ->
                val output = result[0].value as Array<FloatArray>
                val scores = output[0]
                return decodeScores(scores)
            }
        }
    }

    fun release() {
        releaseSession()
    }

    private fun releaseSession() {
        session?.close()
        session = null
    }

    private fun loadConfig(
        modelKey: ModelKey,
        classFilter: ClassFilter,
        threshold: Float,
        tightCrop: Boolean,
    ) {
        useTightCrop = tightCrop
        confThreshold = threshold

        val jsonText = context.assets.open("asl_yolo_config.json").bufferedReader().use { it.readText() }
        val root = JSONObject(jsonText)
        val pipeline = root.getJSONObject("pipeline")
        cropMarginRatio = pipeline.getDouble("crop_margin").toFloat()
        cropMarginTightPx = pipeline.getInt("crop_margin_tight_px")
        minCropSizePx = pipeline.getInt("min_crop_size_px")

        val modelConfigKey = when (modelKey) {
            ModelKey.FULL_COMBINED -> "full_combined"
            ModelKey.LETTERS_DIGITS -> "letters_digits"
        }
        val classesArray = root.getJSONObject("classes").getJSONArray(modelConfigKey)
        classNames = (0 until classesArray.length()).map { classesArray.getString(it) }

        allowedIndices = classNames.mapIndexedNotNull { index, name ->
            when (classFilter) {
                ClassFilter.DIGITS -> if (name in DIGITS) index else null
                ClassFilter.LETTERS -> if (name in LETTERS) index else null
                ClassFilter.BOTH -> index
            }
        }.toIntArray()
    }

    private fun decodeScores(scores: FloatArray): Prediction {
        var bestIdx = 0
        var bestScore = -1f
        for (idx in allowedIndices) {
            if (idx in scores.indices && scores[idx] > bestScore) {
                bestScore = scores[idx]
                bestIdx = idx
            }
        }
        val topLabel = classNames.getOrElse(bestIdx) { "?" }
        val accepted = if (bestScore >= confThreshold) topLabel else null
        return Prediction(accepted, bestScore, topLabel)
    }

    private fun preprocess(bitmap: Bitmap): FloatBuffer? {
        val scaled = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true)
        if (scaled !== bitmap) {
            bitmap.recycle()
        }

        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        scaled.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)
        scaled.recycle()

        val buffer = FloatBuffer.allocate(3 * INPUT_SIZE * INPUT_SIZE)
        for (y in 0 until INPUT_SIZE) {
            for (x in 0 until INPUT_SIZE) {
                val pixel = pixels[y * INPUT_SIZE + x]
                val r = ((pixel shr 16) and 0xFF) / 255f
                val g = ((pixel shr 8) and 0xFF) / 255f
                val b = (pixel and 0xFF) / 255f
                val offset = y * INPUT_SIZE + x
                buffer.put(offset, r)
                buffer.put(INPUT_SIZE * INPUT_SIZE + offset, g)
                buffer.put(2 * INPUT_SIZE * INPUT_SIZE + offset, b)
            }
        }
        buffer.rewind()
        return buffer
    }

    private fun marginCropBox(
        landmarks: List<NormalizedLandmark>,
        frameW: Int,
        frameH: Int,
        margin: Float,
        minSize: Int,
    ): Rect? {
        val xs = landmarks.map { it.x() * frameW }
        val ys = landmarks.map { it.y() * frameH }
        val xMin = xs.minOrNull() ?: return null
        val xMax = xs.maxOrNull() ?: return null
        val yMin = ys.minOrNull() ?: return null
        val yMax = ys.maxOrNull() ?: return null
        val boxW = xMax - xMin
        val boxH = yMax - yMin
        if (boxW <= 0 || boxH <= 0) return null

        val marginW = (boxW * margin).toInt()
        val marginH = (boxH * margin).toInt()
        val x1 = max(0, (xMin - marginW).toInt())
        val y1 = max(0, (yMin - marginH).toInt())
        val x2 = min(frameW, (xMax + marginW).toInt())
        val y2 = min(frameH, (yMax + marginH).toInt())
        if ((x2 - x1) < minSize || (y2 - y1) < minSize) return null
        return Rect(x1, y1, x2, y2)
    }

    private fun tightCropBox(
        landmarks: List<NormalizedLandmark>,
        frameW: Int,
        frameH: Int,
        marginPx: Int,
    ): Rect? {
        val xs = landmarks.map { it.x() * frameW }
        val ys = landmarks.map { it.y() * frameH }
        val x1 = max(0, (xs.minOrNull()!! - marginPx).toInt())
        val x2 = min(frameW, (xs.maxOrNull()!! + marginPx).toInt())
        val y1 = max(0, (ys.minOrNull()!! - marginPx).toInt())
        val y2 = min(frameH, (ys.maxOrNull()!! + marginPx).toInt())
        if (x2 <= x1 || y2 <= y1) return null
        return Rect(x1, y1, x2, y2)
    }

    private fun copyAssetToCache(assetPath: String): String {
        val fileName = assetPath.substringAfterLast('/')
        val outFile = File(context.cacheDir, fileName)
        if (!outFile.exists()) {
            context.assets.open(assetPath).use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            }
        }
        return outFile.absolutePath
    }
}
