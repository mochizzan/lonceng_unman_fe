# LMS Login

Validate LMS credentials and cache the session for subsequent requests. On success, the browser session is kept alive for reuse.

**Endpoint:** `POST /api/v1/lms/login`

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

**Response 200 OK — Login Success:**

```json
{
  "status": "success",
  "data": {
    "success": true,
    "message": "Login successful",
    "npm": "2211700006",
    "timestamp": "2026-08-06T00:45:00+07:00"
  },
  "message": "Login successful"
}
```

| Field | JSON Path | Type | Example Value | Description |
|-------|-----------|------|---------------|-------------|
| Success | `data.success` | `boolean` | `true` | Whether the login attempt succeeded |
| Message | `data.message` | `string` | `"Login successful"` | Login result description from the server |
| NPM | `data.npm` | `string` | `"2211700006"` | The NPM that was used for login |
| Timestamp | `data.timestamp` | `string` (ISO 8601) | `"2026-08-06T00:45:00+07:00"` | When the login attempt occurred (server timezone) |

> **Note:** Both success and login failure return HTTP 200. Differentiate by checking `data.success`.

**Response 200 OK — Login Failed (Invalid Credentials):**

```json
{
  "status": "success",
  "data": {
    "success": false,
    "message": "Username atau password salah",
    "npm": "2211700006",
    "timestamp": "2026-08-06T00:45:00+07:00"
  },
  "message": "Username atau password salah"
}
```

> **Note:** Login failure returns HTTP 200 with `data.success: false`. The message `"Username atau password salah"` is returned when LMS credentials are invalid.

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

**Response 500 Internal Server Error — Browser Failure:**

```json
{
  "status": "error",
  "message": "login operation failed",
  "trace_id": "abc123..."
}
```

> **Note:** Internal error details are logged server-side only, never exposed to the client.
> Possible causes: Chrome/Chromium not installed, browser timeout, LMS unreachable.

**Example curl:**

```bash
# Login success
curl -X POST http://localhost:3000/api/v1/lms/login \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"izzan027"}'

# Login failed (wrong credentials)
curl -X POST http://localhost:3000/api/v1/lms/login \
  -H "Content-Type: application/json" \
  -d '{"npm":"2211700006","password":"wrong"}'

# Missing NPM
curl -X POST http://localhost:3000/api/v1/lms/login \
  -H "Content-Type: application/json" \
  -d '{"password":"test"}'
```
