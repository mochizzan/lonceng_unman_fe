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

  const DataInitInProgress(this.status);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitInProgress &&
          runtimeType == other.runtimeType &&
          status == other.status;

  @override
  int get hashCode => status.hashCode;
}

class DataInitSuccess extends DataInitBlocState {
  const DataInitSuccess();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DataInitSuccess;

  @override
  int get hashCode => runtimeType.hashCode;
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
