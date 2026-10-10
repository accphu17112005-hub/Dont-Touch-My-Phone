package com.security.antitheft.dont_touch_my_phone

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var nativeSecurityPlugin: NativeSecurityPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep screen on when security app is in foreground and allow showing over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeSecurityPlugin = NativeSecurityPlugin.registerWith(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext
        )
    }

    override fun onDestroy() {
        nativeSecurityPlugin?.cleanUp()
        super.onDestroy()
    }
}
