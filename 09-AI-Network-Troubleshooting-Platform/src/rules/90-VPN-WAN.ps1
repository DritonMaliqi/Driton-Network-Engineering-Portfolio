function Get-RuleVPN {
    param([string]$Text)

    $findings = @()

    # GRE endpoint validation.
    #
    # Supports:
    # tunnel destination mismatch
    # tunnel destination incorrect
    # wrong tunnel destination
    # wrong tunnel source
    # GRE source/destination mismatch

    $greEndpointProblem = (
        $Text -match '(?i)tunnel\s+(?:source|destination).{0,80}(?:wrong|incorrect|missing|mismatch)' -or
        $Text -match '(?i)(?:wrong|incorrect|missing|mismatch).{0,80}tunnel\s+(?:source|destination)' -or
        $Text -match '(?i)GRE.{0,40}tunnel.{0,40}(?:source|destination).{0,40}mismatch'
    )

    if (
        $Text -match '(?i)\bGRE\b' -and
        $greEndpointProblem
    ) {

        $findings += New-NetFinding `
            -Category "GRE" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "GRE Tunnel Source/Destination Misconfiguration." `
            -Evidence "GRE tunnel source ose destination nuk perputhet me endpoint-in e pritur." `
            -Fix "Korrigjo tunnel source/destination dhe verifiko underlay reachability." `
            -Verify "show interfaces tunnel; show running-config interface Tunnel0" `
            -NextCommand "show interfaces tunnel" `
            -Confidence 98 `
            -Priority 10
    }

    if (
        $Text -match '(?i)IPsec.*(?:proposal mismatch|transform-set mismatch|phase 1 mismatch|phase 2 mismatch)'
    ) {

        $findings += New-NetFinding `
            -Category "IPSEC" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "IPsec Crypto Parameter Mismatch." `
            -Evidence "VPN peers nuk kane crypto parameters kompatibile." `
            -Fix "Perputh encryption, integrity, DH/PFS dhe lifetime sipas fazes." `
            -Verify "show crypto isakmp sa; show crypto ipsec sa" `
            -NextCommand "show crypto isakmp sa" `
            -Confidence 98 `
            -Priority 10
    }

    if ($Text -match '(?i)IPsec.*pre-shared key mismatch|PSK mismatch') {

        $findings += New-NetFinding `
            -Category "IPSEC" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "IPsec Pre-Shared Key Mismatch." `
            -Evidence "VPN peers perdorin PSK te ndryshme." `
            -Fix "Perputh PSK ne te dy peers." `
            -Verify "show crypto isakmp sa" `
            -NextCommand "show crypto isakmp sa" `
            -Confidence 99 `
            -Priority 5
    }

    return @($findings)
}

