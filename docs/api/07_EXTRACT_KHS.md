# Extract KHS

Extract structured data from a downloaded KHS PDF. Always re-extracts and overwrites existing cache. Requires a valid LMS session (verifies credentials first).

**Endpoint:** `POST /api/v1/lms/khs/extract`

**Request Body:**

```json
{
  "npm": "2211700006",
  "password": "izzan027",
  "tahun_ajaran": "2022/2023",
  "semester": "GENAP"
}
```

| Field | JSON Key | Type | Required | Example Value | Description |
|-------|----------|------|----------|---------------|-------------|
| NPM | `npm` | `string` | Yes | `"2211700006"` | Student identification number. Digits only, 8-12 characters |
| Password | `password` | `string` | Yes | `"izzan027"` | LMS password (used to verify session before extraction) |
| Tahun Ajaran | `tahun_ajaran` | `string` | Yes | `"2022/2023"` | Academic year (format: `YYYY/YYYY`) |
| Semester | `semester` | `string` | Yes | `"GENAP"` | Semester: `"GANJIL"` or `"GENAP"` (case-insensitive, auto-uppercased) |

**Response 200 OK:**

```json
{
  "status": "success",
  "data": {
    "success": true,
    "message": "KHS extracted successfully",
    "npm": "2211700006",
    "timestamp": "2026-08-06T12:45:00+07:00"
  },
  "message": "KHS extracted successfully"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| Success | `data.success` | `boolean` | `true` | Whether extraction succeeded |
| Message | `data.message` | `string` | `"KHS extracted successfully"` | Extraction result description |
| NPM | `data.npm` | `string` | `"2211700006"` | Student NPM |
| Timestamp | `data.timestamp` | `string` (ISO 8601) | `"2026-08-06T12:45:00+07:00"` | Extraction time (server timezone) |

> **Note:** This endpoint always re-extracts and overwrites existing cache.
> Use POST `/api/v1/lms/khs/data` to retrieve cached extraction data without re-parsing.

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

**Response 400 Bad Request — Missing Tahun Ajaran:**

```json
{
  "status": "error",
  "message": "tahun_ajaran is required",
  "trace_id": "abc123..."
}
```

**Response 400 Bad Request — Missing Semester:**

```json
{
  "status": "error",
  "message": "semester is required",
  "trace_id": "abc123..."
}
```

**Response 401 Unauthorized — LMS Login Failed:**

```json
{
  "status": "error",
  "message": "Username atau password salah",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 401 when LMS credentials are invalid.

**Response 404 Not Found — PDF Not Found:**

```json
{
  "status": "error",
  "message": "KHS PDF not found",
  "trace_id": "abc123..."
}
```

> **Note:** Returns 404 when no KHS PDF file exists for the given NPM/tahun_ajaran/semester.

**Response 500 Internal Server Error — Extraction Failed:**

```json
{
  "status": "error",
  "message": "KHS extraction failed",
  "trace_id": "abc123..."
}
```

> **Note:** Possible causes: PDF corrupted, PDF empty, PDF too large (>50MB), or parse error.

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/khs/extract \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"izzan027","tahun_ajaran":"2022/2023","semester":"GENAP"}'
```
