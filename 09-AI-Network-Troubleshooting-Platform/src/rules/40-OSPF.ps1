function Get-RuleOSPF {
    param([string]$Text)

    $findings = @()

    # ---------------------------------------------------------
    # Area mismatch
    # ---------------------------------------------------------

    $areaMatches = [regex]::Matches(
        $Text,
        '(?im)^\s*(\d{1,3}(?:\.\d{1,3}){3}\/\d{1,2}).*?\b(?:OSPF\s*)?area\s+(\d+)'
    )

    if ($areaMatches.Count -ge 2) {

        $networks = @{}

        foreach ($m in $areaMatches) {

            $network = $m.Groups[1].Value
            $area    = $m.Groups[2].Value

            if (-not $networks.ContainsKey($network)) {
                $networks[$network] = @()
            }

            $networks[$network] += $area
        }

        foreach ($network in $networks.Keys) {

            $areas = @($networks[$network] | Sort-Object -Unique)

            if ($areas.Count -gt 1) {

                $findings += New-NetFinding `
                    -Category "OSPF" `
                    -Severity "HIGH" `
                    -Role "ROOT_CAUSE" `
                    -Validation "CONFIRMED" `
                    -Problem "OSPF Area Mismatch." `
                    -Evidence "Rrjeti $network eshte ne area te ndryshme: $($areas -join ' / ')." `
                    -Fix "Konfiguro te dy anet ne te njejten OSPF area." `
                    -Verify "show ip ospf neighbor; show ip ospf interface brief" `
                    -NextCommand "show ip ospf interface brief" `
                    -Confidence 99 `
                    -Priority 5
            }
        }
    }

    if (
        $Text -match '(?i)OSPF.*passive-interface.*(?:neighbor|adjacency).*(?:down|not formed|nuk)' -or
        $Text -match '(?i)passive-interface.*OSPF neighbor'
    ) {

        $findings += New-NetFinding `
            -Category "OSPF" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "OSPF Interface Configured Passive." `
            -Evidence "OSPF hello packets nuk dergohen nga passive interface." `
            -Fix "Hiq passive-interface vetem nga linku qe duhet te krijoje adjacency." `
            -Verify "show ip protocols; show ip ospf neighbor" `
            -NextCommand "show ip protocols" `
            -Confidence 98 `
            -Priority 10
    }

    if ($Text -match '(?i)OSPF authentication mismatch|OSPF auth mismatch') {

        $findings += New-NetFinding `
            -Category "OSPF" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "OSPF Authentication Mismatch." `
            -Evidence "OSPF peers perdorin authentication settings te ndryshme." `
            -Fix "Perputh authentication type dhe key." `
            -Verify "show ip ospf interface; show ip ospf neighbor" `
            -NextCommand "show ip ospf interface" `
            -Confidence 99 `
            -Priority 5
    }

    if (
        $Text -match '(?i)OSPF.*MTU mismatch' -or
        $Text -match '(?i)OSPF neighbor.*(?:EXSTART|EXCHANGE).*MTU'
    ) {

        $findings += New-NetFinding `
            -Category "OSPF" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "PROBABLE" `
            -Problem "OSPF MTU Mismatch." `
            -Evidence "OSPF adjacency ngec ne EXSTART/EXCHANGE me MTU mismatch." `
            -Fix "Perputh MTU ne link ose verifiko ip ospf mtu-ignore vetem kur justifikohet." `
            -Verify "show interfaces; show ip ospf neighbor" `
            -NextCommand "show interfaces" `
            -Confidence 96 `
            -Priority 15
    }

    if ($Text -match '(?i)duplicate OSPF router ID|OSPF duplicate router-id') {

        $findings += New-NetFinding `
            -Category "OSPF" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Duplicate OSPF Router ID." `
            -Evidence "Dy OSPF routers perdorin Router ID te njejte." `
            -Fix "Konfiguro Router ID unik dhe restart process kur duhet." `
            -Verify "show ip ospf; show ip ospf neighbor" `
            -NextCommand "show ip ospf" `
            -Confidence 99 `
            -Priority 5
    }

    return @($findings)
}
