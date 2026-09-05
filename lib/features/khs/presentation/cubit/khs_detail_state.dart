import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';

enum DownloadStatus { idle, downloading, success, error }

abstract class KhsDetailState {
  const KhsDetailState({
    required this.selectedTahunAjaran,
    required this.availableYears,
    required this.downloadStatus,
    this.isFetching = false,
    this.downloadedFileName,
    this.downloadedFilePath,
  });

  final String selectedTahunAjaran;
  final List<String> availableYears;
  final DownloadStatus downloadStatus;
  final bool isFetching;
  final String? downloadedFileName;
  final String? downloadedFilePath;
}

class KhsDetailLoading extends KhsDetailState {
  const KhsDetailLoading({
    super.selectedTahunAjaran = '',
    super.availableYears = const [],
    super.downloadStatus = DownloadStatus.idle,
    super.isFetching = false,
    super.downloadedFileName,
    super.downloadedFilePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDetailLoading &&
          runtimeType == other.runtimeType &&
          selectedTahunAjaran == other.selectedTahunAjaran &&
          availableYears == other.availableYears &&
          downloadStatus == other.downloadStatus &&
          isFetching == other.isFetching &&
          downloadedFileName == other.downloadedFileName &&
          downloadedFilePath == other.downloadedFilePath;

  @override
  int get hashCode => Object.hash(
    selectedTahunAjaran,
    availableYears,
    downloadStatus,
    isFetching,
    downloadedFileName,
    downloadedFilePath,
  );
}

class KhsDetailLoaded extends KhsDetailState {
  const KhsDetailLoaded({
    required this.ganjilData,
    required this.genapData,
    required super.selectedTahunAjaran,
    required super.availableYears,
    required super.downloadStatus,
    super.isFetching = false,
    super.downloadedFileName,
    super.downloadedFilePath,
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
          downloadStatus == other.downloadStatus &&
          isFetching == other.isFetching &&
          downloadedFileName == other.downloadedFileName &&
          downloadedFilePath == other.downloadedFilePath;

  @override
  int get hashCode => Object.hash(
    ganjilData,
    genapData,
    selectedTahunAjaran,
    availableYears,
    downloadStatus,
    isFetching,
    downloadedFileName,
    downloadedFilePath,
  );
}

class KhsDetailError extends KhsDetailState {
  const KhsDetailError({
    this.ganjilError,
    this.genapError,
    required super.selectedTahunAjaran,
    required super.availableYears,
    required super.downloadStatus,
    super.isFetching = false,
    super.downloadedFileName,
    super.downloadedFilePath,
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
          downloadStatus == other.downloadStatus &&
          isFetching == other.isFetching &&
          downloadedFileName == other.downloadedFileName &&
          downloadedFilePath == other.downloadedFilePath;

  @override
  int get hashCode => Object.hash(
    ganjilError,
    genapError,
    selectedTahunAjaran,
    availableYears,
    downloadStatus,
    isFetching,
    downloadedFileName,
    downloadedFilePath,
  );
}
