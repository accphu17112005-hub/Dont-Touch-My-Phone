import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../models/app_models.dart';

/// Motion detection service using accelerometer + gyroscope
/// 
/// ANDROID: Works via sensors_plus / native plugin, foreground service keeps it active.
/// iOS: Works while app is in foreground. Apple does NOT allow unrestricted
/// background motion detection. The app MUST be in foreground for detection.
class MotionService {
  static const _channel = MethodChannel(AppConstants.platformChannelName);

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final _motionDetectedController = StreamController<double>.broadcast();

  /// Emits the magnitude of motion when it exceeds the threshold
  Stream<double> get onMotionDetected => _motionDetectedController.stream;

  bool _isRunning = false;
  double _threshold = 2.0;
  int _delaySeconds = 3;

  // Smoothing: keep a rolling average of last N samples
  final List<double> _accelHistory = [];
  static const int _historySize = 5;

  bool get isRunning => _isRunning;

  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  double? _baseX;
  double? _baseY;
  double? _baseZ;
  int _calibrationSamples = 0;
  static const int _requiredCalibrationSamples = 10;

  /// Start listening. [delaySeconds] gives user time to put phone down.
  Future<void> startMonitoring({
    required double sensitivity,
    required int delaySeconds,
    bool skipDelay = false,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    _threshold = sensitivity;
    _delaySeconds = delaySeconds;
    _accelHistory.clear();
    _baseX = null;
    _baseY = null;
    _baseZ = null;
    _calibrationSamples = 0;

    // Platform-specific: start native foreground service on Android
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startMotionService', {
          'sensitivity': sensitivity,
          'delay': delaySeconds,
        });
      } catch (_) {
        // Native motion detection not available — using Flutter-side fallback
      }
    }

    // Wait for arming delay if not skipped
    if (!skipDelay && _delaySeconds > 0) {
      await Future.delayed(Duration(seconds: _delaySeconds));
    }

    if (!_isRunning) return; // User cancelled during delay

    _startSensorListening();
  }

  void _startSensorListening() {
    // 1. Raw accelerometer: detects tilting, picking up, changing orientation
    _accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      _handleAccelEvent,
      onError: (_) {},
    );

    // 2. User accelerometer: detects linear motion/shaking without gravity
    _userAccelSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      _handleUserAccelEvent,
      onError: (_) {},
    );

    // 3. Gyroscope: detects device rotation in rad/s (lifting/moving always rotates)
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      _handleGyroEvent,
      onError: (_) {},
    );
  }

  void _handleAccelEvent(AccelerometerEvent event) {
    // During first few samples, calibrate resting baseline orientation
    if (_calibrationSamples < _requiredCalibrationSamples) {
      _baseX = (_baseX ?? event.x) * 0.7 + event.x * 0.3;
      _baseY = (_baseY ?? event.y) * 0.7 + event.y * 0.3;
      _baseZ = (_baseZ ?? event.z) * 0.7 + event.z * 0.3;
      _calibrationSamples++;
      return;
    }

    // Calculate distance from resting baseline orientation vector
    final dx = event.x - (_baseX ?? event.x);
    final dy = event.y - (_baseY ?? event.y);
    final dz = event.z - (_baseZ ?? event.z);
    final orientationDelta = sqrt(dx * dx + dy * dy + dz * dz);

    if (orientationDelta > _threshold && !_motionDetectedController.isClosed) {
      _motionDetectedController.add(orientationDelta);
    }
  }

  void _handleUserAccelEvent(UserAccelerometerEvent event) {
    if (_calibrationSamples < _requiredCalibrationSamples) return;

    // Magnitude of non-gravity linear acceleration
    final userMag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (userMag > _threshold && !_motionDetectedController.isClosed) {
      _motionDetectedController.add(userMag);
    }
  }

  void _handleGyroEvent(GyroscopeEvent event) {
    if (_calibrationSamples < _requiredCalibrationSamples) return;

    // Angular velocity magnitude in rad/s
    final rotMag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Gyro threshold scaled: 1.0 rad/s is a clear rotation
    final gyroThreshold = (_threshold * 0.6).clamp(0.4, 2.5);
    if (rotMag > gyroThreshold && !_motionDetectedController.isClosed) {
      _motionDetectedController.add(rotMag);
    }
  }

  void stopMonitoring() {
    _isRunning = false;
    _accelSub?.cancel();
    _userAccelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _userAccelSub = null;
    _gyroSub = null;
    _accelHistory.clear();
    _baseX = null;
    _baseY = null;
    _baseZ = null;
    _calibrationSamples = 0;

    if (Platform.isAndroid) {
      _channel.invokeMethod('stopMotionService').catchError((_) {});
    }
  }

  void dispose() {
    stopMonitoring();
    _motionDetectedController.close();
  }


}
