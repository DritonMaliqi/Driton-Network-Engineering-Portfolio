function Get-RuleRouting {
    param([string]$Text)

    $findings = @()

    if ($Text -match '(?i)Gateway of last resort is not set') {

        $findings += New-NetFinding `
            -Category "ROUTING" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Default Route Missing." `
            -Evidence "Routing table tregon Gateway of last resort is not set." `
            -Fix "Konfiguro default route vetem nese topologjia e kerkon." `
            -Verify "show ip route; ping next-hop" `
            -NextCommand "show ip route" `
            -Confidence 98 `
            -Priority 10
    }

    if (
        $Text -match '(?i)(?:route|network).*(?:missing from routing table|route missing|nuk gjendet ne routing table)'
    ) {

        $findings += New-NetFinding `
            -Category "ROUTING" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "Required Route Missing." `
            -Evidence "Destination route nuk gjendet ne routing table." `
            -Fix "Kontrollo connected/static/dynamic route origjinen." `
            -Verify "show ip route; show ip protocols" `
            -NextCommand "show ip route" `
            -Confidence 94 `
            -Priority 20
    }

    if ($Text -match '(?i)next-hop.*(?:unreachable|not reachable)') {

        $findings += New-NetFinding `
            -Category "ROUTING" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Route Next-Hop Unreachable." `
            -Evidence "Next-hop nuk eshte reachable." `
            -Fix "Rregullo Layer 2/3 reachability drejt next-hop." `
            -Verify "ping next-hop; show ip route" `
            -NextCommand "ping next-hop" `
            -Confidence 97 `
            -Priority 10
    }

    return @($findings)
}
