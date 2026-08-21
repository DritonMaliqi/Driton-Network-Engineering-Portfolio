$Project = Split-Path $PSScriptRoot
$Src = Join-Path $Project "src"

. "$Src\Incident-Manager.ps1"

$Description = @"
PC1 eshte ne VLAN 10.
Porta Fa0/2 eshte ne VLAN 1.
PC1 nuk mund te ping gateway 192.168.10.1.
"@

$Analysis = @"
FINDINGS: 1

[HIGH] [CONFIRMED] [ROOT_CAUSE] VLAN
Problem    : Access Port VLAN Mismatch.
Evidence   : Hosti eshte ne VLAN 10, por Fa0/2 eshte ne VLAN 1.
Confidence : 98%

DECISION

FIX

SMART NEXT STEP

show interfaces Fa0/2 switchport
"@

$result = Save-NetOpsIncident `
    -Description $Description `
    -Analysis $Analysis `
    -Status "Resolved" `
    -Notes "NETOPS v5.4 automated documentation test."

$pass = 0
$fail = 0

$checks = @(
    $result.Folder,
    $result.Json,
    $result.Report,
    $result.History
)

foreach ($path in $checks) {
    if (Test-Path $path) {
        Write-Host "[PASS] $path" -ForegroundColor Green
        $pass++
    }
    else {
        Write-Host "[FAIL] $path" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "PASSED : $pass" -ForegroundColor Green
Write-Host "FAILED : $fail" -ForegroundColor $(if ($fail -eq 0) {"Green"} else {"Red"})

if ($fail -eq 0) {
    Write-Host "NETOPS v5.4 DOCUMENTATION ENGINE: READY" -ForegroundColor Green
}
