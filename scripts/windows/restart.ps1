# restart.ps1 - Restart the ERPNext stack.
# Equivalent to `docker compose restart` from the repo root.
# The container's entrypoint re-runs `bench start` automatically.
$ErrorActionPreference = "Stop"

$ComposeFile = Join-Path $PSScriptRoot "..\..\docker-compose.yml"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker CLI not found. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker Desktop, then re-run." -ForegroundColor Red
    exit 1
}

Write-Host "Restarting stack..." -ForegroundColor Cyan
docker compose -f $ComposeFile restart

Write-Host ""
Write-Host "Done. Open http://test.localhost:8000  (Administrator / erpadmindb)" -ForegroundColor Green
