$ProjectRoot = Split-Path $PSScriptRoot
$DataRoot = Join-Path $ProjectRoot "data"
$IncidentRoot = Join-Path $DataRoot "Incidents"
$ReportRoot = Join-Path $DataRoot "Reports"
$HistoryFile = Join-Path $DataRoot "Incident-History.csv"

foreach ($f in @($DataRoot,$IncidentRoot,$ReportRoot)) {
    New-Item -ItemType Directory -Path $f -Force | Out-Null
}

function New-IncidentId {
    $date = Get-Date -Format "yyyyMMdd"
    $existing = @(Get-ChildItem $IncidentRoot -Directory -Filter "INC-$date-*" -ErrorAction SilentlyContinue)
    return "INC-{0}-{1:D3}" -f $date,($existing.Count + 1)
}

function Get-FirstMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Default = ""
    )

    $m = [regex]::Match($Text,$Pattern)

    if ($m.Success) {
        return $m.Groups[1].Value.Trim()
    }

    return $Default
}

function Save-NetOpsIncident {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$true)]
        [string]$Analysis,

        [ValidateSet("Investigating","Monitoring","Resolved","Closed")]
        [string]$Status = "Investigating",

        [string]$Notes = "",

        [string]$IncidentID = ""
    )

    $now = Get-Date

    if ([string]::IsNullOrWhiteSpace($IncidentID)) {
        $IncidentID = New-IncidentId
        $created = $now
    }
    else {
        $created = $now
    }

    $folder = Join-Path $IncidentRoot $IncidentID
    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    $category = Get-FirstMatch $Analysis '\[(?:HIGH|MEDIUM|LOW)\]\s+\[(?:CONFIRMED|PROBABLE)\]\s+\[(?:ROOT_CAUSE|SYMPTOM)\]\s+([A-Z0-9]+)' "GENERAL"
    $severity = Get-FirstMatch $Analysis '\[(HIGH|MEDIUM|LOW)\]' "Unknown"
    $confidence = Get-FirstMatch $Analysis '(?im)^Confidence\s*:\s*(\d+)%' "0"
    $findings = Get-FirstMatch $Analysis '(?im)^FINDINGS:\s*(\d+)' "0"
    $rootCause = Get-FirstMatch $Analysis '(?im)^Problem\s*:\s*(.+)$' ""
    $decision = Get-FirstMatch $Analysis '(?im)^\s*(FIX|VERIFY|COLLECT_MORE|STOP)\s*$' "UNKNOWN"

    $nextStep = ""

    $smart = $Analysis -split 'SMART NEXT STEP'

    if ($smart.Count -gt 1) {
        foreach ($line in ($smart[-1] -split "`r?`n")) {
            $x = $line.Trim()

            if (
                $x -and
                $x -notmatch '^=+$' -and
                $x -notmatch '^FAST MODE'
            ) {
                $nextStep = $x
                break
            }
        }
    }

    $title = (
        $Description -split "`r?`n" |
        Where-Object { $_.Trim() } |
        Select-Object -First 1
    )

    if (-not $title) {
        $title = "Network Incident"
    }

    if ($title.Length -gt 70) {
        $title = $title.Substring(0,70)
    }

    $obj = [ordered]@{
        IncidentID    = $IncidentID
        Title         = $title
        Created       = $created.ToString("o")
        Updated       = $now.ToString("o")
        Category      = $category
        Severity      = $severity
        Status        = $Status
        Findings      = [int]$findings
        Confidence    = [int]$confidence
        Decision      = $decision
        RootCause     = $rootCause
        SmartNextStep = $nextStep
        Description   = $Description
        Analysis      = $Analysis
        Notes         = $Notes
        Analyst       = $env:USERNAME
        Version       = "5.4"
    }

    $jsonPath = Join-Path $folder "incident.json"
    $reportPath = Join-Path $folder "incident-report.md"
    $analysisPath = Join-Path $folder "analysis.txt"
    $descriptionPath = Join-Path $folder "incident-description.txt"

    $obj |
        ConvertTo-Json -Depth 8 |
        Set-Content $jsonPath -Encoding UTF8

    $Analysis |
        Set-Content $analysisPath -Encoding UTF8

    $Description |
        Set-Content $descriptionPath -Encoding UTF8

    $reportText = @"
# NETOPS Incident Report

## Incident Information

- Incident ID: $IncidentID
- Title: $title
- Category: $category
- Severity: $severity
- Status: $Status
- Findings: $findings
- Confidence: $confidence%
- Decision: $decision
- Created: $($created.ToString("yyyy-MM-dd HH:mm:ss"))
- Updated: $($now.ToString("yyyy-MM-dd HH:mm:ss"))
- Analyst: $env:USERNAME

## Incident Description

$Description

## Root Cause

$rootCause

## Smart Next Step

$nextStep

## Notes

$Notes

## Full Analysis

$Analysis

---
Generated automatically by NETOPS v5.4
"@

    $reportText |
        Set-Content $reportPath -Encoding UTF8

    $reportTxt = Join-Path $ReportRoot "$IncidentID.txt"

    $reportText |
        Set-Content $reportTxt -Encoding UTF8

    $rows = @()

    if (Test-Path $HistoryFile) {
        try {
            $rows = @(
                Import-Csv $HistoryFile |
                Where-Object {
                    $_.IncidentID -and
                    $_.IncidentID -ne $IncidentID
                }
            )
        }
        catch {
            $rows = @()
        }
    }

    $rows += [PSCustomObject]@{
        IncidentID = $IncidentID
        Created    = $created.ToString("yyyy-MM-dd HH:mm:ss")
        Updated    = $now.ToString("yyyy-MM-dd HH:mm:ss")
        Title      = $title
        Category   = $category
        Severity   = $severity
        Status     = $Status
        Findings   = $findings
        Confidence = $confidence
        Decision   = $decision
        RootCause  = $rootCause
        ReportPath = $reportPath
    }

    $rows |
        Sort-Object Updated -Descending |
        Export-Csv $HistoryFile -NoTypeInformation -Encoding UTF8

    [PSCustomObject]@{
        IncidentID = $IncidentID
        Folder     = $folder
        Json       = $jsonPath
        Report     = $reportPath
        History    = $HistoryFile
    }
}

function Get-NetOpsIncidentHistory {
    if (-not (Test-Path $HistoryFile)) {
        return @()
    }

    return @(Import-Csv $HistoryFile)
}

function Get-NetOpsIncident {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IncidentID
    )

    $jsonPath = Join-Path `
        (Join-Path $IncidentRoot $IncidentID) `
        "incident.json"

    if (-not (Test-Path $jsonPath)) {
        return $null
    }

    try {
        return Get-Content $jsonPath -Raw |
            ConvertFrom-Json
    }
    catch {
        return $null
    }
}


function Set-NetOpsIncidentStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IncidentID,

        [ValidateSet(
            "Investigating",
            "Monitoring",
            "Resolved",
            "Closed"
        )]
        [string]$Status,

        [string]$Notes = ""
    )

    $incident = Get-NetOpsIncident `
        -IncidentID $IncidentID

    if (-not $incident) {
        throw "Incident nuk u gjet: $IncidentID"
    }

    $finalNotes = $Notes

    if (
        [string]::IsNullOrWhiteSpace($finalNotes) -and
        $incident.Notes
    ) {
        $finalNotes = [string]$incident.Notes
    }

    return Save-NetOpsIncident `
        -Description ([string]$incident.Description) `
        -Analysis ([string]$incident.Analysis) `
        -Status $Status `
        -Notes $finalNotes `
        -IncidentID $IncidentID
}


function Open-NetOpsIncidentFolder {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IncidentID
    )

    $folder = Join-Path $IncidentRoot $IncidentID

    if (Test-Path $folder) {
        Start-Process explorer.exe $folder
    }
}
