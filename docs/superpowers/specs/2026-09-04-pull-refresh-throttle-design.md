# Desain: TTL 2 RPM + Fallback Jalur Ringan untuk Pull-Refresh

- Tanggal: 2026-09-04
- Lokasi: `docs/superpowers/specs/2026-09-04-pull-refresh-throttle-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go (BE) tidak diubah.
- Status: Disetujui per bagian di sesi brainstorming (Desain 1/5 s/d 5/5: ya).

## 1. Latar Belakang & Masalah

Setiap pull-refresh dari Home / Jadwal / Profile memanggil
`DataRefreshOverlay.triggerRefresh()` yang mendispatch pipeline penuh
`DataInitializationRemoteDataSource.initialize()` dengan `forceRefresh: true`.
Pipeline ini mencakup step-step berat yang menekan backend dan proses scraping LMS:

- 2x `scrapeProfile` → `POST /api/v1/lms/student-profile`
- `downloadKrs` → `POST /api/v1/lms/krs`
- `extractKrs` → `POST /api/v1/lms/krs/extract`
- `downloadKhs` per semester → `POST /api/v1/lms/khs`
- `extractKhs` per semester → `POST /api/v1/lms/khs`

Jika user melakukan spam pull-refresh (>2x dalam 1 menit), backend dihantam
request berat yang hasilnya nyaris tidak berubah karena data akademik tidak
berubah secepat itu. Fresh login tidak boleh terpengaruh karena pada login
pertama belum ada cache sama sekali dan semua data wajib diambil lengkap.

Catatan penting dari eksplorasi: endpoint `POST /api/v1/lms/khs/file` (BE:
`docHandler.DownloadKHSFile`) tidak pernah dipakai oleh pipeline data-init.
Endpoint itu hanya dipakai oleh tombol unduh PDF manual via `KhsPdfService`.
Maka throttle ini tidak menyentuh `/khs/file` — tidak ada perubahan di alur
unduh PDF manual.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Membatasi pull-refresh berat maksimal **2 request per menit** (rolling window
   60 detik, per NPM).
2. Pull-refresh ke-3 dan seterusnya dalam jendela yang sama otomatis memakai
   **jalur ringan (fallback)**: skip scrape/download/extract, langsung `get`
   tanpa pemrosesan ulang:
   - `POST /api/v1/lms/student-profile/data` via `getProfile` (wajib)
   - `POST /api/v1/lms/student-profile/photo` via `fetchPhoto` (opsional)
   - `POST /api/v1/lms/khs/semesters` via `getSemesters` (tetap dipanggil,
     sesuai keputusan user)
   - `POST /api/v1/lms/krs/data` via `getKrsData` (opsional)
   - `POST /api/v1/lms/khs/data` per semester via `getKhsData` (opsional)
3. Fresh login selalu jalur berat, tidak pernah kena throttle.
4. Tidak ada perubahan UI, overlay, status text, timeout pipeline, atau cache Hive.
5. Semua perilaku failure yang sudah ada dipertahankan apa adanya di cabang ringan.

### 2.2 Non-Tujuan (Non-Goals)

- Tidak mengubah backend Go (tanpa HTTP 429 / rate-limit server).
- Tidak menyentuh `/khs/file` (unduh PDF manual via `KhsPdfService`).
- Tidak mengubah `DataRefreshOverlay`, `DataInitProgressView`,
  `dataInitStatusText`, `kDataInitTimeout`, atau skema Hive.
- Tidak ada persistensi throttle (in-memory saja, restart app = reset).
- Tidak mengubah makna `forceRefresh` atau perilaku fresh login.
- Tidak menambah endpoint baru.

## 3. Konteks Kode Saat Ini (Hasil Eksplorasi MCP)

### 3.1 Pemicu pipeline: satu event untuk dua alur

- `lib/features/auth/presentation/pages/login_page.dart:72-78`:
  dispatch `DataInitReset()` + `DataInitStarted(npm, password, forceRefresh: true)`.
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart:143-150`
  (`_dispatchPipeline`, dipanggil saat overlay mount dan saat tombol Retry):
  dispatch event yang sama persis.
- `DataInitBloc._onStarted` (`data_initialization_bloc.dart:28-105`):
  guard `_isRunning`, emit `DataInitInProgress`, menjalankan stream dari
  `GetDataInitialization`, memetakan `completed/completedWithErrors → Success`,
  `failed → Failure`, status lain → `InProgress`. Timeout `kDataInitTimeout`.
- Artinya `DataInitializationRemoteDataSource.initialize()` berjalan identik di
  fresh login maupun pull-refresh. Inilah alasan dibutuhkan flag pembeda baru:
  hari ini tidak ada cara membedakan keduanya di lapisan data.

### 3.2 Urutan pipeline berat saat ini

`data_initialization_remote_data_source.dart:58-378`:

1. `yield scrapingProfile` + `_runStep('profile_scrape_1', scrapeProfile)` —
   `POST /student-profile`.
2. `yield scrapingProfile` + `_runStep('profile_scrape_2', scrapeProfile)` —
   pengulangan kedua untuk reliabilitas.
3. `yield gettingProfile` + `_runStep('profile_get', getProfile)` —
   `POST /student-profile/data`, dibungkus try/catch yang `rethrow` (wajib).
4. `yield fetchingPhoto` + `fetchPhoto` — `POST /student-profile/photo`
   (raw JPEG via `http.Client` langsung, bukan `ApiClient`), try/catch non-fatal
   → `photoEmpty` saat gagal/kosong.
5. Blok KRS (try/catch non-fatal → `krsEmpty`):
   `downloadingKrs` (download) → `extractingKrs` (extract) →
   `fetchingKrsData` (getKrsData → `POST /krs/data`, cache internal).
6. Blok KHS (try/catch non-fatal → `khsEmpty`):
   `fetchingKhsSemesters` (getSemesters → `POST /khs/semesters`, selalu fresh) →
   loop per semester: `downloadingKhs` → `extractingKhs` → `fetchingKhsData`
   (`POST /khs/data`, cache internal). Error per semester ditampung di
   `khsErrors`, lanjut ke semester berikut; jika ada error → `yield khsEmpty`.
7. Cache foto di akhir (`_avatarCache.saveAvatar` + `_avatarCubit.bindNpm`),
   lalu `yield completed`.

Semantik wajib vs opsional ini SUDAH berlaku di pull-refresh hari ini
(pelurusan atas dugaan user bahwa aturan itu "tidak ada di pull-refresh").

### 3.3 Manifestasi status di pull-refresh vs login

- `DataInitStatus`: `idle, authenticating, clearingCache, scrapingProfile,
  gettingProfile, fetchingPhoto, downloadingKrs, extractingKrs, fetchingKrsData,
  fetchingKhsSemesters, downloadingKhs, extractingKhs, fetchingKhsData,
  krsEmpty, khsEmpty, photoEmpty, completed, completedWithErrors, failed`.
- BLoC (`_onStarted:70-79`): hanya `completed/completedWithErrors → Success`
  dan `failed → Failure`; semua status lain (termasuk `krsEmpty/khsEmpty/
  photoEmpty`) → `DataInitInProgress`.
- `DataRefreshOverlay` (`isFreshLogin: false`): `Failure` → error view 3 detik
  lalu auto-close (`Timer 3s`, tanpa SnackBar). `Success` → refetch
  `JadwalBloc/HomeBloc/ProfileBloc`, lalu pop 500ms. Retry → `_dispatchPipeline`
  lagi. Close → pop + callback `onPipelineFailure` bila state terakhir Failure.
- `DataInitProgressView`: error view menampilkan chip step
  (`_humanReadableFailedStep` memetakan `failedStep` → label Indonesia via
  `dataInitStatusText`), pesan error, tombol Retry/Close. Auto-retry 15 detik
  (`kStepErrorAutoContinue`) hanya aktif bila `isFreshLogin: true` (login).
- Dampak untuk desain: user pull-refresh tidak pernah melihat error untuk
  kegagalan KRS/KHS/foto — hanya teks progres sesaat lalu Success dengan cache
  lama. Satu-satunya pemicu error view di pull-refresh adalah `profile_get`
  gagal. Cabang ringan harus menyalin semantik ini persis.

### 3.4 Jalur ringan yang sudah ada (tidak dipakai ulang)

`ProfileRemoteDataSource.refreshFromRemote()` sudah mengambil `krs/data` +
`khs/data` langsung, tetapi: (a) hanya dipakai `ProfileBloc` refresh (bukan
pipeline data-init), (b) tidak mencakup student-profile/photo/semesters,
(c) tidak ada throttle. Maka cabang ringan dibangun di dalam
`DataInitializationRemoteDataSource` sebagai cabang pipeline, bukan memanggil
`refreshFromRemote`, agar progress stream, status, dan error view tetap satu
alur.

## 4. Keputusan-Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Lokasi implementasi | FE-only throttling. BE tidak diubah. |
| 2 | Makna 2 RPM | 2x pull-refresh berat dalam rolling 60 detik; refresh ke-3+ = jalur ringan. |
| 3 | Sumber semester saat fallback | `/khs/semesters` tetap dipanggil, lalu `/khs/data` per semester tanpa download/extract. |
| 4 | Scrape profil saat throttled | Skip 2x `scrapeProfile`, langsung `getProfile`. |
| 5 | Pendekatan | A. Saklar throttle di pipeline (Event→UseCase→Repo→DataSource). B (guard per-endpoint) dan C (cek di overlay) ditolak. |
| 6 | Semantik failure cabang ringan | Pertahankan wajib-vs-opsional persis seperti jalur berat. |

Detail penolakan alternatif:

- **B. Guard per-endpoint di tiap datasource**: tiap method berat
  (`downloadKrs`, `extractKrs`, `downloadKhs`, `extractKhs`, `scrapeProfile`)
  punya TTL 60 detik sendiri dan melempar `ThrottledException` bila dipanggil
  dalam jendela. Ditolak karena: control-flow via exception mengotori pipeline,
  loop KHS per-semester butuh penanganan khusus per iterasi, aturan tersebar di
  5+ method sehingga audit "kapan jalur ringan aktif" sulit, dan testing butuh
  mensimulasikan exception di banyak titik.
- **C. Cek di overlay sebelum dispatch**: `DataRefreshOverlay` cek timestamp
  sebelum dispatch; bila throttled, dispatch event ringan berbeda atau langsung
  refetch BLoC dari cache. Ditolak karena: logika bisnis bocor ke lapisan UI,
  tombol Retry dan caller pipeline baru (bila kelak ada) bisa lolos dari aturan,
  dan progress stream ringan harus diduplikasi di luar pipeline.

## 5. Desain Rinci

### 5.1 Desain 1/5 — Penanda pull-refresh vs fresh login (DISETUJUI)

Tambah flag `isPullRefresh` (default `false`) berantai ke bawah:

```text
DataInitStarted(isPullRefresh) → DataInitBloc._onStarted
  → GetDataInitialization.call(isPullRefresh)
    → DataInitializationRepository.initialize(isPullRefresh)
      → DataInitializationRemoteDataSource.initialize(isPullRefresh)
```

Perubahan per file:

- `presentation/bloc/data_initialization_event.dart`: field
  `final bool isPullRefresh;` default `false` di constructor; sertakan di
  `==` dan `hashCode` (saat ini `hashCode = Object.hash(npm, password,
  forceRefresh)` → tambah `isPullRefresh`).
- `domain/usecases/get_data_initialization.dart`: param
  `bool isPullRefresh = false`, teruskan ke `repository.initialize`.
- `domain/repositories/data_initialization_repository.dart`: tambah param ke
  signature abstract `initialize`.
- `data/repositories/data_initialization_repository_impl.dart`: teruskan param.
- `presentation/widgets/data_refresh_overlay.dart::_dispatchPipeline`:
  kirim `isPullRefresh: true` (satu-satunya pengirim `true`; mencakup Retry
  karena Retry memanggil `_dispatchPipeline` yang sama).
- `LoginPage`: tidak diubah (default `false` = jalur berat selalu).

`forceRefresh` tidak diubah — tetap `true` di kedua jalur agar endpoint ringan
(`getProfile`, `getKrsData`, `getSemesters`, `getKhsData`, `fetchPhoto`) tetap
hit network, bukan baca Hive. Ini penting: jalur ringan adalah "langsung get",
bukan "pakai cache".

### 5.2 Desain 2/5 — Pelacak throttle 2 RPM (DISETUJUI)

File baru:
`lib/features/data_initialization/data/services/pull_refresh_throttle.dart`.

```dart
/// Melacak pull-refresh berat dalam rolling window 60 detik, per NPM.
///
/// - [shouldThrottle] true bila sudah ada >= 2 jalur berat dalam 60 detik terakhir.
/// - [recordHeavy] dipanggil saat jalur berat DIMULAI (gagal pun dihitung).
/// - In-memory saja; restart app = reset (wajar untuk jendela 60 detik).
/// - Jam via parameter opsional agar unit-test deterministik.
class PullRefreshThrottle {
  PullRefreshThrottle({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _heavyHits = {};

  static const window = Duration(seconds: 60);
  static const maxHeavyPerWindow = 2;

  bool shouldThrottle(String npm, [DateTime? now]) { ... }
  void recordHeavy(String npm, [DateTime? now]) { ... }
}
```

Spesifikasi perilaku:

- `shouldThrottle(npm, now)`: buang semua timestamp dengan
  `now.difference(t) > window`; return `true` jika sisa `>= maxHeavyPerWindow`.
- `recordHeavy(npm, now)`: prune dulu (agar list tidak tumbuh tanpa batas),
  lalu tambah `now`. Dipanggil tepat sebelum jalur berat dieksekusi di
  `initialize()` — bukan setelah sukses — karena backend tetap kena hit walau
  pipeline akhirnya gagal.
- Keyed per-NPM (`Map<npm, ...>`): akun A tidak memakan kuota akun B.
  Relevan karena cache app mendukung multi-student (per-NPM keying).
- In-memory (`Map`, bukan Hive/SharedPreferences): jendela hanya 60 detik,
  persistensi tidak memberi nilai dan menambah I/O. Reset saat restart
  diterima sebagai perilaku yang wajar dan didokumentasikan.
- Thread-safety: Dart single-threaded event loop; tidak perlu lock. Guard
  `_isRunning` di BLoC juga mencegah dua pipeline berjalan bersamaan.
- Registrasi DI: daftarkan singleton di `main.dart` lewat
  `Services.register<PullRefreshThrottle>(PullRefreshThrottle())`, dengan pola
  constructor-fallback (`param ?? Services.get<T>()`) seperti service lain agar
  bisa di-fake di test.

Titik keputusan di `initialize()`:

```text
if (isPullRefresh && throttle.shouldThrottle(npm)) {
  → cabang ringan (TANPA recordHeavy)
} else {
  throttle.recordHeavy(npm)   // hanya bila isPullRefresh; login tidak dicatat
  → jalur berat (kode yang ada sekarang, tidak diubah)
}
```

Catatan: `recordHeavy` hanya untuk pull-refresh berat. Jalur login
(`isPullRefresh == false`) tidak pernah cek maupun catat — login tidak
mengonsumsi kuota dan tidak terpengaruh kuota yang ada.

Contoh skenario (t = detik):

- t=0 pull-refresh → berat #1 (catat). t=20 pull-refresh → berat #2 (catat).
  t=40 pull-refresh → throttled (2 hit dalam 60 detik) → ringan.
  t=65 pull-refresh → hit t=0 kedaluwarsa, sisa 1 → berat #3 (catat).
- Retry yang ditekan user dalam jendela throttle ikut aturan yang sama
  (ringan), karena Retry mengirim `isPullRefresh: true`.

### 5.3 Desain 3/5 — Cabang ringan / fallback (DISETUJUI)

Struktur `initialize()` menjadi:

```dart
Stream<DataInitProgress> initialize({npm, password, forceRefresh, isPullRefresh}) async* {
  if (isPullRefresh && _throttle.shouldThrottle(npm)) {
    yield* _initializeLight(npm: npm, password: password);
    return;
  }
  if (isPullRefresh) _throttle.recordHeavy(npm);
  yield* _initializeHeavy(npm: npm, password: password, forceRefresh: forceRefresh);
}
```

`_initializeHeavy` adalah isi method saat ini (dipindah tanpa perubahan logika).
`_initializeLight` adalah cabang baru dengan urutan:

1. `yield gettingProfile` → `_runStep('profile_get', getProfile)` dalam
   try/catch yang `rethrow` (wajib — sama seperti jalur berat).
2. `yield fetchingPhoto` → `fetchPhoto` dalam try/catch non-fatal →
   `photoEmpty` (sama seperti jalur berat, termasuk kasus bytes kosong).
3. Blok KRS ringan (try/catch non-fatal → `krsEmpty`):
   `yield fetchingKrsData` → `_runStep('krs_data', getKrsData)`; bila
   `mataKuliah` kosong → `yield krsEmpty` (logika empty yang sama).
4. Blok KHS ringan (try/catch non-fatal → `khsEmpty`):
   `yield fetchingKhsSemesters` → `_runStep('khs_semesters', getSemesters)`;
   loop per semester langsung `yield fetchingKhsData(detail)` →
   `_runStep('khs_data_<semester>', getKhsData)` tanpa download/extract;
   error per semester ditampung ke `khsErrors`, lanjut; bila tak kosong →
   `yield khsEmpty`.
5. Cache foto di akhir (`saveAvatar` + `bindNpm`) bila ada — identik jalur berat.
6. `yield completed` — identik jalur berat.

Hal yang disengaja TIDAK dilakukan di cabang ringan:

- Tidak `yield scrapingProfile / downloadingKrs / extractingKrs / downloadingKhs /
  extractingKhs` — `DataInitProgressView` otomatis melompat karena ia me-render
  berdasarkan status yang di-emit. Tidak ada perubahan UI.
- Tidak memanggil `scrapeProfile / downloadKrs / extractKrs / downloadKhs /
  extractKhs` sama sekali (verifikasi via unit test: mock tidak pernah
  dipanggil).
- Semua `get/data` dipanggil dengan `forceRefresh: true` agar hit network.
- Step-step yang sama antara kedua cabang (`getProfile`, `fetchPhoto`,
  blok KRS-data, blok KHS-per-semester, cache foto akhir) diwajibkan memakai
  helper private bersama agar tidak ada duplikasi logika (mis.
  `_fetchProfileOrThrow`, `_fetchPhotoBestEffort`, `_fetchKrsBestEffort`,
  `_fetchKhsBestEffort`). BLoC, overlay, dan status text tidak diubah.

Daftar endpoint yang dipanggil cabang ringan (pemetaan ke keputusan user):

| Step | Method | Endpoint BE |
|------|--------|-------------|
| getProfile | `_profileDataSource.getProfile` | `POST /api/v1/lms/student-profile/data` |
| fetchPhoto | `_photoService.fetchPhoto` | `POST /api/v1/lms/student-profile/photo` |
| getKrsData | `_getKrs(...)` | `POST /api/v1/lms/krs/data` |
| getSemesters | `_getKhs.getSemesters` | `POST /api/v1/lms/khs/semesters` |
| getKhsData × N | `_getKhs(...)` per semester | `POST /api/v1/lms/khs/data` |

Yang di-skip: `POST /student-profile` (2x), `POST /krs`,
`POST /krs/extract`, `POST /khs` (×N semester), `POST /khs/extract` (×N).

### 5.4 Desain 4/5 — Error handling & edge cases (DISETUJUI, setelah pelurusan)

Hasil eksplorasi pendalaman (bagian yang user minta dieksplorasi ulang):

- Pipeline `initialize()` dipakai bersama login dan pull-refresh (bukti:
  `login_page.dart:72-78` dan `data_refresh_overlay.dart:143-150` dispatch
  `DataInitStarted` yang sama). Jadi aturan wajib-vs-opsional ADA di
  pull-refresh hari ini; dugaan "tidak ada" keliru — yang benar adalah
  manifestasinya berbeda (error view 3 detik vs tombol Retry/Cancel, dan status
  empty hanya jadi teks progres sesaat sebelum Success).
- `krsEmpty/khsEmpty/photoEmpty` bukan failure: BLoC memetakannya ke
  `DataInitInProgress`, sehingga overlay lanjut ke `Success` dengan cache lama
  + refetch `JadwalBloc/HomeBloc/ProfileBloc`.

Aturan cabang ringan (menyalin jalur berat apa adanya):

- `getProfile` gagal → `rethrow` → BLoC emit `DataInitFailure(message,
  failedStep: 'profile_get')` → overlay tampil error view 3 detik lalu tutup.
  Ini satu-satunya pemicu error view di pull-refresh — dipertahankan agar
  kredensial berubah/expiry tetap ketahuan user, bukan diam-diam Success.
- `getKrsData` gagal → `yield krsEmpty`, lanjut (non-fatal).
- `getSemesters` gagal → `yield khsEmpty` (non-fatal, seluruh blok KHS dilewati).
- `getKhsData` per semester gagal → tampung pesan, lanjut semester berikut;
  bila ada error → `yield khsEmpty` di akhir blok (non-fatal).
- `fetchPhoto` gagal/kosong → `yield photoEmpty` (non-fatal).
- `failedStep` memakai nama lama (`profile_get`, `krs_data`, `khs_semesters`,
  `khs_data_<detail>`) agar chip step di error view (`_humanReadableFailedStep`
  → `dataInitStatusText`) tidak berubah.
- `AuthException` (401) dari endpoint ringan manapun tetap merethrow (bukan
  ditelan sebagai empty) → `ApiClient.onAuthError` → `performFullLogout`
  global. Berlaku di kedua jalur.
- Retry overlay tetap `isPullRefresh: true` — tidak ada jalur khusus retry;
  retry dalam jendela throttle = ringan lagi (konsisten, tidak menambah beban).
- Timeout pipeline (`kDataInitTimeout = AppDurations.dataInitPipeline`) tidak
  berubah; cabang ringan (5 request ringan vs 8+ request berat) selesai lebih
  cepat sehingga risiko timeout justru turun.
- Throttle keyed per-NPM; kredensial kosong (tidak ada di cache) → perilaku
  `triggerRefresh` saat ini (abort diam-diam) tidak diubah.
- Tidak ada penanda visual "mode hemat / throttled" di UI (diputuskan implisit:
  overlay menampilkan step yang dilewati sebagai lompatan progres; tidak ada
  teks khusus agar tidak membingungkan user).

### 5.5 Desain 5/5 — Testing (DISETUJUI)

Unit test baru (hand-written fakes, tanpa mockito/mocktail, sesuai konvensi repo):

1. `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`:
   - Hit ke-1 & ke-2 dalam 60 detik → `shouldThrottle == false`.
   - Hit ke-3 dalam 60 detik → `true`.
   - Setelah timestamp tertua kedaluwarsa (>60 detik) → `false` lagi (prune).
   - NPM berbeda isolated (kuota terpisah).
   - Jam di-inject (`fakeNow`), tanpa `Future.delayed` (deterministik, cepat).
2. `test/features/data_initialization/data/datasources/..._light_branch_test.dart`
   (atau perluasan file test datasource yang ada):
   - Fake `PullRefreshThrottle` yang return `true` → verifikasi
     `scrapeProfile/downloadKrs/extractKrs/downloadKhs/extractKhs` TIDAK PERNAH
     dipanggil; `getProfile/getKrsData/getSemesters/getKhsData/fetchPhoto`
     dipanggil sesuai urutan; stream meng-emit status ringan berurutan lalu
     `completed`.
   - Fake throttle return `false` + `isPullRefresh: true` → urutan berat sama
     seperti hari ini + `recordHeavy` dipanggil sekali.
   - `isPullRefresh: false` (login) → throttle tidak pernah dicek
     (`shouldThrottle` tidak dipanggil), jalur berat jalan.
   - Failure: `getProfile` throw → stream berakhir Failure dengan
     `failedStep: 'profile_get'`; `getKrsData` throw → `krsEmpty` lalu lanjut;
     `getSemesters` throw → `khsEmpty`; satu semester `getKhsData` throw →
     semester lain tetap diproses.
3. Pass-through `isPullRefresh`:
   - Default `false` di `DataInitStarted`/usecase/repo (caller lama otomatis
     jalur berat — kompatibilitas sumber).
   - `DataRefreshOverlay._dispatchPipeline` diverifikasi (widget test yang ada
     diperluas atau test baru) mengirim `isPullRefresh: true`.
4. Gate: `flutter analyze` bersih; `flutter test` hijau — fokus pada
   `test/features/data_initialization/**`, `test/features/auth/presentation/pages/login_page_test.dart`,
   dan `test/router/**`. Tanpa Patrol E2E (logika ini murni unit-testable;
   E2E login 50 detik tidak memberi nilai tambah untuk throttle).

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
                → throttle.shouldThrottle(npm)?
                    YA  → _initializeLight  (5 endpoint ringan, skip berat)
                    TIDAK → recordHeavy + _initializeHeavy (jalur lama utuh)
          → stream DataInitProgress → BLoC state → overlay/view
            → Success: refetch Jadwal/Home/Profile + pop
            → Failure: error view 3s + auto-close
```

Komponen baru hanya satu: `PullRefreshThrottle` (data-layer service, tanpa
dependensi framework selain `DateTime`). Selebihnya adalah penambahan parameter
dan cabang di file yang sudah ada — tidak ada file/lapis arsitektur baru, tidak
ada perubahan dependency rule (`presentation → domain → data` tetap).

## 7. Estimasi File yang Disentuh (untuk writing-plans)

Baru:

- `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
- `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`
- Test cabang pipeline (file baru atau perluasan yang ada)

Ubah:

- `lib/features/data_initialization/presentation/bloc/data_initialization_event.dart`
  (`isPullRefresh` + `==`/`hashCode`)
- `lib/features/data_initialization/domain/usecases/get_data_initialization.dart`
- `lib/features/data_initialization/domain/repositories/data_initialization_repository.dart`
- `lib/features/data_initialization/data/repositories/data_initialization_repository_impl.dart`
- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`
  (cabang `_initializeLight`, ekstraksi `_initializeHeavy`, wiring throttle,
  helper bersama)
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart`
  (`isPullRefresh: true`)
- `lib/main.dart` (registrasi `PullRefreshThrottle`; teruskan ke
  `DataInitializationRemoteDataSource` mengikuti pola DI yang ada)
- Perluasan `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`
  bila perlu (verifikasi flag)

Tidak disentuh: `LoginPage`, BLoC, `DataInitProgressView`, `dataInitStatusText`,
`ApiClient`, `PhotoService`, `KhsPdfService`, cache services, router, tema.

## 8. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Lupa meneruskan `isPullRefresh` di satu lapis → pull-refresh selalu berat | Default `false` aman (berat); test pass-through per lapis; compiler menandai signature yang belum update |
| Helper bersama mengubah perilaku jalur berat | `_initializeHeavy` = pindahan kode verbatim; diff direview; test urutan berat yang ada tetap hijau |
| `recordHeavy` dicatat tapi pipeline dibatalkan sebelum request | Diterima: kuota dihitung saat niat berat; window hanya 60 detik |
| User bingung kenapa refresh ke-3 cepat tapi data sama | Perilaku yang diinginkan (hemat backend); tanpa teks khusus sesuai keputusan |
| Multi-akun satu device | Throttle per-NPM, sudah di desain |

## 9. Pertanyaan Terbuka

Tidak ada. Semua keputusan (FE-only, semantik 2 RPM rolling-60-detik per-NPM,
semesters tetap dipanggil, skip scrape, pendekatan A, semantik failure,
in-memory, tanpa indikator UI) disetujui di sesi brainstorming.
