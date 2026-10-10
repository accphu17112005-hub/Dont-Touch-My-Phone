/// Protection state machine for the app
enum ProtectionState {
  inactive,
  arming,
  protected,
  motionDetected,
  alarmActive,
  pinRequired,
  unlocked,
}

extension ProtectionStateExt on ProtectionState {
  bool get isActive => this != ProtectionState.inactive;

  String get displayName {
    switch (this) {
      case ProtectionState.inactive:
        return 'Protection OFF';
      case ProtectionState.arming:
        return 'Arming...';
      case ProtectionState.protected:
        return 'Protected';
      case ProtectionState.motionDetected:
        return 'Motion Detected!';
      case ProtectionState.alarmActive:
        return 'ALARM ACTIVE';
      case ProtectionState.pinRequired:
        return 'Enter PIN';
      case ProtectionState.unlocked:
        return 'Unlocked';
    }
  }
}

/// App settings model
class AppSettings {
  final double motionSensitivity;
  final int alarmDelay;
  final int wrongPinThreshold;
  final String selectedSound;
  final double soundVolume;
  final bool flashEnabled;
  final bool vibrationEnabled;
  final String flashMode;
  final String vibrationStrength;
  final bool motionProtectionEnabled;
  final bool breakInAlertEnabled;
  final bool airplaneAlarmEnabled;
  final bool chargingAlarmEnabled;
  final bool chargingDisconnectAlarmEnabled;
  final int batteryThreshold;
  final bool darkMode;
  final bool pinEnabled;
  final int pinLength;

  const AppSettings({
    this.motionSensitivity = 2.0,
    this.alarmDelay = 3,
    this.wrongPinThreshold = 3,
    this.selectedSound = 'police_siren',
    this.soundVolume = 0.8,
    this.flashEnabled = true,
    this.vibrationEnabled = true,
    this.flashMode = 'fast',
    this.vibrationStrength = 'strong',
    this.motionProtectionEnabled = true,
    this.breakInAlertEnabled = true,
    this.airplaneAlarmEnabled = false,
    this.chargingAlarmEnabled = false,
    this.chargingDisconnectAlarmEnabled = false,
    this.batteryThreshold = 80,
    this.darkMode = false,
    this.pinEnabled = false,
    this.pinLength = 4,
  });

  AppSettings copyWith({
    double? motionSensitivity,
    int? alarmDelay,
    int? wrongPinThreshold,
    String? selectedSound,
    double? soundVolume,
    bool? flashEnabled,
    bool? vibrationEnabled,
    String? flashMode,
    String? vibrationStrength,
    bool? motionProtectionEnabled,
    bool? breakInAlertEnabled,
    bool? airplaneAlarmEnabled,
    bool? chargingAlarmEnabled,
    bool? chargingDisconnectAlarmEnabled,
    int? batteryThreshold,
    bool? darkMode,
    bool? pinEnabled,
    int? pinLength,
  }) {
    return AppSettings(
      motionSensitivity: motionSensitivity ?? this.motionSensitivity,
      alarmDelay: alarmDelay ?? this.alarmDelay,
      wrongPinThreshold: wrongPinThreshold ?? this.wrongPinThreshold,
      selectedSound: selectedSound ?? this.selectedSound,
      soundVolume: soundVolume ?? this.soundVolume,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      flashMode: flashMode ?? this.flashMode,
      vibrationStrength: vibrationStrength ?? this.vibrationStrength,
      motionProtectionEnabled: motionProtectionEnabled ?? this.motionProtectionEnabled,
      breakInAlertEnabled: breakInAlertEnabled ?? this.breakInAlertEnabled,
      airplaneAlarmEnabled: airplaneAlarmEnabled ?? this.airplaneAlarmEnabled,
      chargingAlarmEnabled: chargingAlarmEnabled ?? this.chargingAlarmEnabled,
      chargingDisconnectAlarmEnabled: chargingDisconnectAlarmEnabled ?? this.chargingDisconnectAlarmEnabled,
      batteryThreshold: batteryThreshold ?? this.batteryThreshold,
      darkMode: darkMode ?? this.darkMode,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinLength: pinLength ?? this.pinLength,
    );
  }
}
