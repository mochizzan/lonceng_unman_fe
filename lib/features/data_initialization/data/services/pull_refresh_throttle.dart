/// Melacak pull-refresh berat dalam rolling window 60 detik, per NPM.
///
/// - [shouldThrottle] bernilai true bila sudah ada >= 2 jalur berat dalam
///   60 detik terakhir ([window]) untuk NPM tersebut.
/// - [recordHeavy] dipanggil saat jalur berat DIMULAI (gagal pun dihitung,
///   karena backend tetap kena hit).
/// - In-memory saja ([Map], bukan Hive/SharedPreferences); restart app me-reset
///   semua kuota. Wajar untuk jendela 60 detik dan menghindari I/O persistensi.
/// - Jam bisa di-inject lewat constructor ([clock]) atau parameter [now] agar
///   unit test deterministik tanpa [Future.delayed].
class PullRefreshThrottle {
  PullRefreshThrottle({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _heavyHits = {};

  /// Rolling window throttle: maksimal [maxHeavyPerWindow] jalur berat
  /// per [window], per NPM.
  static const window = Duration(seconds: 60);

  /// Maksimal pull-refresh berat yang diizinkan dalam satu [window].
  static const maxHeavyPerWindow = 2;

  /// True bila NPM ini sudah menghabiskan kuota jalur berat dalam [window].
  ///
  /// Membuang dulu timestamp yang kedaluwarsa
  /// (`now.difference(ts) > window`), lalu mengembalikan true bila sisa
  /// entri `>= maxHeavyPerWindow`.
  bool shouldThrottle(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final hits = _heavyHits[npm];
    if (hits == null) return false;
    hits.removeWhere((ts) => t.difference(ts) > window);
    return hits.length >= maxHeavyPerWindow;
  }

  /// Mencatat satu pull-refresh berat untuk [npm] pada [now].
  ///
  /// Prune dulu (agar list tidak tumbuh tanpa batas), lalu tambah timestamp.
  /// Panggil tepat sebelum jalur berat dieksekusi, bukan setelah sukses.
  void recordHeavy(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final hits = _heavyHits.putIfAbsent(npm, () => <DateTime>[]);
    hits.removeWhere((ts) => t.difference(ts) > window);
    hits.add(t);
  }
}
