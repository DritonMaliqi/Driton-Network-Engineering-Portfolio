$ErrorActionPreference = "Stop"

$WebUI = Split-Path -Parent $MyInvocation.MyCommand.Path

$Backend = Join-Path $WebUI "backend"
$Frontend = Join-Path $WebUI "frontend"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " NETOPS PROJECT 16 - WEB UI" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting FastAPI Backend..." -ForegroundColor Yellow

Start-Process powershell.exe `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        "Set-Location '$Backend'; python -m uvicorn api:app --host 127.0.0.1 --port 8000"
    )

Start-Sleep -Seconds 2

Write-Host "Starting Frontend Server..." -ForegroundColor Yellow

Start-Process powershell.exe `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        "Set-Location '$Frontend'; python -m http.server 3000 --bind 127.0.0.1"
    )

Start-Sleep -Seconds 2

$URL = "http://127.0.0.1:3000"

Write-Host ""
Write-Host "Backend:" -ForegroundColor Cyan
Write-Host "http://127.0.0.1:8000" -ForegroundColor Green

Write-Host ""
Write-Host "Frontend:" -ForegroundColor Cyan
Write-Host $URL -ForegroundColor Green

Write-Host ""
Write-Host "Swagger:" -ForegroundColor Cyan
Write-Host "http://127.0.0.1:8000/docs" -ForegroundColor Green

Write-Host ""

Start-Process $URL