package com.masruri.fashohah

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.masruri.fashohah/notifications"
        ).setMethodCallHandler { call, result ->
            if (call.method == "clearNotificationCache") {
                applicationContext
                    .getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
                    .edit().clear().commit() // commit() = synchronous, apply() = async
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
