@echo off
echo ======================================
echo  SkillMatch - Quick Fix & Start
echo ======================================
echo.

echo [1/3] Checking Backend Status...
curl http://localhost:5000/api/auth/login -Method POST -ContentType "application/json" -Body "{}" -TimeoutSec 3 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Backend is NOT running!
    echo Please start the backend first:
    echo   cd backend
    echo   npm start
    echo.
    pause
    exit /b 1
)
echo Backend is RUNNING ✓
echo.

echo [2/3] Cleaning Flutter Build...
cd frontend
call flutter clean
echo.

echo [3/3] Starting Flutter App...
echo.
echo IMPORTANT: Make sure to update your IP address in:
echo   lib/core/constants/api_constants.dart
echo.
echo For Physical Device:
echo   - Set _useEmulator = false
echo   - Set _lanIP to your PC's IP (run 'ipconfig' to find it)
echo.
echo For Emulator:
echo   - Set _useEmulator = true
echo.

call flutter run

pause
