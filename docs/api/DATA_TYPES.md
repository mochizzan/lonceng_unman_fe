# Data Types

All Go structs from `internal/domain/entity/` used in API responses.

## Primitive Types

| Go Type | JSON Type | Example | Notes |
|---------|-----------|---------|-------|
| `string` | `string` | `"hello"` | UTF-8 text |
| `int` | `integer` | `42` | Signed integer |
| `float64` | `number` | `3.65` | IEEE 754 double-precision |
| `bool` | `boolean` | `true` | `true` or `false` |
| `*string` | `string \| null` | `null` | Nullable string. Pointer in Go; `null` in JSON when nil |
| `time.Time` | `string` (ISO 8601) | `"2026-08-06T12:45:00+07:00"` | RFC 3339 format with timezone |

## Mahasiswa

Student identity information, shared by both KRS and KHS.

```go
type Mahasiswa struct {
    Nama         string `json:"nama"`
    NPM          string `json:"npm"`
    ProgramStudi string `json:"program_studi"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Nama | `nama` | `string` | `"MOCHAMAD IZZAN FIRASYANSYAH"` | Student full name (uppercase) |
| NPM | `npm` | `string` | `"2211700006"` | Student identification number |
| ProgramStudi | `program_studi` | `string` | `"Sistem Informasi"` | Study program name |

## TahunAjaran

Academic year range (e.g. 2025/2026).

```go
type TahunAjaran struct {
    Awal  string `json:"awal"`
    Akhir string `json:"akhir"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Awal | `awal` | `string` | `"2025"` | Start year (YYYY) |
| Akhir | `akhir` | `string` | `"2026"` | End year (YYYY) |

## Periode

Academic period, used by both KRS and KHS.

```go
type Periode struct {
    TahunAjaran TahunAjaran `json:"tahun_ajaran"`
    Semester    string      `json:"semester"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| TahunAjaran | `tahun_ajaran` | `TahunAjaran` | `{"awal":"2025","akhir":"2026"}` | Academic year range |
| Semester | `semester` | `string` | `"GENAP"` | `"GANJIL"` (odd) or `"GENAP"` (even) |

## Penerbitan

Document publication info, used by both KRS and KHS.

```go
type Penerbitan struct {
    Tempat  string `json:"tempat"`
    Tanggal string `json:"tanggal"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Tempat | `tempat` | `string` | `"Yogyakarta"` | Publication location |
| Tanggal | `tanggal` | `string` | `"2026-01-15"` | Publication date (YYYY-MM-DD) |

## ExtractionMetadata

Metadata about the extraction process.

```go
type ExtractionMetadata struct {
    ExtractedAt time.Time `json:"extracted_at"`
    SourceFile  string    `json:"source_file"`
    FileSize    int       `json:"file_size"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| ExtractedAt | `extracted_at` | `string` (ISO 8601) | `"2026-08-06T12:45:00+07:00"` | When extraction was performed |
| SourceFile | `source_file` | `string` | `"downloads/2211700006/krs/semester_8.pdf"` | Path to source PDF |
| FileSize | `file_size` | `integer` | `183701` | Source PDF size in bytes |

## KRS Types

### KRSJadwal

Class schedule for a KRS course.

```go
type KRSJadwal struct {
    Hari         string `json:"hari"`
    WaktuMulai   string `json:"waktu_mulai"`
    WaktuSelesai string `json:"waktu_selesai"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Hari | `hari` | `string` | `"Senin"` | Day of week (Indonesian) |
| WaktuMulai | `waktu_mulai` | `string` | `"08:00"` | Start time (HH:MM) |
| WaktuSelesai | `waktu_selesai` | `string` | `"10:30"` | End time (HH:MM) |

### KRSMataKuliah

A course entry in KRS.

```go
type KRSMataKuliah struct {
    No     int       `json:"no"`
    Kode   string    `json:"kode"`
    Nama   string    `json:"nama"`
    SKS    int       `json:"sks"`
    Kelas  string    `json:"kelas"`
    Dosen  string    `json:"dosen"`
    Jadwal KRSJadwal `json:"jadwal"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| No | `no` | `integer` | `1` | Sequence number |
| Kode | `kode` | `string` | `"SI401"` | Course code |
| Nama | `nama` | `string` | `"Sistem Informasi Manajemen"` | Course name |
| SKS | `sks` | `integer` | `3` | Credit units |
| Kelas | `kelas` | `string` | `"A"` | Class section |
| Dosen | `dosen` | `string` | `"Dr. Budi Santoso, M.Kom."` | Lecturer name |
| Jadwal | `jadwal` | `KRSJadwal` | *(see above)* | Class schedule |

### KRSPersetujuan

Approval section in KRS.

```go
type KRSPersetujuan struct {
    Mahasiswa struct {
        Nama string `json:"nama"`
    } `json:"mahasiswa"`
    KetuaProgramStudi struct {
        Jabatan string  `json:"jabatan"`
        Nama    *string `json:"nama"`
        NIDN    *string `json:"nidn"`
    } `json:"ketua_program_studi"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Mahasiswa. Nama | `mahasiswa.nama` | `string` | `"MOCHAMAD IZZAN FIRASYANSYAH"` | Student name |
| Ketua Prodi. Jabatan | `ketua_program_studi.jabatan` | `string` | `"Ketua Program Studi"` | Position title |
| Ketua Prodi. Nama | `ketua_program_studi.nama` | `string \| null` | `"Dr. Eko Prasetyo, M.Kom."` | Head of study program. `null` if unavailable |
| Ketua Prodi. NIDN | `ketua_program_studi.nidn` | `string \| null` | `"0425088901"` | National lecturer ID. `null` if unavailable |

### KRSExtraction

Full extracted KRS data (returned by POST `/api/v1/lms/krs/data`).

```go
type KRSExtraction struct {
    KRS struct {
        Mahasiswa   Mahasiswa       `json:"mahasiswa"`
        Periode     Periode         `json:"periode"`
        MataKuliah  []KRSMataKuliah `json:"mata_kuliah"`
        TotalSKS    int             `json:"total_sks"`
        Penerbitan  Penerbitan      `json:"penerbitan"`
        Persetujuan KRSPersetujuan  `json:"persetujuan"`
    } `json:"krs"`
    Metadata ExtractionMetadata `json:"metadata"`
}
```

## KHS Types

### KHSMataKuliah

A course entry in KHS.

```go
type KHSMataKuliah struct {
    No    int    `json:"no"`
    Kode  string `json:"kode"`
    Nama  string `json:"nama"`
    Dosen string `json:"dosen"`
    SKS   int    `json:"sks"`
    Nilai string `json:"nilai"`
    Mutu  int    `json:"mutu"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| No | `no` | `integer` | `1` | Sequence number |
| Kode | `kode` | `string` | `"SI301"` | Course code |
| Nama | `nama` | `string` | `"Basis Data Lanjut"` | Course name |
| Dosen | `dosen` | `string` | `"Dr. Hendra Wijaya, M.T."` | Lecturer name |
| SKS | `sks` | `integer` | `3` | Credit units |
| Nilai | `nilai` | `string` | `"A"` | Letter grade: `"A"`, `"B+"`, `"B"`, `"C+"`, `"C"`, `"D"`, `"E"` |
| Mutu | `mutu` | `integer` | `4` | Grade point (0-4 scale) |

### KHSRekapitulasi

Summary statistics in KHS.

```go
type KHSRekapitulasi struct {
    TotalSKS  int     `json:"total_sks"`
    TotalMutu int     `json:"total_mutu"`
    IPK       float64 `json:"ipk"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| TotalSKS | `total_sks` | `integer` | `23` | Total credit units for the semester |
| TotalMutu | `total_mutu` | `integer` | `84` | Total grade points (mutu) |
| IPK | `ipk` | `number` | `3.65` | Cumulative GPA (Indeks Prestasi Kumulatif) |

### KHSPersetujuan

Approval section in KHS.

```go
type KHSPersetujuan struct {
    Dekan struct {
        Jabatan string `json:"jabatan"`
        Nama    string `json:"nama"`
        NIDN    string `json:"nidn"`
    } `json:"dekan"`
}
```

| Field | JSON Key | Type | Example | Description |
|-------|----------|------|---------|-------------|
| Dekan. Jabatan | `dekan.jabatan` | `string` | `"Dekan Fakultas Ilmu Komputer"` | Dean position title |
| Dekan. Nama | `dekan.nama` | `string` | `"Prof. Dr. Rina Hartati, M.Si."` | Dean name |
| Dekan. NIDN | `dekan.nidn` | `string` | `"0412066201"` | National lecturer ID |

### KHSExtraction

Full extracted KHS data (returned by POST `/api/v1/lms/khs/data`).

```go
type KHSExtraction struct {
    KHS struct {
        Mahasiswa    Mahasiswa       `json:"mahasiswa"`
        Periode      Periode         `json:"periode"`
        MataKuliah   []KHSMataKuliah `json:"mata_kuliah"`
        Rekapitulasi KHSRekapitulasi `json:"rekapitulasi"`
        Penerbitan   Penerbitan      `json:"penerbitan"`
        Persetujuan  KHSPersetujuan  `json:"persetujuan"`
    } `json:"khs"`
    Metadata ExtractionMetadata `json:"metadata"`
}
```

## Student Profile Types

### StudentProfile

Full student profile data scraped from LMS form. Returned by `POST /api/v1/lms/student-profile/data`.

```go
type StudentProfile struct {
    PersonalData   PersonalData   `json:"personal_data"`
    ContactData    ContactData    `json:"contact_data"`
    EducationData  EducationData  `json:"education_data"`
    AddressData    AddressData    `json:"address_data"`
    EmploymentData EmploymentData `json:"employment_data"`
    FatherData     FatherData     `json:"father_data"`
    MotherData     MotherData     `json:"mother_data"`
    GuardianData   GuardianData   `json:"guardian_data"`
    OtherData      OtherData      `json:"other_data"`
}
```

### PersonalData

```go
type PersonalData struct {
    NIM             string `json:"nim"`
    NISN            string `json:"nisn"`
    NIK             string `json:"nik"`
    NamaMahasiswa   string `json:"nama_mahasiswa"`
    ProgramStudi    string `json:"program_studi"`
    Semester        string `json:"semester"`
    Kelas           string `json:"kelas"`
    StatusKonversi  string `json:"status_konversi"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NIM | `nim` | `"2211700006"` | Student ID |
| NISN | `nisn` | `"0043912837"` | National Student ID |
| NIK | `nik` | `"3213032709040006"` | National ID Card number |
| NamaMahasiswa | `nama_mahasiswa` | `"MOCHAMAD IZZAN FIRASYANSYAH"` | Full name |
| ProgramStudi | `program_studi` | `"Sistem Informasi"` | Study program display text (full name, not code) |
| Semester | `semester` | `"8"` | Current semester |
| Kelas | `kelas` | `"A"` | Class section |
| StatusKonversi | `status_konversi` | `"TIDAK"` | Transfer status |

### ContactData

```go
type ContactData struct {
    NoWA               string `json:"no_wa"`
    Email              string `json:"email"`
    TempatLahir        string `json:"tempat_lahir"`
    TanggalLahir       string `json:"tanggal_lahir"`
    Agama              string `json:"agama"`
    Kelamin            string `json:"kelamin"`
    Suku               string `json:"suku"`
    StatusMenikah      string `json:"status_menikah"`
    KebutuhanKhusus    string `json:"id_kebutuhan_khusus_mahasiswa"`
    StatusTinggal      string `json:"status_tinggal"`
    Transportasi       string `json:"transportasi"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NoWA | `no_wa` | `"88971689891"` | WhatsApp number |
| Email | `email` | `"izzanfirasyansyah2709@gmail.com"` | Email address |
| TempatLahir | `tempat_lahir` | `"SUBANG"` | Place of birth |
| TanggalLahir | `tanggal_lahir` | `"2004-09-27"` | Date of birth (YYYY-MM-DD) |
| Agama | `agama` | `""` | Religion display text. Empty string when placeholder (not selected) |
| Kelamin | `kelamin` | `"Laki - Laki"` | Gender display text: `"Laki - Laki"` or `"Perempuan"` |
| Suku | `suku` | `"SUNDA"` | Ethnicity |
| StatusMenikah | `status_menikah` | `"LAJANG"` | Marital status display text |
| KebutuhanKhusus | `id_kebutuhan_khusus_mahasiswa` | `""` | Special needs display text. Empty string when placeholder (not selected) |
| StatusTinggal | `status_tinggal` | `""` | Living status display text. Empty string when placeholder (not selected) |
| Transportasi | `transportasi` | `""` | Transportation display text. Empty string when placeholder (not selected) |

### EducationData

```go
type EducationData struct {
    NamaAsalSekolah string `json:"nama_asal_sekolah"`
    TahunLulus      string `json:"tahun_lulus"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NamaAsalSekolah | `nama_asal_sekolah` | `"SMKN 1 SUBANG"` | Previous school name |
| TahunLulus | `tahun_lulus` | `"2022"` | Graduation year |

### AddressData

```go
type AddressData struct {
    Provinsi     string `json:"propinsi"`
    Kabupaten    string `json:"kabupaten"`
    Kecamatan    string `json:"kecamatan"`
    IdWilayah    string `json:"id_wilayah"`
    Desa         string `json:"desa"`
    AlamatDusun  string `json:"alamat_dusun"`
    AlamatRW     string `json:"alamat_rw"`
    AlamatRT     string `json:"alamat_rt"`
    AlamatJalan  string `json:"alamat_jalan"`
    KodePos      string `json:"kode_pos"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| Provinsi | `propinsi` | `"32"` | Province region code (not display name) |
| Kabupaten | `kabupaten` | `"3213"` | District region code (not display name) |
| Kecamatan | `kecamatan` | `"321303"` | Sub-district region code (not display name) |
| IdWilayah | `id_wilayah` | `""` | Region ID. Empty string when not provided |
| Desa | `desa` | `""` | Village. Empty string when not provided |
| AlamatDusun | `alamat_dusun` | `""` | Hamlet name. Empty string when not provided |
| AlamatRW | `alamat_rw` | `""` | RW number. Empty string when not provided |
| AlamatRT | `alamat_rt` | `""` | RT number. Empty string when not provided |
| AlamatJalan | `alamat_jalan` | `""` | Street name. Empty string when not provided |
| KodePos | `kode_pos` | `""` | Postal code. Empty string when not provided |

### EmploymentData

```go
type EmploymentData struct {
    StatusBekerja  string `json:"status_bekerja"`
    NamaKantor     string `json:"nama_kantor"`
    AlamatKantor   string `json:"alamat_kantor"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| StatusBekerja | `status_bekerja` | `"BELUM BEKERJA"` | Employment status display text |
| NamaKantor | `nama_kantor` | `""` | Company name. Empty string when not provided |
| AlamatKantor | `alamat_kantor` | `""` | Company address. Empty string when not provided |

### FatherData

```go
type FatherData struct {
    NamaAyah                string `json:"nama_ayah"`
    TanggalLahirAyah        string `json:"tanggal_lahir_ayah"`
    NIKAyah                 string `json:"nik_ayah"`
    NoHpAyah                string `json:"no_hp_ayah"`
    JenjangPendidikanAyah   string `json:"id_jenjang_pendidikan_ayah"`
    PekerjaanAyah           string `json:"id_pekerjaan_ayah"`
    PenghasilanAyah         string `json:"id_penghasilan_ayah"`
    KebutuhanKhususAyah     string `json:"id_kebutuhan_khusus_ayah"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NamaAyah | `nama_ayah` | `"Mochamad Iwan Hermansyah (ALM)"` | Father's name |
| TanggalLahirAyah | `tanggal_lahir_ayah` | `""` | Father's birth date. Always empty (element not present in LMS form) |
| NIKAyah | `nik_ayah` | `""` | Father's NIK. Empty string when not provided |
| NoHpAyah | `no_hp_ayah` | `"85317092266"` | Father's phone |
| JenjangPendidikanAyah | `id_jenjang_pendidikan_ayah` | `""` | Father's education level display text. Empty string when placeholder (not selected) |
| PekerjaanAyah | `id_pekerjaan_ayah` | `""` | Father's occupation display text. Empty string when placeholder (not selected) |
| PenghasilanAyah | `id_penghasilan_ayah` | `""` | Father's income range display text. Empty string when placeholder (not selected) |
| KebutuhanKhususAyah | `id_kebutuhan_khusus_ayah` | `""` | Father's special needs display text. Empty string when placeholder (not selected) |

### MotherData

```go
type MotherData struct {
    NamaIbu                string `json:"nama_ibu"`
    TanggalLahirIbu        string `json:"tanggal_lahir_ibu"`
    NIKIbu                 string `json:"nik_ibu"`
    NoHpIbu                string `json:"no_hp_ibu"`
    JenjangPendidikanIbu   string `json:"id_jenjang_pendidikan_ibu"`
    PekerjaanIbu           string `json:"id_pekerjaan_ibu"`
    PenghasilanIbu         string `json:"id_penghasilan_ibu"`
    KebutuhanKhususIbu     string `json:"id_kebutuhan_khusus_ibu"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NamaIbu | `nama_ibu` | `"Sri Nani"` | Mother's name |
| TanggalLahirIbu | `tanggal_lahir_ibu` | `""` | Mother's birth date. Empty string when not provided |
| NIKIbu | `nik_ibu` | `""` | Mother's NIK. Empty string when not provided |
| NoHpIbu | `no_hp_ibu` | `"85317092266"` | Mother's phone |
| JenjangPendidikanIbu | `id_jenjang_pendidikan_ibu` | `""` | Mother's education level display text. Empty string when placeholder (not selected) |
| PekerjaanIbu | `id_pekerjaan_ibu` | `""` | Mother's occupation display text. Empty string when placeholder (not selected) |
| PenghasilanIbu | `id_penghasilan_ibu` | `""` | Mother's income range display text. Empty string when placeholder (not selected) |
| KebutuhanKhususIbu | `id_kebutuhan_khusus_ibu` | `""` | Mother's special needs display text. Empty string when placeholder (not selected) |

### GuardianData

```go
type GuardianData struct {
    NamaWali                string `json:"nama_wali"`
    TanggalLahirWali        string `json:"tanggal_lahir_wali"`
    JenjangPendidikanWali   string `json:"id_jenjang_pendidikan_wali"`
    PekerjaanWali           string `json:"id_pekerjaan_wali"`
    PenghasilanWali         string `json:"id_penghasilan_wali"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| NamaWali | `nama_wali` | `""` | Guardian's name. Empty string when not provided |
| TanggalLahirWali | `tanggal_lahir_wali` | `""` | Guardian's birth date. Empty string when not provided |
| JenjangPendidikanWali | `id_jenjang_pendidikan_wali` | `""` | Guardian's education level display text. Empty string when placeholder (not selected) |
| PekerjaanWali | `id_pekerjaan_wali` | `""` | Guardian's occupation display text. Empty string when placeholder (not selected) |
| PenghasilanWali | `id_penghasilan_wali` | `""` | Guardian's income range display text. Empty string when placeholder (not selected) |

### OtherData

```go
type OtherData struct {
    PenerimaKPS string `json:"penerima_kps"`
    NoKPS       string `json:"no_kps"`
    NPWP        string `json:"npwp"`
    Remark      string `json:"remark"`
}
```

| Field | JSON Key | Example | Description |
|-------|----------|---------|-------------|
| PenerimaKPS | `penerima_kps` | `"Tidak"` | KPS recipient: `"Tidak"` or `"Ya"` |
| NoKPS | `no_kps` | `""` | KPS number. Empty string when not provided |
| NPWP | `npwp` | `""` | Tax ID (NPWP). Empty string when not provided |
| Remark | `remark` | `"PEKERJAAN IBU : GURU HONORER SWASTA\nAYAH : ALMARHUM"` | Additional notes. May contain multi-line text |

### StudentProfileRequest

Request body for student profile operations.

```go
type StudentProfileRequest struct {
    NPM      string `json:"npm"`
    Password string `json:"password"`
}
```

### StudentProfileResult

Result of a successful profile scrape.

```go
type StudentProfileResult struct {
    NPM      string `json:"npm"`
    Message  string `json:"message"`
    CachedAt string `json:"cached_at"`
}
```

## Request Types

### LoginRequest

```go
type LoginRequest struct {
    NPM      string `json:"npm"`
    Password string `json:"password"`
}
```

### KRSDownloadRequest

```go
type KRSDownloadRequest struct {
    NPM      string `json:"npm"`
    Password string `json:"password"`
}
```

### KHSSemestersRequest

```go
type KHSSemestersRequest struct {
    NPM      string `json:"npm"`
    Password string `json:"password"`
}
```

### KHSDownloadRequest

```go
type KHSDownloadRequest struct {
    NPM         string `json:"npm"`
    Password    string `json:"password"`
    TahunAjaran string `json:"tahun_ajaran"`
    Semester    string `json:"semester"`
}
```

## Response Types

### LoginResult

```go
type LoginResult struct {
    Success   bool      `json:"success"`
    Message   string    `json:"message"`
    NPM       string    `json:"npm"`
    Timestamp time.Time `json:"timestamp"`
}
```

### KRSDownloadResult

```go
type KRSDownloadResult struct {
    Success   bool      `json:"success"`
    Message   string    `json:"message"`
    NPM       string    `json:"npm"`
    FilePath  string    `json:"file_path"`
    Size      int       `json:"size"`
    Timestamp time.Time `json:"timestamp"`
}
```

### KHSDownloadResult

```go
type KHSDownloadResult struct {
    Success     bool      `json:"success"`
    Message     string    `json:"message"`
    NPM         string    `json:"npm"`
    TahunAjaran string    `json:"tahun_ajaran"`
    Semester    string    `json:"semester"`
    FilePath    string    `json:"file_path"`
    Size        int       `json:"size"`
    Timestamp   time.Time `json:"timestamp"`
}
```

### KHSSemestersResult

```go
type KHSSemestersResult struct {
    Success   bool          `json:"success"`
    Message   string        `json:"message"`
    NPM       string        `json:"npm"`
    Semesters []KHSSemester `json:"semesters"`
    Timestamp time.Time     `json:"timestamp"`
}
```

### KHSSemester

```go
type KHSSemester struct {
    TahunAjaran string `json:"tahun_ajaran"`
    Semester    string `json:"semester"`
    SKS         int    `json:"sks"`
}
```

### ExtractionResult

```go
type ExtractionResult struct {
    Success   bool      `json:"success"`
    Message   string    `json:"message"`
    NPM       string    `json:"npm"`
    FilePath  string    `json:"file_path"`
    Timestamp time.Time `json:"timestamp"`
}
```

## Constants

| Constant | Value | Used In |
|----------|-------|---------|
| `SemesterGanjil` | `"GANJIL"` | Semester validation |
| `SemesterGenap` | `"GENAP"` | Semester validation |
| `DocTypeKRS` | `"krs"` | Extraction cache directory |
| `DocTypeKHS` | `"khs"` | Extraction cache directory |
| `ExtPDF` | `".pdf"` | File extension |
| `ExtJSON` | `".json"` | File extension |
| `KRSFilePrefix` | `"semester_"` | KRS filename prefix |

## Validation Rules

| Field | Rules |
|-------|-------|
| `npm` | Required. Digits only (`^[0-9]+$`). 8-12 characters. |
| `password` | Required. Any string. |
| `tahun_ajaran` | Required (where applicable). Format: `YYYY/YYYY`. |
| `semester` | Required (where applicable). Must be `"GANJIL"` or `"GENAP"` (case-insensitive on input, auto-uppercased). |
