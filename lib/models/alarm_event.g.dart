// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a stub adapter for Hive - run build_runner to regenerate properly

part of 'alarm_event.dart';

class AlarmEventAdapter extends TypeAdapter<AlarmEvent> {
  @override
  final int typeId = 0;

  @override
  AlarmEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmEvent(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      eventTypeIndex: fields[2] as int,
      details: fields[3] as String,
      failedAttempts: fields[4] as int?,
      imagePath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmEvent obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.eventTypeIndex)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.failedAttempts)
      ..writeByte(5)
      ..write(obj.imagePath);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
