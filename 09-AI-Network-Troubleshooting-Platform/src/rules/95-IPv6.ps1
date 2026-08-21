function Get-RuleIPv6 {
    param([string]$Text)

    $findings = @()

    if (
        $Text -match '(?i)IPv6 default route.*(?:missing|not configured)' -or
        $Text -match '(?i)::/0.*(?:missing|not present)'
    ) {

        $findings += New-NetFinding `
            -Category "IPV6" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "IPv6 Default Route Missing." `
            -Evidence "IPv6 ::/0 route nuk ekziston." `
            -Fix "Konfiguro IPv6 default route kur topologjia e kerkon." `
            -Verify "show ipv6 route" `
            -NextCommand "show ipv6 route" `
            -Confidence 98 `
            -Priority 10
    }

    if ($Text -match '(?i)IPv6 prefix mismatch') {

        $findings += New-NetFinding `
            -Category "IPV6" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "IPv6 Prefix Mismatch." `
            -Evidence "Devices ne te njejtin link perdorin IPv6 prefixes te papershtatshem." `
            -Fix "Korrigjo IPv6 addressing/prefix length." `
            -Verify "show ipv6 interface brief; ping ipv6" `
            -NextCommand "show ipv6 interface brief" `
            -Confidence 98 `
            -Priority 10
    }

    if ($Text -match '(?i)OSPFv3.*area mismatch') {

        $findings += New-NetFinding `
            -Category "OSPFV3" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "OSPFv3 Area Mismatch." `
            -Evidence "OSPFv3 peers jane ne area te ndryshme." `
            -Fix "Perputh OSPFv3 area ne link." `
            -Verify "show ipv6 ospf neighbor; show ipv6 ospf interface" `
            -NextCommand "show ipv6 ospf neighbor" `
            -Confidence 99 `
            -Priority 5
    }

    return @($findings)
}
