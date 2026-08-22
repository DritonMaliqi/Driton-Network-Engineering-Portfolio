function Get-RuleDhcpDns {
    param([string]$Text)

    $findings = @()

    if ($Text -match '(?i)\b169\.254\.\d+\.\d+\b|APIPA') {

        $findings += New-NetFinding `
            -Category "DHCP" `
            -Severity "HIGH" `
            -Role "SYMPTOM" `
            -Validation "PROBABLE" `
            -Problem "Klienti nuk ka marre DHCP lease." `
            -Evidence "U identifikua APIPA 169.254.x.x." `
            -Fix "Kontrollo VLAN, trunk, DHCP pool dhe DHCP relay." `
            -Verify "ipconfig /renew; show ip dhcp binding" `
            -NextCommand "show running-config | include dhcp|helper" `
            -Confidence 95 `
            -Priority 30
    }

    # IPv4 / IPv6 default gateway validation.
    # Windows ipconfig mund ta vendose gateway ne rreshtin pasues.

    $gatewayLineBlank = (
        $Text -match '(?im)^\s*Default Gateway\s*:\s*$'
    )

    $gatewayOnNextLine = (
        $Text -match '(?im)^\s*Default Gateway\s*:\s*\r?\n\s*(?:\d{1,3}(?:\.\d{1,3}){3}|[0-9A-Fa-f]*:[0-9A-Fa-f:]+)\s*$'
    )

    $explicitGatewayMissing = (
        $Text -match '(?i)default gateway.*(?:missing|mungon|bosh)'
    )

    if (
        ($gatewayLineBlank -and -not $gatewayOnNextLine) -or
        $explicitGatewayMissing
    ) {

        $findings += New-NetFinding `
            -Category "IP" `
            -Severity "HIGH" `
            -Role "SYMPTOM" `
            -Validation "CONFIRMED" `
            -Problem "Default Gateway mungon." `
            -Evidence "IP configuration tregon default gateway bosh." `
            -Fix "Kontrollo DHCP option/gateway ose konfigurimin statik." `
            -Verify "ipconfig /all; ping gateway" `
            -NextCommand "ipconfig /all" `
            -Confidence 95 `
            -Priority 35
    }

    if (
        $Text -match '(?i)DHCP pool.*(?:exhausted|full|no available addresses)' -or
        $Text -match '(?i)no available DHCP addresses'
    ) {

        $findings += New-NetFinding `
            -Category "DHCP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "DHCP Pool Exhausted." `
            -Evidence "DHCP server nuk ka adresa te lira." `
            -Fix "Zgjero pool-in ose liro lease te panevojshme." `
            -Verify "show ip dhcp pool; show ip dhcp binding" `
            -NextCommand "show ip dhcp pool" `
            -Confidence 99 `
            -Priority 10
    }

    if (
        $Text -match '(?i)(?:ip helper-address|DHCP relay).*(?:missing|mungon|not configured)'
    ) {

        $findings += New-NetFinding `
            -Category "DHCP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "DHCP Relay Missing." `
            -Evidence "Gateway interface nuk ka DHCP relay/helper-address." `
            -Fix "Konfiguro ip helper-address drejt DHCP server-it." `
            -Verify "show running-config interface; ipconfig /renew" `
            -NextCommand "show running-config | include helper-address" `
            -Confidence 98 `
            -Priority 10
    }

    # ---------------------------------------------------------
    # NETOPS DHCP NATURAL ENGLISH RELAY
    # ---------------------------------------------------------

    if (
        $Text -match '(?i)\bthere\s+is\s+no\s+ip\s+helper-address\b' -or
        $Text -match '(?i)\bno\s+ip\s+helper-address\s+configured\b' -or
        $Text -match '(?i)\bip\s+helper-address\s+is\s+not\s+configured\b'
    ) {

        $findings += New-NetFinding `
            -Category "DHCP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "DHCP Relay Missing." `
            -Evidence "Gateway interface does not have an ip helper-address configured." `
            -Fix "Configure ip helper-address toward the DHCP server." `
            -Verify "show running-config interface; ipconfig /renew" `
            -NextCommand "show running-config | include helper-address" `
            -Confidence 98 `
            -Priority 10
    }

    if (
        $Text -match '(?i)DNS.*(?:failure|failed|not resolving|nuk rezolvon)' -or
        $Text -match '(?i)nslookup.*(?:timed out|server failed)'
    ) {

        $findings += New-NetFinding `
            -Category "DNS" `
            -Severity "MEDIUM" `
            -Role "SYMPTOM" `
            -Validation "PROBABLE" `
            -Problem "DNS Resolution Failure." `
            -Evidence "Name resolution deshton." `
            -Fix "Verifiko DNS server, IP reachability dhe DNS records." `
            -Verify "ping DNS-server; nslookup hostname" `
            -NextCommand "nslookup hostname" `
            -Confidence 92 `
            -Priority 40
    }

    if ($Text -match '(?i)duplicate IP|IP address conflict') {

        $findings += New-NetFinding `
            -Category "IP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "Duplicate IP Address." `
            -Evidence "U identifikua IP address conflict." `
            -Fix "Identifiko pajisjet me IP te njejte dhe korrigjo adresimin." `
            -Verify "arp -a; show ip arp" `
            -NextCommand "show ip arp" `
            -Confidence 98 `
            -Priority 10
    }

    return @($findings)
}



