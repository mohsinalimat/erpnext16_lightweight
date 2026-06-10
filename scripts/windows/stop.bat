@echo off
setlocal
REM stop.bat - Stop the ERPNext container (and the web server inside it). Data is kept.
REM Native cmd version of stop.ps1 - not affected by PowerShell execution policy.
set "COMPOSE=%~dp0..\..\docker-compose.yml"

echo Stopping container (web server stops with it; data is safe in the volume)...
docker compose -f "%COMPOSE%" stop
echo Stopped.
endlocal
