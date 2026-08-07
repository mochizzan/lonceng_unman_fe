// jadwal - Data model
//
// DTO layer: converts between raw JSON data from the remote data source
// and domain [JadwalEntity] objects.
// Follows the same pattern as home's [HomeModel].

import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

/// Top-level jadwal data model.
class JadwalModel extends JadwalEntity {
  const JadwalModel({
    required super.selectedDay,
    required super.days,
    required super.scheduleItems,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    final scheduleJson = json['scheduleItems'] as List<dynamic>;

    return JadwalModel(
      selectedDay: json['selectedDay'] as String,
      days: (json['days'] as List<dynamic>).cast<String>(),
      scheduleItems: scheduleJson
          .map((e) => ScheduleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
