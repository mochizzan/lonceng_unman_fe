# Desain: Debounce 1 Pull-Refresh per 2 Menit + Fallback Jalur Ringan

- Tanggal: 2026-09-05
- Lokasi: `docs/superpowers/specs/2026-09-05-pull-refresh-debounce-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go (BE) tidak diubah.
- Status: Disetujui per bagian di sesi brainstorming (Desain 1/5 s/d 5/5: ya).
- Supersedes: spec throttle rolling-2-RPM (`2026-09-04-pull-refresh-throttle-design.md`)
  bagian Mekanisme diganti dari "rolling 60 detik, 2 RPM" menjadi "debounce 2 menit,
  reset setiap trigger". Spec throttle lama tetap jadi referensi urutan pipeline,
  cabang ringan, dan helper yang sama — bagian yang TIDAK berubah TIDAK ditulis
  ulang di sini.

## 1. Latar Belakang & Masalah

Spec throttle lama (`2026-09-04-pull-refresh-throttle-design.md`) membatasi
pull-refresh berat menjadi 2 per rolling 60 detik dan mengalihkan pull-refresh
ke-3+ ke jalur ringan. Implementasinya sudah jadi dan hijau (commit `7cef42a`).

User meminta perubahan mekanisme dari rolling-2-RPM menjadi **debounce 1 per 2
menit** dengan aturan:

- Pull-refresh pertama saat user diam ≥ 2 menit (atau app baru/restart) =
  jalur BERAT.
- Pull-refresh berikut dalam 2 menit dari trigger terakhir = jalur RINGAN dan
  timestamp di-reset ke waktu trigger itu.
- Pull-refresh setelah diam 2 menit penuh tanpa trigger = jalur BERAT dan
  timestamp di-update.
- Login (fresh login) SELALU BERAT, tidak pernah dicek/catat.
- Throttle keyed per-NPM, in-memory, reset saat restart.

Alasan perubahan: rolling 2 RPM mengizinkan 2× refresh berat dalam 1 menit
(waktu proses 2 endpoint berat) yang tetap membebani backend. Debounce 1 per 2
menit lebih hemat: 1× refresh berat per 2 menit, dan setiap trigger UI
spam-tap hanya menambahkan kerja ringan (5 endpoint get, bukan 8+ berat).

Juga dari eksplorasi sumber: `DataRefreshOverlay` saat ini meneruskan
`onRetry` + `onClose` callback ke `DataInitProgressView` (baris 220-228),
sehingga tombol Retry/Coba Lagi + Tutup SELALU tampil di error view pull-refresh
— padahal spec lama dan niat user adalah auto-close tanpa tombol. Spec ini
memperbaiki itu: pull-refresh TIDAK BOLEH tampilkan tombol apapun.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Mengganti mekanisme throttle rolling-2-RPM dengan debounce 1 per 2 menit
   per NPM.
2. Setiap trigger pull-refresh, terlepas dari hasil, menggeser timestamp
   window ke waktu trigger itu (resettable debounce).
3. Pull-refresh pertama (user diam ≥ 2 menit atau app restart) selalu
   jalur berat.
4. Pull-refresh berikutnya dalam 2 menit otomatis memakai jalur ringan
   (fallback) yang sama seperti spec throttle lama.
5. Pull-refresh overlay TIDAK menampilkan tombol apapun di error view
   maupun sukses view (auto-close saja). Login flow TIDAK TERSENTUH —
   tetap menampilkan tombol Retry/Cancel + auto-retry 15 detik.
6. Fresh login selalu jalur berat, tidak pernah dicek/catat.
7. Tidak ada perubahan backend Go, endpoint, atau cache Hive.

### 2.2 Non-Tujuan (Non-Goals)

- Tidak mengubah backend Go (tanpa HTTP 429 / rate-limit server).
- Tidak menyentuh `/khs/file` (unduh PDF manual via `KhsPdfService`).
- Tidak mengubah `LoginPage`, login flow, atau `DataInitProgressView`
  `isFreshLogin: true` (tombol Retry/Cancel + auto-retry 15 detik
  `kStepErrorAutoContinue` tetap).
- Tidak mengubah urutan step pipeline, semantik wajib-vs-opsional, atau
  nama `failedStep` di jalur ringan/berat (diwarisi dari spec throttle
  lama apa adanya).
- Tidak ada persistensi debounce (in-memory saja, restart app = reset).
- Tidak mengubah makna `forceRefresh` atau perilaku fresh login.
- Tidak menambah endpoint baru.

## 3. Konteks Kode Saat Ini (Hasil Eksplorasi MCP)

### 3.1 Pemicu pipeline: satu event untuk dua alur (diwarisi)

- `lib/features/auth/presentation/pages/login_page.dart:118`: login
  me-mount `DataInitProgressView(isFreshLogin: true)` LANGSUNG
  (di luar `DataRefreshOverlay`). Dispatch `DataInitStarted` via BLoC
  dengan `isPullRefresh: false` (default).
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart:147-159`
  (`_dispatchPipeline` di `DataRefreshOverlay`): dispatch event yang
  sama dengan `isPullRefresh: true`. Dipanggil dari post-frame
  callback (saat overlay mount) dan dari callback `onRetry`/`onClose`
  (tombol UI yang akan dihapus).
- `DataInitBloc._onStarted`: guard `_isRunning`, emit `DataInitInProgress`,
  menjalankan stream dari `GetDataInitialization`, memetakan
  `completed → Success`, `failed → Failure`, status lain → `InProgress`.
  Timeout `kDataInitTimeout`.
- `DataInitializationRemoteDataSource.initialize(isPullRefresh)` (commit
  `7cef42a`): dispatcher throttle; bila `isPullRefresh &&
  _throttle.shouldThrottle(npm)` → `_initializeLight`; else
  `recordHeavy` (hanya bila pull-refresh) + `_initializeHeavy` verbatim.

### 3.2 Perbedaan jalur login vs pull-refresh (sumber)

| Aspek | Login (`isFreshLogin: true`) | Pull-Refresh (`isFreshLogin: false`) |
|-------|-----------------------------|--------------------------------------|
| Widget | `DataInitProgressView` langsung di `LoginPage` | `DataRefreshOverlay` membungkus `DataInitProgressView` |
| Tombol di error view | Retry/Cancel TETAP ada | TIDAK BOLEH ada (koreksi spec) |
| Auto-retry timer 15 detik | `kStepErrorAutoContinue` aktif | Tidak aktif (user tidak boleh auto-retry spam) |
| Auto-close | Tidak | 3 detik pada `DataInitFailure`, 500 ms pada `DataInitSuccess` |
| Refetch BLoC setelah sukses | Tidak (LoginPage yang handle) | Ya — `JadwalFetchRequested`, `HomeFetchRequested`, `ProfileFetchRequested` |

### 3.3 Throttle yang akan diganti

File `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
(commit `7cef42a`) berisi class `PullRefreshThrottle` dengan:
`Map<String, List<DateTime>> _heavyHits` (rolling list),
`shouldThrottle(npm, [now])`, `recordHeavy(npm, [now])`,
`static const window = Duration(seconds: 60)`,
`static const maxHeavyPerWindow = 2`.

Spec ini MENGGANTI mekanisme menjadi debounce 1 timestamp per NPM. File
implementasi dan test lama akan dihapus dan diganti.

## 4. Keputusan-Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Mekanisme throttle | Debounce 1 per 2 menit per NPM (ganti rolling 2 RPM). |
| 2 | Reset window | Setiap trigger pull-refresh (sukses/gagal/whatever) mereset timestamp ke waktu trigger. |
| 3 | Pull-refresh pertama | Selalu BERAT (cold start / app restart / user diam ≥ 2 menit). |
| 4 | Sumber semester saat fallback | `/khs/semesters` tetap dipanggil (diwarisi dari spec throttle lama). |
| 5 | Scrape profil saat throttled | Skip 2x `scrapeProfile`, langsung `getProfile` (diwarisi). |
| 6 | Pendekatan | A. Saklar debounce di pipeline (struktur datasource _initializeHeavy/_initializeLight dipakai apa adanya, tracker diganti). |
| 7 | Semantik failure cabang ringan | Pertahankan wajib-vs-opsional persis seperti spec throttle lama. |
| 8 | Tombol di pull-refresh overlay | TIDAK ADA tombol di error view dan sukses view (koreksi atas spec lama). |
| 9 | Tombol di login flow | TIDAK DIUBAH (Retry/Cancel + auto-retry 15 detik tetap). |

## 5. Desain Rinci

### 5.1 Desain 1/5 — Perilaku debounce (DISETUJUI)

```text
t=0    trigger → BERAT (lastHeavyHit=0).
t=30   trigger → RINGAN (30-0=30<120), lastHeavyHit=30.
t=100  trigger → RINGAN (100-30=70<120), lastHeavyHit=100.
t=200  trigger → RINGAN (200-100=100<120), lastHeavyHit=200.
t=250  trigger → RINGAN (250-200=50<120), lastHeavyHit=250.
t=380  trigger → BERAT (380-250=130>=120), lastHeavyHit=380.
```

Yang penting:

- **Pull-refresh pertama** (cold start / restart / user diam ≥ 2 menit):
  `lastHeavyHit[npm] == null` atau `now - lastHeavyHit[npm] >= 120s`
  → **BERAT**, lalu catat `lastHeavyHit[npm] = now`.
- **Pull-refresh berikut dalam 2 menit** dari trigger terakhir: **RINGAN**,
  `lastHeavyHit[npm] = now` (RESET ke waktu trigger).
- **Login (isPullRefresh == false)**: SELALU **BERAT**, tidak pernah dicek
  maupun catat.

### 5.2 Desain 2/5 — Pelacak debounce (DISETUJUI)

File baru:
`lib/features/data_initialization/data/services/pull_refresh_debounce.dart`.

```dart
/// Pelacak debounce pull-refresh: 1 jalur berat per 2 menit per NPM.
///
/// - [shouldUseLight] true bila ada catatan jalur berat dalam 120 detik
///   terakhir. NULL (belum pernah trigger) = tidak throttled.
/// - [recordHeavy] dipanggil saat jalur berat DIMULAI; update timestamp
///   ke waktu trigger itu (debounce reset).
/// - In-memory saja; restart app = reset.
/// - Jam via parameter opsional agar unit-test deterministik.
class PullRefreshDebounce {
  PullRefreshDebounce({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastHeavyHit = {};

  static const window = Duration(minutes: 2);

  /// True bila jalur ringan harus dipakai (pull-refresh dalam window).
  bool shouldUseLight(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final last = _lastHeavyHit[npm];
    if (last == null) return false;
    return t.difference(last) < window;
  }

  /// Catat timestamp jalur berat; dipanggil tepat sebelum jalur berat.
  void recordHeavy(String npm, [DateTime? now]) {
    _lastHeavyHit[npm] = now ?? _clock();
  }
}
```

Spesifikasi perilaku:

- `shouldUseLight(npm, now)`: `last = _lastHeavyHit[npm]`;
  `return last != null && now.difference(last) < window`.
- `recordHeavy(npm, now)`: `_lastHeavyHit[npm] = now` (overwrite, tidak
  disimpan sebagai list — debounce tidak butuh history).
- Keyed per-NPM (`Map<npm, DateTime>`): akun A tidak menggeser akun B.
- In-memory; restart = `lastHeavyHit` kosong = trigger pertama BERAT.
- Thread-safety: Dart single-threaded event loop; tidak perlu lock.
- Registrasi DI: `Services.register<PullRefreshDebounce>(PullRefreshDebounce())`
  di `main.dart`; constructor-fallback di datasource seperti service lain.

File throttle lama (`pull_refresh_throttle.dart`) dan test-nya DIHAPUS, diganti
dengan file ini. Pendekatan dipilih: tracker sederhana (1 timestamp per NPM)
bukan tracker list (rolling window) yang tidak relevan untuk debounce.

Titik keputusan di `initialize()` (MENGUBAH yang lama, hanya 2 baris):

```dart
Stream<DataInitProgress> initialize({npm, password, forceRefresh, isPullRefresh}) async* {
  if (isPullRefresh && _debounce.shouldUseLight(npm)) {
    yield* _initializeLight(npm: npm, password: password);
    return;
  }
  if (isPullRefresh) _debounce.recordHeavy(npm);
  yield* _initializeHeavy(npm: npm, password: password, forceRefresh: forceRefresh);
}
```

Perubahan dari spec throttle lama: `shouldThrottle` → `shouldUseLight`,
`recordHeavy` tetap (tetap hanya dipanggil untuk pull-refresh).

### 5.3 Desain 3/5 — Titik keputusan di pipeline (DISETUJUI)

Struktur `initialize()` (DARI spec throttle lama, TIDAK berubah):

- `_initializeHeavy`: isi method awal sebelum refactor (commit `7cef42a`),
  dipindah tanpa perubahan logika. Pemanggilan `scrapeProfile/downloadKrs/
  extractKrs/downloadKhs/extractKhs` di sini.
- `_initializeLight`: urutan 1-6 (getProfile rethrow → fetchPhoto non-fatal →
  getKrsData non-fatal → getSemesters + getKhsData per-semester non-fatal →
  cache foto → completed). `forceRefresh: true` di semua get/data.
- Helper private bersama dipakai kedua cabang (tidak diubah).

Yang berubah di spec ini HANYA tracker: `PullRefreshThrottle` →
`PullRefreshDebounce` (nama field `_throttle` → `_debounce`, jenis field
`Map<String, List<DateTime>>` → `Map<String, DateTime>`, method
`shouldThrottle` → `shouldUseLight`). Selebihnya identik dengan spec throttle
lama.

### 5.4 Desain 4/5 — Error handling & edge cases (DISETUJUI dengan koreksi)

Jalur PULL-REFRESH (`DataRefreshOverlay`):

- `DataInitFailure` → tampilkan `_buildErrorView` di `DataInitProgressView`
  dengan `onRetry` dan `onClose` di-pass **null** (TIDAK diteruskan
  dari `DataRefreshOverlay`). Hasil: error view TANPA tombol apapun.
  Auto-close 3 detik oleh `_autoCloseTimer` di `DataRefreshOverlay`.
- `DataInitSuccess` → `Future.delayed(500ms)` lalu `Navigator.pop()`.
  Tidak ada tombol (saat ini memang tidak ada).
- `getProfile` gagal → `rethrow` → BLoC emit `DataInitFailure(message,
  failedStep: 'profile_get')` → overlay 3 detik auto-close.
- `getKrsData/getSemesters/getKhsData/fetchPhoto` gagal → non-fatal
  (`krsEmpty/khsEmpty/photoEmpty`), pipeline lanjut.
- `AuthException` dari endpoint ringan manapun tetap `rethrow` →
  `ApiClient.onAuthError` → `performFullLogout` global.
- `failedStep` nama lama (`profile_get`, `krs_data`, `khs_semesters`,
  `khs_data_<semester>`); chip step di error view via
  `_humanReadableFailedStep` → `dataInitStatusText` tidak berubah.
- Pull-refresh yang gagal: `krsEmpty/khsEmpty/photoEmpty` tetap di-emit
  sebagai `InProgress` (BLoC map) — tidak menjadi error view.
- `kStepErrorAutoContinue` (15 detik auto-retry) TIDAK AKTIF di
  pull-refresh (`isFreshLogin: false` di `DataInitProgressView`).
- Throttle keyed per-NPM; kredensial kosong (tidak ada di cache) →
  `triggerRefresh` abort diam-diam (tidak diubah).
- Tidak ada penanda visual "mode hemat / debounce" di UI.

Jalur LOGIN (`DataInitProgressView(isFreshLogin: true)` di LoginPage):

- Tombol Retry/Cancel TETAP ADA (di-handle oleh `_buildErrorView` dengan
  `hasActions = onRetry != null || onClose != null`).
- Auto-retry 15 detik `kStepErrorAutoContinue` TETAP AKTIF
  (`_isProfileError` + timer di `DataInitProgressView`).
- Tidak auto-close (LoginPage menunggu sukses/failure eksplisit).
- Login SELALU BERAT (tidak dicek throttle).

### 5.5 Desain 5/5 — Testing (DISETUJUI)

1. **Unit test debounce** —
   `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`:
   - Hit pertama (lastHeavyHit null) → `shouldUseLight == false`.
   - Setelah `recordHeavy(t=0)` + cek `t=30` → `shouldUseLight == true`.
   - Cek `t=119s` → `true`; `t=120s` → `false` (boundary tepat
     `>= 120s` = boleh berat).
   - Cek `t=121s` setelah `recordHeavy(t=0)` → `false` (path berat).
   - `recordHeavy` reset timestamp: `recordHeavy(t=0)`, `t=30` cek true,
     `recordHeavy(t=30)`, `t=40` cek true (reset), `t=200` cek false
     (2 menit dari t=30? 200-30=170>=120 → false, BERAT).
   - NPM berbeda isolated (npm1 recordHeavy tidak memengaruhi npm2).
   - Jam di-inject (`fakeNow`), tanpa `Future.delayed`.
   - File: replace spec throttle lama. Test file throttle lama
     (`pull_refresh_throttle_test.dart`) DIHAPUS.

2. **Cabang datasource** — perluasan test spec throttle lama
   (`data_initialization_remote_data_source_light_branch_test.dart`):
   - `_FakeDebounce` yang return `shouldUseLight true` + `isPullRefresh: true`
     → verifikasi `scrapeProfile/downloadKrs/extractKrs/downloadKhs/
     extractKhs` TIDAK PERNAH dipanggil; `getProfile/getKrsData/
     getSemesters/getKhsData/fetchPhoto` dipanggil sesuai urutan; stream
     emit status ringan berurutan lalu `completed`. `recordHeavy` TIDAK
     dipanggil.
   - `_FakeDebounce` return `shouldUseLight false` + `isPullRefresh: true`
     → urutan berat + `recordHeavy` dipanggil sekali (lastHeavyHit tercatat).
   - `isPullRefresh: false` (login) → `shouldUseLight` TIDAK dipanggil,
     jalur berat jalan, `recordHeavy` TIDAK dipanggil.
   - Failure ringan: `getProfile` throw → stream berakhir Failure dengan
     `failedStep: 'profile_get'`; `getKrsData` throw → `krsEmpty` lanjut;
     `getSemesters` throw → `khsEmpty`; `getKhsData` satu semester throw
     → semester lain tetap.
   - AuthException rethrow.

3. **Pass-through flag** — perluasan `is_pull_refresh_passthrough_test.dart`:
   - Default `false` di `DataInitStarted`/usecase/repo.
   - `DataRefreshOverlay._dispatchPipeline` mengirim
     `isPullRefresh: true` (mount + retry callback; meski retry callback
     sudah tidak lagi dipicu dari UI, callback internal masih mengirim
     flag benar).

4. **Overlay TIDAK menampilkan tombol** — widget test baru
   `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`
   (perluan file ini yang sudah ada atau test baru):
   - Pump `DataRefreshOverlay` dengan `DataInitBloc` yang memaksa
     `DataInitFailure`.
   - Verifikasi `find.byType(FilledButton)` findsNothing dan
     `find.byType(OutlinedButton)` findsNothing di error view.
   - Verifikasi `_buildErrorView` di-render (icon, judul, chip step,
     pesan error, hint) — tanpa tombol.
   - Verifikasi auto-close 3 detik: pump 3.1 detik, verifikasi
     `Navigator.pop` dipanggil (atau overlay sudah ter-pop).

5. **Login flow tidak berubah** — tidak perlu test baru. Gate pass
   untuk `login_page_test.dart` (eksisting) sudah cukup.

6. **Gate**: `flutter analyze` bersih; `flutter test` fokus di
   `test/features/data_initialization/**`,
   `test/features/auth/presentation/pages/login_page_test.dart`,
   `test/router/**`. Tanpa Patrol E2E (logika debounce murni unit-testable;
   E2E login 50 detik tidak memberi nilai tambah).

## 6. Arsitektur & Aliran Data (Ringkasan)

```text
Pull-refresh (Home/Jadwal/Profile)
  → DataRefreshOverlay.triggerRefresh (load kredensial Hive)
    → show overlay → _dispatchPipeline
      → DataInitReset + DataInitStarted(isPullRefresh: true, forceRefresh: true)
        → DataInitBloc._onStarted (guard _isRunning, timeout)
          → GetDataInitialization(isPullRefresh)
            → DataInitializationRepository.initialize(isPullRefresh)
              → DataInitializationRemoteDataSource.initialize
                → debounce.shouldUseLight(npm)?
                    YA  → _initializeLight  (5 endpoint ringan, skip berat)
                    TIDAK → (bila pull-refresh: recordHeavy + lastHeavyHit=now)
                            + _initializeHeavy (jalur lama utuh;
                              login langsung _initializeHeavy tanpa catat)
          → stream DataInitProgress → BLoC state → overlay/view
            → Success: refetch Jadwal/Home/Profile + pop 500ms (tanpa tombol)
            → Failure: error view TANPA tombol + auto-close 3s

Login (LoginPage)
  → DataInitProgressView(isFreshLogin: true) (di luar DataRefreshOverlay)
    → DataInitReset + DataInitStarted(isPullRefresh: false, forceRefresh: true)
      → … (jalur BERAT, tidak dicek debounce)
      → Failure: error view DENGAN Retry/Cancel + auto-retry 15s
      → Success: onComplete → navigate ke Home
```

Komponen yang BERUBAH:

- `lib/features/data_initialization/data/services/pull_refresh_debounce.dart`
  (BARU; tracker).
- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`
  (field `_throttle` → `_debounce`, jenis field, panggilan
  `shouldThrottle` → `shouldUseLight`; selebihnya IDENTIK dengan
  commit `7cef42a`).
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart`
  (onRetry + onClose ke `DataInitProgressView` jadi null).
- `lib/main.dart` (registrasi `PullRefreshDebounce` ganti
  `PullRefreshThrottle`; teruskan ke datasource).

Komponen yang DIHAPUS:

- `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
  (ganti debounce).
- `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`
  (ganti debounce test).

## 7. Estimasi File yang Disentuh (untuk writing-plans)

Baru:

- `lib/features/data_initialization/data/services/pull_refresh_debounce.dart`
- `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`
- (widget test tombol hilang di overlay) — bisa berupa test baru atau
  perluasan `data_refresh_overlay_test.dart` yang sudah ada.

Ubah:

- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`
  (ganti tracker, field _throttle → _debounce, panggilan method).
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart`
  (onRetry + onClose = null di DataInitProgressView).
- `lib/main.dart` (registrasi PullRefreshDebounce ganti PullRefreshThrottle).
- `test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart`
  (ganti FakeThrottle jadi FakeDebounce; signature method).
- `test/features/data_initialization/is_pull_refresh_passthrough_test.dart`
  (tidak ada perubahan; sudah menutupi).

Hapus:

- `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
- `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`

Tidak disentuh: `LoginPage`, BLoC, `DataInitProgressView` (logika
internal), `dataInitStatusText`, `ApiClient`, `PhotoService`,
`KhsPdfService`, cache services, router, tema, event/usecase/repo
(flag `isPullRefresh` sudah ada dari commit `7cef42a`).

## 8. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Salah reset window — pencocokan >= vs > | Test boundary tepat 120s; spec eksplisit: `< 120s` = light, `>= 120s` = heavy. |
| Pull-refresh pertama keliru dianggap debounce aktif | Default `lastHeavyHit[npm] == null` → `shouldUseLight == false` (berat). Test eksplisit. |
| User bingung pull-refresh ke-2 lambat (ringan) | Perilaku yang diinginkan (hemat backend); tidak ada teks khusus sesuai keputusan. |
| `DataRefreshOverlay` lupa set onRetry/onClose = null | Widget test yang memaksa Failure dan asserts FilledButton/OutlinedButton findsNothing. |
| Login flow tidak sengaja kena throttle | `isPullRefresh: false` di LoginPage; dispatcher di datasource skip throttle check; test memastikan. |
| Multi-akun satu device | Tracker per-NPM. |

## 9. Pertanyaan Terbuka

Tidak ada. Semua keputusan (debounce 2 menit reset, per-NPM, tanpa
tombol di pull-refresh, login tidak berubah, struktur datasource
dipertahankan) disetujui di sesi brainstorming.
