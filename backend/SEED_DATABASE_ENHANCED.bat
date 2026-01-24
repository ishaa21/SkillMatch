@echo off
echo.
echo ============================================
echo   SkillMatch - Enhanced Database Seeding
echo ============================================
echo.
echo This will:
echo   - Clear all existing data
echo   - Create 2 Admin accounts
echo   - Create 20 Company accounts (15 approved, 5 pending)
echo   - Create 20 Student accounts with complete profiles
echo   - Create 30 Sample internships
echo   - Create 50+ Sample applications with AI match scores
echo.
echo WARNING: This will DELETE all existing data!
echo.
set /p CONFIRM="Continue? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo.
    echo Seeding cancelled.
    echo.
    pause
    exit /b
)

echo.
echo Starting enhanced data seeding...
echo.

cd /d "%~dp0"
node src\scripts\seedDataEnhanced.js

echo.
pause
