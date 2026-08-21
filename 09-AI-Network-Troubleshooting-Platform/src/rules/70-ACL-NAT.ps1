function Get-RuleAclNat {
    param([string]$Text)

    $findings = @()

    if (
        $Text -match '(?i)ACL.*(?:denies|deny|blocking|blocks).*(?:traffic|subnet|host)'
    ) {

        $findings += New-NetFinding `
            -Category "ACL" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "ACL Blocking Required Traffic." `
            -Evidence "ACL deny po perputhet me trafikun qe duhet te lejohet." `
            -Fix "Korrigjo ACL me ndryshimin minimal dhe ruaj rendin e ACE-ve." `
            -Verify "show access-lists; test connectivity" `
            -NextCommand "show access-lists" `
            -Confidence 95 `
            -Priority 15
    }

    if (
        $Text -match '(?i)ACL.*(?:wrong direction|incorrect direction)' -or
        $Text -match '(?i)access-group.*wrong direction'
    ) {

        $findings += New-NetFinding `
            -Category "ACL" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "ACL Applied In Wrong Direction." `
            -Evidence "ACL eshte aplikuar ne drejtim te gabuar." `
            -Fix "Apliko ACL ne interface/direction e duhur." `
            -Verify "show ip interface; show access-lists" `
            -NextCommand "show ip interface" `
            -Confidence 98 `
            -Priority 10
    }

    if (
        $Text -match '(?i)NAT ACL.*(?:missing|does not include|mungon).*(?:subnet|network)' -or
        $Text -match '(?i)subnet.*missing from NAT ACL'
    ) {

        $findings += New-NetFinding `
            -Category "NAT" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Source Subnet Missing From NAT ACL." `
            -Evidence "LAN subnet nuk perfshihet ne NAT/PAT ACL." `
            -Fix "Shto source subnet ne NAT ACL." `
            -Verify "show access-lists; show ip nat translations" `
            -NextCommand "show access-lists" `
            -Confidence 99 `
            -Priority 5
    }

    if ($Text -match '(?i)ip nat inside.*missing|NAT inside interface.*missing') {

        $findings += New-NetFinding `
            -Category "NAT" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "NAT Inside Role Missing." `
            -Evidence "LAN interface nuk ka ip nat inside." `
            -Fix "Konfiguro ip nat inside ne interface-in e brendshem." `
            -Verify "show running-config interface; show ip nat statistics" `
            -NextCommand "show ip nat statistics" `
            -Confidence 99 `
            -Priority 5
    }

    if ($Text -match '(?i)ip nat outside.*missing|NAT outside interface.*missing') {

        $findings += New-NetFinding `
            -Category "NAT" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "NAT Outside Role Missing." `
            -Evidence "WAN interface nuk ka ip nat outside." `
            -Fix "Konfiguro ip nat outside ne WAN interface." `
            -Verify "show running-config interface; show ip nat statistics" `
            -NextCommand "show ip nat statistics" `
            -Confidence 99 `
            -Priority 5
    }

    if (
        $Text -match '(?i)PAT.*overload.*missing' -or
        $Text -match '(?i)NAT overload.*not configured'
    ) {

        $findings += New-NetFinding `
            -Category "NAT" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "PAT Overload Missing." `
            -Evidence "Dynamic PAT command nuk permban overload." `
            -Fix "Shto overload kur dizajni kerkon PAT." `
            -Verify "show ip nat translations; show ip nat statistics" `
            -NextCommand "show ip nat statistics" `
            -Confidence 98 `
            -Priority 10
    }

    return @($findings)
}
