/// Pelacak debounce pull-refresh: sliding 3 menit, setiap pull touch.
///
/// - [shouldUseLight] true bila ada catatan pull dalam 180 detik
///   terakhir. NULL (belum pernah trigger) = tidak throttled.
/// - [touch] dipanggil di AWAL setiap pull-refresh (heavy maupun light,
///   A1 — bahkan jika pipeline gagal/offline/timeout) untuk menggeser
///   jangkar window ke `now` (sliding reset). Heavy hanya terjadi bila
///   sudah ≥ 3 menit tanpa pull sama sekali.
/// - In-memory saja ([Map], bukan Hive/SharedPreferences); restart app
///   me-reset semua catatan. Wajar untuk jendela 3 menit dan menghindari
///   I/O persistensi.
/// - Jam bisa di-inject lewat constructor ([clock]) atau parameter [now]
///   agar unit test deterministik tanpa [Future.delayed].
class PullRefreshDebounce {
  PullRefreshDebounce({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastTouch = {};

  /// Jendela debounce 3 menit (sliding). Setiap pull menggeser jangkar;
  /// pull dalam window memakai jalur ringan, pull setelah idle ≥ window
  /// memakai jalur berat.
  static const window = Duration(minutes: 3);

  /// True bila jalur ringan harus dipakai untuk [npm] pada [now].
  ///
  /// `last == null` (belum pernah pull) → false (jalur berat).
  /// `now - last < window` → true (jalur ringan, debounce aktif).
  /// `now - last >= window` → false (jalur berat, window sudah lewat).
  bool shouldUseLight(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final last = _lastTouch[npm];
    if (last == null) return false;
    return t.difference(last) < window;
  }

  /// Menggeser jangkar debounce untuk [npm] ke [now] (sliding reset).
  ///
  /// Dipanggil di AWAL setiap pull-refresh sebelum branching heavy/light
  /// (A1). Overwrite timestamp: pull berikutnya dalam window dihitung dari
  /// waktu [now] ini, bukan dari pull sebelumnya. Fresh login
  /// (`isPullRefresh:false`) TIDAK memanggil ini.
  void touch(String npm, [DateTime? now]) {
    _lastTouch[npm] = now ?? _clock();
  }
}
