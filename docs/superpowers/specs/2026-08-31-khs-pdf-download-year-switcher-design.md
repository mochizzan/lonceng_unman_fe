# KHS Page: PDF Download & Academic Year Switcher

**Date:** 2026-08-31
**Status:** Approved
**Author:** AI Assistant

## Overview

Add two features to the KHS (Kartu Hasil Studi) detail page:

1. **Academic Year Switcher** — a button in the app bar that opens a bottom sheet picker, allowing users to switch between available academic years
2. **PDF Download Button** — a "Save to Device" button per tab that downloads the KHS PDF for the currently active semester

## Current State Analysis

### KHS Page (`lib/features/khs/presentation/pages/khs_detail_page.dart`)
- Uses hard-coded GANJIL/GENAP tabs (not dynamic)
- Receives `tahunAjaran` and `semester` as route query parameters
- `KhsDetailCubit` loads data from Hive cache only — no direct API calls
- No PDF download functionality exists

### PDF Download Reality
- Current `downloadKhs()` is server-side only: backend scrapes LMS, saves PDF to its own disk, returns JSON status
- The app does NOT download, save, open, or share PDFs — `ApiClient` is JSON-only
- No PDF/file packages in pubspec.yaml (`open_file`, `share_plus`, etc.)

### Backend API
- `POST /api/v1/lms/khs` returns `{file_path, size}` where `file_path` is a server-relative path (e.g., `downloads/{npm}/khs/{tahun_ajaran}_{semester}.pdf`) — NOT a URL or PDF bytes
- **A new endpoint IS required** for actual client-side PDF download

### UI Patterns
- No existing dropdown/picker/selector widgets — must build from scratch
- `JadwalDaySelector` (horizontal pill row) and `showModalBottomSheet` are reference patterns
- Data layer already has `getSemesters()` API + `KhsSemesterModel` for building a year switcher

## Design Decisions

### Approach: Extend KhsDetailCubit

Extend the existing `KhsDetailCubit` with new states for year selection and download progress. Add a new `KhsPdfService` for PDF download.

**Rationale:**
- The codebase consistently uses simple, single-cubit-per-page patterns
- Adding ~80 lines to the existing cubit keeps the diff focused and reviewable
- No coordination overhead between multiple cubits
- The download feature is tightly coupled to the page anyway

### Year Switcher

**Source:** Cache-only from `AcademicCacheService.loadKhsList()`. The semester list is populated during the post-login data initialization pipeline.

**Behavior:**
- Extract unique `tahunAjaran` values from cached semester list
- Default to first year (or route param if valid)
- If cache is empty, hide the year switcher and show "No cached data" message

**UI:**
- `YearSwitcherButton` in app bar actions — shows current year with dropdown arrow
- `YearPickerSheet` — modal bottom sheet with list of available years
- Selected year highlighted with checkmark
- Dismiss on selection, triggers data reload

### PDF Download

**Scope:** Current tab only — one download button per tab, saves the PDF for the currently active semester (GANJIL or GENAP).

**Backend:** New endpoint `POST /api/v1/lms/khs/file` (see backend requirements doc).

**Flow:**
1. Check storage permission (Android 10+ uses scoped storage, no permission needed for Downloads)
2. Get Downloads directory via `path_provider`
3. Call placeholder endpoint → receive PDF bytes
4. Write bytes to file: `KHS_{tahunAjaran}_{semester}.pdf`
5. Show success/error toast

**UI:**
- `KhsDownloadButton` — compact button with icon + "Simpan PDF" text
- Shows progress indicator while downloading
- Disabled during active download

### Data Loading Strategy

**Cache-first with edge case handling:**
1. Check cache: `loadKhsDataSemester(tahunAjaran, 'GANJIL')`
2. If cached → emit loaded immediately
3. If not → call API via `GetKhs().call(tahunAjaran, semester)`
4. On success → cache result → emit loaded
5. On error → emit error state

## Architecture

### Component Map

```
KhsDetailPage (UI)
├── AppBar
│   └── YearSwitcherButton → opens YearPickerSheet (bottom sheet)
├── TabBar (GANJIL/GENAP)
│   └── KhsDownloadButton (per tab, downloads current tab's PDF)
├── TabBarView
│   └── KHS data tables
└── KhsDetailCubit (extended)
    ├── State: selectedTahunAjaran, availableYears, downloadStatus
    ├── Load data: cache-first → API fallback
    └── Download: KhsPdfService → save to device
```

### New Files

| File | Purpose |
|------|---------|
| `lib/features/khs/presentation/widgets/year_switcher_button.dart` | App bar button showing current year |
| `lib/features/khs/presentation/widgets/year_picker_sheet.dart` | Modal bottom sheet with year list |
| `lib/features/khs/presentation/widgets/khs_download_button.dart` | Download button per tab |
| `lib/features/khs/data/services/khs_pdf_service.dart` | PDF download + file saving logic |
| `docs/backend/khs-pdf-download-endpoint.md` | Backend requirements specification |

### Modified Files

| File | Change |
|------|--------|
| `lib/features/khs/presentation/cubit/khs_detail_cubit.dart` | Add year switching + download state management |
| `lib/features/khs/presentation/cubit/khs_detail_state.dart` | Add `selectedTahunAjaran`, `availableYears`, `downloadStatus` fields |
| `lib/features/khs/presentation/pages/khs_detail_page.dart` | Add year switcher + download button to UI |
| `lib/main.dart` | Register `KhsPdfService` in DI |

### New Dependencies

None — all required packages are already present:
- `path_provider` (^2.1.0) — for getting Downloads directory
- `http` (^1.2.0) — for making HTTP requests
- `permission_handler` (^11.3.0) — for storage permission (pre-Android 10)

## State Management

### KhsDetailState Extensions

```dart
// New state fields added to existing states
abstract class KhsDetailState {
  final String selectedTahunAjaran;    // currently selected year
  final List<String> availableYears;    // unique years from cache
  final DownloadStatus downloadStatus;  // idle/downloading/success/error
  const KhsDetailState({...});
}

enum DownloadStatus { idle, downloading, success, error }
```

### Year Switching Flow

1. Page init → cubit loads `availableYears` from `AcademicCacheService.loadKhsList()`
2. Extract unique `tahunAjaran` values from cached semester list
3. Default to first year (or route param if valid)
4. User taps year switcher → `YearPickerSheet` shows available years
5. On select → `KhsDetailCubit.selectYear(tahunAjaran)` → reloads GANJIL/GENAP data

### Download Flow

```
downloadPdf(tahunAjaran, semester) {
  1. Check storage permission (permission_handler)
  2. emit(downloadStatus: downloading)
  3. KhsPdfService.download(tahunAjaran, semester)
     → calls POST /api/v1/lms/khs/file
     → saves to Downloads folder via path_provider
  4. On success → emit(downloadStatus: success) + toast
  5. On error → emit(downloadStatus: error) + toast
}
```

## Edge Cases

| Case | Handling |
|------|----------|
| Empty cache | Hide year switcher, show "No cached data" message |
| Download fails | Show error toast with retry option |
| Permission denied | Show dialog explaining storage permission needed |
| Year not in cache | Auto-fetch from API with loading indicator |
| Invalid year selected | Fallback to first available year |
| Large PDF download | Show progress indicator, handle timeout |

## Backend Requirements

See `docs/backend/khs-pdf-download-endpoint.md` for full specification.

**Summary:**
- New endpoint: `POST /api/v1/lms/khs/file`
- Request body: `{"npm": "...", "password": "...", "tahunAjaran": "...", "semester": "..."}`
- Response: raw PDF bytes (`Content-Type: application/pdf`)
- Status: `200 OK` with PDF body, or `404` if file not found on server
- Security: validate credentials before serving file (same as existing endpoints)

## Testing Strategy

- **Unit tests:** `KhsPdfService` download logic, cubit state transitions
- **Widget tests:** Year switcher button, year picker sheet, download button
- **Integration tests:** Full download flow with mocked endpoint

## Migration Notes

- No database schema changes
- No breaking changes to existing APIs
- New endpoint is additive (existing `/api/v1/lms/khs` unchanged)
- Cache structure unchanged (uses existing `loadKhsList`/`saveKhsList`)
