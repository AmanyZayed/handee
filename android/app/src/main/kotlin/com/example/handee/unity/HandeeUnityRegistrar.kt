package com.example.handee.unity

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine

object HandeeUnityRegistrar {
    const val VIEW_TYPE = "handee-unity-view"

    fun register(flutterEngine: FlutterEngine, activity: Activity) {
        HandeeUnityUtils.activity = activity
        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIEW_TYPE,
            HandeeUnityViewFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
    }

    fun onResume() {
        HandeeUnityUtils.resume()
        HandeeUnityUtils.refocus()
    }
}
