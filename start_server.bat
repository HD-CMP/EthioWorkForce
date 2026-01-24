@echo off
echo ========================================
echo EthioWorkForce - Starting Backend Server
echo ========================================
echo.

cd backend

if not exist "venv" (
    echo ERROR: Virtual environment not found!
    echo Please run setup_local_postgres.sh first
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Starting FastAPI server...
echo Server will be available at: http://localhost:8000
echo API Docs: http://localhost:8000/api/docs
echo.
echo Press Ctrl+C to stop the server
echo.

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause
