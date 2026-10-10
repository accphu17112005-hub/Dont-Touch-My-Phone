/// Core application constants
class AppConstants {
  AppConstants._();

  static const String appName = "Don't Touch My Phone";
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String settingsBox = 'settings_box';
  static const String alarmHistoryBox = 'alarm_history_box';
  static const String securityBox = 'security_box';

  // Hive type IDs
  static const int alarmEventTypeId = 0;

  // Secure storage keys
  static const String pinHashKey = 'app_pin_hash';
  static const String pinEnabledKey = 'pin_enabled';
  static const String pinLengthKey = 'pin_length';

  // Settings keys
  static const String motionSensitivityKey = 'motion_sensitivity';
  static const String alarmDelayKey = 'alarm_delay';
  static const String wrongPinThresholdKey = 'wrong_pin_threshold';
  static const String selectedSoundKey = 'selected_sound';
  static const String soundVolumeKey = 'sound_volume';
  static const String flashEnabledKey = 'flash_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String flashModeKey = 'flash_mode';
  static const String vibrationStrengthKey = 'vibration_strength';
  static const String motionProtectionKey = 'motion_protection';
  static const String breakInAlertKey = 'break_in_alert';
  static const String airplaneAlarmKey = 'airplane_alarm';
  static const String chargingAlarmKey = 'charging_alarm';
  static const String chargingDisconnectAlarmKey = 'charging_disconnect_alarm';
  static const String batteryThresholdKey = 'battery_threshold';
  static const String darkModeKey = 'dark_mode';
  static const String isFirstRunKey = 'is_first_run';
  static const String wrongPinCountKey = 'wrong_pin_count';
  static const String protectionStateKey = 'protection_state';

  // Motion detection
  static const double sensitivityLow = 3.5;
  static const double sensitivityMedium = 2.0;
  static const double sensitivityHigh = 1.0;
  static const int motionCheckIntervalMs = 100;

  // Platform channel name
  static const String platformChannelName = 'com.security.antitheft.dont_touch_my_phone/native_security';

  // Notification
  static const String notificationChannelId = 'protection_channel';
  static const String notificationChannelName = 'Protection Status';
  static const int protectionNotificationId = 1001;
  static const int alarmNotificationId = 1002;

  // Default values
  static const double defaultVolume = 0.8;
  static const int defaultAlarmDelay = 3;
  static const int defaultWrongPinThreshold = 3;
  static const int defaultBatteryThreshold = 80;
}

/// App color constants (semantic names)
class AppColors {
  AppColors._();

  static const int gradientTopARGB = 0xFF6A1B9A;      // Deep purple
  static const int gradientMidARGB = 0xFFAD1457;      // Pink
  static const int gradientBottomARGB = 0xFFBF360C;   // Coral/red
  static const int cardARGB = 0xFFFFFFFF;
  static const int textPrimaryARGB = 0xFFFFFFFF;
  static const int accentARGB = 0xFFFF4081;
  static const int dangerARGB = 0xFFFF1744;
  static const int successARGB = 0xFF00E676;
  static const int warningARGB = 0xFFFF9100;
}

/// Sound options
class AlarmSounds {
  AlarmSounds._();

  static const List<Map<String, String>> sounds = [
    {'id': 'police_siren', 'name': 'Police Siren', 'icon': '🚔', 'file': 'police_siren.mp3'},
    {'id': 'emergency_siren', 'name': 'Emergency Siren', 'icon': '🚨', 'file': 'emergency_siren.mp3'},
    {'id': 'car_alarm', 'name': 'Car Alarm', 'icon': '🚗', 'file': 'car_alarm.mp3'},
    {'id': 'loud_beep', 'name': 'Loud Beep', 'icon': '📢', 'file': 'loud_beep.mp3'},
    {'id': 'warning', 'name': 'Warning', 'icon': '⚠️', 'file': 'warning.mp3'},
    {'id': 'funny_alarm', 'name': 'Funny Alarm', 'icon': '😂', 'file': 'funny_alarm.mp3'},
    {'id': 'scary_alarm', 'name': 'Scary Alarm', 'icon': '😱', 'file': 'scary_alarm.mp3'},
    {'id': 'screaming_alarm', 'name': 'Screaming Alarm', 'icon': '😤', 'file': 'screaming_alarm.mp3'},
  ];
}
