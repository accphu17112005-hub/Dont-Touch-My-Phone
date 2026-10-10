import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/local_storage_service.dart';
import '../../models/app_models.dart';

class SettingsRepository {
  final LocalStorageService _storage;
  AppSettings _settings;

  SettingsRepository(this._storage) : _settings = _storage.loadSettings();

  AppSettings get currentSettings => _settings;

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(settings);
  }

  Future<void> updateSetting<T>(String key, T value) async {
    // Convenience method for single-field updates
    // Full save is always done for simplicity
    await _storage.saveSettings(_settings);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(LocalStorageService.instance);
});

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return LocalStorageService.instance.loadSettings();
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await LocalStorageService.instance.saveSettings(settings);
    ref.read(settingsRepositoryProvider).updateSettings(settings);
  }

  Future<void> toggleMotionProtection(bool value) async {
    await update(state.copyWith(motionProtectionEnabled: value));
  }

  Future<void> toggleFlash(bool value) async {
    await update(state.copyWith(flashEnabled: value));
  }

  Future<void> toggleVibration(bool value) async {
    await update(state.copyWith(vibrationEnabled: value));
  }

  Future<void> toggleAirplaneAlarm(bool value) async {
    await update(state.copyWith(airplaneAlarmEnabled: value));
  }

  Future<void> toggleChargingAlarm(bool value) async {
    await update(state.copyWith(chargingAlarmEnabled: value));
  }

  Future<void> toggleBreakInAlert(bool value) async {
    await update(state.copyWith(breakInAlertEnabled: value));
  }

  Future<void> toggleDarkMode(bool value) async {
    await update(state.copyWith(darkMode: value));
  }

  Future<void> setSensitivity(double value) async {
    await update(state.copyWith(motionSensitivity: value));
  }

  Future<void> setAlarmDelay(int value) async {
    await update(state.copyWith(alarmDelay: value));
  }

  Future<void> setSelectedSound(String soundId) async {
    await update(state.copyWith(selectedSound: soundId));
  }

  Future<void> setVolume(double value) async {
    await update(state.copyWith(soundVolume: value));
  }

  Future<void> setFlashMode(String mode) async {
    await update(state.copyWith(flashMode: mode));
  }

  Future<void> setVibrationStrength(String strength) async {
    await update(state.copyWith(vibrationStrength: strength));
  }

  Future<void> setPinEnabled(bool value) async {
    await update(state.copyWith(pinEnabled: value));
  }

  Future<void> setPinLength(int length) async {
    await update(state.copyWith(pinLength: length));
  }

  Future<void> setWrongPinThreshold(int value) async {
    await update(state.copyWith(wrongPinThreshold: value));
  }

  Future<void> setBatteryThreshold(int value) async {
    await update(state.copyWith(batteryThreshold: value));
  }
}
