@echo off
REM Sync mods+configs from your Prism instance, then push to GitHub.
REM This is the ONE command to run after you add/remove/update a mod.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-from-instance.ps1"
if errorlevel 1 goto :err
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
if errorlevel 1 goto :err
echo.
pause
exit /b 0
:err
echo.
echo *** FAILED - nothing was pushed. See the error above. ***
pause
exit /b 1
