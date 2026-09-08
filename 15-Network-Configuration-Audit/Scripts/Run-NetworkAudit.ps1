$ErrorActionPreference = "Stop"

$Project = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PythonScript = Join-Path $Project "Scripts\network_audit.py"
$ReportsDir = Join-Path $Project "Reports"

Write-Host ""
Write-Host "============================================================="
Write-Host " PROJECT 15 - NETWORK CONFIGURATION AUDIT"
Write-Host "============================================================="
Write-Host ""

# ------------------------------------------------------------
# Run Python audit
# ------------------------------------------------------------

$PythonCommand = $null

if (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonCommand = "python"
}
elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonCommand = "py"
}
else {
    throw "Python was not found in PATH."
}

Write-Host "[1/4] Running configuration audit..."
Write-Host ""

& $PythonCommand $PythonScript

if ($LASTEXITCODE -ne 0) {
    throw "Python audit failed with exit code $LASTEXITCODE."
}

# ------------------------------------------------------------
# Find latest CSV report
# ------------------------------------------------------------

Write-Host ""
Write-Host "[2/4] Loading latest audit results..."

$LatestCsv = Get-ChildItem $ReportsDir -Filter "Network-Audit-*.csv" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $LatestCsv) {
    throw "No CSV audit report was found."
}

$Results = Import-Csv $LatestCsv.FullName

if (-not $Results) {
    throw "The CSV report contains no audit results."
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$PassCount = @($Results | Where-Object { $_.status -eq "PASS" }).Count
$WarningCount = @($Results | Where-Object { $_.status -eq "WARNING" }).Count
$FailCount = @($Results | Where-Object { $_.status -eq "FAIL" }).Count
$TotalCount = @($Results).Count
$DeviceCount = @($Results.device | Sort-Object -Unique).Count

$Score = if ($TotalCount -gt 0) {
    [math]::Round(($PassCount / $TotalCount) * 100)
}
else {
    0
}

# ------------------------------------------------------------
# Build HTML rows
# ------------------------------------------------------------

$Rows = foreach ($Item in $Results) {

    switch ($Item.status) {
        "PASS" {
            $StatusClass = "pass"
        }
        "WARNING" {
            $StatusClass = "warning"
        }
        "FAIL" {
            $StatusClass = "fail"
        }
        default {
            $StatusClass = ""
        }
    }

    switch ($Item.severity) {
        "CRITICAL" {
            $SeverityClass = "critical"
        }
        "HIGH" {
            $SeverityClass = "high"
        }
        "MEDIUM" {
            $SeverityClass = "medium"
        }
        default {
            $SeverityClass = "low"
        }
    }

@"
<tr>
    <td>$($Item.device)</td>
    <td><span class="badge severity $SeverityClass">$($Item.severity)</span></td>
    <td>$($Item.check)</td>
    <td><span class="badge $StatusClass">$($Item.status)</span></td>
    <td>$($Item.details)</td>
    <td>$($Item.recommendation)</td>
</tr>
"@
}

$RowsHtml = $Rows -join "`n"

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$HtmlPath = Join-Path $ReportsDir ("Network-Audit-Dashboard-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".html")

# ------------------------------------------------------------
# HTML Dashboard
# ------------------------------------------------------------

$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Network Configuration Audit</title>

<style>

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    font-family: "Segoe UI", Arial, sans-serif;
    background: #0d1117;
    color: #e6edf3;
}

.header {
    padding: 28px 40px;
    background: #161b22;
    border-bottom: 1px solid #30363d;
}

.header h1 {
    margin: 0;
    font-size: 28px;
}

.header p {
    margin-top: 8px;
    margin-bottom: 0;
    color: #8b949e;
}

.container {
    padding: 30px 40px;
    max-width: 1600px;
    margin: auto;
}

.cards {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 18px;
    margin-bottom: 30px;
}

.card {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 12px;
    padding: 20px;
}

.card-title {
    color: #8b949e;
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.card-value {
    font-size: 32px;
    font-weight: 700;
    margin-top: 8px;
}

.pass-value {
    color: #3fb950;
}

.warning-value {
    color: #d29922;
}

.fail-value {
    color: #f85149;
}

.score-value {
    color: #58a6ff;
}

.device-value {
    color: #c9d1d9;
}

.section {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 12px;
    overflow: hidden;
}

.section-header {
    padding: 20px 22px;
    border-bottom: 1px solid #30363d;
}

.section-header h2 {
    margin: 0;
    font-size: 20px;
}

.table-wrapper {
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th {
    text-align: left;
    background: #21262d;
    padding: 14px;
    font-size: 13px;
    color: #8b949e;
    text-transform: uppercase;
}

td {
    padding: 14px;
    border-top: 1px solid #30363d;
    vertical-align: top;
    line-height: 1.45;
}

tr:hover {
    background: #1c2128;
}

.badge {
    display: inline-block;
    padding: 5px 9px;
    border-radius: 999px;
    font-weight: 700;
    font-size: 12px;
}

.pass {
    background: rgba(63,185,80,.15);
    color: #3fb950;
    border: 1px solid rgba(63,185,80,.4);
}

.warning {
    background: rgba(210,153,34,.15);
    color: #d29922;
    border: 1px solid rgba(210,153,34,.4);
}

.fail {
    background: rgba(248,81,73,.15);
    color: #f85149;
    border: 1px solid rgba(248,81,73,.4);
}

.severity.low {
    color: #8b949e;
    background: #21262d;
}

.severity.medium {
    color: #d29922;
    background: rgba(210,153,34,.12);
}

.severity.high {
    color: #ff7b72;
    background: rgba(248,81,73,.12);
}

.severity.critical {
    color: #ff7b72;
    background: rgba(248,81,73,.22);
}

.footer {
    padding: 25px 0;
    color: #8b949e;
    font-size: 13px;
}

@media(max-width:1000px) {

    .cards {
        grid-template-columns: repeat(2, 1fr);
    }

}

@media(max-width:600px) {

    .cards {
        grid-template-columns: 1fr;
    }

    .container {
        padding: 20px;
    }

}

</style>
</head>

<body>

<div class="header">

    <h1>Network Configuration Audit & Compliance</h1>

    <p>
        Automated Cisco configuration validation |
        Project 15 – Network Engineering Portfolio
    </p>

</div>

<div class="container">

    <div class="cards">

        <div class="card">
            <div class="card-title">Devices Audited</div>
            <div class="card-value device-value">$DeviceCount</div>
        </div>

        <div class="card">
            <div class="card-title">Pass</div>
            <div class="card-value pass-value">$PassCount</div>
        </div>

        <div class="card">
            <div class="card-title">Warnings</div>
            <div class="card-value warning-value">$WarningCount</div>
        </div>

        <div class="card">
            <div class="card-title">Failures</div>
            <div class="card-value fail-value">$FailCount</div>
        </div>

        <div class="card">
            <div class="card-title">Compliance Score</div>
            <div class="card-value score-value">$Score%</div>
        </div>

    </div>

    <div class="section">

        <div class="section-header">

            <h2>Audit Findings</h2>

        </div>

        <div class="table-wrapper">

            <table>

                <thead>
                    <tr>
                        <th>Device</th>
                        <th>Severity</th>
                        <th>Check</th>
                        <th>Status</th>
                        <th>Finding</th>
                        <th>Recommendation</th>
                    </tr>
                </thead>

                <tbody>

                    $RowsHtml

                </tbody>

            </table>

        </div>

    </div>

    <div class="footer">

        Generated: $Timestamp<br>
        Source report: $($LatestCsv.Name)

    </div>

</div>

</body>
</html>
"@

$Html | Set-Content -Path $HtmlPath -Encoding UTF8

# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host "[3/4] HTML dashboard created:"
Write-Host $HtmlPath

Write-Host ""
Write-Host "[4/4] Opening dashboard..."
Write-Host ""

Start-Process $HtmlPath

Write-Host "============================================================="
Write-Host " AUDIT DASHBOARD COMPLETED"
Write-Host "============================================================="
Write-Host ""
Write-Host "Devices : $DeviceCount"
Write-Host "PASS    : $PassCount"
Write-Host "WARNING : $WarningCount"
Write-Host "FAIL    : $FailCount"
Write-Host "Score   : $Score%"
Write-Host ""
