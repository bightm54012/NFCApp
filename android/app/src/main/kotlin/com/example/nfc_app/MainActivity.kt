package com.example.nfc_app

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
                // 從 Flutter 傳過來的參數中取得 uid 和 mode
                val uid = call.argument<String>("uid") ?: ""
                val mode = call.argument<String>("mode") ?: "none"

                if (uid.isNotEmpty()) {
                    // 儲存到 SharedPreferences 供 MyHceService 讀取
                    val prefs = getSharedPreferences("NFC_SETTINGS", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("uid", uid)
                        .putString("mode", mode)
                        .apply()

                    // 回傳 uid 給 Flutter 表示成功
                    result.success(uid)
                } else {
                    result.error("INVALID_ID", "UID is empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}