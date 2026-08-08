import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/bloc_error_handler.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';

class KhsDetailCubit extends Cubit<KhsDetailState> with BlocErrorHandler {
  KhsDetailCubit({required this.tahunAjaran, AcademicCacheService? cache})
    : _cache = cache ?? Services.get<AcademicCacheService>(),
      super(const KhsDetailLoading());

  final String tahunAjaran;
  final AcademicCacheService _cache;

  Future<void> loadAll() async {
    emit(const KhsDetailLoading());
    final results = await Future.wait([
      _loadSemester(semester: 'GANJIL'),
      _loadSemester(semester: 'GENAP'),
    ]);
    final ganjilError = results[0]?['error'] as String?;
    final genapError = results[1]?['error'] as String?;
    final ganjilData = results[0]?['data'];
    final genapData = results[1]?['data'];

    if (ganjilError != null || genapError != null) {
      emit(KhsDetailError(ganjilError: ganjilError, genapError: genapError));
    } else {
      emit(KhsDetailLoaded(ganjilData: ganjilData, genapData: genapData));
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
        tahunAjaran: tahunAjaran,
        semester: semester,
      );
      if (khsJson == null) return {'data': null};
      final khsModel = KhsModel.fromJson(khsJson);
      return {'data': khsModel.khs};
    } catch (e) {
      return {'error': handleError(e)};
    }
  }
}
