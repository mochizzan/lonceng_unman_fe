// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledNotificationModelAdapter
    extends TypeAdapter<ScheduledNotificationModel> {
  @override
  final typeId = 0;

  @override
  ScheduledNotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledNotificationModel(
      id: (fields[0] as num).toInt(),
      courseName: fields[1] as String,
      dayOfWeek: fields[2] as String,
      classTime: fields[3] as DateTime,
      reminderOffset: (fields[4] as num).toInt(),
      room: fields[5] as String,
      lecturer: fields[6] as String?,
      isActive: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledNotificationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseName)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.classTime)
      ..writeByte(4)
      ..write(obj.reminderOffset)
      ..writeByte(5)
      ..write(obj.room)
      ..writeByte(6)
      ..write(obj.lecturer)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
