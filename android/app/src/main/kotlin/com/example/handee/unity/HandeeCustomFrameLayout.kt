package com.example.handee.unity

import android.content.Context
import android.view.InputDevice
import android.view.MotionEvent
import android.widget.FrameLayout

class HandeeCustomFrameLayout(context: Context) : FrameLayout(context) {
    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        event.source = InputDevice.SOURCE_TOUCHSCREEN
        return super.dispatchTouchEvent(event)
    }
}
