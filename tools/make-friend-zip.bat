@echo off
REM Rebuild the zip you hand to friends. Run this if you ever change the
REM instance settings (memory, pre-launch command, Minecraft/Fabric version).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-friend-zip.ps1"
pause
