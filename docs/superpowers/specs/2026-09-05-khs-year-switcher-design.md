# Desain: KHS Year Switcher — Fix Parser + Normalisasi Writer + Fetch Manual

- Tanggal: 2026-09-05
- Lokasi: `docs/superpowers/specs/2026-09-05-khs-year-switcher-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go (BE) tidak diubah.
- Status: Disetujui per seksi 1/4 s/d 4/4 di sesi brainstorming (Opsi 2 tanpa migrasi + bottomsheet sederhana + tombol fetch manual).
- Supersedes: `2026-08-31-khs-pdf-download-year-switcher-design.md` (bagian KHS switcher).
- Terkait: `lib/features/khs/`, `lib/core/cache/academic_cache_service.dart`, `lib/core/routes/app_router.dart`, `lib/features/data_initialization/`.

## 1. Latar Belakang & Masalah

### 1.1 Ringkasan bug

Halaman KHS tidak bisa switch tahun ajaran — tombol tahun di AppBar (`YearSwitcherButton`, key `year_switcher_button`) **tidak muncul sama sekali** (`SizedBox.shrink()`).

### 1.2 Akar penyebab (terbukti via audit file actual)

Regresi di commit `f3d1f98 feat(khs,build,test): simplify KHS cubit`:

| File | Sebelum (`3ad3c3a`, BENAR) | Sesudah (`f3d1f98`, SALAH) |
|------|-----------------------------|-----------------------------|
| `khs_detail_cubit.dart:152` | `item['tahun_ajaran']` snake + handle `Map{awal,akhir} → "2024/2025"` | `item['tahunAjaran'] as String?` camel → selalu `null` |
| `khs_detail_state.dart` | `isFetching` ada | `isFetching` dihapus, `KhsDetailLoading ==` hanya `identical` (ignore fields) |
| `khs_detail_cubit.dart` | `_fetchSemester()` auto-fetch `GetKhs` saat cache miss | Dihapus → cache miss permanen |

Writer `KhsRemoteDataSource.getSemesters()` tetap `saveKhsList(npm, semesters mentah)` dengan key `tahun_ajaran` snake (sesuai `KhsSemesterModel.fromJson` yang baca `tahun_ajaran`). Reader diubah ke camel tanpa mengubah writer → `years={}` → `availableYears=[]` → `if(empty) return SizedBox.shrink()`.

### 1.3 Bug sekunder

- **Race `KhsDetailPage.initState()`**: `cubit.loadAvailableYears()` dan `cubit.loadAll()` di-fire tanpa `await`, saling `emit` dan timpa.
- **Equality `KhsDetailLoading` rusak**: `operator ==` ignore `selectedTahunAjaran/availableYears/downloadStatus/isFetching` → `BlocBuilder` bisa skip rebuild.
- Tidak ada jalur fetch manual — tahun kosong tampil `Belum ada data KHS` tanpa aksi.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Normalisasi writer: `KhsRemoteDataSource.getSemesters()` simpan `khsList` dengan key **`tahunAjaran` camelCase** (`"2024/2025"`), konversi `Map{awal,akhir}` di writer.
2. Reader clean: `KhsDetailCubit.loadAvailableYears()` baca `tahunAjaran` camel saja.
3. Tidak perlu migrasi cache lama — status masih develop, cache boleh dihapus via reinstall; fresh install langsung pakai kontrak baru.
4. Perbaiki `KhsDetailState` equality & tambah `isFetching`.
5. Serialize `KhsDetailPage.initState()` agar tidak race.
6. Sederhanakan `YearPickerSheet`: tanpa tombol Pilih/Batal, tanpa radio/check — tap item langsung `selectYear` + auto-close.
7. Tambah tombol **Muat KHS** di empty-state per-tab untuk fetch manual tahun yang belum ada di cache.

### 2.2 Non-Tujuan

- Tidak mengubah `AcademicCacheService` box structure (tetap `academic` box, key `khs`/`khsList` per NPM).
- Tidak mengubah `ApiClient`, `credential_body` (kecuali dokumentasi), `DataInit` pipeline loop, `Home` `pushNamed`, `AppRouter` path.
- Tidak persist migrasi Hive untuk cache lama.
- Tidak auto-fetch di `selectYear` — hanya tombol manual (sesuai requirement `A`).

## 3. Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Strategi cache | **A** cache-only; fetch hanya via tombol manual di UI empty. |
| 2 | Fix parser | **Opsi 2 tanpa migrasi**: normalisasi di writer (`getSemesters`), reader clean camel. |
| 3 | BottomSheet | **Sederhana**: list tahun doang, tap = `Navigator.pop` + `onYearSelected`, tanpa Pilih/Batal/radio/check. |
| 4 | Fetch manual | Tombol `Muat KHS <tahun>` di empty-state per-tab, `isFetching` guard. |
| 5 | Scope file | 5 file sumber + 1 widget sheet; tidak sentuh auth/home/router. |

## 4. Desain Rinci

### 4.1 Arsitektur & Data Flow (DISETUJUI)

**Writer normalisasi (inti Opsi 2):**

```dart
// khs_remote_data_source.dart — getSemesters()
final response = await apiClient.post('/api/v1/lms/khs/semesters', body: ...);
final rawSemesters = (response['semesters'] as List<dynamic>? ?? []);
final normalized = rawSemesters.map((e) {
  final m = e as Map<String, dynamic>;
  final taRaw = m['tahun_ajaran'];
  final tahunAjaran = taRaw is Map<String, dynamic>
      ? '${taRaw['awal']}/${taRaw['akhir']}'
      : taRaw as String? ?? '';
  return {'tahunAjaran': tahunAjaran, 'semester': m['semester'] as String? ?? '', 'sks': m['sks'] as int? ?? 0};
}).toList();
await academicCacheService.saveKhsList(npm: npm, data: normalized);
return normalized.map((e) => KhsSemesterModel.fromJson(e)).toList();
```

Kontrak cache baru: `khsList = List<Map{tahunAjaran: "2024/2025", semester: "GANJIL", sks: 20}>`.

**Model:**

```dart
// khs_model.dart — KhsSemesterModel.fromJson
factory KhsSemesterModel.fromJson(Map<String, dynamic> json) {
  final ta = json['tahunAjaran'] ?? json['tahun_ajaran'];
  final tahunAjaran = ta is Map<String, dynamic>
      ? '${ta['awal']}/${ta['akhir']}'
      : ta as String? ?? '';
  return KhsSemesterModel(tahunAjaran: tahunAjaran, ...);
}
```
Fallback `tahun_ajaran` dipertahankan untuk kompatibilitas fresh pipeline sebelum reinstall (tidak dianggap migrasi).

**Cubit:**

- `loadAvailableYears()`: `item['tahunAjaran'] as String?` saja.
- `selectYear(String y)`: `_selectedTahunAjaran = y; emit(Loading(y)); await loadAll();`
- `fetchMissingYear()` (baru, pakai `_selectedTahunAjaran` saat ini — sesuai tombol `Muat KHS <tahun>`): guard `if(_isFetching) return`; `_isFetching=true; emit(_emitWithFetching())`; loop `['GANJIL','GENAP']` → `_getKhs.download/extract/call(forceRefresh:true, tahunAjaran:_selectedTahunAjaran)`; kumpulkan error tanpa break; `_isFetching=false; await loadAll();`; catch → `handleError` + `ErrorHandler.show` (butuh `BuildContext?` optional) + reset `isFetching`.
- Inject `GetKhs? getKhs` optional ctor (`?? Services.get<GetKhs>()`).

**State:**

```dart
abstract class KhsDetailState {
  const KhsDetailState({required this.selectedTahunAjaran, required this.availableYears, required this.downloadStatus, this.isFetching = false});
  final bool isFetching;
}
class KhsDetailLoading extends KhsDetailState {
  const KhsDetailLoading({super.selectedTahunAjaran = '', super.availableYears = const [], super.downloadStatus = DownloadStatus.idle, super.isFetching = false});
  @override bool operator ==(...); // include semua fields
  @override int get hashCode => Object.hash(...);
}
class KhsDetailLoaded extends KhsDetailState { // tambah isFetching
  const KhsDetailLoaded({required this.ganjilData, required this.genapData, required super.selectedTahunAjaran, required super.availableYears, required super.downloadStatus, super.isFetching});
}
class KhsDetailError extends KhsDetailState { // tambah isFetching
  const KhsDetailError({this.ganjilError, this.genapError, required super.selectedTahunAjaran, required super.availableYears, required super.downloadStatus, super.isFetching});
}
```

**Page lifecycle:**

```dart
// khs_detail_page.dart — initState serialize
@override void initState() {
  super.initState();
  _tabController = TabController(...);
  _tabController.addListener(_onTabChanged);
  Future.microtask(() async {
    final cubit = context.read<KhsDetailCubit>();
    await cubit.loadAvailableYears();
    if (!mounted) return;
    await cubit.loadAll();
  });
}
```

### 4.2 Komponen & UI (DISETUJUI — revisi bottomsheet sederhana)

| File | Perubahan |
|------|-----------|
| `lib/features/khs/data/datasources/khs_remote_data_source.dart` | Normalisasi `semesters` sebelum `saveKhsList`; return `KhsSemesterModel` dari normalized. |
| `lib/features/khs/data/models/khs_model.dart` | `fromJson` primary `tahunAjaran`, fallback `tahun_ajaran` + `Map{awal,akhir}`. |
| `lib/features/khs/presentation/cubit/khs_detail_cubit.dart` | Reader clean `tahunAjaran`; tambah `isFetching`, `fetchMissingYear`; fix `selectYear`; inject `GetKhs?`. |
| `lib/features/khs/presentation/cubit/khs_detail_state.dart` | Fix `KhsDetailLoading ==/hashCode` include fields; tambah `isFetching`. |
| `lib/features/khs/presentation/pages/khs_detail_page.dart` | Serialize `initState`; empty-state per-tab + tombol `Muat KHS <tahun>` (key `khs_fetch_year_button`, `isFetching`→spinner); `YearSwitcherButton` disable saat fetching. |
| `lib/features/khs/presentation/widgets/year_picker_sheet.dart` | **REVISI**: hanya `Column[DragHandle, Title "Pilih Tahun Ajaran", Divider, List<String> years]`. Tiap tahun `ListTile(title: Text(year, style: isSelected ? bold+cs.primary : normal), onTap: (){Navigator.pop(context); onYearSelected(year);})`. Tanpa `StatefulBuilder/tempSelected`, tanpa trailing check/circle, tanpa `Row[Pilih/Batal]`. `maxHeight 0.6*screen`, `Flexible+SingleChildScrollView`. |
| `lib/features/khs/presentation/widgets/year_switcher_button.dart` | Tidak ubah. |

**Flow tap:** `YearSwitcherButton tap → YearPickerSheet → tap "2023/2024" → pop → cubit.selectYear("2023/2024") → emit Loading → loadAll() → Tab rebuild (AppBar title ikut state).`

**Empty-state baru:**

```dart
// di _buildEmptyState — butuh selectedTahunAjaran + isFetching dari state
if (data == null) return Column(children: [
  Icon(school_outlined), Text('Belum ada data KHS $selectedTahunAjaran'),
  FilledButton(
    key: Key('khs_fetch_year_button'),
    onPressed: isFetching ? null : () => cubit.fetchMissingYear(),
    child: isFetching ? CircularProgressIndicator() : Text('Muat KHS $selectedTahunAjaran'),
  ),
]);
```

### 4.3 Error Handling & Edge Cases (DISETUJUI)

| Kasus | Handling | UI |
|------|----------|----|
| `khsList == null` / `[]` | `loadAvailableYears` early return → `availableYears=[]` → switcher hidden (benar). | Hanya title `KHS ...` di AppBar. |
| Tahun dipilih tapi `loadKhsDataSemester==null` untuk GANJIL & GENAP | Empty-state per-tab + tombol `Muat KHS <tahun>` enabled. | Tap → fetching. |
| `fetchMissingYear` gagal (`NetworkException`/`ServerException`) | `handleError` + `ErrorHandler.show` toast Indonesian; `isFetching=false`; tidak crash. | Toast + tombol retry enabled. |
| Sebagian gagal (GANJIL sukses, GENAP 404) | Loop tidak break; setelah loop `loadAll()` ulang — tab sukses tampil, gagal tetap empty. | Per-tab independen. |
| `401 AuthException` | `ApiClient.onAuthError → performFullLogout()` + `authRedirect` ke login. | Redirect login. |
| Double tap fetch | `if(_isFetching) return` guard; tombol `onPressed:null` saat fetching. | Spinner. |
| Key `_khsKey = "$tahunAjaran_$semester"` | Selalu `"2024/2025_GANJIL"` upper semester; writer normalized jamin konsistensi. | Tidak mismatch. |

### 4.4 Testing & Acceptance Criteria (DISETUJUI)

| Layer | Skenario | Expected |
|------|----------|----------|
| Unit Cubit | `loadAvailableYears` dengan `khsList=[{tahunAjaran:"2024/2025"}]` | `availableYears==["2024/2025"]` |
| | `loadAvailableYears` null | `[]`, tidak throw |
| | `selectYear("2023/2024")` | `selectedTahunAjaran` berubah, emit Loading tahun baru |
| | `fetchMissingYear` sukses (mock GetKhs) | `isFetching true→false`, `loadAll` ulang, tab terisi |
| | `fetchMissingYear` NetworkException | `isFetching false`, toast, tidak crash |
| | Guard `isFetching` | panggilan kedua early return |
| | `KhsDetailLoading` equality | `Loading("2024/2025") != Loading("2023/2024")` |
| Unit Model/DS | `getSemesters` raw `tahun_ajaran:{awal,akhir}` | `saveKhsList` terima `tahunAjaran:"2024/2025"` |
| | `KhsSemesterModel.fromJson({tahunAjaran})` | parse benar |
| | `fromJson({tahun_ajaran:{awal,akhir}})` fallback | tetap parse |
| Widget | `YearPickerSheet` tap item | `onYearSelected` + auto-close, tanpa Pilih/Batal |
| | `YearSwitcherButton` `availableYears=[]` | `SizedBox.shrink` |
| | Empty tahun → tombol Muat KHS | tap trigger `fetchMissingYear` |
| Manual | Fresh install → login → Lihat KHS | Switcher muncul semua tahun LMS; tap ganti tahun → tab berubah tanpa reinstall |
| | Tahun kosong → Muat KHS offline | Toast error, retry enabled |
| Static | `flutter analyze` | 0 error |

## 5. File yang Disentuh & Tidak Disentuh

**Diubah (6 file sumber):**

- `lib/features/khs/data/datasources/khs_remote_data_source.dart`
- `lib/features/khs/data/models/khs_model.dart`
- `lib/features/khs/presentation/cubit/khs_detail_cubit.dart`
- `lib/features/khs/presentation/cubit/khs_detail_state.dart`
- `lib/features/khs/presentation/widgets/year_picker_sheet.dart`
- `lib/features/khs/presentation/pages/khs_detail_page.dart` (serialize + empty-state tombol)

**Tidak diubah:** `lib/core/cache/academic_cache_service.dart` (struktur box tetap), `lib/core/utils/credential_body.dart`, `lib/features/khs/presentation/widgets/year_switcher_button.dart`, `lib/core/routes/app_router.dart`, `lib/features/home/`, `ApiClient`, `DataInit`.

**Dihapus:** Tidak ada file hapus (hanya refactor `YearPickerSheet` dari `StatefulBuilder` ke `StatelessWidget` sederhana).

## 6. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Fresh install cache lama masih snake jika belum reinstall | Fallback `tahun_ajaran` di model handle; instruksi reinstall untuk dev. |
| `fetchMissingYear` spam network | `isFetching` guard + tombol disabled. |
| `selectYear` dipanggil cepat berurutan | `loadAll` sequential `await Future.wait` GANJIL/GENAP, last write wins. |
| BottomSheet tanpa konfirmasi — salah tap | Risiko rendah; tap langsung ganti tahun adalah yang diinginkan (sesuai request). |

## 7. Estimasi Implementasi (untuk writing-plans)

- Fase 1: `khs_remote_data_source.dart` + `khs_model.dart` (writer normalisasi) + verifikasi `saveKhsList` contract.
- Fase 2: `khs_detail_state.dart` + `khs_detail_cubit.dart` (fix equality, loadAvailableYears, selectYear, fetchMissingYear).
- Fase 3: `khs_detail_page.dart` + `year_picker_sheet.dart` (serialize initState, empty-state tombol, sheet sederhana).
- Fase 4: Test + `flutter analyze` + manual fresh install → switch tahun.

## 8. Pertanyaan Terbuka

Tidak ada. Semua keputusan (Opsi 2 tanpa migrasi, bottomsheet sederhana, tombol fetch manual `A`) disetujui per seksi 1-4.
