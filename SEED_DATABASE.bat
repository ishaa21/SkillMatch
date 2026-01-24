@echo off
echo ========================================
echo POPULATING DATABASE WITH SAMPLE DATA
echo ========================================
echo.
echo This will create:
echo - 15 Companies
echo - 15 Students
echo - 20 Internships
echo - 30+ Applications
echo.
echo ========================================
echo.

cd /d "c:\Users\admin\.gemini\antigravity\scratch\internship_app\backend"

node src/utils/seedDatabase.js

echo.
echo ========================================
echo.
pause
