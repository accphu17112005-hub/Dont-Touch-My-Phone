package com.security.antitheft.dont_touch_my_phone

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * Handles silent front-camera intruder photo capture using Android Camera2 API.
 * Triggered when unauthorized unlock attempts exceed the configured threshold.
 */
class IntruderCaptureManager(private val context: Context) {

    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager

    fun captureFrontPhoto(onSuccess: (String) -> Unit, onError: (String) -> Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            onError("Camera permission not granted")
            return
        }

        if (cameraManager == null) {
            onError("Camera service unavailable")
            return
        }

        try {
            var frontCameraId: String? = null
            for (id in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(id)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    frontCameraId = id
                    break
                }
            }

            if (frontCameraId == null) {
                onError("No front camera found")
                return
            }

            val thread = HandlerThread("IntruderCaptureThread").apply { start() }
            val backgroundHandler = Handler(thread.looper)

            val imageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 2)
            imageReader.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
                val buffer = image.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                image.close()

                try {
                    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                    val dir = File(context.filesDir, "intruders")
                    if (!dir.exists()) dir.mkdirs()
                    val photoFile = File(dir, "INTRUDER_$timeStamp.jpg")
                    FileOutputStream(photoFile).use { it.write(bytes) }

                    onSuccess(photoFile.absolutePath)
                } catch (e: Exception) {
                    onError("Failed saving image: ${e.message}")
                } finally {
                    thread.quitSafely()
                }
            }, backgroundHandler)

            @SuppressLint("MissingPermission")
            cameraManager.openCamera(frontCameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    try {
                        val captureBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
                        captureBuilder.addTarget(imageReader.surface)
                        captureBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                        captureBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)

                        camera.createCaptureSession(
                            listOf(imageReader.surface),
                            object : CameraCaptureSession.StateCallback() {
                                override fun onConfigured(session: CameraCaptureSession) {
                                    try {
                                        session.capture(
                                            captureBuilder.build(),
                                            object : CameraCaptureSession.CaptureCallback() {
                                                override fun onCaptureCompleted(
                                                    session: CameraCaptureSession,
                                                    request: CaptureRequest,
                                                    result: TotalCaptureResult
                                                ) {
                                                    super.onCaptureCompleted(session, request, result)
                                                    camera.close()
                                                }
                                            },
                                            backgroundHandler
                                        )
                                    } catch (e: Exception) {
                                        camera.close()
                                        thread.quitSafely()
                                        onError("Capture session error: ${e.message}")
                                    }
                                }

                                override fun onConfigureFailed(session: CameraCaptureSession) {
                                    camera.close()
                                    thread.quitSafely()
                                    onError("Failed to configure capture session")
                                }
                            },
                            backgroundHandler
                        )
                    } catch (e: Exception) {
                        camera.close()
                        thread.quitSafely()
                        onError("Camera initialization error: ${e.message}")
                    }
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    thread.quitSafely()
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    thread.quitSafely()
                    onError("CameraDevice error code: $error")
                }
            }, backgroundHandler)

        } catch (e: Exception) {
            onError("Exception opening camera: ${e.message}")
        }
    }
}
