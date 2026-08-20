param(
    [Parameter(Mandatory=$true)]
    [string]$EnginePath,

    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [ValidateSet("Fast","Hybrid")]
    [string]$Mode = "Fast"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EnginePath)) {
    Write-Output "WORKER ERROR: Engine nuk u gjet: $EnginePath"
    exit 1
}

if (-not (Test-Path $InputFile)) {
    Write-Output "WORKER ERROR: Evidence file nuk u gjet: $InputFile"
    exit 1
}

try {

    & $EnginePath `
        -Engine $Mode `
        -FilePath $InputFile

}
catch {

    Write-Output ""
    Write-Output "WORKER ERROR"
    Write-Output $_.Exception.Message

    exit 1
}
