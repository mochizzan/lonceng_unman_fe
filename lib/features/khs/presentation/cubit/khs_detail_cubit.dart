import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_download_notification_controller.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_pdf_service.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';

class KhsDetailCubit extends Cubit<KhsDetailState> with BlocErrorHandler {
  KhsDetailCubit({
    required this.tahunAjaran,
    AcademicCacheService? cache,
    List<String>? availableYears,
    GetKhs? injectedGetKhs,
    KhsPdfService? pdfService,
    KhsDownloadNotificationController? downloadController,
  }) : _injectedGetKhs = injectedGetKhs,
       _cache = cache ?? Services.get<AcademicCacheService>(),
       _pdfService = pdfService ?? _resolvePdfService(),
       _downloadControllerNullable =
           downloadController ?? _resolveDownloadController(),
       _availableYears = availableYears ?? [],
       _selectedTahunAjaran = tahunAjaran,
       _downloadStatus = DownloadStatus.idle,
       super(const KhsDetailLoading()) {
    final c = _downloadControllerNullable;
    if (c != null) {
      c.onRetryRequested = (semester) async {
        await downloadPdf(semester);
      };
    }
  }

  static KhsPdfService _resolvePdfService() {
    try {
      return Services.get<KhsPdfService>();
    } catch (_) {
      return KhsPdfService();
    }
  }

  static KhsDownloadNotificationController? _resolveDownloadController() {
    try {
      return Services.get<KhsDownloadNotificationController>();
    } catch (_) {
      return null;
    }
  }

  final String tahunAjaran;
  final AcademicCacheService _cache;
  final KhsPdfService _pdfService;
  final KhsDownloadNotificationController? _downloadControllerNullable;
  final GetKhs? _injectedGetKhs;

  KhsDownloadNotificationController? get _downloadController =>
      _downloadControllerNullable;

  GetKhs get _effectiveGetKhs => _injectedGetKhs ?? Services.get<GetKhs>();

  @override
  Future<void> close() {
    try {
      _downloadControllerNullable?.onRetryRequested = null;
    } catch (_) {}
    return super.close();
  }

  late List<String> _availableYears;
  late String _selectedTahunAjaran;
  late DownloadStatus _downloadStatus;
  bool _isFetching = false;
  String? _downloadedFileName;
  String? _downloadedFilePath;

  List<String> get availableYears => _availableYears;
  String get selectedTahunAjaran => _selectedTahunAjaran;
  DownloadStatus get downloadStatus => _downloadStatus;
  bool get isFetching => _isFetching;
  String? get downloadedFileName => _downloadedFileName;
  String? get downloadedFilePath => _downloadedFilePath;

  Future<void> loadAll() async {
    emit(
      KhsDetailLoading(
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
        isFetching: _isFetching,
        downloadedFileName: _downloadedFileName,
        downloadedFilePath: _downloadedFilePath,
      ),
    );
    final results = await Future.wait([
      _loadSemester(semester: 'GANJIL'),
      _loadSemester(semester: 'GENAP'),
    ]);
    if (isClosed) return;
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
          isFetching: _isFetching,
          downloadedFileName: _downloadedFileName,
          downloadedFilePath: _downloadedFilePath,
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
          isFetching: _isFetching,
          downloadedFileName: _downloadedFileName,
          downloadedFilePath: _downloadedFilePath,
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
      if (khsJson == null) return {'data': null};
      final khsModel = KhsModel.fromJson(khsJson);
      return {'data': khsModel.khs};
    } catch (e) {
      return {'error': handleError(e)};
    }
  }

  Future<void> selectYear(String tahunAjaran) async {
    _selectedTahunAjaran = tahunAjaran;
    await loadAll();
  }

  Future<void> fetchMissingYear({BuildContext? context}) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(_emitWithFetching(true));
    try {
      final creds = await _cache.loadCredentials();
      if (isClosed) return;
      final npm = creds?['npm'];
      final password = creds?['password'];
      if (npm == null || npm.isEmpty || password == null || password.isEmpty) {
        if (context != null && context.mounted) {
          ErrorHandler.show(
            context,
            'Kredensial tidak ditemukan. Silakan login ulang.',
          );
        }
        return;
      }
      for (final semester in ['GANJIL', 'GENAP']) {
        try {
          await _effectiveGetKhs.download(
            npm: npm,
            password: password,
            tahunAjaran: _selectedTahunAjaran,
            semester: semester,
            forceRefresh: true,
          );
          if (isClosed) return;
          await _effectiveGetKhs.extract(
            npm: npm,
            password: password,
            tahunAjaran: _selectedTahunAjaran,
            semester: semester,
            forceRefresh: true,
          );
          if (isClosed) return;
          await _effectiveGetKhs.call(
            npm: npm,
            tahunAjaran: _selectedTahunAjaran,
            semester: semester,
            forceRefresh: true,
          );
          if (isClosed) return;
        } catch (e) {
          debugPrint('[KhsDetailCubit] fetchMissingYear $semester failed: $e');
          if (e is AuthException) rethrow;
        }
      }
    } catch (e) {
      if (isClosed) return;
      if (context != null && context.mounted) {
        ErrorHandler.show(context, e);
      } else {
        if (e is AuthException) {
          debugPrint('[KhsDetailCubit] fetchMissingYear auth error: $e');
        } else {
          handleError(e);
        }
      }
    } finally {
      if (isClosed) return;
      _isFetching = false;
      emit(_emitWithFetching(false));
      if (isClosed) return;
      await loadAll();
    }
  }

  String _fileNameFor(String semester) {
    final sanitized = _selectedTahunAjaran.replaceAll('/', '_');
    return 'KHS_${sanitized}_$semester.pdf';
  }

  Future<void> downloadPdf(String semester, {BuildContext? context}) async {
    debugPrint(
      '[KhsDetailCubit] downloadPdf called: semester=$semester selectedTahunAjaran=$_selectedTahunAjaran currentStatus=$_downloadStatus hasController=${_downloadController != null}',
    );
    if (_downloadStatus == DownloadStatus.downloading) {
      debugPrint('[KhsDetailCubit] downloadPdf ignored: already downloading');
      return;
    }

    final creds = await _cache.loadCredentials();
    if (isClosed) return;
    final npm = creds?['npm'];
    final password = creds?['password'];

    if (npm == null || npm.isEmpty || password == null || password.isEmpty) {
      debugPrint(
        '[KhsDetailCubit] downloadPdf credentials missing: npm=${npm?.isNotEmpty} pwd=${password?.isNotEmpty}',
      );
      _downloadStatus = DownloadStatus.error;
      _downloadedFileName = null;
      _downloadedFilePath = null;
      if (isClosed) return;
      emit(_emitWithDownloadStatus(DownloadStatus.error));
      const msg = AppStrings.khsDownloadNoCredentials;
      if (context != null && context.mounted) {
        ErrorHandler.show(context, msg);
      }
      final fileName = _fileNameFor(semester);
      final ctrl = _downloadController;
      if (ctrl != null) {
        try {
          debugPrint(
            '[KhsDetailCubit] noCredentials → checking notification permission for error notification',
          );
          final allowed = await ctrl.ensurePermission();
          debugPrint(
            '[KhsDetailCubit] noCredentials permission allowed=$allowed',
          );
          if (allowed) {
            await ctrl.showError(
              fileName: fileName,
              reason: msg,
              withRetry: false,
            );
          } else {
            debugPrint(
              '[KhsDetailCubit] noCredentials skip error notification: permission denied',
            );
          }
        } catch (e, st) {
          debugPrint(
            '[KhsDetailCubit] noCredentials showError failed: $e\n$st',
          );
        }
      } else {
        debugPrint(
          '[KhsDetailCubit] noCredentials: no controller, skip notification',
        );
      }
      return;
    }

    final fileName = _fileNameFor(semester);
    bool showNotification = false;
    final ctrl = _downloadController;
    if (ctrl != null) {
      debugPrint('[KhsDetailCubit] checking notification permission...');
      try {
        showNotification = await ctrl.ensurePermission();
        if (isClosed) return;
        debugPrint(
          '[KhsDetailCubit] permission result: showNotification=$showNotification',
        );
      } catch (e, st) {
        debugPrint('[KhsDetailCubit] ensurePermission threw: $e\n$st');
        showNotification = false;
      }
      if (showNotification) {
        debugPrint(
          '[KhsDetailCubit] showing ongoing notification: $fileName semester=$semester',
        );
        ctrl.notifyDownloadStarted(semester);
        await ctrl.showOngoing(fileName: fileName);
        if (isClosed) return;
        debugPrint('[KhsDetailCubit] ongoing shown');
      } else {
        debugPrint(
          '[KhsDetailCubit] skipping notification (soft-gate denied) — download continues without notification',
        );
      }
    } else {
      debugPrint(
        '[KhsDetailCubit] no download controller — download without notification',
      );
    }

    _downloadStatus = DownloadStatus.downloading;
    debugPrint('[KhsDetailCubit] emit downloading: $fileName');
    if (isClosed) return;
    emit(_emitWithDownloadStatus(DownloadStatus.downloading));

    try {
      debugPrint(
        '[KhsDetailCubit] calling KhsPdfService.download npm=$npm tahunAjaran=$_selectedTahunAjaran semester=$semester',
      );
      final filePath = await _pdfService.download(
        npm: npm,
        password: password,
        tahunAjaran: _selectedTahunAjaran,
        semester: semester,
      );
      if (isClosed) return;
      debugPrint(
        '[KhsDetailCubit] download success: $fileName → $filePath exists=${File(filePath).existsSync()}',
      );
      _downloadStatus = DownloadStatus.success;
      _downloadedFileName = fileName;
      _downloadedFilePath = filePath;
      if (isClosed) return;
      emit(_emitWithDownloadStatus(DownloadStatus.success));
      debugPrint(
        '[KhsDetailCubit] emit success: fileName=$fileName filePath=$filePath showNotification=$showNotification hasCtrl=${ctrl != null}',
      );
      if (showNotification && ctrl != null) {
        debugPrint('[KhsDetailCubit] showing completed notification');
        await ctrl.showCompleted(fileName: fileName, filePath: filePath);
        debugPrint('[KhsDetailCubit] completed notification shown');
      } else {
        debugPrint(
          '[KhsDetailCubit] skip completed notification (showNotification=$showNotification)',
        );
      }
    } catch (e, st) {
      debugPrint(
        '[KhsDetailCubit] download failed: $e\n$st fileName=$fileName',
      );
      _downloadStatus = DownloadStatus.error;
      _downloadedFileName = fileName;
      _downloadedFilePath = null;
      if (isClosed) return;
      emit(_emitWithDownloadStatus(DownloadStatus.error));
      debugPrint('[KhsDetailCubit] emit error: $fileName error=$e');
      if (context != null && context.mounted) {
        ErrorHandler.show(context, e);
      } else {
        if (e is AuthException) {
          debugPrint('[KhsDetailCubit] download auth error: $e');
        } else {
          try {
            handleError(e);
          } catch (_) {}
        }
      }
      if (showNotification && ctrl != null) {
        final reason = e is AppException ? e.message : e.toString();
        debugPrint('[KhsDetailCubit] showing error notification: $reason');
        await ctrl.showError(fileName: fileName, reason: reason);
      } else {
        debugPrint(
          '[KhsDetailCubit] skip error notification (showNotification=$showNotification)',
        );
      }
    }
  }

  Future<void> loadAvailableYears() async {
    try {
      final creds = await _cache.loadCredentials();
      if (isClosed) return;
      final npm = creds?['npm'];
      if (npm == null || npm.isEmpty) return;

      final khsList = await _cache.loadKhsList(npm: npm);
      if (isClosed) return;
      if (khsList == null) return;

      final years = <String>{};
      for (final item in khsList) {
        if (item is Map) {
          final tahun =
              (item['tahunAjaran'] ?? item['tahun_ajaran']) as String?;
          if (tahun != null && tahun.isNotEmpty) {
            years.add(tahun);
          }
        }
      }
      _availableYears = years.toList();
      if (isClosed) return;
      emit(_emitWithDownloadStatus(_downloadStatus));
    } catch (e) {
      // Silently fail — available years is optional enrichment
    }
  }

  KhsDetailState _emitWithDownloadStatus(DownloadStatus status) {
    final emitName = status == DownloadStatus.idle ? null : _downloadedFileName;
    final emitPath = status == DownloadStatus.idle ? null : _downloadedFilePath;
    final current = state;
    if (current is KhsDetailLoaded) {
      return KhsDetailLoaded(
        ganjilData: current.ganjilData,
        genapData: current.genapData,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: status,
        isFetching: _isFetching,
        downloadedFileName: emitName,
        downloadedFilePath: emitPath,
      );
    }
    if (current is KhsDetailError) {
      return KhsDetailError(
        ganjilError: current.ganjilError,
        genapError: current.genapError,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: status,
        isFetching: _isFetching,
        downloadedFileName: emitName,
        downloadedFilePath: emitPath,
      );
    }
    return KhsDetailLoading(
      selectedTahunAjaran: _selectedTahunAjaran,
      availableYears: _availableYears,
      downloadStatus: status,
      isFetching: _isFetching,
      downloadedFileName: emitName,
      downloadedFilePath: emitPath,
    );
  }

  KhsDetailState _emitWithFetching(bool fetching) {
    final current = state;
    if (current is KhsDetailLoaded) {
      return KhsDetailLoaded(
        ganjilData: current.ganjilData,
        genapData: current.genapData,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
        isFetching: fetching,
        downloadedFileName: _downloadedFileName,
        downloadedFilePath: _downloadedFilePath,
      );
    }
    if (current is KhsDetailError) {
      return KhsDetailError(
        ganjilError: current.ganjilError,
        genapError: current.genapError,
        selectedTahunAjaran: _selectedTahunAjaran,
        availableYears: _availableYears,
        downloadStatus: _downloadStatus,
        isFetching: fetching,
        downloadedFileName: _downloadedFileName,
        downloadedFilePath: _downloadedFilePath,
      );
    }
    return KhsDetailLoading(
      selectedTahunAjaran: _selectedTahunAjaran,
      availableYears: _availableYears,
      downloadStatus: _downloadStatus,
      isFetching: fetching,
      downloadedFileName: _downloadedFileName,
      downloadedFilePath: _downloadedFilePath,
    );
  }
}
