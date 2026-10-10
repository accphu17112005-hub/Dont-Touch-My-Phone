import 'package:flutter_test/flutter_test.dart';
import 'package:dont_touch_my_phone/core/utils/utils.dart';

void main() {
  group('HashUtils Tests', () {
    test('hashPin returns consistent SHA-256 hash', () {
      final hash1 = HashUtils.hashPin('1234');
      final hash2 = HashUtils.hashPin('1234');
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex length
    });

    test('hashPin produces different hashes for different PINs', () {
      final hash1 = HashUtils.hashPin('1234');
      final hash2 = HashUtils.hashPin('4321');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPin validates correct and incorrect PINs', () {
      final pin = '9876';
      final hash = HashUtils.hashPin(pin);

      expect(HashUtils.verifyPin('9876', hash), isTrue);
      expect(HashUtils.verifyPin('1234', hash), isFalse);
      expect(HashUtils.verifyPin('', hash), isFalse);
    });
  });

  group('SensitivityUtils Tests', () {
    test('sensitivityToThreshold maps low, medium, high accurately', () {
      expect(SensitivityUtils.sensitivityToThreshold('low'), equals(3.5));
      expect(SensitivityUtils.sensitivityToThreshold('medium'), equals(2.0));
      expect(SensitivityUtils.sensitivityToThreshold('high'), equals(1.0));
      expect(SensitivityUtils.sensitivityToThreshold('unknown'), equals(2.0));
    });

    test('thresholdToSensitivity returns correct category', () {
      expect(SensitivityUtils.thresholdToSensitivity(3.5), equals('low'));
      expect(SensitivityUtils.thresholdToSensitivity(3.0), equals('low'));
      expect(SensitivityUtils.thresholdToSensitivity(2.0), equals('medium'));
      expect(SensitivityUtils.thresholdToSensitivity(1.5), equals('medium'));
      expect(SensitivityUtils.thresholdToSensitivity(1.0), equals('high'));
      expect(SensitivityUtils.thresholdToSensitivity(0.5), equals('high'));
    });
  });

  group('DateTimeUtils Tests', () {
    test('formatDateTime formats consistently', () {
      final dt = DateTime(2026, 10, 5, 14, 30);
      final formatted = DateTimeUtils.formatDateTime(dt);
      expect(formatted, contains('Oct'));
      expect(formatted, contains('2026'));
      expect(formatted, contains('2:30 PM'));
    });

    test('formatRelative returns expected relative strings', () {
      final now = DateTime.now();
      expect(DateTimeUtils.formatRelative(now), equals('Just now'));

      final tenMinsAgo = now.subtract(const Duration(minutes: 10));
      expect(DateTimeUtils.formatRelative(tenMinsAgo), equals('10m ago'));

      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(DateTimeUtils.formatRelative(twoHoursAgo), equals('2h ago'));
    });
  });
}
