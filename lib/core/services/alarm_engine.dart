import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../core/constants/app_constants.dart';

/// Central alarm engine — controls sound, flash, vibration
/// 
/// All hardware operations are real (no faking).
/// Gracefully handles devices without flashlight / vibration.
class AlarmEngine {
  static const _channel = MethodChannel(AppConstants.platformChannelName);

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmActive = false;
  Timer? _flashTimer;
  bool _flashState = false;
  bool _hasVibrator = false;
  bool _hasFlash = false;

  bool get isAlarmActive => _isAlarmActive;

  Future<void> initialize() async {
    _hasVibrator = await Vibration.hasVibrator() ?? false;

    // Check flash availability via platform channel
    try {
      _hasFlash = await _channel.invokeMethod<bool>('hasFlash') ?? false;
    } on PlatformException {
      _hasFlash = false;
    }
  }

  /// Start the alarm with the given settings
  Future<void> startAlarm({
    required String soundId,
    required double volume,
    required bool flashEnabled,
    required bool vibrationEnabled,
    required String flashMode,
    required String vibrationStrength,
  }) async {
    if (_isAlarmActive) return;
    _isAlarmActive = true;

    // 1. Sound
    await _startSound(soundId, volume);

    // 2. Vibration
    if (vibrationEnabled) {
      _startVibration(vibrationStrength);
    }

    // 3. Flash
    if (flashEnabled) {
      _startFlash(flashMode);
    }
  }

  Future<void> _startSound(String soundId, double volume) async {
    try {
      // Force max alarm volume via native channel first
      await _channel.invokeMethod('setMaxVolume').catchError((_) {});

      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Play native beep / ringtone in parallel as guaranteed hardware alert
      _playNativeBeep();

      // Try wav first, then mp3
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundId.wav'));
      } catch (_) {
        try {
          await _audioPlayer.play(AssetSource('sounds/$soundId.mp3'));
        } catch (_) {
          // Native tone is already running as fallback
        }
      }
    } catch (e) {
      _playNativeBeep();
    }
  }

  void _playNativeBeep() {
    _channel.invokeMethod('playBeep').catchError((_) {});
  }

  void _startVibration(String strength) {
    final patterns = {
      'light': [0, 300, 200, 300],
      'medium': [0, 500, 200, 500],
      'strong': [0, 1000, 200, 1000],
    };
    final pattern = patterns[strength] ?? patterns['strong']!;
    Vibration.vibrate(pattern: pattern, repeat: 0).catchError((_) {
      // Fallback for devices not supporting repeating patterns
      Vibration.vibrate(duration: 1000).catchError((_) {});
    });
  }

  void _startFlash(String mode) {
    final intervals = {
      'slow': const Duration(milliseconds: 800),
      'fast': const Duration(milliseconds: 200),
      'continuous': const Duration(milliseconds: 100),
    };
    final interval = intervals[mode] ?? intervals['fast']!;

    _flashTimer = Timer.periodic(interval, (_) async {
      _flashState = !_flashState;
      try {
        await _channel.invokeMethod('setFlash', {'on': _flashState});
      } catch (_) {
        // Continue strobe on transient errors
      }
    });
  }

  /// Stop all alarm outputs
  Future<void> stopAlarm() async {
    if (!_isAlarmActive) return;
    _isAlarmActive = false;

    // Stop audio player
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    // Stop native ringtone / beep
    try {
      await _channel.invokeMethod('stopBeep');
    } catch (_) {}

    // Stop flashlight
    _flashTimer?.cancel();
    _flashTimer = null;
    _flashState = false;
    try {
      await _channel.invokeMethod('setFlash', {'on': false});
    } catch (_) {}

    // Stop vibration
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// Preview a sound (non-looping, lower volume)
  Future<void> previewSound(String soundId, double volume) async {
    await _audioPlayer.stop();
    await _audioPlayer.setVolume(volume * 0.8);
    await _audioPlayer.setReleaseMode(ReleaseMode.release);

    try {
      await _audioPlayer.play(AssetSource('sounds/$soundId.wav'));
    } catch (_) {
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundId.mp3'));
      } catch (_) {
        _playNativeBeep();
      }
    }
  }

  Future<void> stopPreview() async {
    await _audioPlayer.stop();
  }

  bool get hasFlash => _hasFlash;
  bool get hasVibrator => _hasVibrator;

  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
  }
}
