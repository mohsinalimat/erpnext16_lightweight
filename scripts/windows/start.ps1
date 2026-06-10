# start.ps1 - Start the ERPNext container, then its web server.
# Run from anywhere: right-click > "Run with PowerShell", or:  ./start.ps1
$ErrorActionPreference = "Stop"

# Resolve docker-compose.yml relative to this script (scripts/windows/ -> repo root)
$ComposeFile = Join-Path $PSScriptRoot "..\..\docker-compose.yml"
$Container   = "erpnext_lightweight"

# Make sure Docker is installed and the daemon is actually running
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker CLI not found. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker Desktop, wait until it is ready, then re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Starting container..." -ForegroundColor Cyan
docker compose -f $ComposeFile up -d

# Wait until the container is actually running before exec-ing into it
$tries = 0
while ((docker inspect -f '{{.State.Running}}' $Container 2>$null) -ne 'true' -and $tries -lt 30) {
    Start-Sleep -Seconds 1; $tries++
}

Write-Host "[2/2] Starting web server (bench serve, detached)..." -ForegroundColor Cyan
docker exec -d $Container bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"

Write-Host ""
Write-Host "Done. Open http://test.localhost:8000  (Administrator / erpadmindb)" -ForegroundColor Green
