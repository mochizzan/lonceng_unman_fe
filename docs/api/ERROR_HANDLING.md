# Error Handling

## HTTP Status Codes

| HTTP Status | Constructor | When |
|-------------|-------------|------|
| 400 | `apperror.BadRequest(msg)` | Invalid request (body parse error, missing fields, invalid NPM format) |
| 401 | `apperror.Unauthorized(msg)` | Authentication failure (LMS login failed) |
| 403 | `apperror.Forbidden(msg)` | Permission denied (file system permission denied) |
| 404 | `apperror.NotFound(msg, err)` | Resource not found (PDF missing, extraction data not found) |
| 500 | `apperror.Internal(msg, err)` | Infrastructure failure (browser crash, page load error, PDF corrupted) |

## Extraction-Specific Errors

| HTTP Status | Scenario | Message Pattern |
|-------------|----------|-----------------|
| 404 | KRS PDF not found | `KRS PDF not found for npm: {npm}` |
| 404 | KHS PDF not found | `KHS PDF not found` |
| 404 | KRS extraction not found | `KRS extraction not found for npm: {npm}` |
| 404 | KHS extraction not found | `KHS extraction not found` |
| 500 | PDF corrupted | `pdf file may be corrupted` |
| 500 | PDF empty | `pdf contains no extractable text` |
| 500 | PDF too large | `pdf too large: {size} bytes` |
| 500 | Parse error | `pdf parsing failed: {detail}` |

## Common 400 Validation Errors

| Message | Trigger |
|---------|---------|
| `invalid request body` | Malformed JSON |
| `npm is required` | Missing `npm` field |
| `npm must contain only digits` | NPM contains non-numeric characters |
| `npm must be 8-12 characters` | NPM length outside 8-12 range |
| `password is required` | Missing `password` field |
| `tahun_ajaran is required` | Missing `tahun_ajaran` (KHS endpoints) |
| `semester is required` | Missing `semester` (KHS endpoints) |
| `semester must be GANJIL or GENAP` | Invalid semester value |
