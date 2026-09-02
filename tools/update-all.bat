@echo off
REM Ask Modrinth for newer versions of every mod in the pack and update the metadata.
REM This updates the PACK. Your own instance is updated the next time you launch it,
REM or via Prism's own mod updater.
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" update --all
"%~dp0bin\packwiz.exe" --pack-file "%~dp0..\pack.toml" refresh
echo.
echo Review the changes, then run publish-pack-only.bat to push them.
pause
