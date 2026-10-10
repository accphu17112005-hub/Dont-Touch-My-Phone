import 'package:hive/hive.dart';

part 'alarm_event.g.dart';

/// Types of alarm events recorded in history
enum AlarmEventType {
  motionDetected,
  wrongPin,
  intruderDetected,
  chargerConnected,
  chargerDisconnected,
  batteryThresholdReached,
  airplaneModeChanged,
  protectionActivated,
  protectionDeactivated,
  breakInAttempt,
}

extension AlarmEventTypeExt on AlarmEventType {
  String get displayName {
    switch (this) {
      case AlarmEventType.motionDetected:
        return 'Motion Detected';
      case AlarmEventType.wrongPin:
        return 'Wrong PIN';
      case AlarmEventType.intruderDetected:
        return 'Intruder Detected';
      case AlarmEventType.chargerConnected:
        return 'Charger Connected';
      case AlarmEventType.chargerDisconnected:
        return 'Charger Disconnected';
      case AlarmEventType.batteryThresholdReached:
        return 'Battery Threshold';
      case AlarmEventType.airplaneModeChanged:
        return 'Airplane Mode Changed';
      case AlarmEventType.protectionActivated:
        return 'Protection Activated';
      case AlarmEventType.protectionDeactivated:
        return 'Protection Deactivated';
      case AlarmEventType.breakInAttempt:
        return 'Break-In Attempt';
    }
  }

  String get icon {
    switch (this) {
      case AlarmEventType.motionDetected:
        return '📳';
      case AlarmEventType.wrongPin:
        return '🔑';
      case AlarmEventType.intruderDetected:
        return '🚨';
      case AlarmEventType.chargerConnected:
        return '🔌';
      case AlarmEventType.chargerDisconnected:
        return '⚡';
      case AlarmEventType.batteryThresholdReached:
        return '🔋';
      case AlarmEventType.airplaneModeChanged:
        return '✈️';
      case AlarmEventType.protectionActivated:
        return '🛡️';
      case AlarmEventType.protectionDeactivated:
        return '🔓';
      case AlarmEventType.breakInAttempt:
        return '🔴';
    }
  }
}

@HiveType(typeId: 0)
class AlarmEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final int eventTypeIndex;

  @HiveField(3)
  final String details;

  @HiveField(4)
  final int? failedAttempts;

  @HiveField(5)
  final String? imagePath;

  AlarmEvent({
    required this.id,
    required this.timestamp,
    required this.eventTypeIndex,
    required this.details,
    this.failedAttempts,
    this.imagePath,
  });

  AlarmEventType get eventType => AlarmEventType.values[eventTypeIndex];

  factory AlarmEvent.create({
    required AlarmEventType type,
    required String details,
    int? failedAttempts,
    String? imagePath,
  }) {
    return AlarmEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      eventTypeIndex: type.index,
      details: details,
      failedAttempts: failedAttempts,
      imagePath: imagePath,
    );
  }
}
