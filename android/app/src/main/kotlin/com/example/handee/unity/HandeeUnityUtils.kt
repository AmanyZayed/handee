package com.example.handee.unity

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.unity3d.player.IUnityPlayerLifecycleEvents
import com.unity3d.player.UnityPlayer

object HandeeUnityUtils {
    private const val TAG = "HandeeUnityUtils"

    private val mainHandler = Handler(Looper.getMainLooper())

    // Scene GameObject that owns the ASLAnimator script.
    private val signTargets = listOf(
        "Hamada",
    )

    var activity: Activity? = null
    var unityPlayer: HandeeUnityPlayer? = null
    var unityFrameLayout: FrameLayout? = null

    var unityLoaded: Boolean = false

    @Volatile
    var sceneReady: Boolean = false

    /// Unity ships arm64 native libs only — x86/x86_64 emulators cannot load libmain.so.
    fun isNativeRuntimeSupported(): Boolean {
        val primary = Build.SUPPORTED_ABIS.firstOrNull() ?: return false
        return primary == "arm64-v8a" || primary == "armeabi-v7a"
    }

    private var pendingSignWord: String? = null
    var pendingMessage: Triple<String, String, String>? = null

    private val attachListener = object : View.OnAttachStateChangeListener {
        override fun onViewAttachedToWindow(view: View) {
            scheduleSceneReady()
            prepareForMessage()
            flushPending()
        }

        override fun onViewDetachedFromWindow(view: View) {}
    }

    private fun scheduleSceneReady() {
        sceneReady = false
        mainHandler.removeCallbacksAndMessages(null)
        val delays = longArrayOf(500, 1200, 2500, 4000, 6000, 8000)
        for (delay in delays) {
            mainHandler.postDelayed(
                {
                    sceneReady = true
                    prepareForMessage()
                    flushPending()
                    Log.i(TAG, "sceneReady at ${delay}ms")
                },
                delay,
            )
        }
    }

    @SuppressLint("NewApi")
    fun createUnityPlayer(
        events: IUnityPlayerLifecycleEvents,
        onReady: () -> Unit,
    ) {
        if (!isNativeRuntimeSupported()) {
            Log.w(TAG, "Unity skipped: CPU ABI not supported on this device/emulator")
            return
        }

        val act = activity ?: return

        if (unityFrameLayout != null) {
            unityLoaded = true
            prepareForMessage()
            onReady()
            return
        }

        try {
            unityPlayer = HandeeUnityPlayer(act, events)
            unityFrameLayout = unityPlayer!!.getFrameLayout()
            unityLoaded = true
            unityFrameLayout?.addOnAttachStateChangeListener(attachListener)
            prepareForMessage()
            onReady()
        } catch (e: Exception) {
            Log.e(TAG, "createUnityPlayer failed", e)
        }
    }

    fun prepareForMessage(requestFocus: Boolean = false) {
        if (!unityLoaded || unityPlayer == null) return
        try {
            if (requestFocus) {
                unityFrameLayout?.requestFocus()
            }
            unityPlayer?.windowFocusChanged(true)
            unityPlayer?.resume()
        } catch (e: Exception) {
            Log.e(TAG, "prepareForMessage failed", e)
        }
    }

    fun playSignWord(word: String) {
        val trimmed = word.trim().lowercase()
        if (trimmed.isEmpty() || !isNativeRuntimeSupported()) return

        if (!unityLoaded || unityPlayer == null || !sceneReady) {
            pendingSignWord = trimmed
            Log.w(TAG, "playSignWord queued: $trimmed")
            return
        }

        dispatchSignWord(trimmed)
    }

    private fun dispatchSignWord(word: String) {
        prepareForMessage(requestFocus = true)
        for (target in signTargets) {
            send(target, "ReceiveTextFromFlutter", word)
        }
    }

    fun postMessage(gameObject: String, methodName: String, message: String) {
        if (!isNativeRuntimeSupported()) return

        if (!unityLoaded || unityPlayer == null) {
            pendingMessage = Triple(gameObject, methodName, message)
            Log.w(TAG, "postMessage queued (player not ready)")
            return
        }

        if (!sceneReady) {
            pendingMessage = Triple(gameObject, methodName, message)
            Log.w(TAG, "postMessage queued (scene not ready)")
            return
        }

        prepareForMessage()
        send(gameObject, methodName, message)
    }

    private fun send(gameObject: String, methodName: String, message: String) {
        if (gameObject.isBlank() || methodName.isBlank()) return
        try {
            UnityPlayer.UnitySendMessage(gameObject, methodName, message)
            Log.i(TAG, "UnitySendMessage -> $gameObject.$methodName(\"$message\")")
        } catch (e: Exception) {
            Log.e(TAG, "postMessage failed for $gameObject", e)
        }
    }

    fun flushPending() {
        flushPendingMessage()
        val word = pendingSignWord
        if (word != null && sceneReady && unityLoaded && unityPlayer != null) {
            pendingSignWord = null
            dispatchSignWord(word)
        }
    }

    fun flushPendingMessage() {
        val pending = pendingMessage ?: return
        if (!sceneReady || !unityLoaded || unityPlayer == null) return
        pendingMessage = null
        postMessage(pending.first, pending.second, pending.third)
    }

    fun pause() {
        try {
            unityPlayer?.pause()
        } catch (e: Exception) {
            Log.e(TAG, "pause failed", e)
        }
    }

    fun resume() {
        try {
            unityPlayer?.resume()
        } catch (e: Exception) {
            Log.e(TAG, "resume failed", e)
        }
    }

    fun focus() {
        prepareForMessage(requestFocus = true)
    }

    fun addUnityViewToGroup(group: ViewGroup) {
        val frame = unityFrameLayout ?: return
        if (frame.parent != null) {
            (frame.parent as ViewGroup).removeView(frame)
        }
        group.addView(
            frame,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        scheduleSceneReady()
    }

    fun refocus() {
        prepareForMessage(requestFocus = true)
    }
}
