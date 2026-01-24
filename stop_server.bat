@echo off
echo ========================================
echo EthioWorkForce - Stopping Backend Server
echo ========================================
echo.

for /f "tokens=5" %%a in ('netstat -aon ^| find ":8000" ^| find "LISTENING"') do (
    echo Stopping process %%a on port 8000...
    taskkill /F /PID %%a
)

echo.
echo Server stopped.
pause
