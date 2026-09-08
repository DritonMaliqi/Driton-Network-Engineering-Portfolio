$ErrorActionPreference='Stop'
$ProjectDir=Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir
Write-Host '=== NETOPS SYSLOG ANALYZER - BUILD WINDOWS EXE ===' -ForegroundColor Cyan
& py -3.13 --version
if($LASTEXITCODE-ne 0){throw 'Python 3.13 was not found.'}
& py -3.13 -m pip install --upgrade pyinstaller
if($LASTEXITCODE-ne 0){throw 'PyInstaller installation failed.'}
& py -3.13 -m PyInstaller --noconfirm --clean --onefile --windowed --name 'NETOPS-Syslog-Analyzer' --icon "$ProjectDir\netops-syslog.ico" "$ProjectDir\netops_syslog.py"
if($LASTEXITCODE-ne 0){throw 'EXE build failed.'}
$Exe=Join-Path $ProjectDir 'dist\NETOPS-Syslog-Analyzer.exe'
Write-Host '=== EXE CREATED SUCCESSFULLY ===' -ForegroundColor Green
Write-Host "File: $Exe" -ForegroundColor Yellow
Invoke-Item (Split-Path $Exe)
