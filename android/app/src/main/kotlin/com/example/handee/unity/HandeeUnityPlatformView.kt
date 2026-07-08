package com.example.handee.unity

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import com.unity3d.player.IUnityPlayerLifecycleEvents
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class HandeeUnityPlatformView(
    private val viewId: Int,
    context: Context?,
    messenger: BinaryMessenger,
) : PlatformView,
    MethodChannel.MethodCallHandler,
    IUnityPlayerLifecycleEvents {

    private val logTag = "HandeeUnityView"
    private val channel = MethodChannel(messenger, "handee_unity_$viewId")
    private val frameLayout = HandeeCustomFrameLayout(context!!)

    init {
        frameLayout.setBackgroundColor(Color.TRANSPARENT)
        channel.setMethodCallHandler(this)

        if (!HandeeUnityUtils.isNativeRuntimeSupported()) {
            showUnsupportedPlaceholder()
        } else if (HandeeUnityUtils.unityPlayer == null) {
            HandeeUnityUtils.createUnityPlayer(this) { attachToView() }
        } else {
            attachToView()
        }
    }

    private fun showUnsupportedPlaceholder() {
        val label = TextView(frameLayout.context).apply {
            text = "3D avatar needs a physical Android phone\n(ARM device — not x86 emulator)"
            setTextColor(Color.argb(210, 255, 255, 255))
            textSize = 13f
            gravity = Gravity.CENTER
            setPadding(24, 24, 24, 24)
        }
        frameLayout.addView(
            label,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            ),
        )
    }

    private fun attachToView() {
        HandeeUnityUtils.addUnityViewToGroup(frameLayout)
        HandeeUnityUtils.refocus()
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "postMessage" -> {
                val gameObject = call.argument<String>("gameObject") ?: ""
                val methodName = call.argument<String>("methodName") ?: ""
                val message = call.argument<String>("message") ?: ""
                HandeeUnityUtils.postMessage(gameObject, methodName, message)
                HandeeUnityUtils.refocus()
                result.success(true)
            }
            "resume" -> {
                HandeeUnityUtils.resume()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onUnityPlayerUnloaded() {
        HandeeUnityUtils.unityLoaded = false
    }

    override fun onUnityPlayerQuitted() {
        Log.d(logTag, "Unity player quitted")
    }
}
