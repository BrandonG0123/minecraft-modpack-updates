@echo off
REM ===================================================================
REM  Syncs this server's mods + worldgen configs from the published pack.
REM  Installs ONLY mods whose fabric.mod.json says they can run on a
REM  dedicated server (-s server). Client mods, shaders and resource
REM  packs are skipped automatically.
REM
REM  Put this file in your SERVER folder, next to server.properties.
REM  Run it before starting the server - or call it from start.bat.
REM ===================================================================

set PACK=https://brandong0123.github.io/minecraft-modpack-updates/pack.toml

REM Use the same java the server runs on. If java is not on PATH, set it here:
REM set JAVA="C:\Program Files\Java\jdk-21\bin\java.exe"
if not defined JAVA set JAVA=java

if not exist "packwiz-installer-bootstrap.jar" (
  echo Downloading packwiz-installer-bootstrap.jar ...
  powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://brandong0123.github.io/minecraft-modpack-updates/tools/dist/packwiz-installer-bootstrap.jar' -OutFile 'packwiz-installer-bootstrap.jar'"
)

echo.
echo Syncing server mods from the pack ...
%JAVA% -jar packwiz-installer-bootstrap.jar -g -s server "%PACK%"
if errorlevel 1 (
  echo.
  echo *** Mod sync FAILED - server not started. Fix the error above. ***
  pause
  exit /b 1
)
echo Mods are up to date.
echo.
