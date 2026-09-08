# Download KRS

Download KRS (Kartu Rencana Studi) PDF for a specific student. Navigates to the KRS page, extracts the current semester number, then downloads the PDF.

**Endpoint:** `POST /api/v1/lms/krs`

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
    "message": "KRS downloaded successfully",
    "npm": "2211700006",
    "file_path": "downloads/2211700006/krs/semester_8.pdf",
    "size": 12345,
    "timestamp": "2026-08-06T00:45:00+07:00"
  },
  "message": "KRS downloaded successfully"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| Success | `data.success` | `boolean` | `true` | Whether the download succeeded |
| Message | `data.message` | `string` | `"KRS downloaded successfully"` | Download result description |
| NPM | `data.npm` | `string` | `"2211700006"` | Student NPM |
| File Path | `data.file_path` | `string` | `"downloads/2211700006/krs/semester_8.pdf"` | Canonical saved file path (relative to project root) |
| Size | `data.size` | `integer` | `12345` | File size in bytes |
| Timestamp | `data.timestamp` | `string` (ISO 8601) | `"2026-08-06T00:45:00+07:00"` | Download time (server timezone) |

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

**Response 500 Internal Server Error — Download Failed:**

```json
{
  "status": "error",
  "message": "KRS download failed",
  "trace_id": "abc123..."
}
```

> **Note:** Possible causes: LMS page load error, PDF generation failed, or network timeout.

**Example curl:**

```bash
curl -X POST http://localhost:3000/api/v1/lms/krs \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"izzan027"}'
```

**Saved File Location:**

```
downloads/2211700006/krs/semester_8.pdf
```

> **Note:** KRS filename uses `semester_{N}.pdf` where N is the student's current semester number extracted from the KRS page. File is overwritten if it already exists (latest download wins).
