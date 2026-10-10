package com.security.antitheft.dont_touch_my_phone

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * NativeSecurityPlugin provides real hardware access for:
 * - Camera Flashlight / Strobe
 * - Hardware Siren / Alarm Tone generation
 * - Battery monitoring & Charger status
 * - Airplane mode detection
 * - Audio volume override
 * - Front camera intruder photo capture
 */
class NativeSecurityPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.security.antitheft.dont_touch_my_phone/native_security"

        fun registerWith(messenger: BinaryMessenger, context: Context): NativeSecurityPlugin {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val plugin = NativeSecurityPlugin(context)
            channel.setMethodCallHandler(plugin)
            return plugin
        }
    }

    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private var torchCameraId: String? = null
    private var toneGenerator: ToneGenerator? = null
    private var currentRingtone: Ringtone? = null
    private val intruderCaptureManager = IntruderCaptureManager(context)

    init {
        findTorchCameraId()
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        } catch (_: Exception) {}
    }

    private fun findTorchCameraId(): String? {
        if (cameraManager == null) return null
        try {
            // Priority 1: Back camera with flash
            for (id in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(id)
                val hasFlash = chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                if (hasFlash && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    torchCameraId = id
                    return id
                }
            }
            // Priority 2: Any camera with flash
            for (id in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(id)
                val hasFlash = chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                if (hasFlash) {
                    torchCameraId = id
                    return id
                }
            }
        } catch (_: Exception) {}
        return null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasFlash" -> {
                result.success(torchCameraId != null)
            }
            "setFlash" -> {
                val on = call.argument<Boolean>("on") ?: false
                setFlashlight(on, result)
            }
            "playBeep" -> {
                playAlarmTone()
                result.success(true)
            }
            "stopBeep" -> {
                stopAlarmTone()
                result.success(true)
            }
            "getBatteryLevel" -> {
                val level = getBatteryPercentage()
                result.success(level)
            }
            "isCharging" -> {
                val charging = isDeviceCharging()
                result.success(charging)
            }
            "isAirplaneModeOn" -> {
                val airplane = isAirplaneModeActive()
                result.success(airplane)
            }
            "setMaxVolume" -> {
                setMaxAlarmVolume()
                result.success(true)
            }
            "captureIntruderPhoto" -> {
                intruderCaptureManager.captureFrontPhoto(
                    onSuccess = { photoPath ->
                        Handler(Looper.getMainLooper()).post {
                            result.success(photoPath)
                        }
                    },
                    onError = { error ->
                        Handler(Looper.getMainLooper()).post {
                            result.error("CAPTURE_FAILED", error, null)
                        }
                    }
                )
            }
            "startMotionService" -> {
                result.success(true)
            }
            "stopMotionService" -> {
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun setFlashlight(on: Boolean, result: MethodChannel.Result) {
        if (cameraManager == null || torchCameraId == null) {
            result.error("NO_FLASH", "Flashlight hardware not available", null)
            return
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                cameraManager.setTorchMode(torchCameraId!!, on)
                result.success(true)
            } else {
                result.error("UNSUPPORTED", "Camera2 torch requires API 23+", null)
            }
        } catch (e: Exception) {
            result.error("FLASH_ERROR", e.message, null)
        }
    }

    private fun playAlarmTone() {
        try {
            // Maximize alarm volume
            setMaxAlarmVolume()

            // Play emergency tone generator
            toneGenerator?.startTone(ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 1500)

            // Play alarm ringtone
            val alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val ringtone = RingtoneManager.getRingtone(context, alertUri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                ringtone?.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            currentRingtone?.stop()
            currentRingtone = ringtone
            currentRingtone?.play()
        } catch (_: Exception) {}
    }

    private fun stopAlarmTone() {
        try {
            currentRingtone?.stop()
            currentRingtone = null
            toneGenerator?.stopTone()
        } catch (_: Exception) {}
    }

    private fun setMaxAlarmVolume() {
        try {
            audioManager?.let { am ->
                val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                am.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
            }
        } catch (_: Exception) {}
    }

    private fun getBatteryPercentage(): Int {
        return try {
            val bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        } catch (_: Exception) {
            -1
        }
    }

    private fun isDeviceCharging(): Boolean {
        return try {
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = context.registerReceiver(null, filter)
            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        } catch (_: Exception) {
            false
        }
    }

    private fun isAirplaneModeActive(): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) != 0
        } catch (_: Exception) {
            false
        }
    }

    fun cleanUp() {
        try {
            setFlashlight(false, object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            toneGenerator?.release()
        } catch (_: Exception) {}
    }
}
