// jadwal - Event
//
// Represents user-driven interactions or lifecycle signals flowing
// into the jadwal BLoC.

abstract class JadwalEvent {
  const JadwalEvent();
}

/// Fetch jadwal data on initial load.
class JadwalFetchRequested extends JadwalEvent {
  const JadwalFetchRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalFetchRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Manually refresh jadwal data (pull-to-refresh).
class JadwalRefreshRequested extends JadwalEvent {
  const JadwalRefreshRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalRefreshRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
