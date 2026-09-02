@echo off
REM Re-download the current packwiz build. Run this if packwiz.exe goes missing
REM or you want the newest version (CI artifacts expire after 90 days).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-packwiz.ps1"
pause
