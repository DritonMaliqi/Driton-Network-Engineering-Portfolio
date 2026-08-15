param(
    [string]$TargetProjectPath = "C:\Users\Acer\Documents\GitHub\Driton-Network-Engineering-Portfolio\02-DHCP-Troubleshooting"
)

$SourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Folders = @("evidence", "topology")

foreach ($Folder in $Folders) {
    $SourceFolder = Join-Path $SourceRoot $Folder
    $TargetFolder = Join-Path $TargetProjectPath $Folder

    if (-not (Test-Path $SourceFolder)) {
        throw "Source folder is missing: $SourceFolder"
    }

    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceFolder "*") -Destination $TargetFolder -Force
}

Write-Host "Prepared DHCP troubleshooting images were copied successfully." -ForegroundColor Green
Write-Host "Project: $TargetProjectPath"
Get-ChildItem (Join-Path $TargetProjectPath "evidence"), (Join-Path $TargetProjectPath "topology") |
    Select-Object DirectoryName, Name, Length
