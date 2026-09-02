@echo off
REM Remove a mod from the pack. Use the metadata name, e.g. "zoomify".
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" list
echo.
set /p NAME="Mod to remove (name from the list above): "
if "%NAME%"=="" exit /b 1
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" remove "%NAME%"
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" refresh
echo.
echo Removed from the pack. Run publish-pack-only.bat to push it.
pause
