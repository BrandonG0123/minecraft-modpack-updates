@echo off
setlocal
REM ===================================================================
REM  Points Simple Voice Chat at your playit.gg UDP tunnel.
REM
REM  Voice chat uses UDP on 24454, which a Minecraft TCP tunnel does not
REM  carry. Without voice_host set, the server tells clients to send voice
REM  to its own local address, which nobody outside the LAN can reach - so
REM  voice silently never connects, and AudioPlayer (which is a Simple
REM  Voice Chat add-on) fails with it.
REM
REM  Run this in your SERVER folder, next to server.properties:
REM      set-voice-host.bat something.tun.ply.gg:12345
REM ===================================================================

set "CFG=config\voicechat\voicechat-server.properties"
set "HOSTPORT=%~1"

if "%HOSTPORT%"=="" (
  echo.
  echo   Usage: set-voice-host.bat ^<host:port^>
  echo.
  echo   Get this from playit.gg: Add Tunnel -^> type UDP -^> local port 24454.
  echo   It gives you an address like  stapling-missouri.tun.ply.gg:12345
  echo.
  exit /b 1
)

if not exist "%CFG%" (
  echo   Cannot find %CFG%
  echo   Run this from the server folder ^(the one with server.properties^).
  exit /b 1
)

copy /Y "%CFG%" "%CFG%.bak" >nul
echo   Backed up to %CFG%.bak

powershell -NoProfile -Command ^
  "$c = Get-Content -LiteralPath '%CFG%';" ^
  "if ($c -match '^voice_host=') { $c = $c -replace '^voice_host=.*', 'voice_host=%HOSTPORT%' }" ^
  "else { $c += 'voice_host=%HOSTPORT%' };" ^
  "Set-Content -LiteralPath '%CFG%' -Value $c -Encoding ascii"

echo.
echo   voice_host is now:
findstr /B "voice_host=" "%CFG%"
findstr /B "port=" "%CFG%"
echo.
echo   Restart the server, then check the console for a line about the
echo   voice chat port. Friends should see the voice icon connect.
echo.
endlocal
