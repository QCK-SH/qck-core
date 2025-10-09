# QCK Core (OSS) - Memory

> Open-source URL shortener - self-hostable alternative

## Quick Start
```bash
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d
```

## API Endpoints (via nginx :10180)

**Base**: `http://localhost:10180/api/v1`

### Auth (Public)
- `POST /auth/register` - Register (auto-verified)
- `POST /auth/login` - Login
- `POST /auth/refresh` - Refresh token
- `POST /auth/logout` - Logout
- `POST /auth/forgot-password` - Password reset
- `POST /auth/reset-password` - Reset with token

### Protected (JWT Required)
- `GET /auth/me` - Current user
- `POST /auth/validate` - Validate token
- `POST /links` - Create link
- `GET /links` - List links
- `GET /links/{id}` - Get link
- `PUT /links/{id}` - Update link
- `DELETE /links/{id}` - Delete link
- `POST /links/bulk` - Bulk create
- `GET /links/{id}/stats` - Link stats

### System
- `GET /health` - Health check
- `GET /metrics/rate-limiting` - Rate metrics
- `GET /docs` - Swagger (if enabled)

### Redirects
- `GET /{short_code}` - Redirect to URL
- `GET /{short_code}/preview` - Preview URL

## Architecture
- **Backend**: qck-backend folder (qck-backend-core submodule)
- **Services**: PostgreSQL, Redis, ClickHouse
- **Features**: Auto-verification, no teams/payments (OSS only)

## Recent Fixes
- Renamed containers to qck-backend-oss-dev
- Fixed /auth/me and /validate middleware
- Removed cloud-specific features

---
*OSS version without cloud features*