@echo off
REM Read-only: which shipped mods have a newer version on Modrinth?
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-updates.ps1"
pause
