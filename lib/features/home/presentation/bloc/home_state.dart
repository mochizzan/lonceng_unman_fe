// home - State
//
// Represents the various states the home screen can be in.

import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

abstract class HomeState {
  const HomeState();
}

/// Initial state before any data fetch.
class HomeInitial extends HomeState {
  const HomeInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HomeInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state while fetching home data.
class HomeLoading extends HomeState {
  const HomeLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HomeLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loaded state with home screen data and a computed countdown.
class HomeLoaded extends HomeState {
  const HomeLoaded({required this.data, required this.countdown});

  final HomeEntity data;

  /// Time remaining until the next class starts.
  final Duration countdown;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeLoaded &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          countdown == other.countdown;

  @override
  int get hashCode => Object.hash(data, countdown);
}

/// Error state when data fetch fails.
class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
