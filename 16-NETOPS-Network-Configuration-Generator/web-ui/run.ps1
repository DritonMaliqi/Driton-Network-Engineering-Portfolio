$ErrorActionPreference = "Stop"

$WebUI = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $WebUI "backend"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " NETFORGE - NETWORK AUTOMATION PLATFORM" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting NETFORGE FastAPI server..." -ForegroundColor Yellow

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    "Set-Location '$Backend'; python -m uvicorn api:app --host 127.0.0.1 --port 8000"
)

Start-Sleep -Seconds 3

$URL = "http://127.0.0.1:8000"

Write-Host ""
Write-Host "NETFORGE:" -ForegroundColor Cyan
Write-Host $URL -ForegroundColor Green

Write-Host ""
Write-Host "API Documentation:" -ForegroundColor Cyan
Write-Host "http://127.0.0.1:8000/docs" -ForegroundColor Green

Write-Host ""
Write-Host "NETFORGE is ready." -ForegroundColor Green
Write-Host ""

Start-Process $URL