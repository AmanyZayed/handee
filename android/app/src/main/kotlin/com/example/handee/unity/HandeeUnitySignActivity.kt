package com.example.handee.unity

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.unity3d.player.UnityPlayer
import com.unity3d.player.UnityPlayerActivity

/** Full-screen Unity signer fallback. */
class HandeeUnitySignActivity : UnityPlayerActivity() {

    companion object {
        private const val TAG = "HandeeUnitySign"
        const val EXTRA_WORD = "word"
        private val SIGN_TARGETS = listOf(
            "Hamada",
        )
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val word = intent.getStringExtra(EXTRA_WORD)?.trim()?.lowercase().orEmpty()
        if (word.isEmpty()) {
            finish()
            return
        }

        val delays = longArrayOf(800, 1500, 2500, 3500, 5000, 7000)
        for (delay in delays) {
            handler.postDelayed({ sendSign(word) }, delay)
        }

        handler.postDelayed({ if (!isFinishing) finish() }, 14000L)
    }

    private fun sendSign(word: String) {
        for (target in SIGN_TARGETS) {
            try {
                UnityPlayer.UnitySendMessage(target, "ReceiveTextFromFlutter", word)
                Log.i(TAG, "Sent $target ReceiveTextFromFlutter: $word")
            } catch (e: Exception) {
                Log.e(TAG, "Send failed for $target", e)
            }
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
