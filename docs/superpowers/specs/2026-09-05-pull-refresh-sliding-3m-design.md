# Desain: Sliding Debounce 3 Menit — Setiap Pull Mereset Window

- Tanggal: 2026-09-05
- Lokasi: `docs/superpowers/specs/2026-09-05-pull-refresh-sliding-3m-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go (BE) tidak diubah.
- Status: Disetujui per seksi 1/6 s/d 6/6 di sesi brainstorming (revisi window 5m → 3m, pendekatan P2).
- Supersedes: `2026-09-05-pull-refresh-debounce-design.md` (debounce 2 menit, fixed window, hanya heavy yang `recordHeavy`). Spec throttle lama `2026-09-04-pull-refresh-throttle-design.md` tetap jadi referensi pipeline heavy/light & helper — bagian yang tidak berubah tidak ditulis ulang.

## 1. Latar Belakang & Masalah

Debounce saat ini (`2026-09-05-pull-refresh-debounce-design.md`):
- `PullRefreshDebounce.window = 2 menit` (fixed window).
- `shouldUseLight(npm)` true bila `now - lastHeavyHit[npm] < 2m`.
- `recordHeavy(npm)` hanya dipanggil di cabang HEAVY (`isPullRefresh && !shouldUseLight`). Cabang LIGHT tidak menyentuh timestamp.
- Akibat: jangkar window tetap di heavy terakhir; setiap 2 menit pasti dapat heavy lagi, seberapa sering pun pull. Starvation heavy tidak mungkin.

Permintaan revisi:
- Naikkan window **2m → 5m**, lalu direvisi menjadi **3m** karena sliding (reset tiap pull) membuat 5m terlalu lama — heavy bisa starvation jika user pull tiap <5m selamanya.
- **Reset timer menjadi 0 / kembali ke awal setiap request sebelum debounce habis**, terlepas dari hasil (A1: sukses/gagal/offline/timeout tetap reset). Perlu window **sliding**, bukan fixed.
- Generalisasi nama `recordHeavy → touch` (P2) agar semantik netral: setiap pull menggeser jangkar, bukan hanya heavy.

Keputusan final sesi: **P2, sliding 3 menit, check-then-touch, A1**.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Window debounce **2m → 3m** (`Duration(minutes: 3)`).
2. **Sliding window**: setiap pull-refresh (heavy maupun light) menggeser jangkar window ke `now` (reset ke 0). Heavy hanya terjadi jika sudah **≥ 3m tanpa pull sama sekali**.
3. Reset terjadi **di awal** `DataInitializationRemoteDataSource.initialize()` **sebelum** outcome diketahui (A1) — offline/timeout/Auth gagal pun tetap geser.
4. Rename `recordHeavy → touch` (API netral); kedua cabang `isPullRefresh` sama-sama `touch()`; fresh login (`isPullRefresh:false`) tidak menyentuh debounce sama sekali.
5. Ordering **check-then-touch** (cek `shouldUseLight` terhadap jangkar LAMA, baru `touch()` ke `now`) — jika dibalik, setiap pull jadi light selamanya (bug).
6. Per-NPM isolation, in-memory `Map<String, DateTime>` tetap; restart app = map kosong = next pull heavy.
7. Tidak ada perubahan backend, cache Hive, overlay, BLoC, atau pipeline step.

### 2.2 Non-Tujuan (Non-Goals)

- Tidak persist debounce ke Hive/SharedPreferences.
- Tidak pakai `Timer` per NPM (P3 ditolak) — tetap `Map + Difference`.
- Tidak ada `maxLightStreak` / `maxAge` / `forced heavy` — starvation diterima; future tweak jika perlu.
- Tidak ubah `DataRefreshOverlay` (auto-close 3s / 500ms tetap), `DataInitBloc` fail-fast/timeout, helper `_initializeHeavy/_initializeLight`, atau `DataInitProgressView` login flow.
- Tidak ubah `/khs/file` (`KhsPdfService`) atau endpoint manapun.

## 3. Konteks Kode Saat Ini (Hasil Eksplorasi MCP)

### 3.1 File debounce saat ini

- `lib/features/data_initialization/data/services/pull_refresh_debounce.dart:22` → `window = Duration(minutes: 2)`.
- `shouldUseLight(npm, [now])` (`:29`) — `last==null → false`, else `t.difference(last) < window`.
- `recordHeavy(npm, [now])` (`:41`) — `_lastHeavyHit[npm] = now`.
- Komentar file sudah menyebut "in-memory Map, clock injectable".

### 3.2 Dispatcher pipeline saat ini

- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart:74-102`:
  ```dart
  if (isPullRefresh && _debounce.shouldUseLight(npm)) {
    yield* _initializeLight(...); return;
  }
  if (isPullRefresh) _debounce.recordHeavy(npm);
  yield* _initializeHeavy(...);
  ```
  Hanya cabang HEAVY yang `recordHeavy`.

### 3.3 Jalur heavy vs light (tidak berubah)

- `_initializeHeavy` — 8 step penuh: scrapeProfile 2x → gettingProfile (wajib rethrow) → fetchingPhoto (opsional) → KRS (download→extract→fetchingKrsData, non-fatal) → KHS (fetchingKhsSemesters + per-semester download→extract→fetchingKhsData, non-fatal) → cache foto → completed.
- `_initializeLight` — skip scrape/download/extract, langsung `gettingProfile → fetchingPhoto → fetchingKrsData → fetchingKhsSemesters + fetchingKhsData per semester → cache foto → completed`. `forceRefresh:true` di semua get.

### 3.4 Alur pemicu

- `DataRefreshOverlay.triggerRefresh` → `loadCredentials` → `await show(DataRefreshOverlay)` → `addPostFrameCallback` → `DataInitReset + DataInitStarted(isPullRefresh:true, forceRefresh:true)` → `DataInitBloc._onStarted` (guard `_isRunning`, `connectivity.isOnline` fail-fast, `kDataInitTimeout`) → `GetDataInitialization` → `DataInitializationRemoteDataSource.initialize(isPullRefresh:true)`.
- `LoginPage` → `DataInitStarted(isPullRefresh:false)` — tidak pernah lewat debounce.

## 4. Keputusan-Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Durasi window | **3 menit** (`Duration(minutes: 3)`) — revisi dari 5m. |
| 2 | Jenis window | **Sliding** — setiap pull (heavy & light) geser jangkar ke `now`. |
| 3 | Kapan reset | **Di awal** `initialize()` sebelum branching (A1) — sukses/gagal tetap reset. |
| 4 | Ordering | **check-then-touch**: `useLight = shouldUseLight(npm)` dulu, baru `touch(npm)` — bukan sebaliknya. |
| 5 | Nama API | `recordHeavy` → **`touch`** (P2, netral). |
| 6 | Fresh login | Tidak pernah `touch`/`shouldUseLight` — selalu heavy. |
| 7 | Pendekatan | **P2** (window 3m + rename touch + touch di kedua cabang pull, check-then-touch). P1 ditolak karena misleading, P3 ditolak karena Timer overhead. |
| 8 | Scope | Tidak persist, tidak Timer, tidak maxLightStreak di scope ini. |

## 5. Desain Rinci

### 5.1 Desain 1/6 — Ringkasan & Tujuan (DISETUJUI)

Sliding debounce 3 menit, setiap pull mereset window ke 0 (geser jangkar ke `now`), A1. Tujuan: hemat server 2.5× vs 2m tapi tetap jamin heavy setelah idle 3m tanpa pull. Pull-refresh vs login tetap dibedakan via `isPullRefresh`.

### 5.2 Desain 2/6 — Arsitektur & Dampak File (DISETUJUI, window direvisi 5→3)

**Berubah (2 file sumber + 1 test):**

| File | Perubahan |
|---|---|
| `lib/features/data_initialization/data/services/pull_refresh_debounce.dart` | `window` `2 → 3` menit; `recordHeavy(...)` → `touch(...)` + update doc comment "sliding 3 menit, setiap pull touch di awal (A1)". Opsional pertahankan `recordHeavy` sebagai alias deprecated → `touch` untuk kompatibilitas sementara, tapi scope P2 = rename bersih (hapus alias). |
| `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart:74-102` | Dispatcher `initialize()` diubah ke pola **check-then-touch** (lihat 5.3). Kedua cabang `isPullRefresh` sama-sama `touch()` di awal branching; `isPullRefresh==false` tidak menyentuh debounce. |
| `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart` | `window` assertion `5 → 3` menit; semua `recordHeavy` → `touch`; boundary `299s/300s → 179s/180s`; tambah kasus sliding light juga reset (lihat 5.5). |

**Tidak berubah:** `DataInitBloc` (`presentation/bloc/data_initialization_bloc.dart`), `GetDataInitialization`, `DataInitializationRepositoryImpl`, `DataRefreshOverlay`, `app_router.dart` ShellRoute, `Home/Jadwal/Profile` RefreshIndicator — meneruskan `isPullRefresh:true` apa adanya.

**DI:** `PullRefreshDebounce` singleton di `Services` (`lib/main.dart`) — registrasi tidak berubah selain type name.

### 5.3 Desain 3/6 — Data Flow / Urutan Eksekusi (DISETUJUI — ordering check-then-touch)

**Pola baru di `DataInitializationRemoteDataSource.initialize()`:**

```dart
Stream<DataInitProgress> initialize({
  required String npm,
  required String password,
  bool forceRefresh = true,
  bool isPullRefresh = false,
}) async* {
  debugPrint('[DATA_INIT_DS] initialize() START — npm=$npm, forceRefresh=$forceRefresh, isPullRefresh=$isPullRefresh');

  if (isPullRefresh) {
    final useLight = _debounce.shouldUseLight(npm); // cek terhadap jangkar LAMA
    _debounce.touch(npm);                             // geser jangkar ke now (A1, bahkan jika nanti gagal)
    if (useLight) {
      debugPrint('[DATA_INIT_DS] initialize() → LIGHT branch (debounced, sliding 3m)');
      yield* _initializeLight(npm: npm, password: password);
      return;
    }
    debugPrint('[DATA_INIT_DS] initialize() → HEAVY branch (pull-refresh, sliding 3m)');
  } else {
    debugPrint('[DATA_INIT_DS] initialize() → HEAVY branch (fresh login)');
  }
  yield* _initializeHeavy(npm: npm, password: password, forceRefresh: forceRefresh);
}
```

**Mengapa check-then-touch wajib:**

- Jika `touch` dulu baru `shouldUseLight`, maka setiap pull setelah heavy pertama akan tampak `now - now == 0 < 3m → light selamanya`, **tidak pernah** heavy lagi — bug starvation permanen.
- Check-then-touch menjamin: heavy berikutnya hanya jika `now - lastTouch >= 3m`, di mana `lastTouch` adalah waktu **pull terakhir** (heavy atau light).

**Timeline sliding 3m (contoh deterministik):**

```text
T0        pull → shouldUseLight? null → false → HEAVY → touch T0
T0+30s    pull → 30s < 180s → LIGHT → touch T0+30s
T0+60s    pull → 30s < 180s (60-30) → LIGHT → touch T0+60s
T0+200s   pull → 140s < 180s (200-60) → LIGHT → touch T0+200s
T0+380s   pull → 180s >= 180s (380-200) → HEAVY → touch T0+380s  (idle ≥3m baru heavy)
T0+381s   pull → 1s < 180s → LIGHT → touch T0+381s
```

Alur lengkap tetap:
```
RefreshIndicator.onRefresh → DataRefreshOverlay.triggerRefresh → await show → addPostFrameCallback → DataInitReset+DataInitStarted(isPullRefresh:true)
  → DataInitBloc._onStarted (isOnline fail-fast, _isRunning guard, timeout AppDurations.dataInitPipeline)
    → GetDataInitialization → DataInitializationRemoteDataSource.initialize (check-then-touch) → _initializeLight atau _initializeHeavy
      → stream DataInitProgress → BLoC state → overlay/view → Success pop 500ms / Failure auto-close 3s
```

### 5.4 Desain 4/6 — Error Handling & Edge Cases (DISETUJUI)

**Semantik A1 — reset bahkan jika gagal:**
- `touch()` sebelum pipeline, jadi `DataInitFailure` (offline `no_connection`, `TimeoutException`, `DataInitStepException`, `AuthException`/401) tidak memengaruhi jangkar. Deterministik, tanpa cabang sukses/gagal.
- Konsekuensi yang diterima: spam pull saat offline (3× dalam 1 menit, semua fail) tetap geser jangkar → begitu online, tetap tunggu 3m dari pull terakhir baru heavy. Sesuai A1 (hemat server > cepat fresh). Mitigasi future (di luar scope): `maxLightStreak`/`maxAge`.

**Invariant:**
- `isPullRefresh==false` (LoginPage) tidak pernah `touch`/`shouldUseLight` — selalu heavy penuh.
- Per-NPM isolation (`Map<String, DateTime>` keyed by npm) — akun A tidak memengaruhi B.
- In-memory only — restart app = map kosong = next pull heavy (wajar untuk 3m).
- `DataRefreshOverlay` tidak diubah — failure tetap auto-close 3s tanpa tombol, login `isFreshLogin:true` tetap Retry/Cancel + auto-retry `kStepErrorAutoContinue`.

### 5.5 Desain 5/6 — Testing (DISETUJUI)

**Unit — `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`:**
- `window` assertion `Duration(minutes: 3)`.
- Semua `recordHeavy` → `touch`; reuse test "hit pertama → false", "dalam 180s → true", "boundary 179s true / 180s false", "recordHeavy kedua reset" → ganti angka window.
- **Tambahan baru** — sliding light juga reset:
  ```dart
  // T0 heavy → T0+30s light (touch T0+30s) → cek T0+60s harus masih light karena jangkar sudah di T0+30s (30s < 3m)
  // Bandingkan fixed lama yang jangkar tetap di T0.
  ```

**Datasource — `test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart`:**
- Tambah kasus "pull kedua dalam 3m tetap light dan menggeser jangkar" — verifikasi `shouldUseLight` panggilan kedua masih `true` setelah light pertama (karena sudah `touch`).

**Overlay/BLoC:**
- Tidak perlu test baru; existing `DataRefreshOverlay` 3s auto-close + `DataInitBloc` fail-fast/timeout tetap.

**Acceptance:**
- `flutter test test/features/data_initialization/data/services/pull_refresh_debounce_test.dart` hijau.
- `flutter analyze` 0 error.
- Log `touch` tampak untuk setiap `isPullRefresh:true` (heavy & light), tidak untuk fresh login.

### 5.6 Desain 6/6 — Risiko, Konsekuensi & Tindak Lanjut (DISETUJUI, window 3m)

**Risiko utama — starvation heavy:**
- Spam pull tiap <3m selamanya light → scrape/download KRS/KHS tidak pernah jalan, data basi. Diterima sebagai trade-off hemat server. Dengan 3m (bukan 5m) risiko lebih ringan.

**Future tweak (di luar scope ini, jika starvation jadi masalah):**
- `maxLightStreak` (tiap N light paksa heavy) atau `maxAge` (paksa heavy jika jangkar >24 jam). Tidak dikerjakan sekarang.

**Scope tidak disentuh (YAGNI):** persist Hive, Timer per NPM, debounce UI, overlay timing, timeout pipeline.

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
                → if isPullRefresh: useLight = shouldUseLight(npm) // cek jangkar LAMA
                                 touch(npm) // geser ke now (A1)
                                 if useLight → _initializeLight (5 endpoint ringan)
                                 else        → _initializeHeavy (8 step berat)
                  else (login): _initializeHeavy tanpa cek/touch
          → stream DataInitProgress → BLoC state → overlay/view
            → Success: refetch Jadwal/Home/Profile + pop 500ms
            → Failure: error view (tanpa tombol pull-refresh) + auto-close 3s

Login (LoginPage)
  → DataInitProgressView(isFreshLogin: true) (di luar DataRefreshOverlay)
    → DataInitStarted(isPullRefresh: false, forceRefresh: true)
      → _initializeHeavy tanpa cek/touch debounce → Failure: Retry/Cancel + auto-retry 15s
```

Komponen BERUBAH: `pull_refresh_debounce.dart` (window 3m + touch), `data_initialization_remote_data_source.dart` (check-then-touch dispatcher). Komponen DIHAPUS: tidak ada (hanya rename method). Tidak disentuh: BLoC, `DataInitProgressView`, `dataInitStatusText`, `ApiClient`, `PhotoService`, cache services, router, tema, event/usecase/repo.

## 7. Estimasi File yang Disentuh (untuk writing-plans)

Baru/diubah:

- `lib/features/data_initialization/data/services/pull_refresh_debounce.dart` (window 3m + recordHeavy → touch)
- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart` (check-then-touch dispatcher)
- `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart` (window 3m + touch + sliding-light-reset case)

Tidak disentuh: `lib/main.dart` registrasi type (hanya rename type jika mengikuti P2), `LoginPage`, BLoC, overlay, helpers, cache, router, tema, event/usecase/repo (flag `isPullRefresh` sudah ada).

Hapus: tidak ada file hapus (hanya rename method).

## 8. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Salah ordering (touch sebelum check → light selamanya) | Spec eksplisit check-then-touch; test sliding-light-reset. |
| Salah boundary (>= vs >) | Spec eksplisit `< 3m` light, `>= 3m` heavy; test 179s/180s. |
| Pull pertama keliru light | `last==null → false` (heavy); test eksplisit. |
| Login tidak sengaja kena debounce | `isPullRefresh:false` skip touch/check; test login path. |
| Starvation heavy karena sliding | Diterima; mitigasi future maxLightStreak/maxAge di luar scope. |
| Multi-akun | Per-NPM isolation; test isolated. |

## 9. Pertanyaan Terbuka

Tidak ada. Semua keputusan (sliding 3m, reset tiap pull di awal A1, check-then-touch, rename touch P2, per-NPM, in-memory) disetujui. Window final 3 menit (revisi dari 5m).
