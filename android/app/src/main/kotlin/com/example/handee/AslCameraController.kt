package com.example.handee

import android.content.Context

class AslCameraController(private val context: Context) {

    private var isCameraStarted = false

    fun startCamera(): String {
        isCameraStarted = true
        return "Native camera controller started ✅"
    }

    fun stopCamera(): String {
        isCameraStarted = false
        return "Native camera controller stopped ✅"
    }

    fun isRunning(): Boolean {
        return isCameraStarted
    }
}