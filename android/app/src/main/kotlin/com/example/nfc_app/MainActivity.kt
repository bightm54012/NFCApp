package com.ni.nfcApp

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.nfc/action").setMethodCallHandler { call, result ->
            if (call.method == "startEmulation") {
                val uid = call.argument<String>("uid")
                getSharedPreferences("NFC_PREFS", Context.MODE_PRIVATE).edit().putString("current_uid", uid).apply()
                result.success("Android 模擬就緒: $uid")
            }
        }
    }
}