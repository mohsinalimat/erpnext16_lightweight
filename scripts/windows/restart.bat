@echo off
setlocal enableextensions
REM restart.bat - Restart the ERPNext container, then re-launch its web server.
REM Native cmd version of restart.ps1 - not affected by PowerShell execution policy.
set "COMPOSE=%~dp0..\..\docker-compose.yml"
set "CONTAINER=erpnext_lightweight"

where docker >nul 2>nul
if errorlevel 1 ( echo Docker CLI not found. Please install Docker Desktop first.& exit /b 1 )
docker info >nul 2>nul
if errorlevel 1 ( echo Docker is not running. Start Docker Desktop, wait until ready, then re-run.& exit /b 1 )

echo [1/2] Restarting container...
docker compose -f "%COMPOSE%" restart

REM Wait until the container is running again before exec-ing into it
set /a tries=0
:waitloop
for /f "delims=" %%i in ('docker inspect -f "{{.State.Running}}" %CONTAINER% 2^>nul') do set "STATE=%%i"
if "%STATE%"=="true" goto ready
set /a tries+=1
if %tries% geq 30 goto ready
ping -n 2 127.0.0.1 >nul
goto waitloop
:ready

echo [2/2] Re-launching web server (restart kills bench serve, so we start it again)...
docker exec -d %CONTAINER% bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"
echo.
echo Done. Open http://test.localhost:8000  (Administrator / erpadmindb)
endlocal
