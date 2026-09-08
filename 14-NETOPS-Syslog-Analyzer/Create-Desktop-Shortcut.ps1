$ErrorActionPreference='Stop'
$ProjectDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$Exe=Join-Path $ProjectDir 'dist\NETOPS-Syslog-Analyzer.exe'
if(-not(Test-Path $Exe)){throw 'NETOPS-Syslog-Analyzer.exe was not found. Run Build-Windows-EXE.ps1 first.'}
$Path=Join-Path ([Environment]::GetFolderPath('Desktop')) 'NETOPS Syslog Analyzer.lnk'
$Shell=New-Object -ComObject WScript.Shell;$Link=$Shell.CreateShortcut($Path);$Link.TargetPath=$Exe;$Link.WorkingDirectory=Split-Path $Exe;$Link.IconLocation="$Exe,0";$Link.Description='NETOPS Network Log and Syslog Analyzer';$Link.Save()
Write-Host "Desktop shortcut created: $Path" -ForegroundColor Green
