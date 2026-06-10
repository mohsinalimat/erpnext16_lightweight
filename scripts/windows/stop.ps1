# stop.ps1 - Stop the ERPNext container (and the web server inside it). Data is kept.
$ErrorActionPreference = "Stop"

# Resolve docker-compose.yml relative to this script (scripts/windows/ -> repo root)
$ComposeFile = Join-Path $PSScriptRoot "..\..\docker-compose.yml"

Write-Host "Stopping container (web server stops with it; data is safe in the volume)..." -ForegroundColor Cyan
docker compose -f $ComposeFile stop

Write-Host "Stopped." -ForegroundColor Green
