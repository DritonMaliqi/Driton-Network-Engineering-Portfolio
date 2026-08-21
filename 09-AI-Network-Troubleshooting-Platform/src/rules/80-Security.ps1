function Get-RuleSecurity {
    param([string]$Text)

    $findings = @()

    if (
        $Text -match '(?i)port-security.*violation' -or
        $Text -match '(?i)psecure-violation'
    ) {

        $findings += New-NetFinding `
            -Category "SECURITY" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Port Security Violation." `
            -Evidence "Port-security violation eshte regjistruar." `
            -Fix "Identifiko MAC/device dhe policy para recovery." `
            -Verify "show port-security interface; show interfaces status" `
            -NextCommand "show port-security interface" `
            -Confidence 99 `
            -Priority 5
    }

    if (
        $Text -match '(?i)DHCP snooping.*(?:drop|untrusted)' -and
        $Text -match '(?i)DHCP'
    ) {

        $findings += New-NetFinding `
            -Category "SECURITY" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "DHCP Snooping Trust Issue." `
            -Evidence "DHCP traffic po bllokohet nga snooping trust state." `
            -Fix "Verifiko trusted uplink dhe VLAN snooping scope." `
            -Verify "show ip dhcp snooping" `
            -NextCommand "show ip dhcp snooping" `
            -Confidence 94 `
            -Priority 20
    }

    if ($Text -match '(?i)DAI.*(?:invalid arp|ARP inspection.*drop)') {

        $findings += New-NetFinding `
            -Category "SECURITY" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "Dynamic ARP Inspection Drop." `
            -Evidence "DAI po refuzon ARP packets." `
            -Fix "Kontrollo DHCP snooping binding dhe trusted interfaces." `
            -Verify "show ip arp inspection; show ip dhcp snooping binding" `
            -NextCommand "show ip arp inspection" `
            -Confidence 94 `
            -Priority 20
    }

    return @($findings)
}
