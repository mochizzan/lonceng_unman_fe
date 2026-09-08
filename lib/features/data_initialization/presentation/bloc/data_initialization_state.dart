import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';

/// States for the data initialization BLoC.
abstract class DataInitBlocState {
  const DataInitBlocState();
}

class DataInitIdle extends DataInitBlocState {
  const DataInitIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DataInitIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

class DataInitInProgress extends DataInitBlocState {
  final DataInitStatus status;
  final String? detail;

  const DataInitInProgress(this.status, {this.detail});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitInProgress &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          detail == other.detail;

  @override
  int get hashCode => Object.hash(status, detail);
}

class DataInitSuccess extends DataInitBlocState {
  final bool isPartial;
  final List<String> skippedSteps;

  const DataInitSuccess({this.isPartial = false, this.skippedSteps = const []});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitSuccess &&
          runtimeType == other.runtimeType &&
          isPartial == other.isPartial &&
          _listEquals(skippedSteps, other.skippedSteps);

  @override
  int get hashCode => Object.hash(isPartial, Object.hashAll(skippedSteps));
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class DataInitPaused extends DataInitBlocState {
  final String failedStep;
  final String message;
  final bool skippable;
  final bool isNetworkError;

  const DataInitPaused(
    this.message, {
    required this.failedStep,
    required this.skippable,
    this.isNetworkError = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitPaused &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          failedStep == other.failedStep &&
          skippable == other.skippable &&
          isNetworkError == other.isNetworkError;

  @override
  int get hashCode =>
      Object.hash(message, failedStep, skippable, isNetworkError);
}

class DataInitFailure extends DataInitBlocState {
  final String message;
  final String? failedStep;

  const DataInitFailure(this.message, {this.failedStep});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          failedStep == other.failedStep;

  @override
  int get hashCode => Object.hash(message, failedStep);
}
