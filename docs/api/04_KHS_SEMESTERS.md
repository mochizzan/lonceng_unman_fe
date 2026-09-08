# Get KHS Semesters

Get the list of available KHS (Kartu Hasil Studi) semesters for a specific student. Navigates to the KHS page and scrapes the semester list.

**Endpoint:** `POST /api/v1/lms/khs/semesters`

**Request Body:**

```json
{
  "npm": "2211700006",
  "password": "izzan027"
}
```

| Field | JSON Key | Type | Required | Example Value | Description |
|-------|----------|------|----------|---------------|-------------|
| NPM | `npm` | `string` | Yes | `"2211700006"` | Student identification number. Digits only, 8-12 characters |
| Password | `password` | `string` | Yes | `"izzan027"` | LMS password |

**Response 200 OK:**

```json
{
  "status": "success",
  "data": {
    "success": true,
    "message": "KHS semesters retrieved",
    "npm": "2211700006",
    "semesters": [
      {
        "tahun_ajaran": "2022/2023",
        "semester": "GANJIL",
        "sks": 20
      },
      {
        "tahun_ajaran": "2022/2023",
        "semester": "GENAP",
        "sks": 22
      },
      {
        "tahun_ajaran": "2023/2024",
        "semester": "GANJIL",
        "sks": 21
      }
    ],
    "timestamp": "2026-08-06T00:45:00+07:00"
  },
  "message": "KHS semesters retrieved"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| Success | `data.success` | `boolean` | `true` | Whether the retrieval succeeded |
| Message | `data.message` | `string` | `"KHS semesters retrieved"` | Result description |
| NPM | `data.npm` | `string` | `"2211700006"` | Student NPM |
| Semesters | `data.semesters` | `array<KHSSemester>` | *(see below)* | Array of available KHS semesters |
| Semesters[i]. Tahun Ajaran | `data.semesters[i].tahun_ajaran` | `string` | `"2022/2023"` | Academic year range (format: `YYYY/YYYY`) |
| Semesters[i]. Semester | `data.semesters[i].semester` | `string` | `"GANJIL"` | Semester name: `"GANJIL"` (odd) or `"GENAP"` (even) |
| Semesters[i]. SKS | `data.semesters[i].sks` | `integer` | `20` | Total SKS (credits) taken in that semester |
| Timestamp | `data.timestamp` | `string` (ISO 8601) | `"2026-08-06T00:45:00+07:00"` | Retrieval time (server timezone) |

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

**Response 400 Bad Request — Missing Password:**

```json
{
  "status": "error",
  "message": "password is required",
  "trace_id": "abc123..."
}
```

**Response 500 Internal Server Error — Fetch Failed:**

```json
{
  "status": "error",
  "message": "fetch KHS semesters failed",
  "trace_id": "abc123..."
}
```

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/khs/semesters \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"izzan027"}'
```
