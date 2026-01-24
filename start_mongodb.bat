@echo off
echo ========================================
echo STARTING MONGODB FOR INTERNSHIP APP
echo ========================================
echo.

cd /d "C:\Program Files\MongoDB\Server\8.2\bin"

echo Starting MongoDB server...
echo.
echo IMPORTANT: Keep this window open!
echo Press Ctrl+C to stop MongoDB when done.
echo.
echo ========================================
echo.

mongod.exe

pause
