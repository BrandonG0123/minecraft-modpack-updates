@echo off
REM Example of wiring the updater into your own start script.
REM Copy the CALL line into your existing start.bat, above the java line.

call "%~dp0server-update.bat"
if errorlevel 1 exit /b 1

REM --- your existing launch line goes here, for example: ---
java -Xms4G -Xmx8G -jar fabric-server-launch.jar nogui

pause
