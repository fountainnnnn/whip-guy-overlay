@echo off
rem Whip Guy for Windows. Needs Node.js (https://nodejs.org).
cd /d "%~dp0electron"
if not exist node_modules call npm install --no-audit --no-fund
call npm start
