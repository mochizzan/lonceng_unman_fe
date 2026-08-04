// jadwal - State
//
// Represents the various states the jadwal screen can be in.

import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

abstract class JadwalState {
  const JadwalState();
}

/// Initial state before any data fetch.
class JadwalInitial extends JadwalState {
  const JadwalInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JadwalInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state while fetching jadwal data.
class JadwalLoading extends JadwalState {
  const JadwalLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JadwalLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loaded state with jadwal screen data.
class JadwalLoaded extends JadwalState {
  const JadwalLoaded({required this.data});

  final JadwalEntity data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalLoaded &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Error state when data fetch fails.
class JadwalError extends JadwalState {
  const JadwalError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
