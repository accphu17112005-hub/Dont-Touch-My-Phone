import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/alarm_event.dart';
import '../../models/app_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/utils.dart';

/// Local data service — all persistent storage in one place
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance!;

  late final SharedPreferences _prefs;
  late final Box<AlarmEvent> _historyBox;
  late final FlutterSecureStorage _secureStorage;

  LocalStorageService._();

  static Future<LocalStorageService> init() async {
    final svc = LocalStorageService._();
    await svc._initialize();
    _instance = svc;
    return svc;
  }

  Future<void> _initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AlarmEventAdapter());
    _historyBox = await Hive.openBox<AlarmEvent>(AppConstants.alarmHistoryBox);
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // ─── PIN Storage (Secure) ────────────────────────────────────────────────

  Future<void> savePin(String pin) async {
    final hash = HashUtils.hashPin(pin);
    await _secureStorage.write(key: AppConstants.pinHashKey, value: hash);
    await _prefs.setBool(AppConstants.pinEnabledKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: AppConstants.pinHashKey);
    if (stored == null) return false;
    return HashUtils.verifyPin(pin, stored);
  }

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: AppConstants.pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> deletePin() async {
    await _secureStorage.delete(key: AppConstants.pinHashKey);
    await _prefs.setBool(AppConstants.pinEnabledKey, false);
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  AppSettings loadSettings() {
    return AppSettings(
      motionSensitivity: _prefs.getDouble(AppConstants.motionSensitivityKey) ?? 2.0,
      alarmDelay: _prefs.getInt(AppConstants.alarmDelayKey) ?? AppConstants.defaultAlarmDelay,
      wrongPinThreshold: _prefs.getInt(AppConstants.wrongPinThresholdKey) ?? AppConstants.defaultWrongPinThreshold,
      selectedSound: _prefs.getString(AppConstants.selectedSoundKey) ?? 'police_siren',
      soundVolume: _prefs.getDouble(AppConstants.soundVolumeKey) ?? AppConstants.defaultVolume,
      flashEnabled: _prefs.getBool(AppConstants.flashEnabledKey) ?? true,
      vibrationEnabled: _prefs.getBool(AppConstants.vibrationEnabledKey) ?? true,
      flashMode: _prefs.getString(AppConstants.flashModeKey) ?? 'fast',
      vibrationStrength: _prefs.getString(AppConstants.vibrationStrengthKey) ?? 'strong',
      motionProtectionEnabled: _prefs.getBool(AppConstants.motionProtectionKey) ?? true,
      breakInAlertEnabled: _prefs.getBool(AppConstants.breakInAlertKey) ?? true,
      airplaneAlarmEnabled: _prefs.getBool(AppConstants.airplaneAlarmKey) ?? false,
      chargingAlarmEnabled: _prefs.getBool(AppConstants.chargingAlarmKey) ?? false,
      chargingDisconnectAlarmEnabled: _prefs.getBool(AppConstants.chargingDisconnectAlarmKey) ?? false,
      batteryThreshold: _prefs.getInt(AppConstants.batteryThresholdKey) ?? AppConstants.defaultBatteryThreshold,
      darkMode: _prefs.getBool(AppConstants.darkModeKey) ?? false,
      pinEnabled: _prefs.getBool(AppConstants.pinEnabledKey) ?? false,
      pinLength: _prefs.getInt(AppConstants.pinLengthKey) ?? 4,
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    await Future.wait([
      _prefs.setDouble(AppConstants.motionSensitivityKey, s.motionSensitivity),
      _prefs.setInt(AppConstants.alarmDelayKey, s.alarmDelay),
      _prefs.setInt(AppConstants.wrongPinThresholdKey, s.wrongPinThreshold),
      _prefs.setString(AppConstants.selectedSoundKey, s.selectedSound),
      _prefs.setDouble(AppConstants.soundVolumeKey, s.soundVolume),
      _prefs.setBool(AppConstants.flashEnabledKey, s.flashEnabled),
      _prefs.setBool(AppConstants.vibrationEnabledKey, s.vibrationEnabled),
      _prefs.setString(AppConstants.flashModeKey, s.flashMode),
      _prefs.setString(AppConstants.vibrationStrengthKey, s.vibrationStrength),
      _prefs.setBool(AppConstants.motionProtectionKey, s.motionProtectionEnabled),
      _prefs.setBool(AppConstants.breakInAlertKey, s.breakInAlertEnabled),
      _prefs.setBool(AppConstants.airplaneAlarmKey, s.airplaneAlarmEnabled),
      _prefs.setBool(AppConstants.chargingAlarmKey, s.chargingAlarmEnabled),
      _prefs.setBool(AppConstants.chargingDisconnectAlarmKey, s.chargingDisconnectAlarmEnabled),
      _prefs.setInt(AppConstants.batteryThresholdKey, s.batteryThreshold),
      _prefs.setBool(AppConstants.darkModeKey, s.darkMode),
      _prefs.setBool(AppConstants.pinEnabledKey, s.pinEnabled),
      _prefs.setInt(AppConstants.pinLengthKey, s.pinLength),
    ]);
  }

  // ─── First Run ────────────────────────────────────────────────────────────

  bool get isFirstRun => _prefs.getBool(AppConstants.isFirstRunKey) ?? true;

  Future<void> markNotFirstRun() async {
    await _prefs.setBool(AppConstants.isFirstRunKey, false);
  }

  // ─── Wrong PIN counter ────────────────────────────────────────────────────

  int get wrongPinCount => _prefs.getInt(AppConstants.wrongPinCountKey) ?? 0;

  Future<void> incrementWrongPinCount() async {
    await _prefs.setInt(AppConstants.wrongPinCountKey, wrongPinCount + 1);
  }

  Future<void> resetWrongPinCount() async {
    await _prefs.setInt(AppConstants.wrongPinCountKey, 0);
  }

  // ─── Alarm History ───────────────────────────────────────────────────────

  List<AlarmEvent> getAlarmHistory() {
    final events = _historyBox.values.toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  Future<void> addAlarmEvent(AlarmEvent event) async {
    await _historyBox.put(event.id, event);
  }

  Future<void> clearAlarmHistory() async {
    await _historyBox.clear();
  }
}
