package com.example.secret_word_society

import android.os.Bundle
import android.media.AudioManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var resumed = false

    private fun updateKeepScreenOn() {
        if (resumed && RoundSignal.keepingScreenOn) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onResume() {
        super.onResume()
        volumeControlStream = AudioManager.STREAM_MUSIC
        resumed = true
        RoundSignal.setForeground(true)
        updateKeepScreenOn()
    }

    override fun onPause() {
        resumed = false
        RoundSignal.setForeground(false)
        updateKeepScreenOn()
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "secret_word_society/round_signal").setMethodCallHandler { call, result ->
            when (call.method) {
                "arm" -> {
                    RoundSignal.arm(call.argument<String>("token")!!,
                        call.argument<Number>("deadlineMillis")!!.toLong())
                    updateKeepScreenOn()
                    result.success(null)
                }
                "finish" -> {
                    RoundSignal.finish(applicationContext, call.argument<String>("token"),
                        call.argument<Boolean>("audible") == true && hasWindowFocus()) {
                        updateKeepScreenOn()
                    }
                    updateKeepScreenOn()
                    result.success(null)
                }
                "cancel" -> {
                    RoundSignal.cancel()
                    updateKeepScreenOn()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        RoundSignal.cancel()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Protect the entire window from its first frame, including task previews.
        // Keeping this enabled avoids a platform-channel race when revealing a card.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }
}
