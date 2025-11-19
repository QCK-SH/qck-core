# QCK Core (OSS) - Makefile

.PHONY: help up down logs build clean dev test lint format check

# Default target
help:
	@echo "QCK Core (OSS) Development Commands:"
	@echo ""
	@echo "  up        Start development environment"
	@echo "  down      Stop development environment"
	@echo "  logs      Show logs for all services"
	@echo "  build     Build all Docker images"
	@echo "  clean     Remove all containers and volumes"
	@echo "  dev       Start development environment (alias for up)"
	@echo "  test      Run tests"
	@echo "  lint      Run linting"
	@echo "  format    Format code"
	@echo "  check     Run all checks (test + lint)"
	@echo ""
	@echo "Service-specific logs:"
	@echo "  logs-backend     Show backend logs"
	@echo "  logs-dashboard   Show dashboard logs"
	@echo "  logs-db          Show database logs"
	@echo ""
	@echo "API Endpoints:"
	@echo "  Backend: http://localhost:10180/api/v1"
	@echo "  Dashboard: http://localhost:10180"
	@echo "  Adminer: http://localhost:10181"

# Development environment
up dev:
	@echo "🚀 Starting QCK Core development environment..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml up -d
	@echo "✅ Services started successfully!"
	@echo "📍 API: http://localhost:10180/api/v1"
	@echo "🎯 Dashboard: http://localhost:10180"

# Stop environment
down:
	@echo "🛑 Stopping QCK Core development environment..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml down
	@echo "✅ Services stopped successfully!"

# Show logs
logs:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f

# Service-specific logs
logs-backend:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f qck-backend-oss-dev

logs-dashboard:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f qck-dashboard-oss-dev

logs-db:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml logs -f qck-postgres-oss-dev

# Build Docker images
build:
	@echo "🔨 Building Docker images..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml build
	@echo "✅ Build completed!"

# Clean up everything (DANGEROUS - removes volumes)
clean:
	@echo "🧹 Cleaning up containers and volumes..."
	@read -p "⚠️  This will delete ALL data. Are you sure? [y/N] " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose --env-file .env.dev -f docker-compose.dev.yml down -v; \
		docker system prune -f; \
		echo "✅ Cleanup completed!"; \
	else \
		echo "❌ Cleanup cancelled."; \
	fi

# Development commands
test:
	@echo "🧪 Running tests..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev cargo test
	@echo "✅ Tests completed!"

lint:
	@echo "🔍 Running linting..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev cargo clippy -- -D warnings
	@echo "✅ Linting completed!"

format:
	@echo "🎨 Formatting code..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev cargo fmt
	@echo "✅ Code formatted!"

check: test lint
	@echo "✅ All checks completed!"

# Status commands
status:
	@echo "📊 Service Status:"
	docker-compose --env-file .env.dev -f docker-compose.dev.yml ps

# Shell access
shell-backend:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev /bin/bash

shell-db:
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-postgres-oss-dev psql -U qck_user -d qck_db

# Database operations
migrate:
	@echo "🔄 Running database migrations..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev diesel migration run
	@echo "✅ Migrations completed!"

migrate-status:
	@echo "📋 Checking migration status..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml exec qck-backend-oss-dev diesel migration pending

# Quick restart
restart:
	@echo "🔄 Restarting services..."
	docker-compose --env-file .env.dev -f docker-compose.dev.yml restart
	@echo "✅ Services restarted!"