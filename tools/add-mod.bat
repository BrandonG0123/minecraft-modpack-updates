@echo off
REM Add a mod straight to the pack by Modrinth slug, ID, URL or search term.
set /p SLUG="Modrinth slug / URL / search term: "
if "%SLUG%"=="" exit /b 1
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" modrinth add "%SLUG%"
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" refresh
echo.
echo Added to the pack. Run publish-pack-only.bat to push it.
pause
