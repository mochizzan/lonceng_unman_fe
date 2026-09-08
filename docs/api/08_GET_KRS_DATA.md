# Get KRS Data

Retrieve cached KRS extraction data. Returns the full structured KRS data as previously extracted.

**Endpoint:** `POST /api/v1/lms/krs/data`

**Request Body:**

```json
{
  "npm": "2211700006"
}
```

| Field | JSON Key | Type | Required | Example Value | Description |
|-------|----------|------|----------|---------------|-------------|
| NPM | `npm` | `string` | Yes | `"2211700006"` | Student identification number. Digits only, 8-12 characters |

**Response 200 OK:**

```json
{
  "status": "success",
  "data": {
    "krs": {
      "mahasiswa": {
        "nama": "MOCHAMAD IZZAN FIRASYANSYAH",
        "npm": "2211700006",
        "program_studi": "Sistem Informasi"
      },
      "periode": {
        "tahun_ajaran": {
          "awal": "2025",
          "akhir": "2026"
        },
        "semester": "GENAP"
      },
      "mata_kuliah": [
        {
          "no": 1,
          "kode": "SI401",
          "nama": "Sistem Informasi Manajemen",
          "sks": 3,
          "kelas": "A",
          "dosen": "Dr. Budi Santoso, M.Kom.",
          "jadwal": {
            "hari": "Senin",
            "waktu_mulai": "08:00",
            "waktu_selesai": "10:30"
          }
        }
      ],
      "total_sks": 12,
      "penerbitan": {
        "tempat": "Yogyakarta",
        "tanggal": "2026-01-15"
      },
      "persetujuan": {
        "mahasiswa": {
          "nama": "MOCHAMAD IZZAN FIRASYANSYAH"
        },
        "ketua_program_studi": {
          "jabatan": "Ketua Program Studi",
          "nama": "Dr. Eko Prasetyo, M.Kom.",
          "nidn": "0425088901"
        }
      }
    },
    "metadata": {
      "extracted_at": "2026-08-06T12:45:00+07:00",
      "source_file": "downloads/2211700006/krs/semester_8.pdf",
      "file_size": 183701
    }
  },
  "message": "KRS data retrieved"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| **KRS** | `data.krs` | `KRSExtraction.KRS` | *(see above)* | The full KRS extraction data |
| Mahasiswa. Nama | `data.krs.mahasiswa.nama` | `string` | `"MOCHAMAD IZZAN FIRASYANSYAH"` | Student full name (uppercase) |
| Mahasiswa. NPM | `data.krs.mahasiswa.npm` | `string` | `"2211700006"` | Student NPM |
| Mahasiswa. Program Studi | `data.krs.mahasiswa.program_studi` | `string` | `"Sistem Informasi"` | Study program name |
| Periode. Tahun Ajaran. Awal | `data.krs.periode.tahun_ajaran.awal` | `string` | `"2025"` | Start year of academic period |
| Periode. Tahun Ajaran. Akhir | `data.krs.periode.tahun_ajaran.akhir` | `string` | `"2026"` | End year of academic period |
| Periode. Semester | `data.krs.periode.semester` | `string` | `"GENAP"` | `"GANJIL"` (odd) or `"GENAP"` (even) |
| Mata Kuliah | `data.krs.mata_kuliah` | `array<KRSMataKuliah>` | *(see above)* | Array of course entries |
| Mata Kuliah[i]. No | `data.krs.mata_kuliah[i].no` | `integer` | `1` | Course sequence number |
| Mata Kuliah[i]. Kode | `data.krs.mata_kuliah[i].kode` | `string` | `"SI401"` | Course code |
| Mata Kuliah[i]. Nama | `data.krs.mata_kuliah[i].nama` | `string` | `"Sistem Informasi Manajemen"` | Course name |
| Mata Kuliah[i]. SKS | `data.krs.mata_kuliah[i].sks` | `integer` | `3` | Credit units (SKS) |
| Mata Kuliah[i]. Kelas | `data.krs.mata_kuliah[i].kelas` | `string` | `"A"` | Class section |
| Mata Kuliah[i]. Dosen | `data.krs.mata_kuliah[i].dosen` | `string` | `"Dr. Budi Santoso, M.Kom."` | Lecturer name with title |
| Mata Kuliah[i]. Jadwal. Hari | `data.krs.mata_kuliah[i].jadwal.hari` | `string` | `"Senin"` | Day of week (Indonesian) |
| Mata Kuliah[i]. Jadwal. Waktu Mulai | `data.krs.mata_kuliah[i].jadwal.waktu_mulai` | `string` | `"08:00"` | Start time (HH:MM format) |
| Mata Kuliah[i]. Jadwal. Waktu Selesai | `data.krs.mata_kuliah[i].jadwal.waktu_selesai` | `string` | `"10:30"` | End time (HH:MM format) |
| Total SKS | `data.krs.total_sks` | `integer` | `12` | Total credit units across all courses |
| Penerbitan. Tempat | `data.krs.penerbitan.tempat` | `string` | `"Yogyakarta"` | Publication location |
| Penerbitan. Tanggal | `data.krs.penerbitan.tanggal` | `string` | `"2026-01-15"` | Publication date (YYYY-MM-DD) |
| Persetujuan. Ketua Prodi. Jabatan | `data.krs.persetujuan.ketua_program_studi.jabatan` | `string` | `"Ketua Program Studi"` | Position title |
| Persetujuan. Ketua Prodi. Nama | `data.krs.persetujuan.ketua_program_studi.nama` | `string \| null` | `"Dr. Eko Prasetyo, M.Kom."` | Head of study program name. `null` if not available |
| Persetujuan. Ketua Prodi. NIDN | `data.krs.persetujuan.ketua_program_studi.nidn` | `string \| null` | `"0425088901"` | National lecturer ID. `null` if not available |
| **Metadata** | `data.metadata` | `ExtractionMetadata` | *(see above)* | Extraction process metadata |
| Metadata. Extracted At | `data.metadata.extracted_at` | `string` (ISO 8601) | `"2026-08-06T12:45:00+07:00"` | When extraction was performed |
| Metadata. Source File | `data.metadata.source_file` | `string` | `"downloads/2211700006/krs/semester_8.pdf"` | Path to the source PDF file |
| Metadata. File Size | `data.metadata.file_size` | `integer` | `183701` | Source PDF file size in bytes |

**Response 400 Bad Request — Invalid JSON Body:**

```json
{
  "status": "error",
  "message": "invalid request body",
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

**Response 404 Not Found — Extraction Data Not Found:**

```json
{
  "status": "error",
  "message": "KRS extraction not found for npm: 2211700006",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 404 when no cached extraction exists for the given NPM.
> Call POST `/api/v1/lms/krs/extract` first to create extraction data.

**Response 403 Forbidden — Permission Denied:**

```json
{
  "status": "error",
  "message": "permission denied accessing KRS extraction",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 403 when file system permission is denied.

**Response 500 Internal Server Error — Read Failed:**

```json
{
  "status": "error",
  "message": "failed to retrieve KRS extraction",
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

> **Note:** Returns 500 when the cached KRS JSON file is corrupted or unreadable.

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/krs/data \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006"}'
```
