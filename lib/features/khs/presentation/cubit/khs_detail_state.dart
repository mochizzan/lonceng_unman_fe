import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';

enum DownloadStatus { idle, downloading, success, error }

abstract class KhsDetailState {
  const KhsDetailState({
    required this.selectedTahunAjaran,
    required this.availableYears,
    required this.downloadStatus,
  });

  final String selectedTahunAjaran;
  final List<String> availableYears;
  final DownloadStatus downloadStatus;
}

class KhsDetailLoading extends KhsDetailState {
  const KhsDetailLoading({
    super.selectedTahunAjaran = '',
    super.availableYears = const [],
    super.downloadStatus = DownloadStatus.idle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KhsDetailLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class KhsDetailLoaded extends KhsDetailState {
  const KhsDetailLoaded({
    required this.ganjilData,
    required this.genapData,
    required super.selectedTahunAjaran,
    required super.availableYears,
    required super.downloadStatus,
  });

  final KhsDataEntity? ganjilData;
  final KhsDataEntity? genapData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDetailLoaded &&
          runtimeType == other.runtimeType &&
          ganjilData == other.ganjilData &&
          genapData == other.genapData &&
          selectedTahunAjaran == other.selectedTahunAjaran &&
          availableYears == other.availableYears &&
          downloadStatus == other.downloadStatus;

  @override
  int get hashCode => Object.hash(
    ganjilData,
    genapData,
    selectedTahunAjaran,
    availableYears,
    downloadStatus,
  );
}

class KhsDetailError extends KhsDetailState {
  const KhsDetailError({
    this.ganjilError,
    this.genapError,
    required super.selectedTahunAjaran,
    required super.availableYears,
    required super.downloadStatus,
  });

  final String? ganjilError;
  final String? genapError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDetailError &&
          runtimeType == other.runtimeType &&
          ganjilError == other.ganjilError &&
          genapError == other.genapError &&
          selectedTahunAjaran == other.selectedTahunAjaran &&
          availableYears == other.availableYears &&
          downloadStatus == other.downloadStatus;

  @override
  int get hashCode => Object.hash(
    ganjilError,
    genapError,
    selectedTahunAjaran,
    availableYears,
    downloadStatus,
  );
}
