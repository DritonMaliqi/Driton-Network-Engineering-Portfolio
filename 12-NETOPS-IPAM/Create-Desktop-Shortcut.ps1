$ErrorActionPreference='Stop'
$ProjectDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath=Join-Path $ProjectDir 'dist\NETOPS-IPAM.exe'
if (-not (Test-Path $ExePath)) { throw 'NETOPS-IPAM.exe was not found. Run Build-Windows-EXE.ps1 first.' }
$Desktop=[Environment]::GetFolderPath('Desktop')
$ShortcutPath=Join-Path $Desktop 'NETOPS IPAM.lnk'
$Shell=New-Object -ComObject WScript.Shell
$Shortcut=$Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath=$ExePath
$Shortcut.WorkingDirectory=Split-Path $ExePath
$Shortcut.IconLocation="$ExePath,0"
$Shortcut.Description='NETOPS IP Address Manager and Subnet Planner'
$Shortcut.Save()
Write-Host "Desktop shortcut created: $ShortcutPath" -ForegroundColor Green

