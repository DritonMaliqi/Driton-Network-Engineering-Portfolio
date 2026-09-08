$ErrorActionPreference='Stop'
$ProjectDir=Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir
Write-Host '=== NETOPS INVENTORY - BUILD WINDOWS EXE ===' -ForegroundColor Cyan
& py -3.13 --version
if ($LASTEXITCODE -ne 0){throw 'Python 3.13 was not found.'}
& py -3.13 -m pip install --upgrade pyinstaller
if ($LASTEXITCODE -ne 0){throw 'PyInstaller installation failed.'}
& py -3.13 -m PyInstaller --noconfirm --clean --onefile --windowed `
 --name 'NETOPS-Inventory' --icon "$ProjectDir\netops-inventory.ico" "$ProjectDir\netops_inventory.py"
if ($LASTEXITCODE -ne 0){throw 'EXE build failed.'}
$Exe=Join-Path $ProjectDir 'dist\NETOPS-Inventory.exe'
Write-Host '=== EXE CREATED SUCCESSFULLY ===' -ForegroundColor Green
Write-Host "File: $Exe" -ForegroundColor Yellow
Write-Host 'Database: %LOCALAPPDATA%\NETOPS-Inventory\network_inventory.db'
Invoke-Item (Split-Path $Exe)
