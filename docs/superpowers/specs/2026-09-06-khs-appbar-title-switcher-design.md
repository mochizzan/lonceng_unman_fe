# Desain: KHS AppBar Title sebagai Switcher Tahun Ajaran

- Tanggal: 2026-09-06
- Lokasi: `docs/superpowers/specs/2026-09-06-khs-appbar-title-switcher-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go tidak diubah.
- Status: Disetujui per seksi 1/5 s/d 5/5 di sesi brainstorming (Opsi 2 — Widget Baru + Hapus Lama).
- Supersedes: Bagian AppBar di `2026-09-05-khs-year-switcher-design.md` (duplikasi title vs switcher). Writer `tahunAjaran` camelCase + state `isFetching` + fetch manual di spec 2026-09-05 tetap berlaku sebagai referensi dan tidak diduplikasi di sini.
- Terkait: `lib/features/khs/presentation/pages/khs_detail_page.dart`, `lib/features/khs/presentation/widgets/year_picker_sheet.dart`, `lib/features/khs/presentation/widgets/year_switcher_button.dart` (akan dihapus), `lib/features/khs/presentation/widgets/khs_app_bar_title.dart` (baru).

## 1. Latar Belakang & Masalah

AppBar `KhsDetailPage` saat ini duplikasi:

- `AppBar.title`: `Text("KHS 2024/2025")` dari `state.selectedTahunAjaran`.
- `AppBar.actions`: `YearSwitcherButton(tahunAjaran: "2024/2025", availableYears: [...])` yang render `Text("2024/2025") + Icon(arrow_drop_down)` dan membuka `YearPickerSheet`.

Hasil: string `"2024/2025"` muncul dua kali (kiri sebagai title, kanan sebagai tombol), menambah lebar AppBar, membingungkan mana yang tappable, dan menambah satu widget + key (`year_switcher_button`) yang sebenarnya mubazir.

Request: hapus duplikasi — jadikan **title AppBar itu sendiri tombol switch** (tappable, ada icon switch di kanan title). `YearPickerSheet` sudah disederhanakan di spec 2026-09-05 (tap item langsung `pop + selectYear`, tanpa Pilih/Batal/radio).

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. Title AppBar menampilkan `KHS 2024/2025 ▾` (format A) — satu-satunya tempat tahun tampil — dengan icon `arrow_drop_down` di kanan teks.
2. Seluruh title tappable (A) — hit area luas (teks + icon), bukan hanya icon — membuka `YearPickerSheet` yang sama.
3. Saat `availableYears` kosong, title tetap render dan tetap tappable (B) — sheet tampil empty state `Belum ada tahun ajaran` alih-alih `SizedBox.shrink`.
4. Hapus `YearSwitcherButton` sepenuhnya (Opsi 2 — bersih) dan ganti dengan `KhsAppBarTitle`; `AppBar.actions` jadi kosong.
5. `YearPickerSheet` tanpa ubah kontrak utama — hanya tambah cabang `years.isEmpty`.

### 2.2 Non-Tujuan

- Tidak mengubah `KhsDetailCubit` / `KhsDetailState` / `KhsRemoteDataSource` / `KhsModel` / `AcademicCacheService` / `AppRouter` / `GetKhs` / `HomePage` `pushNamed`. Semua sudah benar di spec 2026-09-05.
- Tidak mengubah writer `tahunAjaran` camelCase, `isFetching`, maupun tombol `Muat KHS` di body.
- Tidak menambah chip/pill/background pada title (C ditolak) dan tidak menambah animasi AppBar kustom.
- Tidak menambah persistensi/migrasi cache.

## 3. Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Format title | **A — `KHS 2024/2025 ▾`** (prefix KHS tetap, tahun + icon panah 1 baris). |
| 2 | Empty (`availableYears == []`) | **B — selalu tappable, icon tetap, sheet empty** dengan pesan. Tidak `SizedBox.shrink`. |
| 3 | Interaksi tappable | **A — seluruh title (teks + icon) tappable** via `InkWell`/`TextButton`, ripple subtle, `Row(mainAxisSize: min)`. `actions` kosong. |
| 4 | Pendekatan | **Opsi 2 — Widget Baru + Hapus Lama** (bukan reuse Opsi 1, bukan AppBar kustom Opsi 3). |
| 5 | Scope file | 1 baru + 1 hapus + 1 ubah utama + 1 ubah ringan; cubit/model/DS tidak disentuh. |

## 4. Desain Rinci

### 4.1 Arsitektur (DISETUJUI)

Sebelum:

```
KhsDetailPage AppBar:
  title: BlocBuilder → Text("KHS 2024/2025")
  actions: BlocBuilder → YearSwitcherButton("2024/2025" + ▾)
              └─ _showYearPicker → showModalBottomSheet(YearPickerSheet)
```

Sesudah (Opsi 2):

```
KhsDetailPage AppBar:
  title: BlocBuilder → KhsAppBarTitle(
           tahunAjaran: state.selectedTahunAjaran,
           availableYears: state.availableYears,
           isFetching: state.isFetching,
           onYearSelected: (y) => cubit.selectYear(y),
         )
           └─ Row[Text("KHS 2024/2025", bold), Icon(arrow_drop_down)] + InkWell
           └─ onTap → showModalBottomSheet(YearPickerSheet) — tanpa guard isEmpty
  actions: []  // duplikasi hilang
```

File map:

| Status | File | Keterangan |
|--------|------|------------|
| Baru | `lib/features/khs/presentation/widgets/khs_app_bar_title.dart` | Widget title tappable, reusable hanya di KHS. |
| Hapus | `lib/features/khs/presentation/widgets/year_switcher_button.dart` | Beserta export di barrel jika ada. |
| Ubah | `lib/features/khs/presentation/pages/khs_detail_page.dart` | `AppBar.title` → `KhsAppBarTitle`, `actions: []`, hapus import lama. |
| Ubah ringan | `lib/features/khs/presentation/widgets/year_picker_sheet.dart` | Cabang `years.isEmpty` → empty state. |
| Tidak diubah | `khs_detail_cubit.dart`, `khs_detail_state.dart`, `khs_remote_data_source.dart`, `khs_model.dart`, `academic_cache_service.dart`, `app_router.dart`, `get_khs.dart` | Sudah sesuai spec 2026-09-05. |

Kontrak key: `Key('khs_app_bar_title')` menggantikan `Key('year_switcher_button')`. String `"2024/2025"` hanya muncul sekali di AppBar (di title).

### 4.2 Komponen & Data Flow (DISETUJUI)

**`KhsAppBarTitle` (baru):**

```dart
class KhsAppBarTitle extends StatelessWidget {
  const KhsAppBarTitle({
    super.key, // Key('khs_app_bar_title')
    required this.tahunAjaran,
    required this.availableYears,
    required this.onYearSelected,
    this.isFetching = false,
  });

  final String tahunAjaran;
  final List<String> availableYears;
  final ValueChanged<String> onYearSelected;
  final bool isFetching;
}
```

- Build: `InkWell(onTap: _showSheet, borderRadius: radius3XL, child: Row(mainAxisSize: min, children: [Text("KHS $tahunAjaran", style: bold + onSurface), SizedBox(width: 4), Icon(Icons.arrow_drop_down, size: iconSM, color: onSurface)]))`. Hit area seluruh Row, bukan hanya icon. Tidak ada chip/pill.
- `_showSheet(BuildContext context)`: `showModalBottomSheet<void>(context: context, isScrollControlled: true, shape: RoundedRectangleBorder(top: Radius.circular(radiusLG)), builder: (_) => YearPickerSheet(years: availableYears, selectedYear: tahunAjaran, onYearSelected: onYearSelected))` — tanpa guard `isEmpty`, sehingga B terpenuhi. Tidak ada `Navigator.pop` di caller (sheet yang pop).
- Optional: jika `isFetching` ingin disable, bisa bungkus `IgnorePointer` — keputusan saat ini tetap enabled (lihat §4.3).

**`YearPickerSheet` (ubah ringan):**

```dart
if (years.isEmpty) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.info_outline, color: cs.onSurfaceVariant),
      SizedBox(height: 8),
      Text("Belum ada tahun ajaran", style: TextStyle(color: cs.onSurfaceVariant)),
    ],
  );
}
// existing: Flexible > SingleChildScrollView > Column > ListTile(onTap: () { Navigator.pop(context); onYearSelected(year); })
```

Tetap tanpa `StatefulBuilder`/`tempSelected`, tanpa Pilih/Batal, tanpa trailing check/circle, `maxHeight 0.6*screen`, `Flexible+SingleChildScrollView`. Highlight selected tetap `bold + cs.primary` pada Text saja.

**`KhsDetailPage` (ubah utama):**

```dart
appBar: AppBar(
  title: BlocBuilder<KhsDetailCubit, KhsDetailState>(
    builder: (context, state) => KhsAppBarTitle(
      key: const Key('khs_app_bar_title'),
      tahunAjaran: state.selectedTahunAjaran,
      availableYears: state.availableYears,
      isFetching: state.isFetching,
      onYearSelected: (year) => context.read<KhsDetailCubit>().selectYear(year),
    ),
  ),
  actions: const [], // sebelumnya YearSwitcherButton
  // bottom: TabBar tetap
),
```

Lain-lain di page tetap: `initState` serialize `Future.microtask(() async { await cubit.loadAvailableYears(); if(!mounted) return; await cubit.loadAll(); })`, body `TabBarView` dengan empty `Muat KHS` + `fetchMissingYear`.

**Flow klik:**

```
Tap title "KHS 2024/2025 ▾"
  → KhsAppBarTitle._showSheet → showModalBottomSheet(YearPickerSheet)
    → tap "2023/2024" → YearPickerSheet: Navigator.pop(context); onYearSelected("2023/2024")
      → KhsDetailCubit.selectYear("2023/2024") → emit KhsDetailLoading → loadAll()
        → AppBar title rebuild "KHS 2023/2024 ▾" + Tab GANJIL/GENAP refresh
Empty: Tap title "KHS 2024/2025 ▾" → sheet empty "Belum ada tahun ajaran" → close via drag/swipe
```

### 4.3 Error Handling & Edge Cases (DISETUJUI)

| Kasus | Handling | UI |
|-------|----------|----|
| `availableYears == []` | Title tetap render `KHS <selected>` + `▾`, tap buka sheet empty tanpa list. | Pesan info, close via drag. Tidak `SizedBox.shrink`. |
| `availableYears == [satu tahun]` | Sheet 1 item, highlight bold+primary, tap tetap `selectYear` (idempotent, `loadAll` ulang). | Konsisten, tanpa guard same-year. |
| `loadAvailableYears()` throw | Catch silent (existing) → `availableYears` tetap `[]` → fallback empty. Title tetap dari route. | Halaman tidak block. |
| Tap cepat 2× / selectYear berurutan | `selectYear` `await loadAll()` sequential — last write wins. | Aman karena serialize di `initState` + `loadAll` sequential. |
| Sheet open lalu route di-pop / cubit disposed | Callback `onYearSelected` setelah `pop` — guard `if(context.mounted)` sebelum `read<KhsDetailCubit>().selectYear` di `KhsAppBarTitle._showSheet`. | Tidak `ProviderNotFoundException`. |
| `isFetching == true` (fetch manual berjalan) | Title tetap tappable, sheet bisa dibuka — tidak block. Spinner cukup di tombol `Muat KHS` di body. `IgnorePointer` tidak dipakai. | B murni terpenuhi. |

### 4.4 Testing & Acceptance Criteria (DISETUJUI)

| Layer | Skenario | Expected |
|-------|----------|----------|
| Widget KhsAppBarTitle | Render `tahunAjaran:"2024/2025"` | `find.text("KHS 2024/2025")` + `find.byIcon(Icons.arrow_drop_down)` dalam `Key('khs_app_bar_title')` |
|  | Tap title | `showModalBottomSheet` terbuka, `find.byKey(Key('year_picker_sheet'))` found |
|  | `availableYears: []` tap | Sheet tetap terbuka, `find.text("Belum ada tahun ajaran")` found, `find.byType(ListTile)` none |
|  | Sheet tap item `onYearSelected` | Callback terpanggil dengan argumen tahun, sheet `pop` sekali (tidak double-pop) |
| Widget YearPickerSheet | `years: []` | Empty state tanpa `ListTile` |
|  | `years: ["2024/2025","2023/2024"]` `selectedYear:"2024/2025"` | 2 `ListTile`, selected bold + `cs.primary` |
|  | Tap `"2023/2024"` | `onYearSelected("2023/2024")` + `Navigator.pop` sekali |
| Widget KhsDetailPage | Render awal `selectedTahunAjaran:"2024/2025"` | `find.byKey(Key('khs_app_bar_title'))` oneWidget, `find.byKey(Key('year_switcher_button'))` nothing, `actions` kosong |
|  | Title tap → pilih tahun lain | `KhsDetailCubit.selectYear` terpanggil, tab GANJIL/GENAP rebuild |
|  | Empty tab + title switch ke tahun kosong | Body empty + `Key('khs_fetch_year_button')` tetap (tidak terpengaruh perubahan AppBar) |
| Unit Cubit | Tidak berubah dari `2026-09-05-khs-year-switcher-design.md` | `loadAvailableYears`, `selectYear`, `fetchMissingYear`, equality `isFetching` tetap hijau |
| Static | `flutter analyze --no-pub` (scope `lib/`) | 0 error |
| Manual | Fresh install → Login → Home `Lihat KHS` | Title tunggal `KHS 2024/2025 ▾` (kanan kosong), tap ganti tahun → title + tab berubah, empty tahun tap title → sheet empty |

Key rename: semua pencarian `Key('year_switcher_button')` diganti `Key('khs_app_bar_title')`; test/file yang masih import `YearSwitcherButton` wajib diperbarui/dihapus.

### 4.5 Risiko, File Map & Estimasi (DISETUJUI)

**Risiko & mitigasi:**

| Risiko | Mitigasi |
|--------|----------|
| `year_switcher_button` masih diimpor/dicari test/maestro → fail | Grep `year_switcher_button` sebelum commit, ganti ke `khs_app_bar_title`, hapus file + export barrel. |
| Double `Navigator.pop` (sheet pop + caller pop) → pop route KHS | Sheet yang `pop`, caller jangan `pop` lagi — `KhsAppBarTitle` pass `onYearSelected` langsung. |
| Hit area title terlalu kecil di device kecil | `Row(mainAxisSize: min)` + `InkWell` + padding 4px, tinggi AppBar ≥ 56dp, cukup. |
| Barrel/grep masih export `YearSwitcherButton` | Hapus export di `lib/features/khs/barrel.dart` atau file `barrel.dart` terkait. |

**File map final:**

| Status | File |
|--------|------|
| Baru | `lib/features/khs/presentation/widgets/khs_app_bar_title.dart` |
| Hapus | `lib/features/khs/presentation/widgets/year_switcher_button.dart` |
| Ubah | `lib/features/khs/presentation/pages/khs_detail_page.dart` |
| Ubah ringan | `lib/features/khs/presentation/widgets/year_picker_sheet.dart` |
| Tidak diubah | `khs_detail_cubit.dart`, `khs_detail_state.dart`, `khs_remote_data_source.dart`, `khs_model.dart`, `academic_cache_service.dart`, `app_router.dart`, `get_khs.dart`, `home_page.dart` |

**Estimasi implementasi (untuk writing-plans):**

- Fase 1: Buat `khs_app_bar_title.dart` + hapus `year_switcher_button.dart` + update barrel/grep.
- Fase 2: Ubah `khs_detail_page.dart` (AppBar title → `KhsAppBarTitle`, `actions: []`) + `YearPickerSheet` empty branch.
- Fase 3: `flutter analyze --no-pub` + grep `year_switcher_button` → 0 hit + widget test manual tap flow.

## 5. Pertanyaan Terbuka

Tidak ada. Semua keputusan (format A, empty B, interaksi A, Opsi 2) disetujui per seksi 1/5 s/d 5/5. Writer `tahunAjaran` camelCase dan state `isFetching` merujuk ke spec `2026-09-05-khs-year-switcher-design.md` tanpa diduplikasi.

## 6. Self-Review

- Placeholder/TBD: tidak ada.
- Kontradiksi internal: tidak ada — title `KHS 2024/2025 ▾` konsisten dengan `YearPickerSheet` tap→`selectYear`; empty B konsisten dengan `actions: []`.
- Scope: fokus — 1 baru + 1 hapus + 2 ubah; cubit/model/DS tidak tersentuh.
- Ambiguitas: `isFetching` tidak block title (diputuskan eksplisit di §4.3).
