package com.example.handee.unity

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.unity3d.player.UnityPlayer
import com.unity3d.player.UnityPlayerActivity

/**
 * Full-screen Unity signer — AvatarController.PlaySign + legacy fallbacks.
 */
class HandeeUnitySignActivity : UnityPlayerActivity() {

    companion object {
        private const val TAG = "HandeeUnitySign"
        const val EXTRA_WORD = "word"
        private const val PRIMARY_OBJECT = "AvatarController"
        private const val PRIMARY_METHOD = "PlaySign"
        private val LEGACY_TARGETS = listOf("Hamada", "Avatar")
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val word = intent.getStringExtra(EXTRA_WORD)?.trim()?.lowercase().orEmpty()
        if (word.isEmpty()) {
            finish()
            return
        }

        val delays = longArrayOf(800, 1500, 2500, 3500, 5000, 7000, 9000)
        for (delay in delays) {
            handler.postDelayed({ sendSign(word) }, delay)
        }

        handler.postDelayed({ if (!isFinishing) finish() }, 14000L)
    }

    private fun sendSign(word: String) {
        try {
            UnityPlayer.UnitySendMessage(PRIMARY_OBJECT, PRIMARY_METHOD, word)
            Log.i(TAG, "Sent $PRIMARY_OBJECT.$PRIMARY_METHOD: $word")
        } catch (e: Exception) {
            Log.e(TAG, "Primary send failed", e)
        }

        for (target in LEGACY_TARGETS) {
            try {
                UnityPlayer.UnitySendMessage(target, "ReceiveTextFromFlutter", word)
                UnityPlayer.UnitySendMessage(target, "PlayText", "")
                Log.i(TAG, "Legacy sent to $target: $word")
            } catch (e: Exception) {
                Log.e(TAG, "Legacy send failed for $target", e)
            }
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
