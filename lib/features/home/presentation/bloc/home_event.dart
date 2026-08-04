// home - Event
//
// Represents user-driven interactions or lifecycle signals flowing
// into the home BLoC.

abstract class HomeEvent {
  const HomeEvent();
}

/// Fetch home screen data on initial load.
class HomeFetchRequested extends HomeEvent {
  const HomeFetchRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFetchRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Manually refresh home screen data (pull-to-refresh).
class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeRefreshRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
