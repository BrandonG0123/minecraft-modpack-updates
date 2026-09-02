@echo off
REM One-time GitHub sign-in for publishing the modpack.
"%~dp0bin\gh.exe" auth login --hostname github.com --git-protocol https --web
echo.
"%~dp0bin\gh.exe" auth status
pause
