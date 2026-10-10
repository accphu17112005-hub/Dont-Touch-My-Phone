import 'package:flutter_test/flutter_test.dart';
import 'package:dont_touch_my_phone/models/app_models.dart';
import 'package:dont_touch_my_phone/models/alarm_event.dart';

void main() {
  group('ProtectionState Tests', () {
    test('displayName returns clear state strings', () {
      expect(ProtectionState.inactive.displayName, equals('Protection OFF'));
      expect(ProtectionState.arming.displayName, equals('Arming...'));
      expect(ProtectionState.protected.displayName, equals('Protected'));
      expect(ProtectionState.motionDetected.displayName, equals('Motion Detected!'));
      expect(ProtectionState.alarmActive.displayName, equals('ALARM ACTIVE'));
    });

    test('isActive returns false only for inactive state', () {
      expect(ProtectionState.inactive.isActive, isFalse);
      expect(ProtectionState.arming.isActive, isTrue);
      expect(ProtectionState.protected.isActive, isTrue);
      expect(ProtectionState.alarmActive.isActive, isTrue);
    });
  });

  group('AppSettings Tests', () {
    test('default settings have sensible security values', () {
      const settings = AppSettings();
      expect(settings.alarmDelay, equals(3));
      expect(settings.wrongPinThreshold, equals(3));
      expect(settings.motionSensitivity, equals(2.0));
      expect(settings.selectedSound, equals('police_siren'));
      expect(settings.flashEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
    });

    test('copyWith updates specified properties while preserving others', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        alarmDelay: 5,
        selectedSound: 'emergency_siren',
        flashEnabled: false,
      );

      expect(updated.alarmDelay, equals(5));
      expect(updated.selectedSound, equals('emergency_siren'));
      expect(updated.flashEnabled, isFalse);
      expect(updated.wrongPinThreshold, equals(settings.wrongPinThreshold));
      expect(updated.vibrationEnabled, equals(settings.vibrationEnabled));
    });
  });

  group('AlarmEvent Tests', () {
    test('AlarmEvent.create populates timestamps and types correctly', () {
      final event = AlarmEvent.create(
        type: AlarmEventType.motionDetected,
        details: 'Phone moved from table',
      );

      expect(event.eventType, equals(AlarmEventType.motionDetected));
      expect(event.details, equals('Phone moved from table'));
      expect(event.timestamp, isNotNull);
      expect(event.id.isNotEmpty, isTrue);
    });

    test('AlarmEventType extensions provide icon and display name', () {
      expect(AlarmEventType.motionDetected.displayName, equals('Motion Detected'));
      expect(AlarmEventType.intruderDetected.displayName, equals('Intruder Detected'));
      expect(AlarmEventType.wrongPin.displayName, equals('Wrong PIN'));

      expect(AlarmEventType.motionDetected.icon, equals('📳'));
      expect(AlarmEventType.intruderDetected.icon, equals('🚨'));
    });
  });
}
