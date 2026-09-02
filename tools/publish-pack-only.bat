@echo off
REM Push the pack as-is to GitHub WITHOUT re-reading your Prism instance.
REM Use this after add-mod / remove-mod / update-all.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
pause
