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
      isRead: fields[8] == null ? false : fields[8] as bool,
      sourceIndex: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      scheduledId: (fields[9] as num?)?.toInt(),
      title: fields[10] as String?,
      body: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationDeliveredModel obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.lecturer)
      ..writeByte(7)
      ..write(obj.sourceIndex)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.scheduledId)
      ..writeByte(10)
      ..write(obj.title)
      ..writeByte(11)
      ..write(obj.body);
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
