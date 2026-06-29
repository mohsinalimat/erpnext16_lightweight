@echo off
setlocal enableextensions
REM start.bat - Start the ERPNext stack.
REM Equivalent to `docker compose up -d` from the repo root.
REM The container's entrypoint auto-detects first-install vs restart and runs `bench start`.
set "COMPOSE=%~dp0..\..\docker-compose.yml"

where docker >nul 2>nul
if errorlevel 1 ( echo Docker CLI not found. Please install Docker Desktop first.& exit /b 1 )
docker info >nul 2>nul
if errorlevel 1 ( echo Docker is not running. Start Docker Desktop, then re-run.& exit /b 1 )

echo Starting stack...
docker compose -f "%COMPOSE%" up -d
echo.
echo Done. First-time install can take 5-15 minutes - watch progress with:
echo   docker compose -f "%COMPOSE%" logs -f erpnext-dev
echo Then open http://test.localhost:8000  (Administrator / erpadmindb)
endlocal
