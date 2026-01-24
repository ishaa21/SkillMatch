@echo off
echo ========================================
echo STARTING MONGODB FOR INTERNSHIP APP
echo ========================================
echo.

REM Create data directory if it doesn't exist
if not exist "C:\data\db" mkdir "C:\data\db"

echo Starting MongoDB server on port 27017...
echo Data directory: C:\data\db
echo.
echo IMPORTANT: Keep this window open!
echo Press Ctrl+C to stop MongoDB when done.
echo.
echo ========================================
echo.

"C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe" --dbpath "C:\data\db"

pause
