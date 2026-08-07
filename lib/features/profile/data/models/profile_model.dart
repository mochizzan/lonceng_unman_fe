// profile - Data model
//
// DTO layer: converts between raw JSON data from the remote data source
// and domain [ProfileEntity] objects.
// Follows the same pattern as jadwal's [JadwalModel].

import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

/// Raw profile data model from the API.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.userName,
    required super.avatarUrl,
    required super.npm,
    required super.studyProgram,
    required super.semester,
    required super.gpa,
    required super.sksTaken,
    required super.sksTotal,
    required super.todayClassCount,
    super.bio,
    required super.reminderEnabled,
    required super.darkModeEnabled,
    super.lastUpdated,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String,
      npm: json['npm'] as String,
      studyProgram: json['studyProgram'] as String,
      semester: json['semester'] as String,
      gpa: (json['gpa'] as num).toDouble(),
      sksTaken: json['sksTaken'] as int,
      sksTotal: json['sksTotal'] as int,
      todayClassCount: json['todayClassCount'] as int,
      bio: json['bio'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool,
      darkModeEnabled: json['darkModeEnabled'] as bool,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  @override
  ProfileEntity toEntity() {
    return ProfileEntity(
      userName: userName,
      avatarUrl: avatarUrl,
      npm: npm,
      studyProgram: studyProgram,
      semester: semester,
      gpa: gpa,
      sksTaken: sksTaken,
      sksTotal: sksTotal,
      todayClassCount: todayClassCount,
      bio: bio,
      reminderEnabled: reminderEnabled,
      darkModeEnabled: darkModeEnabled,
      lastUpdated: lastUpdated,
    );
  }
}
