# restart.ps1 - Restart the ERPNext container, then re-launch its web server.
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

Write-Host "[1/2] Restarting container..." -ForegroundColor Cyan
docker compose -f $ComposeFile restart

# Wait until the container is running again before exec-ing into it
$tries = 0
while ((docker inspect -f '{{.State.Running}}' $Container 2>$null) -ne 'true' -and $tries -lt 30) {
    Start-Sleep -Seconds 1; $tries++
}

Write-Host "[2/2] Re-launching web server (restart kills bench serve, so we start it again)..." -ForegroundColor Cyan
docker exec -d $Container bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"

Write-Host ""
Write-Host "Done. Open http://test.localhost:8000  (Administrator / erpadmindb)" -ForegroundColor Green
