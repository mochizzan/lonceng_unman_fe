// profile - State
//
// Represents the various states the profile screen can be in.

import 'package:lonceng_unman_fe/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileState {
  const ProfileState();
}

/// Initial state before any data fetch.
class ProfileInitial extends ProfileState {
  const ProfileInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProfileInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state while fetching profile data.
class ProfileLoading extends ProfileState {
  const ProfileLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProfileLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loaded state with profile screen data.
class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.data});

  final ProfileEntity data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileLoaded &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Error state when data fetch fails.
class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
