#!/bin/bash
cd /home/hnde/EthioWorkForce/backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
