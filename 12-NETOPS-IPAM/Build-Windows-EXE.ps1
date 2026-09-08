$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host '=== NETOPS IPAM - BUILD WINDOWS EXE ===' -ForegroundColor Cyan
& py -3.13 --version
if ($LASTEXITCODE -ne 0) { throw 'Python 3.13 was not found.' }
& py -3.13 -m pip install --upgrade pyinstaller
if ($LASTEXITCODE -ne 0) { throw 'PyInstaller installation failed.' }

& py -3.13 -m PyInstaller --noconfirm --clean --onefile --windowed `
  --name 'NETOPS-IPAM' `
  --icon "$ProjectDir\netops-ipam.ico" `
  --add-data "$ProjectDir\ipam_core.py;." `
  "$ProjectDir\netops_ipam.py"
if ($LASTEXITCODE -ne 0) { throw 'EXE build failed.' }

$ExePath=Join-Path $ProjectDir 'dist\NETOPS-IPAM.exe'
Write-Host '=== EXE CREATED SUCCESSFULLY ===' -ForegroundColor Green
Write-Host "File: $ExePath" -ForegroundColor Yellow
Write-Host 'Database: %LOCALAPPDATA%\NETOPS-IPAM\netops_ipam.db'
Invoke-Item (Split-Path $ExePath)

