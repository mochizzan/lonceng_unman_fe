# Folder Structure

## Download Folders

All PDFs are stored under `{DOWNLOAD_DIR}/{NPM}/` with canonical filenames:

```
downloads/
├── {NPM}/
│   ├── krs/
│   │   └── semester_{N}.pdf           # KRS (N = student's current semester)
│   ├── khs/
│   │   ├── 2022_2023_GANJIL.pdf        # KHS per semester
│   │   ├── 2022_2023_GENAP.pdf
│   │   └── 2023_2024_GANJIL.pdf
│   └── photo/
│       ├── {NPM}.jpg                  # Student profile photo (JPEG)
│       └── {NPM}.json                 # Photo cache metadata (TTL, timestamps)
```

**Naming Rules:**
- KRS: `{downloadDir}/{npm}/krs/semester_{N}.pdf` (N = semester number extracted from KRS page)
- KHS: `{downloadDir}/{npm}/khs/{tahun_ajaran}_{semester}.pdf`
- Photo: `{downloadDir}/{npm}/photo/{NPM}.jpg` (binary) + `{NPM}.json` (cache metadata)
- `tahun_ajaran`: `/` replaced with `_` (e.g. `2022/2023` → `2022_2023`)
- Files are overwritten if they already exist (latest download wins)
- Photo cache TTL is configurable via `PHOTO_CACHE_TTL` (default: 15m)

## Extraction Cache Structure

Extracted JSON files are stored under `{EXTRACT_DIR}/{NPM}/`:

```
extracted/
├── {NPM}/
│   ├── krs/
│   │   └── semester_{N}.json          # KRS extraction cache
│   ├── khs/
│   │   ├── 2022_2023_GANJIL.json      # KHS extraction cache
│   │   ├── 2022_2023_GENAP.json
│   │   └── 2023_2024_GANJIL.json
│   └── profile/
│       └── student_profile.json       # Student profile cache
```

**Naming Rules:**
- KRS: `{extractDir}/{npm}/krs/semester_{N}.json`
- KHS: `{extractDir}/{npm}/khs/{tahun_ajaran}_{semester}.json`
- Profile: `{extractDir}/{npm}/profile/student_profile.json`
- `/` in `tahun_ajaran` replaced with `_`

## Request Flow

```
Client Request (npm + password)
  │
  ▼
Handler: validate JSON body (npm, password, ...)
  │
  ▼
Service: SessionManager.GetOrCreate(npm, password)
  │
  ├── Session exists & valid? ──▶ Reuse cached browser session
  │
  └── No session? ──▶ Launch Chrome → Login → Cache session → Return BrowserSession
  │
  ▼
Service: use BrowserSession (navigate, eval, download)
  │
  ▼
Response envelope → JSON output
```
