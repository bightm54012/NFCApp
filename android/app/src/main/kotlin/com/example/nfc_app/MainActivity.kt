package com.example.nfc_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.nfc/action").setMethodCallHandler { call, result ->
            if (call.method == "startEmulation") {
                val uid = call.argument<String>("uid")
                result.success("Android 已針對 ID $uid 開啟 HCE 服務")
            } else {
                result.notImplemented()
            }
        }
    }
}