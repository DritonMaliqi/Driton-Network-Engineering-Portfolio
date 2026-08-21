function Get-RuleBGP {
    param([string]$Text)

    $findings = @()

    if ($Text -match '(?i)BGP.*remote-as mismatch|wrong remote-as') {

        $findings += New-NetFinding `
            -Category "BGP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "BGP Remote-AS Mismatch." `
            -Evidence "Configured remote-as nuk perputhet me peer AS." `
            -Fix "Korrigjo neighbor remote-as." `
            -Verify "show ip bgp summary" `
            -NextCommand "show ip bgp summary" `
            -Confidence 99 `
            -Priority 5
    }

    if (
        $Text -match '(?i)BGP neighbor.*\bIdle\b' -or
        $Text -match '(?i)BGP neighbor.*\bActive\b'
    ) {

        $findings += New-NetFinding `
            -Category "BGP" `
            -Severity "HIGH" `
            -Role "SYMPTOM" `
            -Validation "CONFIRMED" `
            -Problem "BGP Session Not Established." `
            -Evidence "BGP neighbor eshte Idle/Active." `
            -Fix "Kontrollo TCP/179, peer reachability, AS dhe update-source." `
            -Verify "show ip bgp summary; ping peer" `
            -NextCommand "show ip bgp summary" `
            -Confidence 94 `
            -Priority 30
    }

    if ($Text -match '(?i)BGP next-hop.*(?:unreachable|not reachable)') {

        $findings += New-NetFinding `
            -Category "BGP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "BGP Next-Hop Unreachable." `
            -Evidence "BGP next-hop nuk eshte reachable nga routing table." `
            -Fix "Rregullo IGP/static reachability ose next-hop-self kur duhet." `
            -Verify "show ip route; show ip bgp" `
            -NextCommand "show ip route" `
            -Confidence 97 `
            -Priority 10
    }

    if ($Text -match '(?i)BGP route.*not advertised|network.*not advertised into BGP') {

        $findings += New-NetFinding `
            -Category "BGP" `
            -Severity "MEDIUM" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "BGP Prefix Not Advertised." `
            -Evidence "Expected prefix nuk po reklamohet." `
            -Fix "Kontrollo network statement, route existence dhe policy." `
            -Verify "show ip bgp; show ip route" `
            -NextCommand "show ip bgp" `
            -Confidence 93 `
            -Priority 20
    }

    return @($findings)
}
