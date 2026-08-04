// profile - Entity
//
// Domain-layer entity representing the aggregated user profile data.
// Follows Clean Architecture: domain layer has no framework dependencies.

/// Aggregated profile screen data returned from the repository.
class ProfileEntity {
  const ProfileEntity({
    required this.userName,
    required this.avatarUrl,
    required this.npm,
    required this.studyProgram,
    required this.semester,
    required this.gpa,
    required this.sksTaken,
    required this.sksTotal,
    required this.todayClassCount,
    this.bio,
    required this.reminderEnabled,
    required this.darkModeEnabled,
    this.lastUpdated,
  });

  final String userName;
  final String avatarUrl;
  final String npm;
  final String studyProgram;
  final String semester;
  final double gpa;
  final int sksTaken;
  final int sksTotal;
  final int todayClassCount;
  final String? bio;
  final bool reminderEnabled;
  final bool darkModeEnabled;
  final DateTime? lastUpdated;

  /// Returns this entity as a [ProfileEntity].
  /// Subclasses (e.g. [ProfileModel]) override to return a clean entity.
  ProfileEntity toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileEntity &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          avatarUrl == other.avatarUrl &&
          npm == other.npm &&
          studyProgram == other.studyProgram &&
          semester == other.semester &&
          gpa == other.gpa &&
          sksTaken == other.sksTaken &&
          sksTotal == other.sksTotal &&
          todayClassCount == other.todayClassCount &&
          bio == other.bio &&
          reminderEnabled == other.reminderEnabled &&
          darkModeEnabled == other.darkModeEnabled &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(
    userName,
    avatarUrl,
    npm,
    studyProgram,
    semester,
    gpa,
    sksTaken,
    sksTotal,
    todayClassCount,
    bio,
    reminderEnabled,
    darkModeEnabled,
    lastUpdated,
  );
}
