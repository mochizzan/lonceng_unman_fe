// profile - Avatar Cubit
//
// Mengelola foto profil lokal: memuat dari Hive box `avatar`, menyimpan hasil
// crop, dan menghapus. Avatar bersifat lokal — tidak pernah dikirim ke backend.
//
// Cubit ini SINGLETON GLOBAL (didaftarkan di `Services` dan di-provide di root
// `main.dart`), sehingga header Home dan halaman Profile membaca instance yang
// sama dan selalu menampilkan foto yang identik. NPM pemilik avatar tidak lagi
// dikunci di konstruktor melainkan diikat lewat [bindNpm] saat profil termuat,
// dan dilepas lewat [reset] saat logout.
//
// Pemilihan gambar dan crop dilakukan di layer presentation (butuh
// BuildContext untuk navigasi), cubit hanya menerima bytes PNG hasil crop.

import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';

class AvatarCubit extends Cubit<AvatarState> {
  AvatarCubit({
    AvatarCacheService? cache,
    AcademicCacheService? academicCache,
    PhotoService? photoService,
  }) : _cache = cache ?? Services.get<AvatarCacheService>(),
       // Tidak bisa memakai initializing formal: parameter bernama tidak boleh
       // privat, sedangkan fieldnya privat.
       _injectedAcademicCache = academicCache,
       _photoService = photoService,
       super(const AvatarInitial());

  final AvatarCacheService _cache;

  /// Bila null, [_academic] mencoba mengambilnya dari service locator saat
  /// dibutuhkan — supaya cubit tetap bisa dibuat pada test yang tidak
  /// mendaftarkan [AcademicCacheService].
  final AcademicCacheService? _injectedAcademicCache;

  /// Service untuk mengambil foto dari backend LMS.
  /// Bila null, lazy-loaded dari service locator saat dibutuhkan.
  final PhotoService? _photoService;

  PhotoService get _photo => _photoService ?? Services.get<PhotoService>();

  /// NPM pemilik avatar yang sedang terikat — sekaligus key di box `avatar`.
  /// Bernilai '' bila belum ada akun terikat (belum login / sudah logout).
  String _npm = '';

  /// True selama satu operasi tulis (simpan/hapus) berjalan. Dipakai untuk
  /// menolak permintaan ganda; SENGAJA tidak memakai `state is AvatarProcessing`
  /// karena layer presentation memasang state itu lebih dulu saat user membuka
  /// galeri (lihat ProfileAvatar._pickAndCrop), sehingga penjagaan berbasis
  /// state akan menolak setiap penyimpanan yang sah.
  bool _writing = false;

  /// NPM yang sedang terikat, '' bila belum ada.
  String get npm => _npm;

  AcademicCacheService? get _academic {
    if (_injectedAcademicCache != null) return _injectedAcademicCache;
    try {
      return Services.get<AcademicCacheService>();
    } catch (_) {
      return null;
    }
  }

  /// Emit yang aman dipanggil setelah `await`: cubit bisa saja sudah ditutup
  /// (mis. widget dilepas) sehingga `emit` biasa akan melempar StateError.
  void _safeEmit(AvatarState s) {
    if (!isClosed) emit(s);
  }

  /// Dipanggil DataInit setelah foto backend berhasil di-cache.
  /// Jika cubit sudah terikat ke [npm] yang sama, ini tetap meng-emit bytes
  /// tersebut (berbeda dari [bindNpm] yang no-op untuk npm sama). Jika cubit
  /// belum terikat, ia mengikat dulu lalu emit.
  void onPhotoCached(String npm, Uint8List bytes) {
    if (bytes.isEmpty) return;
    if (_npm == npm) {
      _safeEmit(AvatarReady(bytes));
      return;
    }
    _npm = npm;
    _safeEmit(AvatarReady(bytes));
  }

  /// Mengikat cubit ke [npm] dan memuat avatar miliknya.
  ///
  /// No-op bila [npm] sama dengan yang sedang terikat, supaya rebuild widget
  /// tidak memicu pembacaan cache dan emit ulang yang sia-sia.
  Future<void> bindNpm(String npm) async {
    if (npm == _npm) return;
    _npm = npm;
    if (npm.isEmpty) {
      _safeEmit(const AvatarReady(null));
      return;
    }
    try {
      final bytes = await _cache.loadAvatar(npm);
      // NPM bisa berganti lagi selama await; abaikan hasil yang kedaluwarsa
      // agar foto akun lama tidak menimpa akun yang baru terikat.
      if (_npm != npm) return;
      _safeEmit(AvatarReady(bytes));
    } catch (_) {
      if (_npm != npm) return;
      _safeEmit(const AvatarReady(null));
    }
  }

  /// Mengikat NPM dari kredensial tersimpan saat cold start, sebelum halaman
  /// Profile sempat terbuka, agar header Home langsung menampilkan foto.
  ///
  /// Tidak pernah melempar — kegagalan apa pun berujung AvatarReady(null).
  Future<void> bootstrap() async {
    try {
      final credentials = await _academic?.loadCredentials();
      final npm = credentials?['npm'];
      if (npm != null && npm.isNotEmpty) {
        await bindNpm(npm);
        return;
      }
      _safeEmit(const AvatarReady(null));
    } catch (_) {
      _safeEmit(const AvatarReady(null));
    }
  }

  /// Mengambil foto profil dari backend LMS dan menyimpannya ke cache lokal.
  ///
  /// Dipanggil saat DataInit pipeline dan saat user menekan "Perbarui Data".
  /// Tidak melempar — kegagalan dicatat ke state tanpa menghentikan pipeline.
  Future<void> fetchFromBackend({
    required String npm,
    required String password,
  }) async {
    if (_npm.isEmpty || _npm != npm) return;
    final previous = state.bytes;
    _safeEmit(AvatarFetching(bytes: previous));
    try {
      final bytes = await _photo.fetchPhoto(npm: npm, password: password);
      if (_npm != npm) return; // NPM berganti selama await
      if (bytes != null && bytes.isNotEmpty) {
        await _cache.saveAvatar(npm: npm, bytes: bytes);
        _safeEmit(AvatarReady(bytes));
      } else {
        // Backend tidak ada foto — pertahankan apa yang sudah ada
        _safeEmit(AvatarReady(previous));
      }
    } catch (e) {
      debugPrint('[AvatarCubit] fetchFromBackend gagal: $e');
      // Kegagalan fetch tidak menghapus foto yang sudah ada
      if (_npm != npm) return;
      _safeEmit(AvatarReady(previous));
    }
  }

  /// Melepas keterikatan akun saat logout: NPM dikosongkan dan foto berhenti
  /// ditampilkan.
  ///
  /// SENGAJA tidak menghapus apa pun dari box `avatar` — foto akun lama tetap
  /// tersimpan dan muncul lagi bila akun itu login kembali.
  void reset() {
    _npm = '';
    _safeEmit(const AvatarReady(null));
  }

  /// Menandai bahwa proses pilih/crop sedang berjalan.
  void markProcessing() => _safeEmit(AvatarProcessing(bytes: state.bytes));

  /// Membatalkan status proses tanpa mengubah avatar (user batal memilih).
  void cancelProcessing() => _safeEmit(AvatarReady(state.bytes));

  /// Menyimpan [png] hasil crop sebagai avatar milik NPM yang terikat.
  Future<void> save(Uint8List png) async {
    // Tolak permintaan simpan kedua saat penulisan pertama belum selesai.
    if (_writing) return;
    if (_npm.isEmpty) {
      _safeEmit(AvatarFailure(AppStrings.avatarSaveError, bytes: state.bytes));
      return;
    }
    // Foto lama dicatat SEBELUM emit processing supaya bisa dipulihkan bila
    // penulisan ke Hive gagal — yang tampil di layar harus selalu sama dengan
    // isi penyimpanan.
    final previous = state.bytes;
    _writing = true;
    _safeEmit(AvatarProcessing(bytes: previous));
    try {
      await _cache.saveAvatar(npm: _npm, bytes: png);
      _safeEmit(AvatarReady(png));
    } catch (_) {
      _safeEmit(AvatarFailure(AppStrings.avatarSaveError, bytes: previous));
    } finally {
      // Wajib di finally: kegagalan tulis tidak boleh mengunci cubit sehingga
      // percobaan simpan berikutnya tetap bisa berjalan.
      _writing = false;
    }
  }

  /// Menghapus avatar milik NPM yang terikat.
  Future<void> remove() async {
    if (_writing) return;
    if (_npm.isEmpty) return;
    final previous = state.bytes;
    _writing = true;
    _safeEmit(AvatarProcessing(bytes: previous));
    try {
      await _cache.deleteAvatar(_npm);
      _safeEmit(const AvatarReady(null));
    } catch (_) {
      _safeEmit(AvatarFailure(AppStrings.avatarSaveError, bytes: previous));
    } finally {
      _writing = false;
    }
  }

  /// Melaporkan kegagalan dari layer presentation (pilih gambar / crop).
  void reportFailure(String message) =>
      _safeEmit(AvatarFailure(message, bytes: state.bytes));
}
