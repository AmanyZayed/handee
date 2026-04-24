package com.example.handee

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ai_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "getPrediction") {
                    result.success("AI is working 🔥")
                }

              
                else if (call.method == "openCamera") {
                    val intent = Intent(this, CameraActivity::class.java)
                    startActivity(intent)
                    result.success("opened")
                }
            }
    }
}