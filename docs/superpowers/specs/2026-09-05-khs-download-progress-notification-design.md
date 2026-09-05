# Desain: KHS Download — Notifikasi Progres & Aksi (Play Store-like)

- Tanggal: 2026-09-05
- Lokasi: `docs/superpowers/specs/2026-09-05-khs-download-progress-notification-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go tidak diubah (endpoint `POST /api/v1/lms/khs/file` sudah ada — lihat `docs/backend/khs-pdf-download-endpoint.md`).
- Status: Disetujui per seksi 1/7 s/d 7/7 di sesi brainstorming (Pendekatan 2 — Decoupled Notification Controller).
- Terkait: `lib/features/khs/data/services/khs_pdf_service.dart`, `lib/features/khs/presentation/cubit/khs_detail_cubit.dart` + `khs_detail_state.dart`, `lib/features/khs/presentation/pages/khs_detail_page.dart`, `lib/features/khs/presentation/widgets/khs_download_icon.dart` + `khs_download_button.dart`, `lib/core/services/notification_service.dart`, `lib/core/constants/notification_config.dart`, `lib/core/constants/app_strings.dart`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart` (DI).
- Supersedes: Bagian download di `2026-08-31-khs-pdf-download-year-switcher-design.md` — state `DownloadStatus` dan `KhsPdfService` tetap, tapi perilaku sukses/error diperkaya dengan notifikasi + action + modal kondisional sesuai spec ini. Writer `tahunAjaran` camelCase + `isFetching` dari spec 2026-09-05/06 tetap berlaku dan tidak diduplikasi.

## 1. Latar Belakang & Masalah

Halaman KHS (`KhsDetailPage`) sudah punya tombol unduh PDF (`KhsDownloadIcon` di info card tiap tab GANJIL/GENAP, dan `KhsDownloadButton` varian Filled). Saat ditekan, `KhsDetailCubit.downloadPdf(semester)` memanggil `KhsPdfService.download()` yang `POST /api/v1/lms/khs/file` dan menulis file ke `Documents/LoncengUnMan/KHS/KHS_<tahun>_<semester>.pdf`. Status hanya tercermin sebagai:

- `DownloadStatus.downloading` → spinner 20px di tombol (via `BlocBuilder`)
- `DownloadStatus.success/error` → emit state baru
- error via `ErrorHandler.show` (Fluttertoast)

Yang belum ada:

1. Tidak ada **feedback sistem** di luar halaman — user tidak tahu unduhan sudah selesai, tersimpan di mana, dengan nama apa, terutama jika sudah pindah halaman atau app di-background.
2. Tidak ada **notifikasi progres** ala Play Store (ongoing → completed dengan info lokasi + nama file).
3. Tidak ada **aksi cepat** dari notifikasi (Buka / Bagikan) dan tidak ada **retry** dari notifikasi saat gagal.
4. Tidak ada **modal sukses** kondisional saat masih di KHS (user butuh konfirmasi file + lokasi + hint).

Request: saat unduh ditekan tampil **notifikasi indeterminate "Mengunduh…" (ongoing)** → setelah selesai ganti menjadi **notifikasi selesai persistent** berisi nama file + lokasi singkat + hint "tap Buka untuk melihat" dengan **actions Buka & Bagikan**. Jika **masih di halaman KHS** tampilkan juga **AlertDialog sukses**; jika **tidak/sudah background** hanya notifikasi. Keduanya (ongoing & selesai) harus **tetap tampil sampai tap/swipe**. Saat **gagal**, tampil **notifikasi error persistent + action Coba Lagi**. Izin notifikasi soft-gate: unduhan tetap jalan walau tanpa notifikasi.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Tekan unduh → tampil notifikasi `Mengunduh KHS…` (`ongoing: true`, `autoCancel: false`, indeterminate tanpa persen) dengan ID tunggal, menggantikan notifikasi sebelumnya (Play Store-like).
2. Selesai → notifikasi berganti (ID sama) ke `Unduhan selesai — KHS_*.pdf — Tersimpan di Documents/LoncengUnMan/KHS — tap Buka untuk melihat` (`ongoing: false`, `autoCancel: true`, persistent sampai swipe/tap) dengan **2 actions: Buka & Bagikan**.
3. Gagal → notifikasi `Unduhan gagal — <reason>` + **action Coba Lagi** yang benar-benar retry download semester terakhir.
4. Jika `ModalRoute.of(context).isCurrent == true` saat sukses → tampilkan juga **AlertDialog sukses** (icon check, fileName bold + lokasi singkat + hint, tombol Tutup + Buka). Jika tidak, hanya notifikasi.
5. **Soft-gate `POST_NOTIFICATIONS`**: cek status sebelum `showOngoing`; jika denied → minta; jika tetap denied → skip semua `show*`, unduhan + file write tetap jalan, hanya `DownloadStatus` + toast + dialog (jika di KHS). Jangan batalkan unduh karena izin notifikasi.
6. **Blocking sequential**: satu unduhan pada satu waktu (guard `DownloadStatus.downloading` existing dipertahankan); tap kedua diabaikan, tombol disabled+spinner.
7. Channel baru `downloads` (`lonceng_unman_downloads`, high importance, no vibration/lights) auto-create di `NotificationService.initialize()`.

### 2.2 Non-Tujuan

- Tidak menampilkan **persen byte 0–100%** di v1 (dipilih opsi B indeterminate; `KhsPdfService` tetap `bodyBytes` non-streaming — disiapkan seam `onProgress` untuk iterasi berikut).
- Tidak mendukung **concurrent/queue** unduhan (opsi A blocking dipilih).
- Tidak memakai **ForegroundService / WorkManager / flutter_downloader** (background isolate yang survive app-kill — overkill untuk PDF 1–3 MB, YAGNI).
- Tidak memindahkan posisi tombol unduh dari info card; tidak menambah tombol baru di AppBar.
- Tidak mengubah writer `tahunAjaran` camelCase, `isFetching`, maupun kontrak `KhsPdfService._buildPublicPath` (hanya memakai return-nya sebagai `filePath`).

## 3. Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Progress | **B — indeterminate** `Mengunduh…` tanpa persen. `Content-Length` tidak diandalkan; fallback indeterminate jika tidak ada. |
| 2 | Selesai tap & action | **C — notifikasi dengan 2 actions Buka & Bagikan**. Tap body juga buka file. Butuh `open_filex` + `share_plus`. |
| 3 | Isi notifikasi & modal sukses | **C — `fileName` + lokasi singkat `Documents/LoncengUnMan/KHS` + hint `tap Buka untuk melihat`**. Modal berupa **AlertDialog** (bukan BottomSheet) kondisional `isCurrent`. |
| 4 | Concurrency | **A — blocking sequential**, satu ID notifikasi tunggal (`7001`), guard `downloading` tetap. |
| 5 | Error & izin | **Notifikasi error persistent + Coba Lagi**; izin `POST_NOTIFICATIONS` **soft-gate** (tetap unduh tanpa notifikasi jika denied). |
| 6 | Pendekatan | **Pendekatan 2 — Decoupled Notification Controller** (bukan Cubit-centric P1, bukan True background downloader P3). |
| 7 | Research Android 26→36 | Verifikasi langsung `developer.android.com/behavior-changes-14` & `behavior-changes-16` + `build.gradle.kts` (`compileSdk 37, targetSdk 34`): **tidak perlu ForegroundService/type baru** untuk v1 — cukup `show(ongoing)` biasa. `POST_NOTIFICATIONS` (33) soft-gate wajib; ongoing di 14+ bisa di-swipe di beberapa OEM → handle dengan cancel&re-show ID sama. |

## 4. Desain Rinci

### 4.1 Arsitektur (DISETUJUI)

```
KhsDetailPage (Tab GANJIL/GENAP — info card)
  └─ KhsDownloadIcon / KhsDownloadButton
       └─ onPressed → KhsDetailCubit.downloadPdf(semester, context: context)

KhsDetailCubit.downloadPdf
  ├─ loadCredentials() → jika kosong → DownloadStatus.error + ErrorHandler.show + (jika izin) showError(noRetry)
  ├─ if downloadStatus==downloading → return (blocking guard)
  ├─ bool showNotification = await controller.ensurePermission()  // soft-gate
  ├─ DownloadStatus.downloading → emit
  ├─ if showNotification → controller.showOngoing(fileName)
  ├─ await KhsPdfService.download(npm,password,tahunAjaran,semester) → filePath
  │    └─ POST /api/v1/lms/khs/file (raw PDF), tulis ke Documents/LoncengUnMan/KHS/
  ├─ on success:
  │    ├─ DownloadStatus.success + downloadedFileName/FilePath → emit
  │    ├─ if showNotification → controller.showCompleted(fileName, filePath)  [Buka, Bagikan]
  │    └─ if context.mounted && ModalRoute.of(context).isCurrent → showDialog AlertDialog
  └─ on error (AppException/Socket/Timeout/FormatException):
       ├─ DownloadStatus.error → emit
       ├─ if showNotification → controller.showError(fileName, reason)  [Coba Lagi]
       └─ ErrorHandler.show(context, e)  // fallback existing — tetap

Global tap handler (NotificationService.initialize):
  onDidReceiveNotificationResponse → controller.handleResponse(response)
    ├─ actionId==open  → OpenFilex.open(filePath dari payload)
    ├─ actionId==share → Share.shareXFiles([XFile(filePath)])
    └─ actionId==retry → Services.get<KhsDetailCubit>().downloadPdf(lastSemester)
```

ID notifikasi tunggal `7001` (range reserve `7000–7999` untuk download — lihat mitigasi §4.7) — setiap `show*` dengan ID sama akan update in-place (Play Store pattern). `lastSemester` disimpan di controller saat `showOngoing`.

### 4.2 Komponen & Data Flow (DISETUJUI)

**Artefak baru (1 file + 1 channel):**

| Artefak | Peran |
|---------|-------|
| `lib/features/khs/data/services/khs_download_notification_controller.dart` **baru** | Controller terpusat. API: `ensurePermission()`, `showOngoing({fileName})`, `showCompleted({fileName,filePath})`, `showError({fileName,reason})`, `cancel()`, `handleResponse(NotificationResponse)`. Membungkus `FlutterLocalNotificationsPlugin.show()` + payload + action wiring. Diuji via fake plugin. |
| `NotificationChannel.downloads` **enum baru** di `lib/core/constants/notification_config.dart` | `id:'lonceng_unman_downloads'`, `name:'Unduhan'`, `description:'Notifikasi progres & status unduhan berkas KHS'`, `importance: high`, `enableVibration:false`, `enableLights:false`. Auto-create saat `NotificationService.initialize()` loop `values`. |

**Dependency baru (2, ringan):**

| Package | Alasan |
|---------|--------|
| `open_filex` | `Buka` → intent `ACTION_VIEW` `application/pdf` via FileProvider. Handle `noAppToOpen` → toast. |
| `share_plus` | `Bagikan` → `Share.shareXFiles([XFile(filePath)])`. |

**File yang dimodifikasi (8 + 2 dep):**

| File | Perubahan |
|------|-----------|
| `lib/core/services/notification_service.dart` | Tambah thin-wrapper `show()`/`showWithActions()`/`showOngoing()` di atas `_plugin.show` + pasang `onDidReceiveNotificationResponse` routing untuk `actionId ∈ {open, share, retry}` yang delegasi ke controller. Expose `areNotificationsEnabled()` jika belum ada (sudah ada `checkPermissionStatus`/`requestPermission`). |
| `lib/features/khs/data/services/khs_pdf_service.dart` | **Minimal** — tidak diubah ke streaming di v1. Hanya pakai return `filePath` untuk notifikasi/modal. Seam `onProgress` opsional disiapkan untuk upgrade byte-progres nanti tanpa ubah caller. |
| `lib/features/khs/presentation/cubit/khs_detail_cubit.dart` | `downloadPdf()` disisipkan soft-gate izin, guard blocking tetap, panggil controller `showOngoing`/`showCompleted`/`showError`, dan enrich state dengan `downloadedFileName/FilePath`. Menerima `DownloadNotificationController` via DI (fallback `Services.get`). Tidak import `open_filex`/`share_plus`. |
| `lib/features/khs/presentation/cubit/khs_detail_state.dart` | Tambah 2 field opsional ke `KhsDetailState`: `downloadedFileName` + `downloadedFilePath` (nullable). `_emitWithDownloadStatus` dan `_emitWithFetching` ikut meneruskan. `operator==` dan `hashCode` di semua subclass (`KhsDetailLoading`/`Loaded`/`Error`) diperbarui untuk mencakup 2 field baru. `success` isi keduanya dari return service; `error`/`idle` → null. |
| `lib/features/khs/presentation/pages/khs_detail_page.dart` | Tambah `BlocListener<KhsDetailCubit,KhsDetailState>` yang trigger `AlertDialog` sukses hanya saat `success && filePath!=null && ModalRoute.isCurrent` (dengan `listenWhen: previous.downloadStatus != current.downloadStatus`). Alternatif: cubit trigger via context — dipilih listener agar tidak langgar `mounted` di cubit. |
| `lib/main.dart` | Registrasi `DownloadNotificationController` di DI + channel `downloads` auto-create (tanpa ubah lain). |
| `lib/core/constants/app_strings.dart` | 6–8 string baru: judul/body ongoing, selesai, error, label action Buka/Bagikan/Coba Lagi, dialog title/body/hint. |
| `android/app/src/main/AndroidManifest.xml` | **Tidak perlu** izin baru untuk v1 (tanpa ForegroundService). Hanya tambah `<queries><intent><action android:name="android.intent.action.VIEW" /><data android:mimeType="application/pdf" /></intent></queries>` jika `open_filex` memerlukan. |

**Yang sengaja TIDAK diubah:** `KhsDownloadIcon`/`KhsDownloadButton` tetap di info card; `DownloadStatus` enum tetap (`idle/downloading/success/error`); posisi tombol tidak pindah.

**Kontrak controller:**

```dart
abstract class DownloadNotificationController {
  static const int notificationId = 7001; // tunggal — blocking sequential, range 7000–7999 reserved
  Future<bool> ensurePermission(); // soft-gate: check → request → bool
  Future<void> showOngoing({required String fileName});
  Future<void> showCompleted({required String fileName, required String filePath});
  Future<void> showError({required String fileName, required String reason});
  Future<void> cancel();
  void handleResponse(NotificationResponse response); // routing open/share/retry
}
```

- `payload` berisi `filePath` (string) agar `handleResponse` bisa open/share tanpa baca cubit.
- `actionId`: `open` / `share` / `retry`. `retry` memanggil cubit `downloadPdf(lastSemester)` — `lastSemester` disimpan di controller saat `showOngoing` pertama.

### 4.3 State & Kontrak (DISETUJUI)

**`DownloadStatus` — tetap:**

`idle / downloading / success / error` sudah cukup. Tidak perlu `cancelling`/`paused`.

**Enrichment state — bawa `filePath` & `fileName`:**

```dart
abstract class KhsDetailState {
  final String selectedTahunAjaran;
  final List<String> availableYears;
  final DownloadStatus downloadStatus;
  final bool isFetching;
  final String? downloadedFileName; // "KHS_2024_2025_GANJIL.pdf"
  final String? downloadedFilePath; // "/storage/.../KHS/...pdf"
}
```

`_emitWithDownloadStatus` di-clone dengan field baru ikut diteruskan. Pada `success` → isi keduanya dari return `KhsPdfService.download()`. Pada `error`/`idle` → `null`. Listener di `KhsDetailPage` hanya trigger dialog saat `success && downloadedFilePath != null && ModalRoute.of(context).isCurrent`.

**Kontrak notifikasi → action tap:**

- `payload` berisi `filePath` agar `handleResponse` bisa open/share tanpa baca state cubit.
- `actionId`: `open` / `share` / `retry`. `retry` via `Services.get` atau callback inject (dipilih saat implement).

### 4.4 UI/UX Rinci — Notifikasi + Modal (DISETUJUI)

**Notifikasi — 3 fase, 1 ID (`7001`):**

| Fase | `ongoing` | `autoCancel` | Judul | Body (max 2 baris) | Actions |
|------|-----------|--------------|-------|--------------------|---------|
| Mengunduh | `true` | `false` | `Mengunduh KHS…` | `KHS_2024_2025_GANJIL.pdf` | — |
| Selesai | `false` | `true` | `Unduhan selesai` | `KHS_2024_2025_GANJIL.pdf — Tersimpan di Documents/LoncengUnMan/KHS — tap Buka untuk melihat` | **Buka**, **Bagikan** |
| Gagal | `false` | `true` | `Unduhan gagal` | `KHS_2024_2025_GANJIL.pdf — <reason singkat>` | **Coba Lagi** |

- Semua pakai channel `downloads` (high importance, no vibration supaya tidak berisik tiap ganti fase).
- `showOngoing` dipanggil **sebelum** `await pdfService.download()`; `showCompleted`/`showError` **menggantikan** notifikasi yang sama (ID sama → update in-place).
- Jika `ensurePermission()==false` → skip semua `show*`, hanya `DownloadStatus` + toast + dialog jika di KHS.

**AlertDialog sukses — hanya jika masih di KHS:**

- Trigger: `BlocListener` di `KhsDetailPage` saat `state.downloadStatus==success && filePath!=null && ModalRoute.of(context).isCurrent==true`.
- Layout: Material 3 `AlertDialog` — icon `check_circle` (success color), title `Unduhan selesai`, content: `KHS_2024_2025_GANJIL.pdf` (bold) + `Tersimpan di Documents/LoncengUnMan/KHS` (caption) + hint `Tap Buka untuk melihat`. Path lengkap tidak ditampilkan penuh — hanya dirName singkat; detail via long-press copy jika perlu (opsional).
- Actions: **Tutup** (dismiss) + **Buka** (primary, `OpenFilex.open(filePath)`). Share tidak perlu di modal (sudah ada di notifikasi).
- Jika `!isCurrent` atau `!mounted` → jangan tampilkan dialog, hanya notifikasi.

**Tombol unduh existing:**

- Tetap `FilledButton.icon` / `KhsDownloadIcon` di info card. Saat `downloading` → ganti jadi `CircularProgressIndicator` 20px + `onPressed=null` (blocking). Tidak ada penambahan tombol baru di v1.

### 4.5 Error Handling, Izin & Edge Cases (DISETUJUI)

| Kasus | Handling |
|-------|----------|
| Kredensial kosong | `DownloadStatus.error` + (jika izin) `showError(reason: "Kredensial tidak ditemukan")` tanpa action Coba Lagi + `ErrorHandler.show("Silakan login ulang")`. Tidak tampil dialog sukses. |
| Izin storage ditolak | `KhsPdfService._checkStoragePermission()` → `ServerException("Izin penyimpanan diperlukan…")` → `showError` + `ErrorHandler.show`. |
| Izin POST_NOTIFICATIONS denied | Soft-gate: `ensurePermission()==false` → tetap unduh file (file tetap tersimpan di `Documents/LoncengUnMan/KHS/`), skip `showOngoing/Completed/Error`, hanya `DownloadStatus` + toast + dialog jika di KHS. Tidak ada dialog blocking "Aktifkan di Pengaturan". |
| Network error / timeout | `NetworkException` → `showError(reason: "Tidak ada koneksi" / "Koneksi timeout")` + action **Coba Lagi** (retry panggil `downloadPdf` lagi dengan semester terakhir). Persistent sampai swipe/tap. |
| HTTP 401/404/5xx | `AuthException`/`ServerException` → `showError(reason: message)` + toast. 401 tetap throw AuthException (sudah di-handle manual di `KhsPdfService` dengan `http.Client` langsung — tidak via `ApiClient` onAuthError). |
| User swipe notifikasi ongoing | Di Android 14+ ongoing bisa di-swipe di beberapa OEM — tidak fatal. Setelah `download()` selesai, `showCompleted`/`showError` tetap muncul (ID sama), user tetap dapat notifikasi akhir. |
| Tap Buka tapi tidak ada viewer | `OpenFilex.open()` → `ResultType.noAppToOpen` → fallback `ErrorHandler.show("Tidak ada aplikasi untuk membuka PDF")`. File tetap ada. |
| Tap Bagikan | `Share.shareXFiles([XFile(filePath)])` — system share sheet. Jika file hilang → toast "Berkas tidak ditemukan". |
| Coba Lagi | Callback ke cubit `downloadPdf(lastSemester, context: null)` — notifikasi diganti lagi ke ongoing → flow ulang. `lastSemester` disimpan di controller saat `showOngoing`. |
| Concurrent tap (double-tap) | Guard `if (downloadStatus==downloading) return` di awal `downloadPdf()` — tap kedua diabaikan, tombol sudah disabled via `buildWhen`. |
| App background / pindah halaman | `ModalRoute.isCurrent==false` → skip dialog. Notifikasi tetap tampil (ongoing→completed/error). Tap notifikasi tetap bisa Buka/Bagikan dari mana saja via global handler. |

**Research Android per versi (verifikasi langsung 2026-09-05):**

| Versi | Dampak ke fitur ini |
|-------|---------------------|
| Android 8 (API 26) | Channel wajib — dipenuhi via `NotificationChannel.downloads` auto-create di `initialize()` loop `values`. |
| Android 12 (API 31) | `SCHEDULE_EXACT_ALARM` — tidak relevan (kita tidak pakai exact alarm untuk download, hanya `show()` biasa). |
| Android 13 (API 33) | `POST_NOTIFICATIONS` runtime permission — notifikasi (termasuk ongoing) **tidak tampil sama sekali** jika denied. Alasan soft-gate wajib. |
| Android 14 (API 34) | (1) ForegroundService type wajib — **tidak berlaku** (kita TIDAK pakai ForegroundService, cuma `show(ongoing:true)` biasa, jadi tidak perlu `FOREGROUND_SERVICE_DATA_SYNC`). (2) Ongoing kini bisa di-swipe di beberapa OEM — handle dengan cancel&re-show ID sama. `targetSdk` app saat ini 34 → sudah aman. |
| Android 15 (API 35) | Edge-to-edge enforcement — tidak terkait notifikasi. |
| Android 16 (API 36) | Dok resmi `behavior-changes-16` (dibaca langsung): edge-to-edge opt-out dihapus, predictive back default, adaptive layout, health permission granular — **nol perubahan untuk `NotificationManager`/`NotificationChannel`/`POST_NOTIFICATIONS`**. Live Updates / quota / STOP action adalah preview belum final — belum wajib untuk `targetSdk 36`. Jika bump targetSdk ke 36 nanti, desain download tidak perlu revisi. |

Implikasi: tetap pakai `flutter_local_notifications` `show()` dengan `AndroidNotificationDetails(ongoing:true, autoCancel:false)` untuk mengunduh → lalu `show()` lagi ID sama `ongoing:false, autoCancel:true` untuk selesai/error (tanpa ForegroundService). `compileSdk 37 / targetSdk 34` aman.

### 4.6 Testing & Kriteria Sukses (DISETUJUI)

**Strategi testing (hand-written fakes, `blocTest`, `flutter_test` — konsisten existing):**

| Layer | Skenario |
|-------|----------|
| Unit — `DownloadNotificationController` | `ensurePermission` (granted/denied), `showOngoing` panggil `plugin.show(id:7001, ongoing:true)`, `showCompleted` update ID sama dengan actions Buka/Bagikan, `showError` dengan Coba Lagi, `cancel`, `handleResponse` routing `open/share/retry` (fake `FlutterLocalNotificationsPlugin` seperti `test/core/services/notification_service_test.dart`). |
| Unit — `KhsDetailCubit.downloadPdf` | Guard blocking (tap saat `downloading` → ignore), soft-gate false → cubit tetap `success` tanpa panggil controller, success path → emit `downloading→success` + `downloadedFilePath` terisi + controller `showCompleted` terpanggil, error path → `error` + `showError`, kredensial kosong → `error` tanpa panggil service. |
| Widget — `KhsDetailPage` dialog | `BlocListener` trigger `AlertDialog` hanya saat `success && isCurrent==true`; tidak trigger saat `!isCurrent` (mock `ModalRoute`). Dialog menampilkan `fileName` + lokasi singkat + tombol Buka/Tutup. |
| Widget — tombol | Tetap disabled + spinner saat `downloading` (regression check). |

Tidak menambah Patrol E2E untuk v1 — unduhan butuh kredensial real & file I/O; cukup unit+widget.

**Kriteria sukses (acceptance):**

1. Tekan unduh di KHS → muncul notifikasi `Mengunduh…` (`ongoing:true`) yang tidak hilang sampai selesai (di Android 13 ke bawah tidak bisa di-swipe; di 14+ jika ke-swipe, notifikasi selesai tetap muncul).
2. Setelah selesai → notifikasi berganti ke `Unduhan selesai — KHS_...pdf — Tersimpan di Documents/LoncengUnMan/KHS` dengan actions **Buka** & **Bagikan**; tap Buka → PDF terbuka; tap Bagikan → share sheet; keduanya persistent sampai swipe/tap.
3. Jika masih di KHS → `AlertDialog` sukses tampil (fileName+lokasi+hint) dengan tombol Buka/Tutup; jika sudah pindah/background → tidak ada dialog, hanya notifikasi.
4. Jika gagal → notifikasi `Unduhan gagal — <reason>` + **Coba Lagi** yang retry; jika `POST_NOTIFICATIONS` denied → file tetap terunduh & dialog/toast tetap tampil (tanpa notifikasi).
5. Tap kedua saat masih downloading → diabaikan (blocking sequential).
6. `dart analyze` 0 error, existing tests tetap hijau.

### 4.7 Risiko, File Map & Estimasi (DISETUJUI)

**Risiko & mitigasi:**

| Risiko | Mitigasi |
|--------|----------|
| `POST_NOTIFICATIONS` denied → user kira unduh gagal | Soft-gate + toast + dialog tetap; file tetap tersimpan. |
| `open_filex` butuh `<queries>` VIEW pdf | Tambah `<queries><intent VIEW type application/pdf>` di Manifest saat implement. |
| Payload `filePath` hilang (app kill sebelum tap) | `handleResponse` guard `File.existsSync` → toast "Berkas tidak ditemukan" jika hilang. |
| Double `showDialog` jika `success` emit 2× | Listener guard `listenWhen: previous.downloadStatus != current.downloadStatus` + cek `downloadedFilePath != null`. |
| Channel `downloads` tidak ter-create di device lama | `NotificationService.initialize()` loop `values` sudah handle semua channel; tambah enum cukup. |
| ID `7001` tabrakan dengan jadwal `computeId` | `computeId` = `hashCode & 0x7FFFFFFF` (31-bit, probabilistik) sedangkan `7001` di bawah 10k — ruang jadwal praktis ≥5 digit, tapi amankan dengan guard: `DownloadNotificationController.notificationId` dipilih dari range `7000–7999` yang di-reserve untuk download dan didokumentasi di `notification_config.dart` agar jadwal tidak pakai range tersebut. Alternatif: pakai `8000+` sentinel yang tidak mungkin keluar dari `computeId` untuk courseName normal. |
| `Services.performFullLogout()` `cancelAll()` menghapus notifikasi download | Sebelumnya `NotificationService.cancelAll()` menghapus **semua** notifikasi termasuk download `7001` — tidak diinginkan jika user logout saat download selesai masih tampil. Saat implement, ubah `performFullLogout` menjadi cancel selektif untuk `classReminders` saja, atau setelah `cancelAll` re-show tidak diperlukan karena logout juga clear cache; cukup dokumentasi: `performFullLogout` tetap `cancelAll` (menghapus tray termasuk download selesai) — diterima karena logout adalah reset total. |

**File map final:**

| Status | File |
|--------|------|
| Baru | `lib/features/khs/data/services/khs_download_notification_controller.dart` |
| Baru (enum) | `lib/core/constants/notification_config.dart` — tambah `NotificationChannel.downloads` |
| Ubah | `lib/core/services/notification_service.dart` — thin-wrapper + `onDidReceiveNotificationResponse` |
| Ubah | `lib/features/khs/presentation/cubit/khs_detail_cubit.dart` + `khs_detail_state.dart` — enrich state + panggil controller |
| Ubah | `lib/features/khs/presentation/pages/khs_detail_page.dart` — `BlocListener` AlertDialog sukses |
| Ubah | `lib/core/constants/app_strings.dart` — strings ongoing/selesai/error + action labels + dialog |
| Ubah | `lib/main.dart` — registrasi controller di DI |
| Ubah | `android/app/src/main/AndroidManifest.xml` — `<queries VIEW pdf>` jika perlu |
| Tambah dep | `pubspec.yaml` — `open_filex` + `share_plus` |
| Tidak diubah | `khs_pdf_service.dart` (v1), `khs_download_icon.dart`/`khs_download_button.dart`, `year_picker_sheet.dart`, `khs_app_bar_title.dart`, router, cache, model/DS |

**Estimasi implementasi (untuk writing-plans):**

- Fase 1: `pubspec` deps + `notification_config` channel baru (reserve range 7000–7999) + `notification_service` wrapper + `DownloadNotificationController` baru.
- Fase 2: `khs_detail_state` enrich (`downloadedFileName/FilePath` + `==`/`hashCode` di 3 subclass + `_emitWithFetching` ikut meneruskan) + `khs_detail_cubit` wiring soft-gate & controller calls.
- Fase 3: `khs_detail_page` `BlocListener` AlertDialog + `app_strings` + Manifest queries.
- Fase 4: `main.dart` DI registrasi + `performFullLogout` dokumentasi `cancelAll` vs download tray + `flutter analyze` + unit/widget tests.

## 5. Pertanyaan Terbuka

Tidak ada. Semua keputusan (B, C, C+AlertDialog, A blocking, soft-gate + error persistent + Coba Lagi, Pendekatan 2, research Android 26→36) disetujui per seksi 1/7 s/d 7/7. Jika `open_filex` vs `open_file` atau `share_plus` versi perlu penyesuaian saat implement, cukup sesuaikan di Fase 1 tanpa ubah kontrak.

## 6. Self-Review

- Placeholder/TBD: tidak ada.
- Kontradiksi internal: tidak ada — `showOngoing` indeterminate konsisten dengan `KhsPdfService` non-streaming; blocking sequential konsisten dengan ID tunggal `7001`; soft-gate konsisten dengan tabel error.
- Scope: fokus — 1 file baru + 1 enum + 6 file ubah + 2 dep ringan; tidak menyentuh background isolate, tidak ubah posisi tombol, tidak ubah backend.
- Ambiguitas: `ModalRoute.isCurrent` vs `mounted` diputuskan eksplisit di §4.4/4.5; `Coba Lagi` tanpa kredensial diputuskan tanpa action; `ongoing` di 14+ diputuskan handle via re-show.
