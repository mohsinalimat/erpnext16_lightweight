@echo off
setlocal enableextensions
REM restart.bat - Restart the ERPNext stack.
REM Equivalent to `docker compose restart` from the repo root.
REM The container's entrypoint re-runs `bench start` automatically.
set "COMPOSE=%~dp0..\..\docker-compose.yml"

where docker >nul 2>nul
if errorlevel 1 ( echo Docker CLI not found. Please install Docker Desktop first.& exit /b 1 )
docker info >nul 2>nul
if errorlevel 1 ( echo Docker is not running. Start Docker Desktop, then re-run.& exit /b 1 )

echo Restarting stack...
docker compose -f "%COMPOSE%" restart
echo.
echo Done. Open http://test.localhost:8000  (Administrator / erpadmindb)
endlocal
