package com.bdewev18.dicethronesolo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dt_solo_quest/active_adventure"
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("dt_solo_quest", MODE_PRIVATE)
            val key = call.argument<String>("key") ?: "active_adventure_v1"

            when (call.method) {
                "read" -> result.success(prefs.getString(key, null))
                "write" -> {
                    val value = call.argument<String>("value") ?: ""
                    prefs.edit().putString(key, value).apply()
                    result.success(null)
                }
                "clear" -> {
                    prefs.edit().remove(key).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
