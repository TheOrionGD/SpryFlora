@echo off
title SpryFlora Web App (Edge)
color 0A
echo Launching SpryFlora Flutter Web App on Microsoft Edge browser...
cd /d %~dp0
flutter run -d edge --web-port=8080
pause
