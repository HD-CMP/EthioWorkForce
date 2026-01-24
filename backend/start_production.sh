#!/bin/bash

echo "========================================"
echo "EthioWorkForce - Production Mode"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d "venv" ]; then
    echo "ERROR: Virtual environment not found!"
    exit 1
fi

source venv/bin/activate

echo "Starting FastAPI server in production mode..."
echo "Workers: 4"
echo "Host: 0.0.0.0"
echo "Port: 8000"
echo ""

uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4 --no-access-log
