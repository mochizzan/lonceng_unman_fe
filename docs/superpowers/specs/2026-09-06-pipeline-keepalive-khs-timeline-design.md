# Pipeline Keep-Alive + KHS Timeline Hybrid — Design Spec

**Date:** 2026-09-06
**Status:** Approved (brainstorming §1–§6 OK)
**Scope:** Fresh-login overlay + pull-refresh heavy/light — surgical, view-side accumulator

## 1) Tujuan & Scope

Menyatukan UX pipeline data-init di dua permukaan menjadi satu tampilan konsisten:

- **Fresh login** — `LoginPage → DataInitProgressView(isFreshLogin: true)` (sekarang 1 baris status + spinner).
- **Pull refresh** — `HomePage → DataRefreshOverlay(showGeneralDialog) → DataInitProgressView(isFreshLogin: false)` (barrier non-dismissible).

Target:
- Flat list untuk **Profile → Foto → KRS** (tetap 1 baris `dataInitStatusText()` seperti sekarang).
- **Timeline vertikal KHS per `tahunAjaran + semester`** di bawahnya, tiap semester punya sub-step `DOWNLOAD → EXTRACT → GET → SELESAI/ERROR` dengan warna per sub-step dan warna baris induk = terburuk.
- **Jalur ringan** (debounced pull 3m, `_initializeLight` skip `download/extract`) → KHS hanya `GET` aktif, `DOWNLOAD/EXTRACT` tampil badge `Dilewati` abu.
- **Keep alive** selama pipeline berjalan, ikat ke `DataInitBloc.isRunning` (bukan widget lifecycle), auto-release di `completed/failed/timeout/dispose`.
- Tidak ubah urutan/nama step di `DataInitializationRemoteDataSource`, tidak ubah `DataInitStatus` enum, tidak ubah `PullRefreshDebounce` (sliding 3m check-then-touch A1).

Non-goals: ubah endpoint, ubah debounce window, redesign auth, global keep-alive toggle di Settings.

## 2) Arsitektur & Komponen

```
LoginPage  ─┐
            ├─► DataInitBloc (unchanged: isRunning, Stream<DataInitProgress>)
HomePage ───┤         │ BlocListener<DataInitBloc>
            │         ├──► WakelockController (baru, ikat ke isRunning)
            │         └──► DataInitProgressView (diperluas)
                              ├── FlatStepsView (existing, tetap)
                              └── KhsTimelineView (baru, view-side accumulator)
DataRefreshOverlay (tipis: barrier + showGeneralDialog, dispatch via _dispatchPipeline)
AppRouter ShellRoute BlocListener<DataInitBloc> (tetap: refresh Home/Jadwal/Profile on success)
```

### Sentuh / tidak

- **Tidak ubah:** `DataInitBloc`, `DataInitStatus`/`DataInitProgress`/`DataInitStepOutcome`, `DataInitializationRemoteDataSource` (heavy/light), `PullRefreshDebounce`, `AppRouter` ShellRoute listener, `dataInitStatusText`, `DataInitStepOutcome` logging (tetap jalan).
- **Baru:**
  - `lib/features/data_initialization/presentation/widgets/khs_timeline_view.dart` — `KhsTimelineView` stateless + model lokal `KhsSemesterTimeline` + `KhsSemesterSubStepStatus { idle, progress, success, error, skipped }`.
  - `lib/features/data_initialization/presentation/widgets/wakelock_controller.dart` — `WakelockController` (wrapper `wakelock_plus`, enable/disable + try/catch `PlatformException` + debugPrint). Alternatif: inline `WakelockPlus.enable/disable` di listener.
- **Diperluas:**
  - `lib/features/data_initialization/presentation/widgets/data_init_progress_view.dart` — tambah `BlocListener` accumulator `Map<String, KhsSemesterTimeline> _khsMap` (key `"$tahunAjaran|$semester"`), clear di `DataInitReset`/`DataInitIdle`/`dispose`, render flat di atas + `KhsTimelineView` scrollable di bawah, cancel timer.
  - `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` — constraint tinggi timeline + delay 1.5s saat `_khsMap.length > 1` sebelum `pop` (lihat §5).

### Dependency

- **Baru:** `wakelock_plus: ^1.3.x` di `pubspec.yaml`. `WAKE_LOCK` permission sudah ada di `android/app/src/main/AndroidManifest.xml`.
- Tidak perlu izin baru, tidak ubah `permission_handler` flow.

## 3) Data Flow & Status Mapping

### Sumber

`DataInitBloc` emit `DataInitInProgress(status, detail?)` — `detail = "$tahunAjaran $semester"` hanya untuk 3 status KHS: `downloadingKhs`, `extractingKhs`, `fetchingKhsData`. Status lain (`scrapingProfile`, `gettingProfile`, `fetchingPhoto`, `downloadingKrs`, `extractingKrs`, `fetchingKrsData`, `fetchingKhsSemesters`, `krsEmpty/khsEmpty/photoEmpty`, `completed/failed`) tidak punya `detail`.

### Akumulasi (view-side, pilihan B)

```dart
// di _DataInitProgressViewState
final Map<String, KhsSemesterTimeline> _khsMap = {}; // ordered (LinkedHashMap) — urut insert sesuai pipeline
// KhsSemesterTimeline { String tahunAjaran, semester, label; KhsSemesterSubStepStatus download, extract, fetch; }

/// Parse `detail` "$tahunAjaran $semester" (contoh "2022/2023 Ganjil").
/// Tahun ajaran mengandung '/', semester tidak mengandung spasi — split di spasi TERAKHIR.
/// Return (tahunAjaran, semester) atau null jika detail null/kosong.
(String tahunAjaran, String semester)? parseKhsDetail(String? detail) {
  if (detail == null || detail.trim().isEmpty) return null;
  final idx = detail.lastIndexOf(' ');
  if (idx <= 0) return null;
  return (detail.substring(0, idx), detail.substring(idx + 1));
}

void _accumulate(DataInitInProgress s) {
  if (s.detail == null) return;
  final parsed = parseKhsDetail(s.detail); if (parsed == null) return;
  final key = '${parsed.$1}|${parsed.$2}';
  // switch s.status:
  //   downloadingKhs → download = progress
  //   extractingKhs  → download = success (implisit selesai), extract = progress
  //   fetchingKhsData → extract = success (implisit), fetch = progress
  // On next semester's downloadingKhs, previous semester fetch: jika masih progress → auto success (implisit selesai).
  // On DataInitSuccess/completed → semua entry yang masih progress → finalize jadi success.
  // On global khsEmpty (tanpa detail) → tidak ubah map; banner konteks di §5 yang handle.
}
```

- Per-semester `catch (e)` di `DataInitializationRemoteDataSource` loop tidak emit `failed` spesifik — entry tetap di `khsErrors: List<String>` dan global `khsEmpty` di-yield. Di view: semester yang `download/extract/fetch` pernah `catch` → `fetch = error` (atau `download/extract` sesuai step yang throw) — derive dari urutan: jika `downloadingKhs` throw sebelum `extractingKhs`, `download=error, extract=idle, fetch=idle`.
- Global `khsEmpty` / `DataInitFailure(no_connection/timeout)` bukan per-semester — tampil sebagai banner error existing di atas timeline (timeline tetap render sebagai konteks, tidak di-hide).
- **Light path:** `_initializeLight` hanya yield `fetchingKhsData(detail)` per semester; tidak pernah yield `downloadingKhs/extractingKhs`. Di view, fakta `download==idle && extract==idle && fetch∈{progress,success,error}` → render `DOWNLOAD/EXTRACT` sebagai chip `Dilewati` abu (`cs.outlineVariant`, `skipped`), hanya `GET` yang punya progress/success/error.

### Derived warna per sub-step & per semester

```
sub-step: idle/skipped → outlineVariant (abu)
          progress     → primary + pulsing dot (existing pulsing_dot pattern)
          success      → success / onSuccess (AppColors.success)
          error        → error / errorContainer
semester row overall = max(error, progress, success, idle/skipped) by severity
```

Gunakan token existing saja (`cs.primary`, `cs.error`, `cs.errorContainer`, `cs.outlineVariant`, `AppColors.success`/`successContainer` jika ada) — tidak nambah hex baru. Tidak tambah `Color` literal.

### Reset

- `BlocListener` clear `_khsMap` saat `state is DataInitIdle` (hasil dari `DataInitReset` event — `LoginPage` emit `DataInitReset` sebelum `DataInitStarted`; bloc yield `DataInitIdle`) atau saat `state is DataInitInProgress && status==scrapingProfile` untuk fresh start pipeline baru.
- `dispose` → `_khsMap.clear()`, cancel `_autoContinueTimer` dan scroll controller jika ada, `WakelockController.disable()` safety (sekali, idempotent via `_held`).

## 4) Keep Alive

### Trigger

- **Enable:** transisi `!isRunning → isRunning` — status pertama `DataInitStatus.scrapingProfile` diamati di `BlocListener<DataInitBloc>` (di `MainShellScaffold` atau di `DataInitProgressView`). Guard `if (state is DataInitInProgress && state.status == DataInitStatus.scrapingProfile && !_wakelockHeld)`.
  - Implementasi paling aman: listener di `DataInitProgressView` + juga di `MainShellScaffold`/`DataRefreshOverlay` sebagai fallback — intinya ikat ke BLoC, bukan ke `showGeneralDialog` mount, agar survive jika user background app atau overlay di-pop manual.
- **Disable:** transisi `isRunning → !isRunning` — `state is DataInitSuccess` atau `state is DataInitFailure` (termasuk `no_connection`, `timeout`, `unknown`). Juga di `dispose` view dan `finally { _isRunning=false }` di bloc (bloc sudah set false di finally). Guard `_held` di `WakelockController` mencegah double-enable/disable bila dua listener (view + ShellRoute) sama-sama trigger.
- **Offline fail-fast:** bila `ConnectivityService.isOnline==false` langsung emit `DataInitFailure(no_connection)` tanpa pernah enable wakelock — tidak bocor.

### Implementasi

```dart
// wakelock_controller.dart
import 'package:wakelock_plus/wakelock_plus.dart';
class WakelockController {
  bool _held = false;
  Future<void> enable() async { try { await WakelockPlus.enable(); _held=true; } catch(e){ debugPrint('[WAKELOCK] enable failed: $e'); } }
  Future<void> disable() async { if(!_held) return; try { await WakelockPlus.disable(); _held=false; } catch(e){ debugPrint('[WAKELOCK] disable failed: $e'); } }
}
```

- Tidak ada toggle di Settings, tidak persist ke `SharedPreferences`, tidak ubah `permission_handler` flow.

## 5) Tampilan & Interaksi Timeline

### Layout hybrid

- **Atas — FlatStepsView:** tetap seperti sekarang: `BellLogo` + `Text(dataInitStatusText(currentStatus))` + `CircularProgressIndicator` saat `InProgress`. Tidak diubah. Flat area sticky di atas, tidak ikut scroll timeline.
- **Bawah — KhsTimelineView:** render **inkremental** — muncul segera saat entry pertama `_khsMap` terbentuk (yakni `downloadingKhs` semester pertama), bukan menunggu `fetchingKhsSemesters` selesai sepenuhnya. Jika pipeline selesai dan `_khsMap.isEmpty` (yakni `semesters.isEmpty` atau global `khsEmpty` tanpa semester) → ganti timeline dengan banner `KHS belum tersedia` (reuse `cs.errorContainer`/`outlineVariant`). Selama pipeline berjalan, `khsEmpty` per-semester belum final — banner hanya tampil di state `completed/khsEmpty` akhir.

### KhsTimelineView detail

- **Container:** `ConstrainedBox(maxHeight: 0.6 * screenHeight)` + `ListView(shrinkWrap: true, physics: ClampingScrollPhysics, controller: _scrollCtrl)`. Auto-scroll ke item aktif saat key baru masuk: `WidgetsBinding.instance.addPostFrameCallback → Scrollable.ensureVisible` atau `_scrollCtrl.animateTo(maxScrollExtent)`.
- **Row per semester:**
  - Kiri: garis vertikal `Container(width: 2, color: semesterColor)` + dot `Container(12, decoration: Circle, color: dotColor, border: outline)` — dot pulsing jika `progress` (reuse `pulsing_dot` jika ada, atau `AnimatedContainer`).
  - Kanan: card `Container(decoration: SurfaceContainer, radius: 20)` berisi header `Text("$tahunAjaran — $semester", style: titleSmall)` + row chip 3 sub-step `DOWNLOAD | EXTRACT | GET` (chips: `Container(padding: 8/12, decoration: pill, color: chipBg, child: Row(icon, label))`).
  - Light path: 2 chip pertama label `Dilewati` abu + ikon `remove`, hanya `GET` yang punya state.
  - Semester `error` → dot merah + header merah + chip yang gagal merah dengan ikon `error_outline`.
- **Token warna:** reuse `cs.primary`, `cs.error`/`errorContainer`/`onErrorContainer`, `cs.outlineVariant`, `cs.surfaceContainer`/`surfaceContainerHigh`, `AppColors.success` — tidak tambah literal.
- **Responsif & A11y:** `sp()` + `responsiveFontSize()`, `Semantics(label: "KHS $tahunAjaran $semester, ${overall.name}")`.

### Dismiss timing (A)

- **Sukses:**
  - Jika `_khsMap.length > 1` → tahan **1.5s** sebelum `pop` (pull-refresh) / `onComplete → authStatusNotifier.setStatus(authenticated)` (fresh login). Selama jeda, timeline tetap scrollable agar user bisa lihat hijau/merah.
  - Jika `_khsMap.length <= 1` → tetap **500ms** seperti sekarang.
- **Error:** tetap **3s** auto-close di overlay; fresh login tetap tampil error view dengan tombol `Retry`/`Cancel` (tidak auto-pop) — plus auto-continue 15s non-profile error seperti existing `kStepErrorAutoContinue`.
- **Kepemilikan delay (eksplisit):** `DataInitProgressView` adalah pemilik `_khsMap` dan pemilik keputusan durasi. Ia expose `ValueNotifier<int> khsCount` (atau callback `onKhsCountChanged(int)`). `DataRefreshOverlay` hanya membaca nilai tersebut via `GlobalKey<_DataInitProgressViewState>` atau callback — tidak menghitung sendiri. `LoginPage` (fresh login) juga membaca via `GlobalKey` untuk menunda `onComplete`. Tidak ada duplikasi hitung `length` di overlay.

## 6) Error, Edge Case & Testing

### Error

- Per-semester error tidak stop pipeline (catch di loop DS preserve existing behavior). Timeline: semester gagal dot merah + chip sub-step gagal merah, semester lain hijau.
- Global `DataInitFailure(no_connection)` → error view existing di atas timeline (failedStep `no_connection` → label `Tidak ada koneksi`), `WAKE_LOCK` tidak pernah enable.
- `timeout` (30s/step × 8, `kDataInitTimeout`) → `DataInitFailure(failedStep: timeout)` → error view + wakelock disable.

### Edge

- `detail == null` → accumulator ignore.
- `DataInitReset` cepat berturut → clear map + cancel timer + disable wakelock.
- `semesters == []` → no timeline, banner saja.
- App background → wakelock tetap on sampai disable (by design).
- `dispose` → cancel `Timer`, `ScrollController`, `WakelockController.disable()`.

### Testing

- **Unit test `parseKhsDetail`:** `"2022/2023 Ganjil" → ("2022/2023","Ganjil")`, `"2022/2023 Genap" → ("2022/2023","Genap")`, null/empty/`"Ganjil"` tanpa tahun → null.
- **Widget test `KhsTimelineView`:** render 2 semester mix `success/error/skipped`, warna map benar (primary/success/error/outlineVariant), chip label `Dilewati` di light path, auto-scroll dipanggil.
- **Widget test `DataInitProgressView` accumulator:** emit sequence `downloadingKhs(detail:A) → extractingKhs(A) → fetchingKhsData(A) → downloadingKhs(B) → error B` → map terbentuk benar (previous fetch auto-success); light sequence `fetchingKhsSemesters → fetchingKhsData(A) → fetchingKhsData(B)` → skip badge; `DataInitIdle`/`scrapingProfile` → map clear; `completed` → remaining `progress` finalize ke `success`.
- **WakelockController test:** fake `WakelockPlus` (mock), enable di `scrapingProfile`, disable di `Success/Failure/dispose`, no-enable di `no_connection`, `PlatformException` di enable/disable tidak throw.
- **Existing `blocTest` DataInitBloc:** tetap hijau (BLoC tidak berubah).
- **Manual QA checklist:** fresh login heavy (real backend/local), pull heavy (≥3m idle), pull light (<3m), offline fail-fast, timeout, 6–8 semester, light path mix.

## 7) File & Diff Plan

- **Tambah:** `lib/features/data_initialization/presentation/widgets/khs_timeline_view.dart`, `lib/features/data_initialization/presentation/widgets/wakelock_controller.dart` (opsional, bisa inline).
- **Ubah:** `lib/features/data_initialization/presentation/widgets/data_init_progress_view.dart` (accumulator + render timeline), `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` (constraint + delay 1.5s), `pubspec.yaml` (`wakelock_plus`), `android/app/src/main/AndroidManifest.xml` (sudah ada `WAKE_LOCK`, verifikasi).
- **Tidak ubah:** `lib/features/data_initialization/presentation/bloc/*`, `domain/entities/*`, `data/datasources/data_initialization_remote_data_source.dart`, `data/services/pull_refresh_debounce.dart`, `core/routes/app_router.dart` (kecuali tambah wakelock listener jika dipilih di ShellRoute).

## 8) Risiko & Mitigasi

- Logika status pindah ke view (risiko duplikasi/typo parse `detail`) → mitigasi: helper `parseDetail(detail)` terpusat + unit test parsing.
- Wakelock leak → mitigasi: disable di `Success/Failure/dispose` + guard `_held` + `try/catch`.
- Timeline panjang di layar kecil → mitigasi: `maxHeight 0.6` + scroll + jeda 1.5s (A).

## 9) Kriteria Selesai

- [ ] `wakelock_plus` enable saat pipeline jalan, disable saat selesai/gagal/dispose, tidak bocor di offline.
- [ ] Fresh login & pull-refresh heavy tampil flat + timeline KHS per semester dengan warna per sub-step (token existing), sukses tahan 1.5s jika >1 semester.
- [ ] Pull-refresh light (≤3m) KHS hanya `GET` aktif, lainnya badge `Dilewati`.
- [ ] `DataInitReset` clear timeline, semua test widget + bloc hijau, manual QA 5 skenario lulus.
