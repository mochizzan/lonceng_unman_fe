# Login Offline Modal + Centered Header — Design Spec

**Date:** 2026-09-08
**Status:** Approved
**Scope:** `LoginPage` — offline warning + card header alignment
**Approach:** Pendekatan 2 — Service/Helper reusable (controller + modal bottom sheet)

## Ringkasan & Latar Belakang

`LoginPage` saat ini menampilkan peringatan offline sebagai **inline banner** di dalam `_LoginCard` (`SizedBox(space48)` + `BlocBuilder<ConnectivityCubit>` + `_OfflineBanner` berwarna `tertiaryContainer`, icon `cloud_off`, teks `AppStrings.loginOfflineBanner`). Banner muncul/hilang reaktif, memakan ruang tetap di card, dan kurang menonjol sebagai peringatan.

Permintaan perubahan:
1. Peringatan "internet terputus / tidak ada" **diubah menjadi modal bottom sheet** (overlapping, bukan menempel di bawah layar).
2. Teks header card **"Masuk Akun"** dan **"Gunakan NPM aktif kamu"** yang sekarang rata kiri (`CrossAxisAlignment.stretch` tanpa `textAlign`) diubah menjadi **align center vertical/horizontal** — keduanya terpusat seperti greeting "Halo Mahasiswa!" di atasnya.

Discovery yang sudah fix:
- **Trigger sheet:** otomatis saat `ConnectivityCubit` emit `isOnline == false` selama di `LoginPage` form (bukan hanya saat submit)
- **Aksi sheet:** tombol **"Mengerti"** (+ swipe/drag + tap scrim dismiss, + auto-dismiss saat kembali online)
- **Header:** keduanya center horizontal (`textAlign: TextAlign.center`)
- **Sifat sheet:** **modal overlapping** (`showModalBottomSheet` dengan scrim), bukan `Scaffold.bottomSheet` persistent — jadi tidak mendorong `SingleChildScrollView` / tidak menempel sebagai footer layout

Desain ini menggantikan inline banner dengan modal yang lebih menonjol, sekaligus menyiapkan controller reusable agar halaman lain bisa memakai sheet yang sama tanpa duplikasi logic.

## Tujuan & Non-Tujuan

### Tujuan
- Ganti inline `_OfflineBanner` di `_LoginCard` menjadi **modal bottom sheet** yang muncul otomatis saat offline dan hilang otomatis saat online.
- Sheet **reusable**: controller + widget sheet tidak terikat `LoginPage`, bisa dipakai feature lain dengan `Services.get<OfflineSheetController>()`.
- Header card login rata tengah: "Masuk Akun" + "Gunakan NPM aktif kamu" → `TextAlign.center`.
- Tidak ada regresi: `ConnectivityService` / `ConnectivityCubit` tetap `bool isOnline` + `Stream<bool>`, `AuthBloc` submit flow tetap, `AppStrings` tetap sumber teks, theming `sp()` + `responsiveFontSize` tetap.
- Testable: 5 file test (4 baru + 1 existing di-update) dengan hand-written fakes.

### Non-Tujuan
- Tidak mengubah `ConnectivityService` / `ConnectivityCubit` / `connectivity_plus` wiring.
- Tidak memblokir tombol "Masuk Akun" saat offline (sheet hanya informatif; validasi tetap via `AuthError` + `ErrorHandler.show`).
- Tidak menambah analytics, logging baru, atau permission Android baru.
- Tidak mengubah pipeline `DataInitBloc` fail-fast (sudah ada di spec 2026-09-05).
- Tidak menyentuh `domain` / `data` layer — murni `presentation` + `core`.

## Pendekatan yang Dipertimbangkan

### Pendekatan 1 — Minimal, lokal di LoginPage
Inline `BlocListener` di `LoginPage` langsung `showModalBottomSheet` tanpa controller eksternal. Guard `_isShowing` disimpan sebagai field di `_LoginPageState`. Kelebihan: footprint terkecil. Kekurangan: logic sheet terikat LoginPage, tidak reusable.

### Pendekatan 2 — Service/Helper reusable (Dipilih)
Ekstrak `OfflineSheetController` (guard anti-duplikat + `sync`) + widget `OfflineInfoBottomSheet` (presentasi murni) + `showOfflineInfoBottomSheet()` helper. Controller diregistrasi di `Services` (`main.dart`), dipanggil dari `BlocListener` di `LoginPage`. Kelebihan: reuse lintas halaman tanpa ubah LoginPage lagi. Kekurangan: tambah 1 registrasi DI + 1 file controller — diterima karena YAGNI-nya rendah (request eksplisit reusable).

### Pendekatan 3 — Hybrid banner + sheet fallback
Pertahankan inline banner sebagai fallback + sheet muncul sekali saat pertama offline. Kelebihan: tidak kehilangan affordance inline. Kekurangan: duplikat UI untuk pesan sama, maintenance 2×, bertentangan dengan "diubah menggunakan modal bottomsheet".

**Keputusan:** Pendekatan 2. Selaras dengan `Services.register` procedural existing, Clean Architecture tetap (`presentation → domain → data` tidak dilanggar — perubahan hanya di `presentation` + `core`), dan YAGNI terpenuhi (2 file lib baru + 4 file test baru; tidak ada dependensi baru).

## Arsitektur & Penempatan File

### Aturan DI & Layer
- Tetap `lib/core/di/di.dart` `Services.register<T>` / `Services.get<T>` (13+ registrasi di `lib/main.dart`).
- Tidak ada repository/usecase baru — ini bukan feature domain.

### File yang Dibuat / Diubah

| Aksi | Path | Peran |
|------|------|-------|
| BARU | `lib/shared/widgets/offline_info_bottom_sheet.dart` | `OfflineInfoBottomSheet` — StatelessWidget presentasi murni (drag handle, icon, title/desc dari `AppStrings`, tombol "Mengerti" → `Navigator.pop`). Tidak tahu `ConnectivityCubit`. |
| BARU | `lib/core/utils/offline_sheet_controller.dart` | `OfflineSheetController` — simpan `_isShowing`, `sync(bool isOnline, BuildContext context)`, `show/dismiss` dengan guard anti-duplikat. Tidak hold `BuildContext` di field. |
| UBAH | `lib/main.dart` | `Services.register<OfflineSheetController>(OfflineSheetController())` di dekat registrasi `ConnectivityService`. |
| UBAH | `lib/features/auth/presentation/pages/login_page.dart` | Hapus slot offline di `_LoginCard` (SizedBox space48 + BlocBuilder offline + `_OfflineBanner`). Di `_LoginPageState`, tambah `BlocListener<ConnectivityCubit, ConnectivityState>` yang `controller.sync(state.isOnline, context)` dengan guard `isLoginFormState`. `dispose` → `dismissIfShowing`. |
| UBAH | `lib/core/constants/app_strings.dart` | Tambah `loginOfflineSheetTitle` + `loginOfflineSheetAction = 'Mengerti'` (+ opsional `loginOfflineSheetDesc` bila split title/desc; fallback ke `loginOfflineBanner`). |
| UBAH (opsional) | `lib/core/constants/app_dimens.dart` | Tidak wajib — sheet pakai token existing (`radius3XL`, `space16/24`, `iconLG`). |
| TEST BARU | `test/shared/widgets/offline_info_bottom_sheet_test.dart` | Widget test sheet isolasi |
| TEST BARU | `test/core/utils/offline_sheet_controller_test.dart` | Unit test controller murni |
| TEST BARU | `test/core/utils/offline_sheet_guard_test.dart` | Unit test guard `isLoginFormState` |
| TEST BARU | `test/features/auth/presentation/pages/login_page_header_alignment_test.dart` | Widget test header center |
| TEST UBAH | `test/features/auth/presentation/pages/login_page_offline_test.dart` | Ganti assert banner inline → assert modal sheet |

### Kenapa `shared/widgets` + `core/utils`?
- `shared/widgets` = reusable UI lintas feature (konsisten dengan `auth_background`, `bell_logo`, `bloc_scaffold`).
- `core/utils` = helper/controller non-UI reusable (konsisten dengan `error_handler`, `responsive`, `map_cast`). Controller tidak menyimpan `BuildContext` di field — testable tanpa widget.

### Kenapa bukan `features/connectivity/`?
`connectivity` sekarang hanya deteksi (`Cubit` + `State`). Sheet adalah presentasi kondisi offline — wajar di `shared`/`core` agar feature lain (`home`, `khs`) bisa pakai tanpa depend ke feature `connectivity`.

## Komponen

### 1. `lib/shared/widgets/offline_info_bottom_sheet.dart` (BARU)

Presentasi murni, tidak depend ke BLoC.

```dart
class OfflineInfoBottomSheet extends StatelessWidget {
  const OfflineInfoBottomSheet({super.key, this.onUnderstood});

  /// Dipanggil saat tombol Mengerti ditekan. Jika null, pop dilakukan di helper.
  final VoidCallback? onUnderstood;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        sp(context, 24),
        sp(context, 16),
        sp(context, 24),
        MediaQuery.viewInsetsOf(context).bottom +
            sp(context, 24) +
            MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(sp(context, 28)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: sp(context, 40),
              height: sp(context, 4),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(sp(context, 2)),
              ),
            ),
          ),
          SizedBox(height: sp(context, 16)),
          Icon(Icons.cloud_off, size: sp(context, AppDimens.iconLG), color: cs.onSurfaceVariant),
          SizedBox(height: sp(context, 12)),
          Text(AppStrings.loginOfflineSheetTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    fontSize: responsiveFontSize(context, AppDimens.textLG),
                  )),
          SizedBox(height: sp(context, 8)),
          Text(AppStrings.loginOfflineBanner, // atau loginOfflineSheetDesc
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: responsiveFontSize(context, AppDimens.textSM),
              )),
          SizedBox(height: sp(context, 24)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('offline_sheet_understood_button'),
              onPressed: () {
                if (onUnderstood != null) {
                  onUnderstood!.call();
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sp(context, AppDimens.radius3XL)),
                ),
                padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
              ),
              child: const Text(AppStrings.loginOfflineSheetAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper reusable — menampilkan sheet sebagai **modal overlapping** (scrim).
Future<void> showOfflineInfoBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => const OfflineInfoBottomSheet(),
  );
}
```

Catatan:
- `backgroundColor: Colors.transparent` + `barrierColor` membuat sheet **mengambang di atas scrim**, bukan menempel sebagai footer layout — sama dengan pattern `EditBioBottomSheet` & `YearPickerSheet` yang sudah ada.
- Tinggi sheet wrap content (Column min), bukan `SizedBox` dengan tinggi tetap — scrim yang overlap sisa layar.
- Tidak perlu `NavbarVisibilityNotifier.hide()` karena `LoginPage` standalone (tanpa bottom nav).
- Semua dimensi via `sp(context, ...)` + `responsiveFontSize` — konsisten dengan `login_page.dart`.

### 2. `lib/core/utils/offline_sheet_controller.dart` (BARU)

Reusable controller — guard anti-duplikat + lifecycle.

```dart
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/shared/widgets/offline_info_bottom_sheet.dart';

/// Reusable controller untuk modal offline sheet.
///
/// Tidak menyimpan BuildContext di field — context diteruskan per call.
/// Diregistrasi sebagai singleton di `Services`.
class OfflineSheetController {
  bool _isShowing = false;

  bool get isShowing => _isShowing;

  /// Sinkronkan tampilan sheet dengan status koneksi.
  ///
  /// - `isOnline == false` + `!isShowing` + `isLoginForm == true` → show
  /// - `isOnline == true` + `isShowing` → dismiss
  void sync(bool isOnline, BuildContext context, {required bool isLoginForm}) {
    if (!context.mounted) return;
    if (!isOnline) {
      if (_isShowing) return;
      if (!isLoginForm) return;
      _show(context);
    } else {
      if (!_isShowing) return;
      _dismiss(context);
    }
  }

  Future<void> _show(BuildContext context) async {
    _isShowing = true;
    // Fire-and-forget di caller — jangan await di BlocListener.
    // ignore: discarded_futures — sengaja fire-and-forget dengan guard _isShowing
    showOfflineInfoBottomSheet(context).whenComplete(() {
      _isShowing = false;
    });
  }

  void _dismiss(BuildContext context) {
    if (!context.mounted) return;
    if (!Navigator.canPop(context)) {
      _isShowing = false;
      return;
    }
    Navigator.of(context).pop();
    // _isShowing akan reset via whenComplete dari _show
  }

  /// Best-effort dismiss saat page dispose.
  void dismissIfShowing(BuildContext context) {
    if (!_isShowing) return;
    if (!context.mounted) return;
    if (!Navigator.canPop(context)) {
      _isShowing = false;
      return;
    }
    Navigator.of(context).pop();
  }
}

/// Guard: hanya tampilkan sheet saat masih di form login.
bool isLoginFormState(Object authState) {
  // Hindari import cycle — cek via runtimeType string atau type check bila import tersedia.
  // Implementasi nyata pakai `authState is AuthInitial || authState is AuthError`.
  final name = authState.runtimeType.toString();
  return name == 'AuthInitial' || name == 'AuthError';
}
```

Alternatif implementasi `isLoginFormState` yang type-safe (bila import `auth_state.dart` diperbolehkan di `core/utils` — jika dianggap layering violation, pindahkan helper ini ke `lib/features/auth/presentation/utils/` atau terima `bool isLoginForm` dari `LoginPage`):

```dart
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
bool isLoginFormState(AuthState state) => state is AuthInitial || state is AuthError;
```

Desain ini memilih opsi **`bool isLoginForm` dari LoginPage** untuk menghindari import feature di `core` (menjaga dependency rule `presentation → domain → data`).

### 3. `lib/main.dart` (DIMODIFIKASI)

```dart
// Setelah:
// Services.register<ConnectivityService>(ConnectivityServiceImpl(Connectivity()));
Services.register<OfflineSheetController>(OfflineSheetController());
```

Urutan tidak sensitif — controller tidak depend ke service lain saat konstruksi.

### 4. `lib/features/auth/presentation/pages/login_page.dart` (DIMODIFIKASI)

#### 4a. Hapus inline banner di `_LoginCard`

Hapus:
- `SizedBox(height: sp(context, AppDimens.space48), child: BlocBuilder<ConnectivityCubit, ...>(_OfflineBanner))`
- `SizedBox(height: sp(context, AppDimens.space8))` yang mengapitnya
- class `_OfflineBanner` private di bawah file
- import `connectivity_cubit.dart` / `connectivity_state.dart` dari `_LoginCard` (tetap di `_LoginPageState` untuk listener)

#### 4b. Header card jadi center

```dart
// Sebelum:
Text(AppStrings.loginButton, style: headlineMedium),
SizedBox(height: sp(context, AppDimens.space8)),
Text(AppStrings.loginNpmHelper, style: bodyMedium onSurfaceVariant),

// Sesudah:
Text(AppStrings.loginButton,
    textAlign: TextAlign.center,
    style: theme.textTheme.headlineMedium?.copyWith(
      fontSize: responsiveFontSize(context, AppDimens.text4XL),
    )),
SizedBox(height: sp(context, AppDimens.space8)),
Text(AppStrings.loginNpmHelper,
    textAlign: TextAlign.center,
    style: theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: responsiveFontSize(context, AppDimens.textMD),
    )),
```

`CrossAxisAlignment.stretch` pada Column tetap — field `AppTextField`, error slot, dan button tetap full width. Hanya 2 `Text` header yang `textAlign: center`.

#### 4c. BlocListener untuk modal overlapping di `_LoginPageState`

```dart
class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Best-effort dismiss sheet agar tidak bocor.
    // Hati-hati: context di dispose sudah deactivated — guard mounted/canPop di controller
    // akan membuat ini jadi no-op yang aman. Alternatif: simpan `BuildContext` valid di
    // didChangeDependencies atau panggil dismiss dari listener saat authState berubah.
    try {
      Services.get<OfflineSheetController>().dismissIfShowing(context);
    } catch (_) {}
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      listener: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isLoginForm = authState is AuthInitial || authState is AuthError;
        Services.get<OfflineSheetController>().sync(
          state.isOnline,
          context,
          isLoginForm: isLoginForm,
        );
      },
      child: BlocListener<AuthBloc, AuthState>( // existing listener tetap
        listener: (context, state) { ... },
        child: Scaffold(
          body: AuthBackground(
            child: SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>( ... ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Catatan:
- `BlocListener` offline diletakkan **di luar** `BlocListener<AuthBloc>` agar `context.read<AuthBloc>().state` terbaca fresh.
- `listenWhen` mencegah panggilan `sync` berulang untuk state sama (redundan dengan filter di service, tapi murah).
- `sync` tidak `await` — fire-and-forget dengan guard `_isShowing`.
- `dismissIfShowing` di `dispose` pakai `try/catch` karena `Services` mungkin belum terisi di test harness tertentu.

### 5. `lib/core/constants/app_strings.dart` (DIMODIFIKASI)

```dart
// Di grup Auth, setelah loginOfflineBanner:
static const String loginOfflineSheetTitle = 'Tidak Ada Koneksi';
static const String loginOfflineSheetAction = 'Mengerti';
// Opsional split desc (jika tidak, reuse loginOfflineBanner):
// static const String loginOfflineSheetDesc =
//     'Mode offline — masuk mungkin gagal. Periksa koneksi internet.';
```

Jika split tidak diinginkan, `loginOfflineSheetDesc` tidak perlu — sheet pakai `loginOfflineBanner` langsung.

### 6. `lib/core/constants/app_dimens.dart` (TIDAK WAJIB)

Sheet pakai token existing (`radius3XL`, `space16/24`, `iconLG`). Tidak perlu tambah token baru.

## Aliran Data & Siklus Hidup

```
ConnectivityServiceImpl (connectivity_plus)
  ↓ Stream<bool> onStatusChange (emit hanya saat transisi)
ConnectivityCubit (root BlocProvider di main.dart)
  ↓ ConnectivityState(isOnline)
LoginPage.BlocListener<ConnectivityCubit>
  ↓ OfflineSheetController.sync(isOnline, context, isLoginForm)
     ├─ offline + !isShowing + isLoginForm → showOfflineInfoBottomSheet (modal, scrim)
     └─ online + isShowing → Navigator.pop (auto-dismiss)
User: tap Mengerti / swipe / tap scrim → .whenComplete → isShowing=false
```

Lifecycle:
1. Mount pertama: `ConnectivityService` default `isOnline=true` → tidak ada sheet.
2. Plugin emit `none` → service `isOnline=false` → cubit emit offline → `LoginPage` listener `sync(false, ...)` → `isLoginForm==true` (AuthInitial) → `showModalBottomSheet` (overlapping, scrim 0.32).
3. Koneksi pulih: plugin emit `wifi` → `sync(true, ...)` → `Navigator.pop` jika `canPop` → scrim hilang.
4. User close manual (Mengerti/drag/scrim): `whenComplete` reset `isShowing=false`; `sync(false)` berikutnya tidak re-show sampai ada transisi `online→offline` lagi (anti-spam).
5. Guard form: jika `authState` adalah `AuthProfileReview` / `AuthAuthenticated` / progress pipeline → `isLoginForm==false` → skip show agar tidak menutupi ReviewScreen.
6. Dispose page: `dismissIfShowing` best-effort agar overlay tidak bocor saat logout/navigasi.

Submit flow tidak diubah: tombol "Masuk Akun" tetap `bloc.add(AuthSubmitted())`; sheet hanya informatif.

## UI/UX & Theming

### OfflineInfoBottomSheet (modal, overlapping)
- `showModalBottomSheet(isScrollControlled: true, isDismissible: true, enableDrag: true, useSafeArea: true, backgroundColor: Colors.transparent, barrierColor: Colors.black.withValues(alpha: 0.32))` — drag down & tap scrim dismissable; `PopScope` tidak perlu (tidak ada unsaved changes).
- Container: `color: cs.surfaceContainerHigh`, `borderRadius: vertical(top: 28)` — hanya top radius, bottom lurus tapi karena `backgroundColor: transparent` sheet terlihat mengambang di atas scrim.
- Handle bar 40×4 `outlineVariant`, Icon `cloud_off` 26 `onSurfaceVariant`, Title `titleLarge bold center` `onSurface`, Desc `bodyMedium center` `onSurfaceVariant` maxLines 3, FilledButton full-width `primaryContainer/onPrimaryContainer` radius `radius3XL`.
- Padding: `fromLTRB(24, 16, 24, viewInsets.bottom + 24 + padding.bottom)` — hormati keyboard + safe area bawah; tinggi wrap content (Column min).
- Responsif: `sp(context, ...)` + `responsiveFontSize`.
- Aksesibilitas: icon semantics, tombol key `offline_sheet_understood_button`.

### Header card login
- Hanya tambah `textAlign: TextAlign.center` pada 2 `Text` header; `Column(crossAxisAlignment: stretch)` tetap untuk field/button. Hasil selaras dengan `_buildGreeting` yang sudah center.

Tidak ada perubahan warna/typography selain alignment.

## Penanganan Error & Kasus Tepi

| Kasus | Perilaku |
|-------|----------|
| Flapping cepat offline→online | Service filter duplikat; controller guard `isShowing` cegah tumpuk/pop ganda |
| Sheet terbuka, LoginPage dispose / authState pindah ke ReviewScreen | `dispose` → `dismissIfShowing` + cek `mounted`/`canPop`; guard `isLoginForm` cegah show saat bukan form |
| Close manual saat masih offline | `whenComplete` reset `isShowing`; tidak auto re-show sampai transisi `online→offline` lagi (anti-spam). Opsional `forceShow` tidak di scope |
| Show dipanggil saat bukan form | Skip (guard) |
| Stream connectivity error | Service `onError` tidak emit; sheet tidak pernah tampil — aman |
| Tema gelap/terang | `cs.*` adaptif via `lightTheme`/`darkTheme` |
| `context.mounted == false` atau `Navigator.canPop == false` | Guard return tanpa throw |

## Pengujian

Semua test hand-written fakes (tanpa mockito/mocktail), konsisten dengan `test/helpers/test_di.dart`.

| # | File | Jenis | Cakupan |
|---|------|-------|---------|
| 1 | `test/shared/widgets/offline_info_bottom_sheet_test.dart` | testWidgets | Render icon+title+desc+tombol Mengerti; tap Mengerti → pop; drag down dismissable; semantics. Tanpa Cubit. |
| 2 | `test/core/utils/offline_sheet_controller_test.dart` | test unit murni | `show` pertama → isShowing true; show kedua saat showing → guard tidak dobel; dismiss saat online → reset; `sync(false→false)` tidak dobel; `sync(true)` tanpa showing → no-op; berurutan tidak throw |
| 3 | `test/core/utils/offline_sheet_guard_test.dart` | test unit murni | `isLoginFormState` / `bool isLoginForm` branching: hanya `AuthInitial`/`AuthError` boleh show; `AuthProfileReview`/`AuthAuthenticated`/DataInit* → skip |
| 4 | `test/features/auth/presentation/pages/login_page_header_alignment_test.dart` | testWidgets | `find.text(loginButton)` + `find.text(loginNpmHelper)` → `textAlign == TextAlign.center`; tetap 2 baris, layout field tidak pecah |
| 5 | `test/features/auth/presentation/pages/login_page_offline_test.dart` (update) | testWidgets | Ganti assert banner inline → assert modal sheet: online → `find.text(loginOfflineBanner)` tidak ada; `fakeConn.setOnline(false)` → sheet muncul (`find.text` + `find.byKey(offline_sheet_understood_button)` di overlay); tap Mengerti → hilang; flip online → auto-dismiss. Reuse `_FakeConnectivityService` + `_Noop*` |

Tidak ada Patrol E2E baru — coverage widget-level cukup; `login_e2e_test` tetap jalur online.

Verifikasi manual:
1. `flutter analyze` bersih
2. `flutter test test/features/auth/presentation/pages/login_page_offline_test.dart test/shared/widgets/offline_info_bottom_sheet_test.dart test/core/utils/offline_sheet_controller_test.dart test/core/utils/offline_sheet_guard_test.dart test/features/auth/presentation/pages/login_page_header_alignment_test.dart` hijau
3. Smoke emulator: matikan WiFi → sheet modal overlapping + scrim muncul; Mengerti/swipe/scrim → hilang; nyalakan → auto-dismiss; header card center

## Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| `showModalBottomSheet` dengan context unmounted | `if (!context.mounted) return` di setiap sync |
| `Navigator.pop` double | Guard `_isShowing` + `canPop` sebelum pop; reset via `whenComplete` |
| Sheet menutupi ReviewScreen | Guard `isLoginForm` |
| Regresi header kembali kiri | `login_page_header_alignment_test` assert center |
| Hardcoded string di widget | Wajib `AppStrings.loginOfflineSheetTitle/Action` |
| Context leak di controller | Tidak simpan context di field |

## Kriteria Selesai (Definition of Done)

1. Inline `_OfflineBanner` + slot `space48` hilang dari card — card tidak punya banner di dalamnya.
2. Saat offline di LoginPage form, modal bottom sheet overlapping + scrim muncul otomatis; Mengerti / swipe / tap scrim / auto-dismiss saat online berfungsi tanpa dobel sheet.
3. Header "Masuk Akun" + "Gunakan NPM aktif kamu" `textAlign center`.
4. `AppStrings` punya `loginOfflineSheetTitle` + `loginOfflineSheetAction` ("Mengerti") — tidak ada hardcoded string.
5. `OfflineSheetController` terdaftar di `Services` (reusable).
6. 5 file test hijau (4 baru + 1 update); `flutter analyze` bersih; tidak ada regresi test offline lama (sudah dimigrasi ke sheet).

## Perubahan File

### File baru
- `lib/shared/widgets/offline_info_bottom_sheet.dart`
- `lib/core/utils/offline_sheet_controller.dart`
- `test/shared/widgets/offline_info_bottom_sheet_test.dart`
- `test/core/utils/offline_sheet_controller_test.dart`
- `test/core/utils/offline_sheet_guard_test.dart`
- `test/features/auth/presentation/pages/login_page_header_alignment_test.dart`

### File dimodifikasi
- `lib/main.dart` — registrasi controller
- `lib/features/auth/presentation/pages/login_page.dart` — hapus inline banner, center header, BlocListener modal
- `lib/core/constants/app_strings.dart` — tambah title + action
- `test/features/auth/presentation/pages/login_page_offline_test.dart` — migrasi ke assert modal sheet
- `test/helpers/test_di.dart` — tambah fake/registrasi `OfflineSheetController` bila perlu
