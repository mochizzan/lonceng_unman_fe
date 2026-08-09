// profile - Event
//
// Represents user-driven interactions or lifecycle signals flowing
// into the profile BLoC.

abstract class ProfileEvent {
  const ProfileEvent();
}

/// Fetch profile data on initial load.
class ProfileFetchRequested extends ProfileEvent {
  const ProfileFetchRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileFetchRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Manually refresh profile data (pull-to-refresh).
class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileRefreshRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Update bio for the authenticated user.
class ProfileBioUpdated extends ProfileEvent {
  const ProfileBioUpdated({required this.bio});

  final String bio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileBioUpdated &&
          runtimeType == other.runtimeType &&
          bio == other.bio;

  @override
  int get hashCode => Object.hash(runtimeType, bio);
}

/// Delete bio for the authenticated user.
class ProfileBioDeleted extends ProfileEvent {
  const ProfileBioDeleted();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileBioDeleted && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
