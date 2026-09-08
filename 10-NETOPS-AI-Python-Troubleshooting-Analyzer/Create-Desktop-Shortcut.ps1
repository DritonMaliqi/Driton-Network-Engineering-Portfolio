$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $ProjectDir 'dist\NETOPS-AI.exe'
if (-not (Test-Path $ExePath)) { throw 'NETOPS-AI.exe nuk u gjet. Fillimisht ekzekuto Build-Windows-EXE.ps1.' }
$Desktop = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = Join-Path $Desktop 'NETOPS AI.lnk'
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $ExePath
$Shortcut.WorkingDirectory = Split-Path $ExePath
$Shortcut.IconLocation = "$ExePath,0"
$Shortcut.Description = 'NETOPS AI - Network Troubleshooting Analyzer'
$Shortcut.Save()
Write-Host "Shortcut u krijua: $ShortcutPath" -ForegroundColor Green
