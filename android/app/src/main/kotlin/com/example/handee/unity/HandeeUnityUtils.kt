package com.example.handee.unity

import android.annotation.SuppressLint
import android.app.Activity
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

    var activity: Activity? = null
    var unityPlayer: HandeeUnityPlayer? = null
    var unityFrameLayout: FrameLayout? = null

    /** Player instance exists (may still be loading scene). */
    var unityLoaded: Boolean = false

    /** Scene is ready for UnitySendMessage (set after first attach + delay). */
    @Volatile
    var sceneReady: Boolean = false

    var pendingMessage: Triple<String, String, String>? = null

    private val legacyTargets = listOf("Hamada", "Avatar")

    private val attachListener = object : View.OnAttachStateChangeListener {
        override fun onViewAttachedToWindow(view: View) {
            scheduleSceneReady()
            prepareForMessage()
            flushPendingMessage()
        }

        override fun onViewDetachedFromWindow(view: View) {}
    }

    private fun scheduleSceneReady() {
        sceneReady = false
        mainHandler.removeCallbacksAndMessages(null)
        val delays = longArrayOf(2000, 4000, 6000, 9000)
        for (delay in delays) {
            mainHandler.postDelayed(
                {
                    sceneReady = true
                    prepareForMessage()
                    flushPendingMessage()
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

    fun prepareForMessage() {
        if (!unityLoaded || unityPlayer == null) return
        try {
            unityFrameLayout?.requestFocus()
            unityPlayer?.windowFocusChanged(true)
            unityPlayer?.resume()
        } catch (e: Exception) {
            Log.e(TAG, "prepareForMessage failed", e)
        }
    }

    fun postMessage(gameObject: String, methodName: String, message: String) {
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

        // Current export uses Hamada + ReceiveTextFromFlutter until Unity is rebuilt with AvatarController.
        if (methodName == "PlaySign") {
            for (target in legacyTargets) {
                send(target, "ReceiveTextFromFlutter", message)
                send(target, "PlayText", "")
            }
        } else if (methodName == "ReceiveTextFromFlutter") {
            for (target in legacyTargets) {
                send(target, "PlayText", "")
            }
        }
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
        prepareForMessage()
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
        prepareForMessage()
    }
}
