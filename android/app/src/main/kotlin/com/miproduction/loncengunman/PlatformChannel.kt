package com.miproduction.loncengunman

import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Registers a Flutter MethodChannel that exposes Android platform information.
 *
 * Currently exposes:
 * - `getSdkVersion` → `Build.VERSION.SDK_INT` (e.g. 31 for Android 12)
 *
 * Used by [AndroidCompat] on the Dart side to branch behavior for
 * version-specific restrictions (PendingIntent mutability, POST_NOTIFICATIONS
 * runtime permission, foreground service types, exact-alarm checks, etc.).
 */
class PlatformChannel {
    companion object {
        const val CHANNEL = "com.lonceng_unman/platform"
    }

    fun configure(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSdkVersion" -> result.success(Build.VERSION.SDK_INT)
                    else -> result.notImplemented()
                }
            }
    }
}
