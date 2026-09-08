$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host '=== NETOPS AI - BUILD WINDOWS EXE ===' -ForegroundColor Cyan
Write-Host 'Kontrollimi i Python 3.13...'
& py -3.13 --version
if ($LASTEXITCODE -ne 0) { throw 'Python 3.13 nuk u gjet.' }

Write-Host 'Instalimi/kontrollimi i PyInstaller...'
& py -3.13 -m pip install --upgrade pyinstaller
if ($LASTEXITCODE -ne 0) { throw 'Instalimi i PyInstaller deshtoi.' }

Write-Host 'Krijimi i NETOPS-AI.exe...'
& py -3.13 -m PyInstaller --noconfirm --clean --onefile --windowed `
  --name 'NETOPS-AI' `
  --icon "$ProjectDir\netops-ai.ico" `
  --add-data "$ProjectDir\netops-ai.ico;." `
  "$ProjectDir\src\netops_ai.py"
if ($LASTEXITCODE -ne 0) { throw 'Krijimi i EXE deshtoi.' }

$ExePath = Join-Path $ProjectDir 'dist\NETOPS-AI.exe'
Write-Host ''
Write-Host '=== EXE U KRIJUA ME SUKSES ===' -ForegroundColor Green
Write-Host "Skedari: $ExePath" -ForegroundColor Yellow
Write-Host 'Incidentet ruhen ne: %LOCALAPPDATA%\NETOPS-AI\netops_ai.db'
Invoke-Item (Split-Path $ExePath)
