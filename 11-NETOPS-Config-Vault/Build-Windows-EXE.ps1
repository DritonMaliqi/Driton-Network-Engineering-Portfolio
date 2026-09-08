$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host '=== NETOPS CONFIG VAULT - BUILD WINDOWS EXE ===' -ForegroundColor Cyan
Write-Host 'Checking Python 3.13...'
& py -3.13 --version
if ($LASTEXITCODE -ne 0) { throw 'Python 3.13 was not found.' }

Write-Host 'Installing/checking PyInstaller...'
& py -3.13 -m pip install --upgrade pyinstaller
if ($LASTEXITCODE -ne 0) { throw 'PyInstaller installation failed.' }

Write-Host 'Building NETOPS-Config-Vault.exe...'
& py -3.13 -m PyInstaller --noconfirm --clean --onefile --windowed `
  --name 'NETOPS-Config-Vault' `
  --icon "$ProjectDir\netops-backup.ico" `
  "$ProjectDir\netops_backup.py"
if ($LASTEXITCODE -ne 0) { throw 'EXE build failed.' }

$ExePath = Join-Path $ProjectDir 'dist\NETOPS-Config-Vault.exe'
Write-Host ''
Write-Host '=== EXE CREATED SUCCESSFULLY ===' -ForegroundColor Green
Write-Host "File: $ExePath" -ForegroundColor Yellow
Write-Host 'Database: %LOCALAPPDATA%\NETOPS-Config-Vault\config_vault.db'
Invoke-Item (Split-Path $ExePath)

