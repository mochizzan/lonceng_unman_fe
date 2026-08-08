import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';

abstract class KhsDetailState {
  const KhsDetailState();
}

class KhsDetailLoading extends KhsDetailState {
  const KhsDetailLoading();
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KhsDetailLoading;
  @override
  int get hashCode => runtimeType.hashCode;
}

class KhsDetailLoaded extends KhsDetailState {
  const KhsDetailLoaded({required this.ganjilData, required this.genapData});
  final KhsDataEntity? ganjilData;
  final KhsDataEntity? genapData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDetailLoaded &&
          runtimeType == other.runtimeType &&
          ganjilData == other.ganjilData &&
          genapData == other.genapData;
  @override
  int get hashCode => Object.hash(ganjilData, genapData);
}

class KhsDetailError extends KhsDetailState {
  const KhsDetailError({this.ganjilError, this.genapError});
  final String? ganjilError;
  final String? genapError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDetailError &&
          runtimeType == other.runtimeType &&
          ganjilError == other.ganjilError &&
          genapError == other.genapError;
  @override
  int get hashCode => Object.hash(ganjilError, genapError);
}
