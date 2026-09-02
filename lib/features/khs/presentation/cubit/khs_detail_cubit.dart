import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_pdf_service.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';

class KhsDetailCubit extends Cubit<KhsDetailState> with BlocErrorHandler {
  KhsDetailCubit({
    required this.tahunAjaran,
    AcademicCacheService? cache,
    List<String>? availableYears,
  }) : _cache = cache ?? Services.get<AcademicCacheService>(),
       _pdfService = KhsPdfService(),
       _availableYears = availableYears ?? [],
       _selectedTahunAjaran = tahunAjaran,
       _downloadStatus = DownloadStatus.idle,
       super(const KhsDetailLoading());

  final String tahunAjaran;
  final AcademicCacheService _cache;
  final KhsPdfService _pdfService;

  late List<String> _availableYears;
  late String _selectedTahunAjaran;
  late DownloadStatus _downloadStatus;
  bool _isFetching = false;

  List<String> get availableYears => _availableYears;
  String get selectedTahunAjaran => _selectedTahunAjaran;
  DownloadStatus get downloadStatus => _downloadStatus;
  bool get isFetching => _isFetching;

  Future<void> loadAll() async {
    emit(
      KhsDetailLoading(
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
      ),
    );
    try {
      final results = await Future.wait([
        _loadSemester(semester: 'GANJIL'),
        _loadSemester(semester: 'GENAP'),
      ]);
      final ganjilError = results[0]?['error'] as String?;
      final genapError = results[1]?['error'] as String?;
      final ganjilData = results[0]?['data'];
      final genapData = results[1]?['data'];

      if (ganjilError != null || genapError != null) {
        emit(
          KhsDetailError(
            ganjilError: ganjilError,
            genapError: genapError,
            selectedTahunAjaran: _selectedTahunAjaran,
            availableYears: _availableYears,
            downloadStatus: _downloadStatus,
          ),
        );
      } else {
        emit(
          KhsDetailLoaded(
            ganjilData: ganjilData,
            genapData: genapData,
            selectedTahunAjaran: _selectedTahunAjaran,
            availableYears: _availableYears,
            downloadStatus: _downloadStatus,
          ),
        );
      }
    } catch (e) {
      // Prevent crash: catch any unhandled exception and emit error state
      final errorMsg = handleError(e);
      emit(
        KhsDetailError(
          ganjilError: errorMsg,
          genapError: errorMsg,
          selectedTahunAjaran: _selectedTahunAjaran,
          availableYears: _availableYears,
          downloadStatus: _downloadStatus,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _loadSemester({
    required String semester,
  }) async {
    try {
      final creds = await _cache.loadCredentials();
      final npm = creds?['npm'];
      if (npm == null || npm.isEmpty) {
        return {'error': 'NPM tidak ditemukan'};
      }
      final khsJson = await _cache.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
      );
      if (khsJson == null) {
        // Data not in cache — auto-fetch from backend (separate from full pipeline)
        final fetched = await _fetchSemester(semester);
        if (fetched) {
          // Retry loading from cache after fetch
          final retryJson = await _cache.loadKhsDataSemester(
            npm: npm,
            tahunAjaran: _selectedTahunAjaran,
            semester: semester,
          );
          if (retryJson != null) {
            final khsModel = KhsModel.fromJson(retryJson);
            return {'data': khsModel.khs};
          }
        }
        return {'data': null};
      }
      final khsModel = KhsModel.fromJson(khsJson);
      return {'data': khsModel.khs};
    } catch (e) {
      return {'error': handleError(e)};
    }
  }

  /// Fetches a single semester's KHS data from backend.
  /// Downloads PDF, extracts data, and saves to cache.
  /// Returns true if successful, false otherwise.
  Future<bool> _fetchSemester(String semester) async {
    if (_isFetching) return false;

    final creds = await _cache.loadCredentials();
    final npm = creds?['npm'];
    final password = creds?['password'];

    if (npm == null || npm.isEmpty || password == null || password.isEmpty) {
      return false;
    }

    _isFetching = true;
    emit(_emitWithFetching());

    try {
      final getKhs = Services.get<GetKhs>();
      // Download PDF from LMS
      await getKhs.download(
        npm: npm,
        password: password,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
        forceRefresh: true,
      );
      // Extract data from PDF
      await getKhs.extract(
        npm: npm,
        password: password,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
        forceRefresh: true,
      );
      // Save parsed data to cache
      await getKhs.call(
        npm: npm,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
        forceRefresh: true,
      );

      _isFetching = false;
      emit(_emitWithFetching());
      return true;
    } catch (e) {
      _isFetching = false;
      emit(_emitWithFetching());
      return false;
    }
  }

  void selectYear(String tahunAjaran) {
    _selectedTahunAjaran = tahunAjaran;
    loadAll();
  }

  Future<void> downloadPdf(String semester, {BuildContext? context}) async {
    final creds = await _cache.loadCredentials();
    final npm = creds?['npm'];
    final password = creds?['password'];

    if (npm == null || npm.isEmpty || password == null || password.isEmpty) {
      _downloadStatus = DownloadStatus.error;
      emit(_emitWithDownloadStatus(DownloadStatus.error));
      if (context != null && context.mounted) {
        ErrorHandler.show(
          context,
          'Kredensial tidak ditemukan. Silakan login ulang.',
        );
      }
      return;
    }

    // Show snackbar: download started
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mengunduh KHS $_selectedTahunAjaran $semester...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _downloadStatus = DownloadStatus.downloading;
    emit(_emitWithDownloadStatus(DownloadStatus.downloading));

    try {
      final filePath = await _pdfService.download(
        npm: npm,
        password: password,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
      );
      _downloadStatus = DownloadStatus.success;
      emit(_emitWithDownloadStatus(DownloadStatus.success));

      // Show success alert modal
      if (context != null && context.mounted) {
        _showDownloadSuccessDialog(context, filePath);
      }
    } catch (e) {
      _downloadStatus = DownloadStatus.error;
      emit(_emitWithDownloadStatus(DownloadStatus.error));
      if (context != null && context.mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  /// Shows an alert modal when download completes successfully.
  void _showDownloadSuccessDialog(BuildContext context, String filePath) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Unduhan Selesai'),
        content: Text(
          'File KHS berhasil disimpan di:\n$filePath',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> loadAvailableYears() async {
    try {
      final creds = await _cache.loadCredentials();
      final npm = creds?['npm'];
      if (npm == null || npm.isEmpty) return;

      final khsList = await _cache.loadKhsList(npm: npm);
      if (khsList == null) return;

      final years = <String>{};
      for (final item in khsList) {
        if (item is Map) {
          // Cache stores raw API response with snake_case 'tahun_ajaran'
          // which can be a String OR a Map {awal, akhir}
          final tahunRaw = item['tahun_ajaran'];
          final tahun = tahunRaw is Map<String, dynamic>
              ? '${tahunRaw['awal']}/${tahunRaw['akhir']}'
              : tahunRaw as String?;
          if (tahun != null && tahun.isNotEmpty) {
            years.add(tahun);
          }
        }
      }
      _availableYears = years.toList();
      // Emit so the UI rebuilds and shows the YearSwitcherButton.
      emit(_emitWithDownloadStatus(_downloadStatus));
    } catch (e) {
      // Silently fail — available years is optional enrichment
    }
  }

  /// Emits a state preserving current data but updating isFetching.
  KhsDetailState _emitWithFetching() {
    final current = state;
    if (current is KhsDetailLoaded) {
      return KhsDetailLoaded(
        ganjilData: current.ganjilData,
        genapData: current.genapData,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
        isFetching: _isFetching,
      );
    }
    if (current is KhsDetailError) {
      return KhsDetailError(
        ganjilError: current.ganjilError,
        genapError: current.genapError,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
      );
    }
    return KhsDetailLoading(
      selectedTahunAjaran: _selectedTahunAjaran,
      availableYears: _availableYears,
      downloadStatus: _downloadStatus,
    );
  }

  /// Emits a state preserving current data but updating downloadStatus.
  KhsDetailState _emitWithDownloadStatus(DownloadStatus status) {
    final current = state;
    if (current is KhsDetailLoaded) {
      return KhsDetailLoaded(
        ganjilData: current.ganjilData,
        genapData: current.genapData,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: status,
      );
    }
    if (current is KhsDetailError) {
      return KhsDetailError(
        ganjilError: current.ganjilError,
        genapError: current.genapError,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: status,
      );
    }
    return KhsDetailLoading(
      selectedTahunAjaran: _selectedTahunAjaran,
      availableYears: _availableYears,
      downloadStatus: status,
    );
  }
}
