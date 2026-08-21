function Get-RuleLayer2 {
    param([string]$Text)

    $findings = @()

    # ---------------------------------------------------------
    # Access VLAN mismatch
    # ---------------------------------------------------------

    # Explicit VLAN mismatch detection.
    #
    # Examples:
    # Fa0/2 duhet te jete ne VLAN 10 por eshte VLAN 20
    # Fa0/2 should be in VLAN 10 but is configured in VLAN 20

    $explicitVlanMismatch = [regex]::Match(
        $Text,
        '(?is)(?:porta|porti|port|interface|switch\s+port)\s+((?:Fa|Gi|FastEthernet|GigabitEthernet)[0-9\/\.]+).*?(?:duhet(?:\s+te\s+jete)?|should\s+be).*?\bVLAN\s+(\d+).*?(?:konfiguruar|configured|eshte|is).*?\bVLAN\s+(\d+)'
    )

    if ($explicitVlanMismatch.Success) {

        $explicitIf    = $explicitVlanMismatch.Groups[1].Value
        $expectedVlan  = $explicitVlanMismatch.Groups[2].Value
        $configuredVlan = $explicitVlanMismatch.Groups[3].Value

        if ($expectedVlan -ne $configuredVlan) {

            $findings += New-NetFinding `
                -Category "VLAN" `
                -Severity "HIGH" `
                -Role "ROOT_CAUSE" `
                -Validation "CONFIRMED" `
                -Problem "Access Port VLAN Mismatch." `
                -Evidence "$explicitIf duhet te jete ne VLAN $expectedVlan, por eshte ne VLAN $configuredVlan." `
                -Fix "Konfiguro $explicitIf ne access VLAN $expectedVlan." `
                -Verify "show vlan brief; show interfaces $explicitIf switchport" `
                -NextCommand "show interfaces $explicitIf switchport" `
                -Confidence 99 `
                -Priority 5 `
                -Interface $explicitIf
        }
    }

    $hostVlan = [regex]::Match(
        $Text,
        '(?i)(?:PC\d*|hosti?|klienti?)\s+.*?\bVLAN\s+(\d+)'
    )

    $portVlan = [regex]::Match(
        $Text,
        '(?i)(?:porta|porti|port|interface)\s+((?:Fa|Gi|FastEthernet|GigabitEthernet)[0-9\/\.]+)\s+.*?\bVLAN\s+(\d+)'
    )

    if (
        -not $explicitVlanMismatch.Success -and
        $hostVlan.Success -and
        $portVlan.Success
    ) {

        $hv = $hostVlan.Groups[1].Value
        $if = $portVlan.Groups[1].Value
        $pv = $portVlan.Groups[2].Value

        if ($hv -ne $pv) {

            $findings += New-NetFinding `
                -Category "VLAN" `
                -Severity "HIGH" `
                -Role "ROOT_CAUSE" `
                -Validation "CONFIRMED" `
                -Problem "Access Port VLAN Mismatch." `
                -Evidence "Hosti eshte ne VLAN $hv, por $if eshte ne VLAN $pv." `
                -Fix "Konfiguro $if ne access VLAN $hv." `
                -Verify "show vlan brief; show interfaces $if switchport" `
                -NextCommand "show interfaces $if switchport" `
                -Confidence 98 `
                -Priority 10 `
                -Interface $if
        }
    }

    # ---------------------------------------------------------
    # Trunk allowed VLAN mismatch
    # ---------------------------------------------------------

    $trunks = [regex]::Matches(
        $Text,
        '(?im)^\s*Vlans allowed on trunk\s*:\s*([0-9,\- ]+)'
    )

    if ($trunks.Count -ge 2) {

        $a = @(
            $trunks[0].Groups[1].Value -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
        )

        $b = @(
            $trunks[1].Groups[1].Value -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
        )

        $missing = @(
            @($a | Where-Object { $b -notcontains $_ }) +
            @($b | Where-Object { $a -notcontains $_ }) |
            Sort-Object -Unique
        )

        if ($missing.Count -gt 0) {

            $missingText = $missing -join ", "

            $findings += New-NetFinding `
                -Category "TRUNK" `
                -Severity "HIGH" `
                -Role "ROOT_CAUSE" `
                -Validation "CONFIRMED" `
                -Problem "Trunk Allowed VLAN Mismatch." `
                -Evidence "Allowed VLAN list nuk perputhet midis dy aneve. VLAN qe mungon: $missingText." `
                -Fix "Shto VLAN-in qe mungon ne allowed VLAN list." `
                -Verify "show interfaces trunk" `
                -NextCommand "show interfaces trunk" `
                -Confidence 98 `
                -Priority 10
        }
    }

    # ---------------------------------------------------------
    # Native VLAN mismatch
    # ---------------------------------------------------------

    $nativeVlans = Get-UniqueMatches `
        -Text $Text `
        -Pattern '(?i)native vlan\s*(?:is|:|=)?\s*(\d+)'

    if ($nativeVlans.Count -ge 2) {

        $findings += New-NetFinding `
            -Category "TRUNK" `
            -Severity "MEDIUM" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Native VLAN Mismatch." `
            -Evidence "Native VLAN values nuk perputhen: $($nativeVlans -join ' / ')." `
            -Fix "Konfiguro native VLAN identik ne te dy anet e trunk-ut." `
            -Verify "show interfaces trunk" `
            -NextCommand "show interfaces trunk" `
            -Confidence 97 `
            -Priority 15
    }

    # ---------------------------------------------------------
    # Administratively down
    # ---------------------------------------------------------

    $adminDown = [regex]::Match(
        $Text,
        '(?im)^\s*((?:GigabitEthernet|FastEthernet|Ethernet|Serial|Gi|Fa|Se)[A-Za-z0-9\/\.\-]+).*administratively down'
    )

    if ($adminDown.Success) {

        $ifName = $adminDown.Groups[1].Value

        $findings += New-NetFinding `
            -Category "INTERFACE" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Interface administratively down." `
            -Evidence "$ifName raportohet administratively down." `
            -Fix "Kontrollo qellimin e interface-it dhe apliko no shutdown nese duhet." `
            -Verify "show ip interface brief; show interfaces $ifName" `
            -NextCommand "show running-config interface $ifName" `
            -Confidence 99 `
            -Priority 5 `
            -Interface $ifName
    }

    # ---------------------------------------------------------
    # Err-disabled
    # ---------------------------------------------------------

    if ($Text -match '(?i)err-disabled|errdisabled') {

        $findings += New-NetFinding `
            -Category "INTERFACE" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Interface Err-Disabled." `
            -Evidence "Interface raportohet ne gjendje err-disabled." `
            -Fix "Identifiko shkakun para shutdown/no shutdown." `
            -Verify "show interfaces status err-disabled; show errdisable recovery" `
            -NextCommand "show interfaces status err-disabled" `
            -Confidence 99 `
            -Priority 5
    }

    # ---------------------------------------------------------
    # Duplex mismatch
    # ---------------------------------------------------------

    if (
        $Text -match '(?i)duplex mismatch' -or
        $Text -match '(?i)late collision.*duplex'
    ) {

        $findings += New-NetFinding `
            -Category "LAYER2" `
            -Severity "MEDIUM" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "Duplex Mismatch." `
            -Evidence "Evidence tregon duplex mismatch ose late collisions." `
            -Fix "Verifiko speed/duplex ne te dy anet." `
            -Verify "show interfaces" `
            -NextCommand "show interfaces" `
            -Confidence 92 `
            -Priority 25
    }

    return @($findings)
}

