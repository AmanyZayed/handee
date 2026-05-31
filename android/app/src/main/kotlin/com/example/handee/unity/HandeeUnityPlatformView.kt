package com.example.handee.unity

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
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

        if (HandeeUnityUtils.unityPlayer == null) {
            HandeeUnityUtils.createUnityPlayer(this) { attachToView() }
        } else {
            attachToView()
        }
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
