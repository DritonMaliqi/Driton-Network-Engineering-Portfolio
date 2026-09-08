$ErrorActionPreference='Stop'
$ProjectDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$Exe=Join-Path $ProjectDir 'dist\NETOPS-Inventory.exe'
if(-not(Test-Path $Exe)){throw 'NETOPS-Inventory.exe was not found. Run Build-Windows-EXE.ps1 first.'}
$Path=Join-Path ([Environment]::GetFolderPath('Desktop')) 'NETOPS Inventory.lnk'
$Shell=New-Object -ComObject WScript.Shell
$Link=$Shell.CreateShortcut($Path);$Link.TargetPath=$Exe;$Link.WorkingDirectory=Split-Path $Exe;$Link.IconLocation="$Exe,0";$Link.Description='NETOPS Network Inventory and Documentation Tool';$Link.Save()
Write-Host "Desktop shortcut created: $Path" -ForegroundColor Green
