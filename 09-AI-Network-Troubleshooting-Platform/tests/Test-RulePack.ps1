$ErrorActionPreference = "Stop"

$Project = Split-Path $PSScriptRoot
$EnginePath = Join-Path $Project "src\AI-Offline.ps1"

$Tests = @(

    @{
        Name = "VLAN Access Port Mismatch"
        Expected = "Access Port VLAN Mismatch"
        Input = @"
PC1 eshte ne VLAN 10.
Porta Fa0/2 eshte ne VLAN 1.
PC1 nuk mund te ping gateway.
"@
    },

    @{
        Name = "Trunk Allowed VLAN Mismatch"
        Expected = "Trunk Allowed VLAN Mismatch"
        Input = @"
SW1:
Vlans allowed on trunk: 10,20,50
SW2:
Vlans allowed on trunk: 20,50
"@
    },

    @{
        Name = "Native VLAN Mismatch"
        Expected = "Native VLAN Mismatch"
        Input = @"
SW1 native vlan: 10
SW2 native vlan: 99
"@
    },

    @{
        Name = "Administrative Down"
        Expected = "Interface administratively down"
        Input = @"
GigabitEthernet0/1 192.168.1.1 YES manual administratively down down
"@
    },

    @{
        Name = "Err Disabled"
        Expected = "Interface Err-Disabled"
        Input = "Fa0/3 is err-disabled"
    },

    @{
        Name = "DHCP APIPA"
        Expected = "DHCP lease"
        Input = @"
Windows IP Configuration
IPv4 Address: 169.254.20.44
Default Gateway:
"@
    },

    @{
        Name = "DHCP Pool Exhausted"
        Expected = "DHCP Pool Exhausted"
        Input = "DHCP pool exhausted - no available addresses"
    },

    @{
        Name = "DHCP Relay Missing"
        Expected = "DHCP Relay Missing"
        Input = "ip helper-address missing on client gateway interface"
    },

    @{
        Name = "DNS Failure"
        Expected = "DNS Resolution Failure"
        Input = "DNS resolution failed. nslookup server timed out."
    },

    @{
        Name = "Default Route Missing"
        Expected = "Default Route Missing"
        Input = "Gateway of last resort is not set"
    },

    @{
        Name = "OSPF Area Mismatch"
        Expected = "OSPF Area Mismatch"
        Input = @"
10.0.12.0/30 OSPF area 0
10.0.12.0/30 OSPF area 1
OSPF neighbor nuk krijohet.
"@
    },

    @{
        Name = "OSPF Authentication"
        Expected = "OSPF Authentication Mismatch"
        Input = "OSPF authentication mismatch between R1 and R2"
    },

    @{
        Name = "OSPF MTU"
        Expected = "OSPF MTU Mismatch"
        Input = "OSPF neighbor stuck EXSTART because of MTU mismatch"
    },

    @{
        Name = "EIGRP AS"
        Expected = "EIGRP Autonomous System Mismatch"
        Input = @"
R1 EIGRP AS 100
R2 EIGRP AS 200
"@
    },

    @{
        Name = "EIGRP K Values"
        Expected = "EIGRP K-Value Mismatch"
        Input = "EIGRP K-value mismatch"
    },

    @{
        Name = "BGP Remote AS"
        Expected = "BGP Remote-AS Mismatch"
        Input = "BGP remote-as mismatch between peers"
    },

    @{
        Name = "BGP Idle"
        Expected = "BGP Session Not Established"
        Input = "BGP neighbor 10.1.1.2 Idle"
    },

    @{
        Name = "ACL Blocking"
        Expected = "ACL Blocking Required Traffic"
        Input = "ACL denies required traffic from branch subnet"
    },

    @{
        Name = "NAT ACL Missing Subnet"
        Expected = "Source Subnet Missing From NAT ACL"
        Input = "Branch subnet 192.168.30.0/24 missing from NAT ACL"
    },

    @{
        Name = "PAT Overload"
        Expected = "PAT Overload Missing"
        Input = "PAT overload missing from NAT configuration"
    },

    @{
        Name = "Port Security"
        Expected = "Port Security Violation"
        Input = "switchport port-security violation detected on Fa0/4"
    },

    @{
        Name = "GRE Tunnel"
        Expected = "GRE Tunnel Source/Destination Misconfiguration"
        Input = "GRE tunnel down because tunnel destination is wrong"
    },

    @{
        Name = "IPsec Proposal"
        Expected = "IPsec Crypto Parameter Mismatch"
        Input = "IPsec proposal mismatch between VPN peers"
    },

    @{
        Name = "IPv6 Default Route"
        Expected = "IPv6 Default Route Missing"
        Input = "IPv6 default route missing"
    },

    @{
        Name = "IPv6 Prefix"
        Expected = "IPv6 Prefix Mismatch"
        Input = "IPv6 prefix mismatch between devices on same LAN"
    },

    @{
        Name = "OSPFv3 Area"
        Expected = "OSPFv3 Area Mismatch"
        Input = "OSPFv3 area mismatch"
    }
)

$Pass = 0
$Fail = 0

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NETOPS v5.3 AUTOMATED TEST SUITE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($t in $Tests) {

    $output = (
        & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $EnginePath `
            -Engine Fast `
            -Prompt $t.Input
    ) | Out-String

    if ($output -match [regex]::Escape($t.Expected)) {

        Write-Host "[PASS] $($t.Name)" -ForegroundColor Green
        $Pass++
    }
    else {

        Write-Host "[FAIL] $($t.Name)" -ForegroundColor Red
        Write-Host "       Expected: $($t.Expected)" -ForegroundColor Yellow
        $Fail++
    }
}

# -------------------------------------------------------------
# GUI transport / evidence-file test
# -------------------------------------------------------------

$temp = Join-Path $env:TEMP "NETOPS-v53-transport-test.txt"

@"
PC1 eshte ne VLAN 10.
Porta Fa0/2 eshte ne VLAN 1.
PC1 nuk mund te ping gateway.
"@ | Set-Content $temp -Encoding ASCII

$output = (
    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $EnginePath `
        -Engine Fast `
        -FilePath $temp
) | Out-String

if ($output -match "Access Port VLAN Mismatch") {

    Write-Host "[PASS] GUI / Evidence File Transport" -ForegroundColor Green
    $Pass++
}
else {

    Write-Host "[FAIL] GUI / Evidence File Transport" -ForegroundColor Red
    $Fail++
}

Remove-Item $temp -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TEST RESULT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "PASSED : $Pass" -ForegroundColor Green

if ($Fail -eq 0) {
    Write-Host "FAILED : 0" -ForegroundColor Green
    Write-Host ""
    Write-Host "NETOPS v5.3 RULE PACK: READY" -ForegroundColor Green
}
else {
    Write-Host "FAILED : $Fail" -ForegroundColor Red
    Write-Host ""
    Write-Host "Some rules require correction." -ForegroundColor Yellow
}

exit $Fail
