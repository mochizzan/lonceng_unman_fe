# Get Student Profile Data

Retrieve cached student profile data. Returns nested profile with 9 sub-structs containing ~55 fields scraped from the LMS student profile form.

**Endpoint:** `POST /api/v1/lms/student-profile/data`

**Request Body:**

```json
{
  "npm": "2211700006",
  "password": "izzan027"
}
```

| Field | JSON Key | Type | Required | Example | Description |
|-------|----------|------|----------|---------|-------------|
| NPM | `npm` | `string` | Yes | `"2211700006"` | Student ID. Digits only, 8-12 chars |
| Password | `password` | `string` | Yes | `"izzan027"` | LMS password |

**Response 200 OK:**

```json
{
  "status": "success",
  "data": {
    "personal_data": {
      "nim": "2211700006",
      "nisn": "0043912837",
      "nik": "3213032709040006",
      "nama_mahasiswa": "MOCHAMAD IZZAN FIRASYANSYAH",
      "program_studi": "Sistem Informasi",
      "semester": "8",
      "kelas": "A",
      "status_konversi": "TIDAK"
    },
    "contact_data": {
      "no_wa": "88971689891",
      "email": "izzanfirasyansyah2709@gmail.com",
      "tempat_lahir": "SUBANG",
      "tanggal_lahir": "2004-09-27",
      "agama": "",
      "kelamin": "Laki - Laki",
      "suku": "SUNDA",
      "status_menikah": "LAJANG",
      "id_kebutuhan_khusus_mahasiswa": "",
      "status_tinggal": "",
      "transportasi": ""
    },
    "education_data": {
      "nama_asal_sekolah": "SMKN 1 SUBANG",
      "tahun_lulus": "2022"
    },
    "address_data": {
      "propinsi": "32",
      "kabupaten": "3213",
      "kecamatan": "321303",
      "id_wilayah": "",
      "desa": "",
      "alamat_dusun": "",
      "alamat_rw": "",
      "alamat_rt": "",
      "alamat_jalan": "",
      "kode_pos": ""
    },
    "employment_data": {
      "status_bekerja": "BELUM BEKERJA",
      "nama_kantor": "",
      "alamat_kantor": ""
    },
    "father_data": {
      "nama_ayah": "Mochamad Iwan Hermansyah (ALM)",
      "tanggal_lahir_ayah": "",
      "nik_ayah": "",
      "no_hp_ayah": "85317092266",
      "id_jenjang_pendidikan_ayah": "",
      "id_pekerjaan_ayah": "",
      "id_penghasilan_ayah": "",
      "id_kebutuhan_khusus_ayah": ""
    },
    "mother_data": {
      "nama_ibu": "Sri Nani",
      "tanggal_lahir_ibu": "",
      "nik_ibu": "",
      "no_hp_ibu": "85317092266",
      "id_jenjang_pendidikan_ibu": "",
      "id_pekerjaan_ibu": "",
      "id_penghasilan_ibu": "",
      "id_kebutuhan_khusus_ibu": ""
    },
    "guardian_data": {
      "nama_wali": "",
      "tanggal_lahir_wali": "",
      "id_jenjang_pendidikan_wali": "",
      "id_pekerjaan_wali": "",
      "id_penghasilan_wali": ""
    },
    "other_data": {
      "penerima_kps": "Tidak",
      "no_kps": "",
      "npwp": "",
      "remark": "PEKERJAAN IBU : GURU HONORER SWASTA\nAYAH : ALMARHUM"
    }
  },
  "message": "Student profile retrieved"
}
```

**Response Field Table:**

| JSON Path | Type | Description |
|-----------|------|-------------|
| `data.personal_data.nim` | `string` | Student ID (NIM) |
| `data.personal_data.nisn` | `string` | National Student ID (NISN) |
| `data.personal_data.nik` | `string` | National ID Card number (NIK/KTP) |
| `data.personal_data.nama_mahasiswa` | `string` | Full name |
| `data.personal_data.program_studi` | `string` | Study program full name (e.g. `"Sistem Informasi"`, `"Teknologi Informasi"`) |
| `data.personal_data.semester` | `string` | Current semester number |
| `data.personal_data.kelas` | `string` | Class section |
| `data.personal_data.status_konversi` | `string` | Transfer status display text (e.g. `"Tidak"`, `"Ya"`) |
| `data.contact_data.no_wa` | `string` | WhatsApp number |
| `data.contact_data.email` | `string` | Email address |
| `data.contact_data.tempat_lahir` | `string` | Place of birth |
| `data.contact_data.tanggal_lahir` | `string` | Date of birth (YYYY-MM-DD) |
| `data.contact_data.agama` | `string` | Religion display text when selected (e.g. `"Islam"`, `"Kristen"`); empty string when placeholder not selected |
| `data.contact_data.kelamin` | `string` | Gender display text (e.g. `"Laki - Laki"`, `"Perempuan"`) |
| `data.contact_data.suku` | `string` | Ethnicity display text |
| `data.contact_data.status_menikah` | `string` | Marital status display text (e.g. `"LAJANG"`, `"KAWIN"`) |
| `data.contact_data.id_kebutuhan_khusus_mahasiswa` | `string` | Special needs display text; empty string when placeholder not selected |
| `data.contact_data.status_tinggal` | `string` | Living status display text; empty string when placeholder not selected |
| `data.contact_data.transportasi` | `string` | Transportation display text; empty string when placeholder not selected |
| `data.education_data.nama_asal_sekolah` | `string` | Previous school name |
| `data.education_data.tahun_lulus` | `string` | Graduation year |
| `data.address_data.propinsi` | `string` | Province code (e.g. `"32"` for Jawa Barat) |
| `data.address_data.kabupaten` | `string` | District code (e.g. `"3213"` for Kabupaten Subang) |
| `data.address_data.kecamatan` | `string` | Sub-district code (e.g. `"321303"` for Kecamatan Subang) |
| `data.address_data.id_wilayah` | `string` | Region ID |
| `data.address_data.desa` | `string` | Village |
| `data.address_data.alamat_dusun` | `string` | Hamlet name |
| `data.address_data.alamat_rw` | `string` | RW number |
| `data.address_data.alamat_rt` | `string` | RT number |
| `data.address_data.alamat_jalan` | `string` | Street name |
| `data.address_data.kode_pos` | `string` | Postal code |
| `data.employment_data.status_bekerja` | `string` | Employment status display text (e.g. `"BELUM BEKERJA"`, `"BEKERJA"`) |
| `data.employment_data.nama_kantor` | `string` | Company name |
| `data.employment_data.alamat_kantor` | `string` | Company address |
| `data.father_data.nama_ayah` | `string` | Father's name |
| `data.father_data.tanggal_lahir_ayah` | `string` | Father's birth date (always empty — form element does not exist) |
| `data.father_data.nik_ayah` | `string` | Father's NIK |
| `data.father_data.no_hp_ayah` | `string` | Father's phone |
| `data.father_data.id_jenjang_pendidikan_ayah` | `string` | Display text when selected; empty string when placeholder not selected |
| `data.father_data.id_pekerjaan_ayah` | `string` | Display text when selected; empty string when placeholder not selected |
| `data.father_data.id_penghasilan_ayah` | `string` | Display text when selected; empty string when placeholder not selected |
| `data.father_data.id_kebutuhan_khusus_ayah` | `string` | Display text when selected; empty string when placeholder not selected |
| `data.mother_data.*` | `string` | Same structure as father_data |
| `data.guardian_data.nama_wali` | `string` | Guardian's name |
| `data.guardian_data.*` | `string` | Guardian fields |
| `data.other_data.penerima_kps` | `string` | KPS recipient display text: `"Tidak"` or `"Ya"` |
| `data.other_data.no_kps` | `string` | KPS number |
| `data.other_data.npwp` | `string` | Tax ID (NPWP) |
| `data.other_data.remark` | `string` | Free-text remark field from form (e.g. `"PEKERJAAN IBU : GURU HONORER SWASTA\nAYAH : ALMARHUM"`) |

**Response 400 Bad Request:**

```json
{
  "status": "error",
  "message": "npm is required",
  "trace_id": "abc123..."
}
```

**Response 404 Not Found (not cached):**

```json
{
  "status": "error",
  "message": "student profile not found. Use POST /api/v1/lms/student-profile to fetch"
}
```

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/student-profile/data \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"izzan027"}'
```
