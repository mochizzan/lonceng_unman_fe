/// Pelacak debounce pull-refresh: 1 jalur berat per 2 menit per NPM.
///
/// - [shouldUseLight] true bila ada catatan jalur berat dalam 120 detik
///   terakhir. NULL (belum pernah trigger) = tidak throttled.
/// - [recordHeavy] dipanggil saat jalur berat DIMULAI; update timestamp
///   ke waktu trigger itu (debounce reset).
/// - In-memory saja ([Map], bukan Hive/SharedPreferences); restart app
///   me-reset semua catatan. Wajar untuk jendela 2 menit dan menghindari
///   I/O persistensi.
/// - Jam bisa di-inject lewat constructor ([clock]) atau parameter [now]
///   agar unit test deterministik tanpa [Future.delayed].
class PullRefreshDebounce {
  PullRefreshDebounce({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastHeavyHit = {};

  /// Jendela debounce 2 menit. Trigger dalam window ini memakai jalur
  /// ringan; trigger setelah window (atau tidak ada catatan) memakai
  /// jalur berat dan memperbarui timestamp.
  static const window = Duration(minutes: 2);

  /// True bila jalur ringan harus dipakai untuk [npm] pada [now].
  ///
  /// `last == null` (belum pernah trigger) → false (jalur berat).
  /// `now - last < window` → true (jalur ringan, debounce aktif).
  /// `now - last >= window` → false (jalur berat, window sudah lewat).
  bool shouldUseLight(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final last = _lastHeavyHit[npm];
    if (last == null) return false;
    return t.difference(last) < window;
  }

  /// Mencatat timestamp jalur berat untuk [npm] pada [now].
  ///
  /// Dipanggil tepat sebelum jalur berat dieksekusi. Overwrite timestamp
  /// (debounce reset): trigger berikutnya dalam window dihitung dari
  /// waktu [now] ini, bukan dari trigger sebelumnya.
  void recordHeavy(String npm, [DateTime? now]) {
    _lastHeavyHit[npm] = now ?? _clock();
  }
}
