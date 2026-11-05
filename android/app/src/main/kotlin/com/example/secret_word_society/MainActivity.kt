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

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        RoundSignal.setForeground(resumed && hasFocus)
        updateKeepScreenOn()
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
                "prepareReveal" -> {
                    RoundSignal.prepareReveal(call.argument<String>("token")!!)
                    updateKeepScreenOn()
                    result.success(null)
                }
                "reveal" -> {
                    RoundSignal.reveal(applicationContext, call.argument<String>("token"),
                        call.argument<String>("winner"),
                        call.argument<Boolean>("audible") == true && hasWindowFocus()) {
                        updateKeepScreenOn()
                    }
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
        // CameraX creates CAP<number>.jpg in this app's private cache. A killed
        // process cannot run Dart finally blocks; remove only our photo files
        // before a fresh session starts; leave unrelated cache entries intact.
        cacheDir.listFiles()?.forEach { file ->
            if (file.name.matches(Regex("CAP[0-9]+\\.jpg")) && file.isFile) {
                file.delete()
            } else if (file.name.startsWith("sws-photo-") && file.isDirectory) {
                val input = java.io.File(file, "face.jpg")
                input.delete()
                file.delete()
            }
        }
        super.onCreate(savedInstanceState)
    }
}
