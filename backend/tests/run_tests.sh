#!/bin/bash

echo "========================================"
echo "EthioWorkForce Test Suite"
echo "========================================"

cd "$(dirname "$0")/.."

echo "Running unit tests..."
pytest tests/ -m unit -v

echo ""
echo "Running integration tests..."
pytest tests/ -m integration -v

echo ""
echo "Running all tests with coverage..."
pytest tests/ --cov=app --cov-report=html --cov-report=term-missing

echo ""
echo "Test results saved to htmlcov/index.html"
echo "========================================"
