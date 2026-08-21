param(
    [string]$Prompt,
    [string[]]$FilePath,

    [ValidateSet("Fast","Hybrid")]
    [string]$Engine = "Fast"
)

$ErrorActionPreference = "Stop"

$RuleFolder = Join-Path $PSScriptRoot "rules"

if (-not (Test-Path $RuleFolder)) {
    Write-Output "ENGINE ERROR: Rules folder nuk u gjet: $RuleFolder"
    exit 1
}

Get-ChildItem $RuleFolder -Filter "*.ps1" |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }

function Get-EvidenceType {
    param([string]$Content)

    if (
        $Content -match '(?i)Windows IP Configuration' -or
        $Content -match '(?i)IPv4 Address' -or
        $Content -match '(?i)Default Gateway'
    ) {
        return "WINDOWS_IPCONFIG"
    }

    if ($Content -match '(?i)Vlans allowed on trunk|show interfaces trunk') {
        return "TRUNK"
    }

    if ($Content -match '(?i)VLAN Name\s+Status\s+Ports|show vlan brief') {
        return "VLAN"
    }

    if ($Content -match '(?i)OSPF|show ip ospf') {
        return "OSPF"
    }

    if ($Content -match '(?i)EIGRP|show ip eigrp') {
        return "EIGRP"
    }

    if ($Content -match '(?i)\bBGP\b|show ip bgp') {
        return "BGP"
    }

    if ($Content -match '(?i)access-list|show access-lists|access-group') {
        return "ACL"
    }

    if ($Content -match '(?i)\bNAT\b|show ip nat') {
        return "NAT"
    }

    if ($Content -match '(?i)Gateway of last resort|show ip route') {
        return "ROUTING"
    }

    if ($Content -match '(?i)IPv6|show ipv6') {
        return "IPV6"
    }

    return "TEXT"
}

$inputText = ""
$fileSummary = @()

if ($FilePath) {

    foreach ($file in $FilePath) {

        if (-not (Test-Path $file)) {
            Write-Output "ENGINE ERROR: File nuk ekziston: $file"
            exit 1
        }

        $content = Get-Content $file -Raw

        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        $type = Get-EvidenceType $content

        $fileSummary += [PSCustomObject]@{
            File = $file
            Type = $type
        }

        $inputText += "`r`n$content`r`n"
    }
}

if (-not [string]::IsNullOrWhiteSpace($Prompt)) {
    $inputText += "`r`n$Prompt`r`n"
}

Write-Output ""
Write-Output "============================================================"
Write-Output " NETWORK TROUBLESHOOTER v5.7"
Write-Output " FULL CCNA / CCNP RULE PACK - RELIABILITY PATCH"
Write-Output "============================================================"
Write-Output ""

if ([string]::IsNullOrWhiteSpace($inputText)) {

    Write-Output "Nuk u dha incident description ose evidence."
    exit
}

$knownEvidence = @(
    $fileSummary.Type |
    Sort-Object -Unique
)

Write-Output "KNOWN EVIDENCE:"

if ($knownEvidence.Count -eq 0) {
    Write-Output "- INCIDENT TEXT"
}
else {
    foreach ($item in $knownEvidence) {
        Write-Output "- $item"
    }
}

$findings = @()

$ruleFunctions = @(
    "Get-RuleLayer2",
    "Get-RuleDhcpDns",
    "Get-RuleRouting",
    "Get-RuleOSPF",
    "Get-RuleEIGRP",
    "Get-RuleBGP",
    "Get-RuleAclNat",
    "Get-RuleSecurity",
    "Get-RuleVPN",
    "Get-RuleIPv6"
)

foreach ($ruleFunction in $ruleFunctions) {

    if (Get-Command $ruleFunction -ErrorAction SilentlyContinue) {

        try {
            $result = & $ruleFunction -Text $inputText

            if ($null -ne $result) {
                $findings += @($result)
            }
        }
        catch {
            Write-Output ""
            Write-Output "RULE ERROR [$ruleFunction]"
            Write-Output $_.Exception.Message
        }
    }
}

$findings = @(
    $findings |
    Sort-Object Priority, Category, Problem
)

Write-Output ""
Write-Output "FINDINGS: $($findings.Count)"
Write-Output ""

foreach ($f in $findings) {

    Write-Output "[$($f.Severity)] [$($f.Validation)] [$($f.Role)] $($f.Category)"
    Write-Output "Problem    : $($f.Problem)"
    Write-Output "Evidence   : $($f.Evidence)"
    Write-Output "Confidence : $($f.Confidence)%"

    if ($f.Interface) {
        Write-Output "Interface  : $($f.Interface)"
    }

    Write-Output ""
}

Write-Output "============================================================"
Write-Output " DECISION"
Write-Output "============================================================"
Write-Output ""

$rootCauses = @(
    $findings |
    Where-Object {
        $_.Role -eq "ROOT_CAUSE" -and
        $_.Validation -eq "CONFIRMED"
    }
)

$probableRoot = @(
    $findings |
    Where-Object {
        $_.Role -eq "ROOT_CAUSE" -and
        $_.Validation -eq "PROBABLE"
    }
)

$symptoms = @(
    $findings |
    Where-Object {
        $_.Role -eq "SYMPTOM"
    }
)

if ($rootCauses.Count -gt 0) {

    $decision = "FIX"

    Write-Output "FIX"
    Write-Output "Ka root cause te konfirmuar."

}
elseif ($probableRoot.Count -gt 0) {

    $decision = "VERIFY"

    Write-Output "VERIFY"
    Write-Output "Ka root cause probable. Verifiko para ndryshimit."

}
elseif ($symptoms.Count -gt 0) {

    $decision = "COLLECT_MORE"

    Write-Output "COLLECT_MORE"
    Write-Output "Ka simptoma, por root cause ende nuk eshte konfirmuar."

}
else {

    $decision = "STOP"

    Write-Output "STOP"
    Write-Output "Nuk ka evidence te mjaftueshme per troubleshooting te sigurt."
}

Write-Output ""
Write-Output "============================================================"
Write-Output " SMART NEXT STEP"
Write-Output "============================================================"
Write-Output ""

if ($findings.Count -gt 0) {

    $next = $findings[0].NextCommand

    if ($next) {
        Write-Output $next
    }
    else {
        Write-Output "Mblidh evidence shtese."
    }
}
else {

    Write-Output "Mblidh evidence shtese."
}

if ($Engine -eq "Hybrid") {

    Write-Output ""
    Write-Output "============================================================"
    Write-Output " HYBRID AI"
    Write-Output "============================================================"
    Write-Output ""

    try {

        $summary = (
            $findings |
            ForEach-Object {
                "$($_.Category): $($_.Problem) [$($_.Confidence)%]"
            }
        ) -join "`n"

        $aiPrompt = @"
Ti je NETOPS Network Troubleshooting Assistant.

Mos shpik fakte.
Perdor findings e rule engine.
Pergjigju ne shqip.
Jep:
1. Analizen
2. Root cause
3. Fix
4. Verification
5. Risk para ndryshimit

DECISION:
$decision

FINDINGS:
$summary

RAW INCIDENT:
$inputText
"@

        $body = @{
            model = "llama3.2"
            prompt = $aiPrompt
            stream = $false
            options = @{
                temperature = 0.05
                num_predict = 350
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod `
            -Uri "http://127.0.0.1:11434/api/generate" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body

        Write-Output $response.response
    }
    catch {
        Write-Output "Ollama unavailable: $($_.Exception.Message)"
    }
}
else {

    Write-Output ""
    Write-Output "FAST MODE: Ollama nuk u perdor."
}

