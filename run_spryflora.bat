@echo off
title SpryFlora Launcher - Backend ^& Web (Edge)
color 0A

echo ====================================================
echo SPRYFLORA FULL-STACK LAUNCHER
echo ====================================================
echo Starting Node.js Backend Server ^& Flutter Web App on Edge...
echo.

:: 1. Launch Node.js Backend Server in a new window
echo [1/2] Starting SpryFlora Backend Server on http://localhost:3000 ...
start "SpryFlora Node.js Backend Server" cmd /k "cd /d %~dp0spryflora_backend && npm run dev"

:: Wait 3 seconds for backend server initialization
ping -n 4 127.0.0.1 >nul

:: 2. Launch Flutter Web App on Microsoft Edge browser
echo [2/2] Launching SpryFlora Flutter Web App on Microsoft Edge ...
cd /d %~dp0
flutter run -d edge --web-port=8080

echo.
echo ====================================================
echo SpryFlora Web App is running!
echo Backend: http://localhost:3000
echo Frontend: http://localhost:8080 (Microsoft Edge)
echo ====================================================
pause
