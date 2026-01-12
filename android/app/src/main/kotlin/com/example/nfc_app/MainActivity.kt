package com.ni.nfcApp

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.nfc/action"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startEmulation") {
                val uid = call.argument<String>("uid")
                if (uid != null) {
                    val prefs = getSharedPreferences("NFC_STORAGE", Context.MODE_PRIVATE)
                    prefs.edit().putString("current_uid", uid).apply()
                    result.success("Android 準備模擬 UID: $uid")
                } else {
                    result.error("EMPTY_UID", "UID 格式錯誤", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}