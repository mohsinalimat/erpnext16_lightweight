# start.ps1 - Start the ERPNext stack.
# Equivalent to `docker compose up -d` from the repo root.
# The container's entrypoint auto-detects first-install vs restart and runs `bench start`.
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

Write-Host "Starting stack..." -ForegroundColor Cyan
docker compose -f $ComposeFile up -d

Write-Host ""
Write-Host "Done. First-time install can take 5-15 minutes - watch progress with:" -ForegroundColor Green
Write-Host "  docker compose -f `"$ComposeFile`" logs -f erpnext-dev"
Write-Host "Then open http://test.localhost:8000  (Administrator / erpadmindb)" -ForegroundColor Green
