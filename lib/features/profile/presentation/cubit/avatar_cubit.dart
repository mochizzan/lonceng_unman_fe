// profile - Avatar Cubit
//
// Mengelola foto profil lokal: memuat dari Hive box `avatar`, menyimpan hasil
// crop, dan menghapus. Avatar bersifat lokal — tidak pernah dikirim ke backend.
//
// Pemilihan gambar dan crop dilakukan di layer presentation (butuh
// BuildContext untuk navigasi), cubit hanya menerima bytes PNG hasil crop.

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';

class AvatarCubit extends Cubit<AvatarState> {
  AvatarCubit({required this.npm, AvatarCacheService? cache})
    : _cache = cache ?? Services.get<AvatarCacheService>(),
      super(const AvatarInitial());

  /// NPM pemilik avatar — sekaligus key di box `avatar`.
  final String npm;
  final AvatarCacheService _cache;

  /// Membaca avatar tersimpan milik [npm].
  Future<void> load() async {
    if (npm.isEmpty) {
      emit(const AvatarReady(null));
      return;
    }
    try {
      final bytes = await _cache.loadAvatar(npm);
      emit(AvatarReady(bytes));
    } catch (_) {
      emit(const AvatarReady(null));
    }
  }

  /// Menandai bahwa proses pilih/crop sedang berjalan.
  void markProcessing() => emit(AvatarProcessing(bytes: state.bytes));

  /// Membatalkan status proses tanpa mengubah avatar (user batal memilih).
  void cancelProcessing() => emit(AvatarReady(state.bytes));

  /// Menyimpan [png] hasil crop sebagai avatar milik [npm].
  Future<void> save(Uint8List png) async {
    if (npm.isEmpty) {
      emit(AvatarFailure(AppStrings.avatarSaveError, bytes: state.bytes));
      return;
    }
    emit(AvatarProcessing(bytes: state.bytes));
    try {
      await _cache.saveAvatar(npm: npm, bytes: png);
      emit(AvatarReady(png));
    } catch (_) {
      emit(AvatarFailure(AppStrings.avatarSaveError, bytes: state.bytes));
    }
  }

  /// Menghapus avatar milik [npm].
  Future<void> remove() async {
    if (npm.isEmpty) return;
    emit(AvatarProcessing(bytes: state.bytes));
    try {
      await _cache.deleteAvatar(npm);
      emit(const AvatarReady(null));
    } catch (_) {
      emit(AvatarFailure(AppStrings.avatarSaveError, bytes: state.bytes));
    }
  }

  /// Melaporkan kegagalan dari layer presentation (pilih gambar / crop).
  void reportFailure(String message) =>
      emit(AvatarFailure(message, bytes: state.bytes));
}
