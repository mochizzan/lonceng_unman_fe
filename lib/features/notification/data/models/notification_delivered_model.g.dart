// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_delivered_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationDeliveredModelAdapter
    extends TypeAdapter<NotificationDeliveredModel> {
  @override
  final typeId = 1;

  @override
  NotificationDeliveredModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationDeliveredModel(
      id: (fields[0] as num).toInt(),
      courseName: fields[1] as String,
      dayOfWeek: fields[2] as String,
      classTime: fields[3] as DateTime,
      deliveredAt: fields[4] as DateTime,
      room: fields[5] as String,
      lecturer: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationDeliveredModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseName)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.classTime)
      ..writeByte(4)
      ..write(obj.deliveredAt)
      ..writeByte(5)
      ..write(obj.room)
      ..writeByte(6)
      ..write(obj.lecturer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDeliveredModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
