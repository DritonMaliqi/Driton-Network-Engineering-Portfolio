$Project = Split-Path $PSScriptRoot
$Engine = Join-Path $Project "src\AI-Offline.ps1"

$Passed = 0
$Failed = 0

function Test-Result {
    param(
        [string]$Name,
        [bool]$Condition
    )

    if ($Condition) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:Passed++
    }
    else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        $script:Failed++
    }
}

Write-Host ""
Write-Host "============================================="
Write-Host " NETOPS v5.7 RELIABILITY REGRESSION TESTS"
Write-Host "============================================="

# -------------------------------------------------------------
# TEST 1 - IPv6 gateway false positive
# -------------------------------------------------------------

$IPv6 = @"
PC1 ka IPv6 address:
2001:DB8:10::10/64

Default Gateway:
2001:DB8:10::1

R1 interface drejt LAN:
2001:DB8:10::1/64

PC1 mund te ping gateway IPv6.

show ipv6 route ne R1 nuk ka default route.

IPv6 default route missing.
"@

$result1 = & $Engine -Prompt $IPv6 -Engine Fast 2>&1 | Out-String

Test-Result `
    "IPv6 default route detected" `
    ($result1 -match "IPv6 Default Route Missing")

Test-Result `
    "IPv6 gateway does NOT trigger IPv4 gateway false-positive" `
    ($result1 -notmatch "Default Gateway mungon")


# -------------------------------------------------------------
# TEST 2 - GRE destination mismatch
# -------------------------------------------------------------

$GRE = @"
R-PRISHTINA dhe R-GJILANI jane connected permes WAN.

Underlay connectivity funksionon.

GRE tunnel nuk kalon trafik.

interface Tunnel0
 tunnel source 10.1.1.1
 tunnel destination 10.2.2.99

Actual WAN IP of R-GJILANI is 10.2.2.1.

GRE tunnel destination mismatch.
Tunnel destination is incorrect.
"@

$result2 = & $Engine -Prompt $GRE -Engine Fast 2>&1 | Out-String

Test-Result `
    "GRE destination mismatch detected" `
    ($result2 -match "GRE Tunnel Source/Destination Misconfiguration")

Test-Result `
    "GRE decision is FIX" `
    ($result2 -match "(?i)\bDECISION\b[\s\S]*?\bFIX\b")


# -------------------------------------------------------------
# TEST 3 - Multiple root causes VLAN + DHCP
# -------------------------------------------------------------

$Multi = @"
PC1 ndodhet ne VLAN 10.

PC1:
IPv4 Address: 169.254.50.20
Default Gateway:

Switch port Fa0/2 duhet te jete ne VLAN 10,
por eshte konfiguruar ne VLAN 20.

DHCP server ndodhet ne 192.168.50.10.

Interface gateway per VLAN 10 nuk ka ip helper-address.

Access port VLAN mismatch on Fa0/2.
DHCP relay missing on client gateway interface.
"@

$result3 = & $Engine -Prompt $Multi -Engine Fast 2>&1 | Out-String

Test-Result `
    "VLAN mismatch detected in multi-problem incident" `
    ($result3 -match "Access Port VLAN Mismatch")

Test-Result `
    "DHCP relay also detected" `
    ($result3 -match "DHCP Relay Missing")

Test-Result `
    "Multiple findings generated" `
    ($result3 -match "FINDINGS:\s*[23456789]")


# -------------------------------------------------------------
# VERSION
# -------------------------------------------------------------

Test-Result `
    "Engine reports v5.7" `
    ($result3 -match "NETWORK TROUBLESHOOTER v5.7")


Write-Host ""
Write-Host "============================================="
Write-Host " PASSED : $Passed"
Write-Host " FAILED : $Failed"
Write-Host "============================================="

if ($Failed -gt 0) {
    exit 1
}

Write-Host "NETOPS v5.7 RELIABILITY PATCH: READY" -ForegroundColor Green

