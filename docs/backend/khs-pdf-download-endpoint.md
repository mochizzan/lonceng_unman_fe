# Backend: KHS PDF Download Endpoint

**Date:** 2026-08-31
**Status:** Requirements Specification
**Related:** `docs/superpowers/specs/2026-08-31-khs-pdf-download-year-switcher-design.md`

## Overview

The Flutter app needs a new endpoint to download KHS (Kartu Hasil Studi) PDF files directly to the client device. The existing `POST /api/v1/lms/khs` endpoint only returns a server-relative file path — it does not serve the actual PDF file.

## New Endpoint

### `POST /api/v1/lms/khs/file`

Serves the KHS PDF file for a specific academic year and semester as binary data.

#### Request

**Content-Type:** `application/json`

**Body:**
```json
{
  "npm": "1234567890",
  "password": "student_password",
  "tahunAjaran": "2024/2025",
  "semester": "GANJIL"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `npm` | string | Yes | Student ID |
| `password` | string | Yes | LMS password |
| `tahunAjaran` | string | Yes | Academic year (format: "YYYY/YYYY") |
| `semester` | string | Yes | Semester: "GANJIL" or "GENAP" |

#### Response

**Success (200 OK):**
- **Content-Type:** `application/pdf`
- **Content-Disposition:** `attachment; filename="KHS_{npm}_{tahunAjaran}_{semester}.pdf"`
- **Body:** Raw PDF file bytes

**Error (400 Bad Request):**
```json
{
  "status": 400,
  "message": "Invalid request: missing required fields"
}
```

**Error (401 Unauthorized):**
```json
{
  "status": 401,
  "message": "Invalid credentials"
}
```

**Error (404 Not Found):**
```json
{
  "status": 404,
  "message": "KHS PDF not found for the specified year and semester"
}
```

**Error (500 Internal Server Error):**
```json
{
  "status": 500,
  "message": "Failed to serve PDF file"
}
```

## Implementation Requirements

### File Lookup Logic

1. Validate `npm` and `password` against LMS (same as existing endpoints)
2. Construct file path: `{DownloadDir}/{npm}/khs/{tahunAjaran}_{semester}.pdf`
   - Replace `/` in `tahunAjaran` with `_` for filename safety
   - Example: `downloads/1234567890/khs/2024_2025_GANJIL.pdf`
3. Check if file exists on disk
4. If found, stream the file directly to response
5. If not found, return 404

### Security

- Validate credentials before serving file (same as existing endpoints)
- Do not expose server file paths in response
- Rate limit to prevent abuse (same as existing endpoints)
- Log access for audit trail

### Headers

```
Content-Type: application/pdf
Content-Disposition: attachment; filename="KHS_{npm}_{tahunAjaran}_{semester}.pdf"
Content-Length: {file_size}
Accept-Ranges: bytes
```

### Performance

- Stream file directly from disk (do not load entire file into memory)
- Support range requests for resumable downloads (optional, nice-to-have)
- Set appropriate cache headers if file is static

## Error Handling

| Scenario | HTTP Status | Message |
|----------|-------------|---------|
| Missing required fields | 400 | "Invalid request: missing required fields" |
| Invalid credentials | 401 | "Invalid credentials" |
| PDF file not found | 404 | "KHS PDF not found for the specified year and semester" |
| File read error | 500 | "Failed to serve PDF file" |
| Server error | 500 | "Internal server error" |

## Implementation Notes

### Go (Golang) Reference

```go
func (h *DocumentHandler) DownloadKHSFile(c *gin.Context) {
    var req struct {
        NPM         string `json:"npm" binding:"required"`
        Password    string `json:"password" binding:"required"`
        TahunAjaran string `json:"tahunAjaran" binding:"required"`
        Semester    string `json:"semester" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"status": 400, "message": "Invalid request"})
        return
    }
    
    // Validate credentials (reuse existing logic)
    if !h.validateCredentials(req.NPM, req.Password) {
        c.JSON(401, gin.H{"status": 401, "message": "Invalid credentials"})
        return
    }
    
    // Construct file path
    safeTahunAjaran := strings.ReplaceAll(req.TahunAjaran, "/", "_")
    filePath := filepath.Join(h.downloadDir, req.NPM, "khs", 
        fmt.Sprintf("%s_%s.pdf", safeTahunAjaran, req.Semester))
    
    // Check if file exists
    if _, err := os.Stat(filePath); os.IsNotExist(err) {
        c.JSON(404, gin.H{"status": 404, "message": "KHS PDF not found"})
        return
    }
    
    // Serve file
    c.File(filePath)
}
```

### File Naming Convention

The backend saves KHS PDFs during the data initialization pipeline. The file naming must be consistent:

- **Pattern:** `{DownloadDir}/{npm}/khs/{tahunAjaran}_{semester}.pdf`
- **Example:** `downloads/1234567890/khs/2024_2025_GANJIL.pdf`

## Testing

### Test Cases

1. **Valid request with existing PDF** → 200 OK with PDF bytes
2. **Valid request with non-existing PDF** → 404 Not Found
3. **Invalid credentials** → 401 Unauthorized
4. **Missing fields** → 400 Bad Request
5. **Invalid semester value** → 400 Bad Request

### Mock for Flutter Testing

For Flutter app testing without backend, mock the endpoint to return a small test PDF file.

## Migration

- No breaking changes to existing endpoints
- New endpoint is additive
- Existing `POST /api/v1/lms/khs` continues to work unchanged
- File storage structure unchanged
