# Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `APP_NAME` | `string` | `lonceng_unman_be` | Application name |
| `APP_ENV` | `string` | `development` | Environment: `development`, `staging`, `production` |
| `APP_PORT` | `string` | `3000` | Server port (validated: 1-65535) |
| `APP_HOST` | `string` | `0.0.0.0` | Bind address |
| `LMS_BASE_URL` | `string` | `https://elearning.universitasmandiri.ac.id` | LMS base URL |
| `LMS_DASHBOARD_URL` | `string` | `https://elearning.universitasmandiri.ac.id/admin/` | Dashboard URL (used for login success detection) |
| `BROWSER_HEADLESS` | `string` | `true` | Run Chrome headless (`true`/`false`) |
| `BROWSER_TIMEOUT` | `string` | `60s` | Overall browser operation timeout (Go duration format) |
| `DNS_TIMEOUT` | `string` | `5s` | DNS lookup timeout before browser connection (Go duration format) |
| `DOWNLOAD_DIR` | `string` | `./downloads` | PDF download directory |
| `EXTRACT_DIR` | `string` | `./extracted` | Directory for extracted JSON cache files |
| `SESSION_TTL` | `string` | `15m` | Session cache duration before expiry (Go duration format) |
| `MAX_SESSIONS` | `string` | `15` | Maximum cached browser sessions in memory |
| `PROFILE_BASE_DIR` | `string` | `./profiles` | Base directory for persistent Chrome profiles |
| `PHOTO_CACHE_TTL` | `string` | `15m` | Student photo disk cache duration (Go duration format) |
| `MAX_BODY_SIZE` | `string` | `1MB` | Max HTTP request body size (Fiber format) |
| `MAX_PDF_SIZE` | `string` | `50MB` | Max PDF file size for extraction |
| `CORS_ALLOW_ORIGINS` | `string` | `*` | CORS allowed origins |
| `CORS_ALLOW_METHODS` | `string` | `GET,POST,OPTIONS` | CORS allowed HTTP methods |
| `CORS_ALLOW_HEADERS` | `string` | `Content-Type` | CORS allowed request headers |

## Prerequisites

- Go 1.26.4+
- Chrome/Chromium installed (required for LMS login via go-rod)
- go-rod v0.116.2 (browser automation, auto-installed via `go mod tidy`)
- razvandimescu/gopdf v0.9.5 (PDF generation, auto-installed via `go mod tidy`)
