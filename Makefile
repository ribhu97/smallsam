# Small Sam Development Makefile

.PHONY: help install-dev start-dev stop-dev test lint format clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install-dev: ## Install development dependencies
	@echo "Installing development dependencies..."
	cd backend && python -m venv venv && source venv/bin/activate && pip install -r requirements-dev.txt
	cd agent-framework && python -m venv venv && source venv/bin/activate && pip install -r requirements-dev.txt
	cd data-orchestration && python -m venv venv && source venv/bin/activate && pip install -r requirements-dev.txt
	cd frontend && npm install
	pip install pre-commit
	pre-commit install

start-dev: ## Start development environment
	@echo "Starting development infrastructure..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "Development infrastructure started!"
	@echo "PostgreSQL: localhost:5432"
	@echo "Redis: localhost:6379"
	@echo "Qdrant: localhost:6333"
	@echo "PgAdmin: http://localhost:5050 (admin@smallsam.dev / admin)"
	@echo "Redis Commander: http://localhost:8081"

stop-dev: ## Stop development environment
	@echo "Stopping development infrastructure..."
	docker-compose -f docker-compose.dev.yml down

start-services: ## Start all services
	@echo "Starting all services..."
	docker-compose up -d

stop-services: ## Stop all services
	@echo "Stopping all services..."
	docker-compose down

test: ## Run all tests
	@echo "Running backend tests..."
	cd backend && source venv/bin/activate && pytest
	@echo "Running agent framework tests..."
	cd agent-framework && source venv/bin/activate && pytest
	@echo "Running data orchestration tests..."
	cd data-orchestration && source venv/bin/activate && pytest
	@echo "Running frontend tests..."
	cd frontend && npm test

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	docker-compose -f docker-compose.test.yml up --abort-on-container-exit

lint: ## Run linting
	@echo "Running linting..."
	cd backend && source venv/bin/activate && flake8 app/
	cd agent-framework && source venv/bin/activate && flake8 app/
	cd data-orchestration && source venv/bin/activate && flake8 app/
	cd frontend && npm run lint

format: ## Format code
	@echo "Formatting code..."
	cd backend && source venv/bin/activate && black app/ && isort app/
	cd agent-framework && source venv/bin/activate && black app/ && isort app/
	cd data-orchestration && source venv/bin/activate && black app/ && isort app/
	cd frontend && npm run lint:fix

type-check: ## Run type checking
	@echo "Running type checking..."
	cd backend && source venv/bin/activate && mypy app/
	cd agent-framework && source venv/bin/activate && mypy app/
	cd data-orchestration && source venv/bin/activate && mypy app/
	cd frontend && npm run type-check

clean: ## Clean up temporary files and containers
	@echo "Cleaning up..."
	docker-compose down -v
	docker-compose -f docker-compose.dev.yml down -v
	docker-compose -f docker-compose.test.yml down -v
	docker system prune -f
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name "node_modules" -exec rm -rf {} +

logs: ## Show logs from all services
	docker-compose logs -f

logs-backend: ## Show backend logs
	docker-compose logs -f backend

logs-frontend: ## Show frontend logs
	docker-compose logs -f frontend

logs-agents: ## Show agent framework logs
	docker-compose logs -f agent-framework

logs-data: ## Show data orchestration logs
	docker-compose logs -f data-orchestration

db-migrate: ## Run database migrations
	cd backend && source venv/bin/activate && alembic upgrade head

db-reset: ## Reset database
	docker-compose exec postgres psql -U smallsam -d smallsam_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	$(MAKE) db-migrate

security-scan: ## Run security scans
	cd backend && source venv/bin/activate && bandit -r app/
	cd agent-framework && source venv/bin/activate && bandit -r app/
	cd data-orchestration && source venv/bin/activate && bandit -r app/
	cd frontend && npm audit

build: ## Build all services
	docker-compose build

build-prod: ## Build production images
	docker-compose -f docker-compose.prod.yml build