@echo off
echo ========================================
echo   STARTING MONGODB - KEEP WINDOW OPEN
echo ========================================
echo.
echo Starting MongoDB server...
echo.

cd /d "C:\Program Files\MongoDB\Server\8.2\bin"

echo If MongoDB starts successfully, you will see:
echo "Waiting for connections on port 27017"
echo.
echo IMPORTANT: DO NOT CLOSE THIS WINDOW!
echo MongoDB must stay running for the app to work.
echo.

start "MongoDB Server" /MIN mongod.exe

echo.
echo MongoDB starting in background window...
echo.
echo Now wait 5 seconds, then try registration again!
echo.
timeout /t 5 /nobreak
echo.
echo MongoDB should be ready now!
echo Try registration again in your browser.
echo.
pause
