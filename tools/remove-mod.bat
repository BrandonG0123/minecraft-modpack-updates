@echo off
REM Stop shipping a mod to your friends. The jar stays in YOUR instance.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0remove-mod.ps1"
pause
