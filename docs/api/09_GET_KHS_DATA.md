# Get KHS Data

Retrieve cached KHS extraction data. Returns the full structured KHS data as previously extracted.

**Endpoint:** `POST /api/v1/lms/khs/data`

**Request Body:**

```json
{
  "npm": "2211700006",
  "tahun_ajaran": "2022/2023",
  "semester": "GENAP"
}
```

| Field | JSON Key | Type | Required | Example Value | Description |
|-------|----------|------|----------|---------------|-------------|
| NPM | `npm` | `string` | Yes | `"2211700006"` | Student identification number. Digits only, 8-12 characters |
| Tahun Ajaran | `tahun_ajaran` | `string` | Yes | `"2022/2023"` | Academic year (format: `YYYY/YYYY`) |
| Semester | `semester` | `string` | Yes | `"GENAP"` | Semester: `"GANJIL"` or `"GENAP"` (case-insensitive, auto-uppercased) |

**Response 200 OK:**

```json
{
  "status": "success",
  "data": {
    "khs": {
      "mahasiswa": {
        "nama": "MOCHAMAD IZZAN FIRASYANSYAH",
        "npm": "2211700006",
        "program_studi": "Sistem Informasi"
      },
      "periode": {
        "tahun_ajaran": {
          "awal": "2022",
          "akhir": "2023"
        },
        "semester": "GENAP"
      },
      "mata_kuliah": [
        {
          "no": 1,
          "kode": "SI301",
          "nama": "Basis Data Lanjut",
          "dosen": "Dr. Hendra Wijaya, M.T.",
          "sks": 3,
          "nilai": "A",
          "mutu": 4
        }
      ],
      "rekapitulasi": {
        "total_sks": 23,
        "total_mutu": 84,
        "ipk": 3.65
      },
      "penerbitan": {
        "tempat": "Yogyakarta",
        "tanggal": "2023-07-20"
      },
      "persetujuan": {
        "dekan": {
          "jabatan": "Dekan Fakultas Ilmu Komputer",
          "nama": "Prof. Dr. Rina Hartati, M.Si.",
          "nidn": "0412066201"
        }
      }
    },
    "metadata": {
      "extracted_at": "2026-08-06T12:45:00+07:00",
      "source_file": "downloads/2211700006/khs/2022_2023_GENAP.pdf",
      "file_size": 193331
    }
  },
  "message": "KHS data retrieved"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| **KHS** | `data.khs` | `KHSExtraction.KHS` | *(see above)* | The full KHS extraction data |
| Mahasiswa. Nama | `data.khs.mahasiswa.nama` | `string` | `"MOCHAMAD IZZAN FIRASYANSYAH"` | Student full name (uppercase) |
| Mahasiswa. NPM | `data.khs.mahasiswa.npm` | `string` | `"2211700006"` | Student NPM |
| Mahasiswa. Program Studi | `data.khs.mahasiswa.program_studi` | `string` | `"Sistem Informasi"` | Study program name |
| Periode. Tahun Ajaran. Awal | `data.khs.periode.tahun_ajaran.awal` | `string` | `"2022"` | Start year of academic period |
| Periode. Tahun Ajaran. Akhir | `data.khs.periode.tahun_ajaran.akhir` | `string` | `"2023"` | End year of academic period |
| Periode. Semester | `data.khs.periode.semester` | `string` | `"GENAP"` | `"GANJIL"` (odd) or `"GENAP"` (even) |
| Mata Kuliah | `data.khs.mata_kuliah` | `array<KHSMataKuliah>` | *(see above)* | Array of course entries |
| Mata Kuliah[i]. No | `data.khs.mata_kuliah[i].no` | `integer` | `1` | Course sequence number |
| Mata Kuliah[i]. Kode | `data.khs.mata_kuliah[i].kode` | `string` | `"SI301"` | Course code |
| Mata Kuliah[i]. Nama | `data.khs.mata_kuliah[i].nama` | `string` | `"Basis Data Lanjut"` | Course name |
| Mata Kuliah[i]. Dosen | `data.khs.mata_kuliah[i].dosen` | `string` | `"Dr. Hendra Wijaya, M.T."` | Lecturer name with title |
| Mata Kuliah[i]. SKS | `data.khs.mata_kuliah[i].sks` | `integer` | `3` | Credit units (SKS) |
| Mata Kuliah[i]. Nilai | `data.khs.mata_kuliah[i].nilai` | `string` | `"A"` | Letter grade (`"A"`, `"B+"`, `"B"`, `"C+"`, `"C"`, `"D"`, `"E"`) |
| Mata Kuliah[i]. Mutu | `data.khs.mata_kuliah[i].mutu` | `integer` | `4` | Grade point (0-4 scale) |
| Rekapitulasi. Total SKS | `data.khs.rekapitulasi.total_sks` | `integer` | `23` | Total credit units for the semester |
| Rekapitulasi. Total Mutu | `data.khs.rekapitulasi.total_mutu` | `integer` | `84` | Total grade points (mutu) |
| Rekapitulasi. IPK | `data.khs.rekapitulasi.ipk` | `number` | `3.65` | Cumulative GPA (Indeks Prestasi Kumulatif) |
| Penerbitan. Tempat | `data.khs.penerbitan.tempat` | `string` | `"Yogyakarta"` | Publication location |
| Penerbitan. Tanggal | `data.khs.penerbitan.tanggal` | `string` | `"2023-07-20"` | Publication date (YYYY-MM-DD) |
| Persetujuan. Dekan. Jabatan | `data.khs.persetujuan.dekan.jabatan` | `string` | `"Dekan Fakultas Ilmu Komputer"` | Dean position title |
| Persetujuan. Dekan. Nama | `data.khs.persetujuan.dekan.nama` | `string` | `"Prof. Dr. Rina Hartati, M.Si."` | Dean name |
| Persetujuan. Dekan. NIDN | `data.khs.persetujuan.dekan.nidn` | `string` | `"0412066201"` | National lecturer ID |
| **Metadata** | `data.metadata` | `ExtractionMetadata` | *(see above)* | Extraction process metadata |
| Metadata. Extracted At | `data.metadata.extracted_at` | `string` (ISO 8601) | `"2026-08-06T12:45:00+07:00"` | When extraction was performed |
| Metadata. Source File | `data.metadata.source_file` | `string` | `"downloads/2211700006/khs/2022_2023_GENAP.pdf"` | Path to the source PDF file |
| Metadata. File Size | `data.metadata.file_size` | `integer` | `193331` | Source PDF file size in bytes |

**Response 400 Bad Request — Invalid JSON Body:**

```json
{
  "status": "error",
  "message": "invalid request body",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — Missing Parameters:**

```json
{
  "status": "error",
  "message": "tahun_ajaran and semester are required",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — Missing NPM:**

```json
{
  "status": "error",
  "message": "npm is required",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — NPM Non-Digits:**

```json
{
  "status": "error",
  "message": "npm must contain only digits",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — NPM Length:**

```json
{
  "status": "error",
  "message": "npm must be 8-12 characters",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — Invalid Semester:**

```json
{
  "status": "error",
  "message": "semester must be GANJIL or GENAP",
  "trace_id": "abc123..."
}
```

**Response 404 Not Found — Extraction Data Not Found:**

```json
{
  "status": "error",
  "message": "KHS extraction not found",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 404 when no cached extraction exists for the given NPM/tahun_ajaran/semester.
> Call POST `/api/v1/lms/khs/extract` first to create extraction data.

**Response 403 Forbidden — Permission Denied:**

```json
{
  "status": "error",
  "message": "permission denied accessing KHS extraction",
  "trace_id": "abc123..."
}
```

**Response 500 Internal Server Error — Read Failed:**

```json
{
  "status": "error",
  "message": "failed to retrieve KHS extraction",
  "trace_id": "abc123..."
}
```

**Response 500 Internal Server Error — Parse Failed:**

```json
{
  "status": "error",
  "message": "failed to parse cached extraction",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 500 when the cached KHS JSON file is corrupted or unreadable.

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/khs/data \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","tahun_ajaran":"2022/2023","semester":"GENAP"}'
```
