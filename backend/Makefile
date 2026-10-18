.PHONY: help install run test lint format clean migrate upgrade downgrade docker-up docker-down

help:
	@echo "EthioWorkforce Backend - Available Commands:"
	@echo "  make install      - Install dependencies"
	@echo "  make run          - Run development server"
	@echo "  make test         - Run tests"
	@echo "  make lint         - Run linters"
	@echo "  make format       - Format code"
	@echo "  make clean        - Clean temporary files"
	@echo "  make migrate      - Create new migration"
	@echo "  make upgrade      - Apply migrations"
	@echo "  make downgrade    - Rollback migrations"
	@echo "  make docker-up    - Start Docker services"
	@echo "  make docker-down  - Stop Docker services"

install:
	pip install -r requirements.txt

run:
	python run.py

test:
	pytest -v --cov=app --cov-report=html

lint:
	flake8 app
	mypy app

format:
	black app
	isort app

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .mypy_cache htmlcov .coverage

migrate:
	alembic revision --autogenerate -m "$(message)"

upgrade:
	alembic upgrade head

downgrade:
	alembic downgrade -1

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down
