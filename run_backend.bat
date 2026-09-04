@echo off
title SpryFlora Backend Server
color 0B
echo Starting SpryFlora Node.js Backend Server on http://localhost:3000 ...
cd /d %~dp0spryflora_backend
npm run dev
pause
