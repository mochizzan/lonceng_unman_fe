# Login Network Awareness — Design Spec

**Date:** 2026-09-05
**Status:** Approved (pending spec self-review)
**Scope:** Halaman `/login` + pipeline `DataInitBloc` (post-login 8-step)

## Latar Belakang & Masalah

Halaman `/login` saat ini hanya mendeteksi kegagalan koneksi **setelah** user menekan tombol "Masuk Akun" — dan bahkan saat itu pun baru setelah `SocketException`/`TimeoutException` (30 detik) dilemparkan oleh `ApiClient`. Dua skenario yang belum tertangani:

1. **Koneksi mati sebelum submit** — user mengisi formulir dengan susah payah, tap tombol, baru tahu tidak ada internet setelah 30 detik. Tidak ada indikasi visual pra-interaksi.
2. **Koneksi putus di tengah pipeline post-login** — pipeline `DataInitBloc` berjalan 8 langkah (scrape profile → foto → KRS download/extract/data → KHS semesters → KHS download/extract/data). Jika koneksi mati di langkah ke-3 atau ke-4 (KRS), pipeline terus mencoba dan masing-masing step yang gagal ditandai `khsEmpty`/`krsEmpty` non-fatal. Di akhir, user melihat "Data siap!" walau sebenarnya hanya profil yang ter-cache, KRS/KHS kosong.

Tujuan desain ini: **proactive detection + targeted UX** di `/login` + **fail-fast** di awal pipeline + **preserve existing** error handling untuk kasus pipeline putus-tengah.

## Tujuan & Non-Tujuan

### Tujuan
- Tampilkan banner info "Mode offline" pada `/login` saat koneksi tidak tersedia, **tanpa** menonaktifkan tombol submit.
- `DataInitBloc` melakukan **fail-fast** sebelum pipeline: jika offline → `DataInitFailure` dengan `failedStep: 'no_connection'`, tanpa memanggil stream pipeline.
- Pipeline putus-tengah **tetap** menggunakan error mapping yang ada (`NetworkException` di `_runStep` → `DataInitFailure(failedStep: step)`); tidak perlu modifikasi pipeline internal.
- Sync status saat aplikasi di-resume dari background.
- Testable: unit test untuk service, cubit, dan widget.

### Non-Tujuan
- Tidak menonaktifkan tombol submit saat offline (keputusan UX).
- Tidak menampilkan banner offline di halaman selain `/login` (Home/Jadwal/Profile tetap pakai error mapping yang sudah ada).
- Tidak menambahkan mode "offline-first" atau cache fallback untuk pipeline.
- Tidak mengubah retry policy `DataInitBloc` dalam-session (sklearn "Coba Lagi" tetap logout kembali ke login).
- Tidak membuat `ConnectivityService` dipakai global di luar `/login` + `DataInitBloc`. Scope dibatasi sesuai permintaan user.

## Pendekatan

**`ConnectivityService` (singleton, DI) + `ConnectivityCubit` (satu instance app-wide) + integrasi minimal ke `LoginPage` dan `DataInitBloc`.**

Plugin: `connectivity_plus` (popular, terawat, cross-platform, Stream-based).

Arsitektur:
```
ConnectivityPlus
    ↓ Stream<ConnectivityResult>
ConnectivityService (singleton, Services.register)
    ↓ Stream<bool> + bool isOnline
ConnectivityCubit (root BlocProvider)
    ↓ emit ConnectivityState(isOnline: bool)
   ├─ LoginPage → BlocBuilder → inline banner di _LoginCard
   └─ DataInitBloc → cek isOnline di _onStarted, fail-fast jika false
```

## Komponen

### 1. `lib/core/network/connectivity_service.dart` (BARU)

```dart
// Abstract interface — agar test bisa bikin fake tanpa depend plugin.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onStatusChange;
  Future<void> refresh();
}

// Implementasi nyata — membungkus plugin connectivity_plus.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl(Connectivity connectivity) : _conn = connectivity {
    // Ambil status awal secara best-effort.
    _conn.checkConnectivity().then(_updateFromResult);
    // Subscribe perubahan real-time.
    _subscription = _conn.onConnectivityChanged.listen(_updateFromResult);
  }

  final Connectivity _conn;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final _controller = StreamController<bool>.broadcast();
  bool _lastIsOnline = true;

  @override
  bool get isOnline => _lastIsOnline;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<void> refresh() async {
    final result = await _conn.checkConnectivity();
    _updateFromResult(result);
  }

  void _updateFromResult(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _lastIsOnline) {
      _lastIsOnline = online;
      _controller.add(online);
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
```

Catatan: `connectivity_plus` v6 emit `Stream<List<ConnectivityResult>>` (bukan single). Online jika **ada satu pun** result bukan `none`. Default `_lastIsOnline = true` agar UI tidak flash "offline" di mount pertama sebelum deteksi selesai.

### 2. `lib/features/connectivity/cubit/connectivity_state.dart` (BARU)

```dart
class ConnectivityState {
  const ConnectivityState({required this.isOnline});
  final bool isOnline;

  factory ConnectivityState.online() => const ConnectivityState(isOnline: true);
  factory ConnectivityState.offline() => const ConnectivityState(isOnline: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState && isOnline == other.isOnline;

  @override
  int get hashCode => isOnline.hashCode;
}
```

### 3. `lib/features/connectivity/cubit/connectivity_cubit.dart` (BARU)

```dart
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(ConnectivityService service)
      : _service = service,
        super(ConnectivityState(isOnline: service.isOnline)) {
    _subscription = _service.onStatusChange.listen((online) {
      if (isClosed) return;
      emit(ConnectivityState(isOnline: online));
    });
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
```

### 4. `lib/features/connectivity/barrel.dart` (BARU)
```dart
export 'cubit/connectivity_state.dart';
export 'cubit/connectivity_cubit.dart';
```

### 5. Dependency injection (`lib/main.dart`)

```dart
// Setelah Services.register<AuthStatusNotifier>(authStatusNotifier);
// ConnectivityService WAJIB sebelum runApp().
final connectivity = Connectivity();
Services.register<ConnectivityService>(
  ConnectivityServiceImpl(connectivity),
);
```

Di `LoncengUnmanApp.build` `MultiBlocProvider`, tambahkan provider (paling atas, agar tersedia di semua sub-tree):
```dart
BlocProvider<ConnectivityCubit>(
  create: (_) => ConnectivityCubit(Services.get<ConnectivityService>()),
),
```

### 6. Lifecycle resume sync (`lib/main.dart`, `_LoncengUnmanAppState`)

Ubah `_LoncengUnmanAppState` menjadi `WidgetsBindingObserver`:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  // ...existing...
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  // ...existing...
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    Services.get<ConnectivityService>().refresh();
  }
}
```

### 7. `lib/features/auth/presentation/pages/login_page.dart` (DIMODIFIKASI)

Tambah inline banner di `_LoginCard.build`, **di antara error slot dan submit button**:

```dart
// Inside _LoginCard build, after the SizedBox(height: sp(context, AppDimens.space8))
// that follows the error slot:
SizedBox(
  height: sp(context, AppDimens.space48), // tinggi tetap agar layout tidak lompat
  child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
    builder: (context, state) {
      if (state.isOnline) return const SizedBox.shrink();
      return _OfflineBanner(); // widget private baru di file ini
    },
  ),
),
SizedBox(height: sp(context, AppDimens.space8)),
```

`_OfflineBanner` (private widget di file yang sama):
```dart
class _OfflineBanner extends StatelessWidget {
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sp(context, AppDimens.space12),
        vertical: sp(context, AppDimens.space8),
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(sp(context, AppDimens.radiusMD)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: cs.onTertiaryContainer),
          SizedBox(width: sp(context, AppDimens.space8)),
          Expanded(
            child: Text(
              AppStrings.loginOfflineBanner,
              style: TextStyle(
                color: cs.onTertiaryContainer,
                fontSize: responsiveFontSize(context, AppDimens.textSM),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Tombol "Masuk Akun" tetap enabled** saat offline (sesuai keputusan UX).

### 8. `lib/features/data_initialization/presentation/bloc/data_initialization_bloc.dart` (DIMODIFIKASI)

Tambah dependency optional:
```dart
class DataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  final GetDataInitialization _getDataInit;
  final ConnectivityService? _connectivity;
  bool _isRunning = false;

  DataInitBloc(
    this._getDataInit, {
    ConnectivityService? connectivity,
  }) : _connectivity = connectivity ?? Services.get<ConnectivityService>(),
       super(const DataInitIdle()) { ... }
```

> Catatan: `Services.get<T>()` melempar `StateError` jika belum register. Karena `lib/main.dart`
> selalu mendaftarkan `ConnectivityService` sebelum `runApp()`, jalur produksi aman.
> Untuk unit test, gunakan `registerTestDependencies()` dari `test/helpers/test_di.dart`
> yang akan ditambah untuk mendaftarkan fake `ConnectivityService`.

Modify `_onStarted` di bagian **paling awal** (sebelum `if (_isRunning) return;`):
```dart
Future<void> _onStarted(DataInitStarted event, Emitter emit) async {
  debugPrint('[DATA_INIT] _onStarted — forceRefresh=${event.forceRefresh}');

  // Fail-fast: kalau offline, jangan panggil pipeline — hemat 30s/step × 8 step.
  if (_connectivity?.isOnline == false) {
    debugPrint('[DATA_INIT] Offline detected — fail-fast');
    emit(const DataInitFailure(
      AppStrings.dataInitNoConnection,
      failedStep: 'no_connection',
    ));
    return;
  }

  // Guard against concurrent / duplicate starts (login + shell bootstrap).
  if (_isRunning) {
    debugPrint('[DATA_INIT] Already running — SKIP');
    return;
  }
  // ... existing logic
}
```

**Tidak ada modifikasi** pada pipeline internal `_initializeHeavy`/`_initializeLight` — skenario pipeline putus-tengah sudah ditangani oleh `_runStep` (sudah melempar `NetworkException`/`DataInitStepException` dan di-catch di `DataInitBloc`).

### 9. `lib/features/data_initialization/presentation/widgets/data_init_progress_view.dart` (DIMODIFIKASI)

Di `_humanReadableFailedStep`, tambah case:
```dart
case 'no_connection':
  return AppStrings.dataInitNoConnectionStep;
```

(Pesan lengkap sudah ada di `state.message` jadi UI error view akan menampilkan: "Langkah yang gagal: Tidak ada koneksi" + pesan lengkap "Tidak ada koneksi internet. Coba lagi saat internet stabil." Tombol Coba Lagi sudah ada.)

### 10. `lib/core/constants/app_strings.dart` (DIMODIFIKASI)

Tambah di grup `Auth`:
```dart
static const String loginOfflineBanner =
    'Mode offline — masuk mungkin gagal. Periksa koneksi internet.';
```

Tambah di grup `Data Refresh Overlay` (setelah `refreshErrorHint`):
```dart
static const String dataInitNoConnection =
    'Tidak ada koneksi internet. Coba lagi saat internet stabil.';
static const String dataInitNoConnectionStep = 'Tidak ada koneksi';
```

### 11. `pubspec.yaml` (DIMODIFIKASI)

Tambah di `dependencies:`:
```yaml
  # Network connectivity detection (Android/iOS/Web/desktop)
  connectivity_plus: ^6.1.0
```

Versi target akan diverifikasi saat implementasi (`flutter pub add connectivity_plus` akan pilih versi terbaru yang memenuhi constraint Flutter SDK `^3.12.0`).

### 12. `android/app/src/main/AndroidManifest.xml` (DIMODIFIKASI)

Tambah setelah permission `WAKE_LOCK`:
```xml
    <!-- Detect network state for offline banner & DataInit fail-fast -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
```

## Aliran Data

### Mount pertama
1. `main()` → register `ConnectivityService` di DI.
2. `LoncengUnmanApp` build → `MultiBlocProvider` menciptakan `ConnectivityCubit`.
3. `ConnectivityService` constructor panggil `checkConnectivity()` async + subscribe stream.
4. `ConnectivityCubit` constructor baca `service.isOnline` (default `true`) → emit initial state.
5. Begitu stream emit pertama (cek selesai) → `ConnectivityCubit` emit ulang dengan state sebenarnya.

### Lifecycle resume
1. App ke background → `didChangeAppLifecycleState(paused)`.
2. App kembali ke foreground → `didChangeAppLifecycleState(resumed)`.
3. `LoncengUnmanAppState` panggil `Services.get<ConnectivityService>().refresh()`.
4. Service cek ulang, emit jika berbeda dari cache.

### User submit saat online
1. `AuthBloc._onSubmitted` → `emit AuthLoading` → `await _getAuth(...)` sukses → `emit AuthProfileReview`.
2. User konfirmasi → `emit AuthAuthenticated`.
3. `LoginPage.BlocListener` panggil `DataInitBloc.add(DataInitStarted(...))`.
4. `DataInitBloc._onStarted` cek `_connectivity?.isOnline` → `true` (existing path, no change).

### User submit saat offline (banner kuning tampil)
1. Tap tombol → `AuthBloc._onSubmitted` → loading → `ApiClient.post` throw `NetworkException` setelah 30s timeout (atau `SocketException` instan).
2. `AuthBloc` emit `AuthError('Tidak ada koneksi...', error: NetworkException)`.
3. `LoginPage.BlocListener` panggil `ErrorHandler.show()` (Toast). Banner kuning tetap tampil dari `ConnectivityCubit` state.

### User submit sukses tapi koneksi putus saat pipeline jalan
1. Pipeline `DataInitBloc._initializeHeavy` jalan. Misal sampai `Step 2: downloadingKrs`, socket drop.
2. `_runStep('krs_download', ...)` catch → throw `DataInitStepException('krs_download', ...)`.
3. Catch block di `_initializeHeavy` (sudah ada) → log error → yield `krsEmpty` → lanjut ke KHS block.
4. KHS juga gagal → `khsEmpty`.
5. Pipeline "selesai" → `DataInitBloc._onStarted` await stream selesai → emit `DataInitSuccess` (existing behavior).
6. Cache profil sudah terisi, KRS/KHS kosong. **Bug existing**, di luar scope. Tetap di-handle nanti di spec berbeda.

### User submit sukses, koneksi putus sebelum pipeline mulai (di antara auth & data init)
1. Setelah `AuthAuthenticated` di-emit, `LoginPage.BlocListener` dispatch `DataInitStarted`.
2. `DataInitBloc._onStarted` cek `_connectivity?.isOnline == false` → emit `DataInitFailure(dataInitNoConnection, failedStep: 'no_connection')` → return.
3. `DataInitProgressView` menampilkan error view dengan failed step "Tidak ada koneksi" + pesan lengkap + tombol "Coba Lagi".

### Koneksi pulih saat di halaman login
1. Plugin emit `ConnectivityResult.wifi` → service `isOnline = true` (jika sebelumnya false).
2. `ConnectivityCubit` emit `ConnectivityState.online()`.
3. Banner kuning hilang otomatis (BlocBuilder rebuild).
4. User bisa tap tombol normal.

## Pengujian

### Unit test baru

**`test/core/network/connectivity_service_test.dart`**
- Pakai fake `Connectivity` (override `checkConnectivity` → `Future.value([ConnectivityResult.wifi])`, `onConnectivityChanged` → `StreamController`).
- Test:
  1. Initial state setelah constructor: `isOnline == true` (default) lalu update saat stream emit.
  2. Stream emit `[ConnectivityResult.wifi]` → `isOnline == true`.
  3. Stream emit `[ConnectivityResult.none]` → `isOnline == false`.
  4. Stream emit duplikat (online→online) → `onStatusChange` tidak emit (filtered).
  5. `refresh()` memicu re-check & emit jika berbeda.

**`test/features/connectivity/cubit/connectivity_cubit_test.dart`**
- Pakai `_FakeConnectivityService` dengan `StreamController<bool>` internal.
- Test:
  1. Initial state mengikuti `service.isOnline`.
  2. Service emit `false` → cubit state `isOnline == false`.
  3. Service emit `true` → cubit state `isOnline == true`.
  4. `close()` cancel subscription (tidak throw jika di-panggil dua kali).

**`test/features/auth/bloc/auth_bloc_test.dart` (extend)**
- Tambah 1 test: `FakeGetAuth` melempar `NetworkException` → bloc emit `[AuthLoading, AuthError('Tidak ada koneksi', error: NetworkException(...))]`.

**`test/features/data_initialization/bloc/data_initialization_bloc_test.dart` (BARU)**
- Pakai fake `ConnectivityService` + fake `GetDataInitialization` yang return stream kosong.
- Test:
  1. `isOnline == false` saat `_onStarted` → emit `DataInitFailure(AppStrings.dataInitNoConnection, failedStep: 'no_connection')`, stream pipeline TIDAK dipanggil.
  2. `isOnline == true` + stream emit `[scrapingProfile, completed]` → emit `[DataInitInProgress(scrapingProfile), DataInitSuccess]`.
  3. `isOnline == null` (service null) → fallback ke existing behavior (pipeline jalan tanpa cek).

### Widget test baru

**`test/features/auth/presentation/pages/login_page_offline_test.dart`**
- Pakai fake `ConnectivityService` yang bisa di-toggle.
- Test:
  1. Online → `find.text(AppStrings.loginOfflineBanner)` returns nothing.
  2. Toggle ke offline → banner teks terlihat.
  3. Tombol "Masuk Akun" **enabled** saat offline (keputusan UX — bukan `onPressed: null`).
- Pattern sama dengan `login_page_test.dart` (BlocProvider.AuthBloc + DataInitBloc). Tambah `BlocProvider<ConnectivityCubit>` di test.

### Test DI helper extension

**`test/helpers/test_di.dart` (extend)**
Tambah `_FakeConnectivityService implements ConnectivityService` dengan `StreamController<bool>.broadcast()` internal + setter `void setOnline(bool)`.

Tambah `Services.register<ConnectivityService>(_FakeConnectivityService());` di `registerTestDependencies()`.

## Perubahan File

### File baru
- `lib/core/network/connectivity_service.dart`
- `lib/features/connectivity/cubit/connectivity_state.dart`
- `lib/features/connectivity/cubit/connectivity_cubit.dart`
- `lib/features/connectivity/barrel.dart`
- `test/core/network/connectivity_service_test.dart`
- `test/features/connectivity/cubit/connectivity_cubit_test.dart`
- `test/features/data_initialization/bloc/data_initialization_bloc_test.dart`
- `test/features/auth/presentation/pages/login_page_offline_test.dart`

### File dimodifikasi
- `pubspec.yaml` — tambah `connectivity_plus`
- `pubspec.lock` — auto-update dari `flutter pub get`
- `android/app/src/main/AndroidManifest.xml` — tambah 2 permission
- `lib/main.dart` — register service, tambah `ConnectivityCubit` ke `MultiBlocProvider`, `WidgetsBindingObserver` di `_LoncengUnmanAppState`
- `lib/core/constants/app_strings.dart` — tambah 3 string
- `lib/features/auth/presentation/pages/login_page.dart` — tambah `_OfflineBanner` widget + `BlocBuilder<ConnectivityCubit>`
- `lib/features/data_initialization/presentation/bloc/data_initialization_bloc.dart` — tambah field `_connectivity`, fail-fast di `_onStarted`
- `lib/features/data_initialization/presentation/widgets/data_init_progress_view.dart` — tambah case `'no_connection'` di `_humanReadableFailedStep`
- `test/helpers/test_di.dart` — tambah fake service + register

## Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| `connectivity_plus` butuh `ACCESS_NETWORK_STATE` di Android | Tambah permission di `AndroidManifest.xml` |
| Stream subscription leak di `ConnectivityCubit` | Override `close()` cancel subscription |
| Stale state saat app resume | `WidgetsBindingObserver` + `refresh()` di root |
| Double indikasi: banner offline + Toast error | Banner ditentukan oleh state global (independent dari error event). Toast hanya muncul saat user tap & server fail — bukan duplikasi. |
| `connectivity_plus` emit duplikat | Service `_updateFromResult` filter perubahan |
| Default `_lastIsOnline = true` bisa false-positive di mount pertama | Best-effort; `checkConnectivity()` di constructor override cepat. Banner kuning yang salah tampil di detik pertama > banner tidak tampil. |
| `DataInitBloc` ada di tempat lain yang mungkin instantiate tanpa `ConnectivityService` (test) | `test/helpers/test_di.dart` `registerTestDependencies()` ditambah untuk register fake `ConnectivityService`. Test yang instantiate `DataInitBloc` langsung (tanpa full DI) WAJIB supply fake via parameter `connectivity:` |

## Verifikasi

Setelah implementasi:
1. `flutter analyze` — harus clean.
2. `flutter test` — semua test existing + baru lulus.
3. Smoke test manual di MuMu emulator:
   - Login normal (online) → pipeline jalan → home tampil.
   - Matikan Wi-Fi emulator → buka login → banner kuning tampil → tap tombol → loading lama → Toast error tampil.
   - Login sukses → matikan Wi-Fi di tengah pipeline → DataInitFailure tampil dengan step KRS atau KHS.
   - Login sukses + Wi-Fi off sebelum DataInit dipanggil → fail-fast "Tidak ada koneksi".
4. Lifecycle: minimize app, matikan Wi-Fi, restore app → banner update dalam 1 detik.

## Cleanup

- Tambah section pendek di `AGENTS.md` grup `Key Directories`: `lib/features/connectivity/ — connectivity detection cubit`.
- Tambah ke `lib/main.dart` header comment singkat: "ConnectivityService registered as singleton, consumed by ConnectivityCubit (root BlocProvider), LoginPage, and DataInitBloc."
- Tidak ada changelog file di project (existing convention). Skip.

## Referensi

- `connectivity_plus` pub.dev: https://pub.dev/packages/connectivity_plus
- Existing `ApiClient._executeRequest`: `lib/core/network/api_client.dart:82-99` (sudah map `SocketException`/`TimeoutException` → `NetworkException`)
- Existing `DataInitBloc`: `lib/features/data_initialization/presentation/bloc/data_initialization_bloc.dart`
- Existing `LoginPage`: `lib/features/auth/presentation/pages/login_page.dart:62-188`
- Existing `BlocErrorHandler`: `lib/core/errors/bloc_error_handler.dart`