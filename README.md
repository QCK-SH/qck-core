# QCK Core (Open Source)

> Self-hostable URL shortener platform - The open-source version of QCK
> **Repository**: https://github.com/QCK-SH/qck-core

## 🚀 What is QCK Core?

QCK Core is the **open-source, self-hostable** version of the QCK URL shortening platform. It provides all the essential features for individuals and teams to run their own URL shortener without any vendor lock-in or cloud dependencies.

### OSS vs Cloud

- **QCK Core (OSS)** - This repository
  - Self-hosted on your own infrastructure
  - Core features: Links, Analytics, Dashboard, Settings
  - Auto-verified user registration (no email verification)
  - No team management or payment features
  - Completely free and open source

- **QCK Cloud** - Hosted SaaS version
  - Managed hosting with automatic updates
  - Additional features: Team management, Custom domains, Advanced API
  - Email verification required
  - Subscription-based pricing

## ✨ Features

- **URL Shortening**: Create short, memorable links
- **Custom Short Codes**: Choose your own short code or auto-generate
- **Analytics Dashboard**: Track clicks, locations, referrers, and devices
- **QR Code Generation**: Generate QR codes for your short links
- **Link Management**: Edit, archive, and organize your links
- **User Authentication**: JWT-based secure authentication
- **REST API**: Full API access for automation
- **Self-Hosted**: Run on your own servers with full control

## 🏗️ Architecture

QCK Core consists of three main components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Nginx Router (:10180)                    │
│                         Entry Point                          │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐
  │  Dashboard  │    │   Backend    │    │  Short URLs  │
  │   Next.js   │    │     Rust     │    │  Redirects   │
  │   (React)   │    │    (Axum)    │    │              │
  └─────────────┘    └──────────────┘    └──────────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │PostgreSQL│   │  Redis   │   │ClickHouse│
        │          │   │  Cache   │   │ Analytics│
        └──────────┘   └──────────┘   └──────────┘
```

## 📋 Prerequisites

### Required
- **Docker** (20.10+) and **Docker Compose** (2.0+)
- **Git** for cloning the repository
- At least **4GB RAM** and **2 CPU cores**
- **10GB disk space** minimum

### Optional (for local development without Docker)
- **Rust** 1.82+ with Cargo
- **Node.js** 18+ with pnpm
- **PostgreSQL** 16+
- **Redis** 7+
- **ClickHouse** 23+

## 🚀 Quick Start (Recommended)

### 1. Clone the Repository

```bash
git clone https://github.com/QCK-SH/qck-core.git
cd qck-core
```

### 2. Start the Platform

```bash
# Start all services in development mode
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d

# View logs
docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f

# Check service health
docker-compose --env-file .env.dev -f docker-compose.dev.yml ps
```

### 3. Access the Platform

The platform will be available at:

| Service | URL | Description |
|---------|-----|-------------|
| **Dashboard** | http://localhost:10180/ | Main user interface |
| **API** | http://localhost:10180/api | Backend API endpoints |
| **Short URLs** | http://localhost:10180/{code} | URL redirects |
| **API Docs** | http://localhost:10180/api/v1/docs | Swagger UI (if enabled) |
| **Database UI** | http://localhost:10181 | Adminer (PostgreSQL management) |
| **Health Check** | http://localhost:10180/health | System health status |

### 4. Create Your First Account

1. Open http://localhost:10180/ in your browser
2. Click **"Sign Up"** to create an account
3. Fill in your details - **accounts are auto-verified in OSS**
4. You'll be redirected to the dashboard
5. Start creating short links!

## 🌐 Available URLs

### User Interface
- `/` - Dashboard home (after login)
- `/login` - Sign in page
- `/register` - Sign up page
- `/forgot-password` - Password reset request
- `/reset-password` - Password reset form
- `/dashboard` - Main dashboard
- `/links` - Link management
- `/analytics` - Analytics dashboard
- `/settings` - User settings

### API Endpoints

**Base URL**: `http://localhost:10180/api/v1`

#### Authentication (Public)
- `POST /auth/register` - Create new account (auto-verified)
- `POST /auth/login` - Sign in with credentials
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Sign out
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

#### Links (Authenticated)
- `POST /links` - Create short link
- `GET /links` - List all links
- `GET /links/{id}` - Get link details
- `PUT /links/{id}` - Update link
- `DELETE /links/{id}` - Delete link
- `POST /links/bulk` - Create multiple links
- `GET /links/{id}/stats` - Link analytics

#### System
- `GET /health` - Health check
- `GET /health/db` - Database health
- `GET /metrics/rate-limiting` - Rate limit metrics

#### Short URL Redirects
- `GET /{short_code}` - Redirect to original URL
- `GET /{short_code}/preview` - Preview URL before redirect

## ⚙️ Configuration

### Environment Variables

All configuration is in `.env.dev` for development. Key variables:

```bash
# Database
DATABASE_URL=postgresql://qck_dev_user:dev_password_2024@qck-postgres-oss-dev:5432/qck_dev_db

# Redis
REDIS_URL=redis://qck-redis-oss-dev:6379

# ClickHouse
CLICKHOUSE_URL=http://qck-clickhouse-oss-dev:8123

# JWT Secrets (CHANGE IN PRODUCTION!)
JWT_ACCESS_SECRET=test-access-secret-hs256-minimum-32-chars-required
JWT_REFRESH_SECRET=test-refresh-secret-hs256-minimum-32-chars-required
JWT_ACCESS_EXPIRY=3600  # 1 hour
JWT_REFRESH_EXPIRY=86400  # 24 hours

# Short Code Configuration
SHORT_CODE_MIN_LENGTH=4
SHORT_CODE_DEFAULT_LENGTH=7
SHORT_CODE_MAX_LENGTH=12

# Frontend URLs
NEXT_PUBLIC_API_URL=http://localhost:10180/api
NEXT_PUBLIC_APP_URL=http://localhost:10180
NEXT_PUBLIC_SHORT_BASE_URL=http://localhost:10180

# Features
ENABLE_SWAGGER_UI=true  # API documentation
ENABLE_ANALYTICS=true   # Click analytics
```

### Ports

| Service | Internal Port | External Port | Description |
|---------|--------------|---------------|-------------|
| Nginx Router | 8080 | 10180 | Main entry point |
| Dashboard | 3000 | - | Internal only (via nginx) |
| Backend | 8080 | - | Internal only (via nginx) |
| PostgreSQL | 5432 | - | Internal only |
| Redis | 6379 | - | Internal only |
| ClickHouse | 8123 | - | Internal only |
| Adminer | 8080 | 10181 | Database UI |

## 🔧 Development

### Backend Development (Rust)

```bash
# Access backend container
docker exec -it qck-backend-oss-dev bash

# Build
cargo build

# Run tests
cargo test

# Check for errors
cargo clippy

# Format code
cargo fmt
```

### Frontend Development (Next.js)

```bash
# Access dashboard container
docker exec -it qck-dashboard-oss-dev sh

# Install dependencies
pnpm install

# Development mode
pnpm dev

# Build
pnpm build

# Run tests
pnpm test
```

### Database Migrations

**IMPORTANT**: Migrations are embedded and run automatically on backend startup.

```bash
# Create new migration
docker exec -it qck-backend-oss-dev diesel migration generate your_migration_name

# Edit the generated files in migrations/diesel/

# Restart backend to apply (migrations auto-run)
docker-compose --env-file .env.dev -f docker-compose.dev.yml restart qck-backend-oss-dev

# Copy auto-generated schema
docker cp qck-backend-oss-dev:/app/src/schema.rs qck-backend/src/schema.rs

# Commit BOTH migration and schema
git add migrations/ qck-backend/src/schema.rs
git commit -m "feat: add migration for [feature]"
```

## 🛠️ Management Commands

### Service Management

```bash
# Start all services
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d

# Stop all services
docker-compose --env-file .env.dev -f docker-compose.dev.yml down

# Restart specific service
docker-compose --env-file .env.dev -f docker-compose.dev.yml restart qck-backend-oss-dev

# View logs
docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f [service-name]

# Check service status
docker-compose --env-file .env.dev -f docker-compose.dev.yml ps
```

### Database Management

```bash
# Access PostgreSQL via Adminer
# Open http://localhost:10181
# System: PostgreSQL
# Server: qck-postgres-oss-dev
# Username: qck_dev_user
# Password: dev_password_2024
# Database: qck_dev_db

# Or via psql command line
docker exec -it qck-postgres-oss-dev psql -U qck_dev_user -d qck_dev_db

# Backup database
docker exec qck-postgres-oss-dev pg_dump -U qck_dev_user qck_dev_db > backup.sql

# Restore database
cat backup.sql | docker exec -i qck-postgres-oss-dev psql -U qck_dev_user -d qck_dev_db
```

### Redis Management

```bash
# Access Redis CLI
docker exec -it qck-redis-oss-dev redis-cli

# Common commands:
# KEYS * - List all keys
# GET key - Get value
# FLUSHALL - Clear all data (WARNING!)
# INFO - Server info
```

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check logs for errors
docker-compose --env-file .env.dev -f docker-compose.dev.yml logs

# Ensure ports are not in use
lsof -i :10180
lsof -i :10181

# Try rebuilding
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

### Database Connection Issues

```bash
# Check PostgreSQL is healthy
docker-compose --env-file .env.dev -f docker-compose.dev.yml ps qck-postgres-oss-dev

# Check database logs
docker logs qck-postgres-oss-dev

# Verify connection
docker exec qck-postgres-oss-dev pg_isready -U qck_dev_user -d qck_dev_db
```

### Dashboard Shows 404 Errors

```bash
# Rebuild dashboard
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d --build qck-dashboard-oss-dev

# Check dashboard logs
docker logs qck-dashboard-oss-dev

# Verify nginx config
docker exec nginx-router-oss-dev cat /etc/nginx/conf.d/default.conf
```

### Backend API Not Responding

```bash
# Check backend health
curl http://localhost:10180/api/v1/health

# Check backend logs
docker logs qck-backend-oss-dev

# Restart backend
docker-compose --env-file .env.dev -f docker-compose.dev.yml restart qck-backend-oss-dev
```

### Clear All Data and Start Fresh

```bash
# ⚠️ WARNING: This will DELETE ALL DATA
docker-compose --env-file .env.dev -f docker-compose.dev.yml down -v

# Start fresh
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

## 🚀 Production Deployment

### Security Checklist

Before deploying to production:

- [ ] Change all default passwords in `.env`
- [ ] Generate strong JWT secrets (minimum 32 characters)
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure proper CORS origins
- [ ] Set up firewall rules (only expose ports 80/443)
- [ ] Enable rate limiting (already configured)
- [ ] Set up log rotation
- [ ] Configure automated backups
- [ ] Disable Swagger UI (`ENABLE_SWAGGER_UI=false`)
- [ ] Disable Adminer (remove from docker-compose)
- [ ] Use production-grade secrets management
- [ ] Set up monitoring and alerts

### Production Environment Variables

Create a `.env` file for production (never commit this):

```bash
# Use strong, randomly generated secrets
JWT_ACCESS_SECRET=$(openssl rand -base64 48)
JWT_REFRESH_SECRET=$(openssl rand -base64 48)
JTI_HASH_SALT=$(openssl rand -base64 48)

# Production database credentials
DATABASE_URL=postgresql://prod_user:STRONG_PASSWORD@postgres:5432/qck_prod
POSTGRES_USER=prod_user
POSTGRES_PASSWORD=STRONG_PASSWORD
POSTGRES_DB=qck_prod

# Production settings
ENVIRONMENT=production
NODE_ENV=production
ENABLE_SWAGGER_UI=false
ENABLE_DEBUG_ENDPOINTS=false
RUST_LOG=info,qck_backend=info

# Your domain
NEXT_PUBLIC_API_URL=https://yourdomain.com/api
NEXT_PUBLIC_APP_URL=https://yourdomain.com
NEXT_PUBLIC_SHORT_BASE_URL=https://yourdomain.com
```

### Deployment with Docker Compose

```bash
# Use production compose file (create docker-compose.yml)
docker-compose up -d

# Monitor logs
docker-compose logs -f

# Set up automatic restarts
# Services are configured with "restart: unless-stopped"
```

### Nginx/Reverse Proxy Setup

If using external reverse proxy (recommended):

```nginx
# /etc/nginx/sites-available/qck.conf
server {
    listen 80;
    server_name yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    # SSL Configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to QCK
    location / {
        proxy_pass http://localhost:10180;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 📊 Tech Stack

- **Backend**: Rust with Axum framework
- **Frontend**: Next.js 14 (React) with TypeScript
- **Database**: PostgreSQL 16 (primary data)
- **Cache**: Redis 7 (sessions, rate limiting)
- **Analytics**: ClickHouse 23 (click tracking)
- **Proxy**: Nginx Alpine
- **ORM**: Diesel (Rust)
- **UI**: Tailwind CSS + shadcn/ui
- **Auth**: JWT with HS256

## 📚 Documentation

- **API Documentation**: http://localhost:10180/api/v1/docs (when ENABLE_SWAGGER_UI=true)
- **Backend Details**: See `qck-backend/CLAUDE.md`
- **Dashboard Details**: See `qck-dashboard/CLAUDE.md`

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Rust conventions (rustfmt, clippy)
- Follow TypeScript/React best practices
- Write tests for new features
- Update documentation
- Keep commits clean and descriptive

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with amazing open-source technologies:
- Rust and the Axum framework
- Next.js and React
- PostgreSQL, Redis, and ClickHouse
- The entire open-source community

## 🔗 Links

- **Website**: https://qck.sh
- **GitHub**: https://github.com/QCK-SH/qck-core
- **Documentation**: https://docs.qck.sh
- **Discord**: https://discord.gg/qck (coming soon)

## ⚡ Quick Reference

```bash
# Start everything
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d

# Access dashboard
open http://localhost:10180

# View all logs
docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f

# Stop everything
docker-compose --env-file .env.dev -f docker-compose.dev.yml down

# Rebuild everything
docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

---

**Made with ❤️ by the QCK Team**
