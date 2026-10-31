package com.example.secret_word_society

import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "secret_word_society/round_signal").setMethodCallHandler { call, result ->
            when (call.method) {
                "backgroundAllowed" -> result.success(RoundSignal.backgroundAllowed(this))
                "requestBackground" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        !RoundSignal.backgroundAllowed(this)) {
                        startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                            Uri.parse("package:$packageName")))
                    }
                    result.success(null)
                }
                "arm" -> {
                    RoundSignal.arm(applicationContext, call.argument<String>("token")!!,
                        call.argument<Number>("deadlineMillis")!!.toLong())
                    result.success(null)
                }
                "finish" -> {
                    RoundSignal.finish(applicationContext, call.argument<String>("token"))
                    result.success(null)
                }
                "cancel" -> {
                    RoundSignal.cancel(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        RoundSignal.cancel(applicationContext)
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Protect the entire window from its first frame, including task previews.
        // Keeping this enabled avoids a platform-channel race when revealing a card.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }
}
