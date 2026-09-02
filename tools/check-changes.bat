@echo off
REM Read-only: shows what differs between your Prism instance and the published pack.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0diff-instance.ps1"
pause
