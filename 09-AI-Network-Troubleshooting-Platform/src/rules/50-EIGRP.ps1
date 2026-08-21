function Get-RuleEIGRP {
    param([string]$Text)

    $findings = @()

    $asNumbers = Get-UniqueMatches `
        -Text $Text `
        -Pattern '(?i)EIGRP\s+(?:AS\s*)?(\d+)'

    if ($asNumbers.Count -ge 2) {

        $findings += New-NetFinding `
            -Category "EIGRP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "EIGRP Autonomous System Mismatch." `
            -Evidence "EIGRP AS values nuk perputhen: $($asNumbers -join ' / ')." `
            -Fix "Perputh EIGRP AS ne peers." `
            -Verify "show ip eigrp neighbors; show ip protocols" `
            -NextCommand "show ip protocols" `
            -Confidence 98 `
            -Priority 10
    }

    if ($Text -match '(?i)EIGRP K-value mismatch|K values mismatch') {

        $findings += New-NetFinding `
            -Category "EIGRP" `
            -Severity "HIGH" `
            -Role "ROOT_CAUSE" `
            -Validation "CONFIRMED" `
            -Problem "EIGRP K-Value Mismatch." `
            -Evidence "EIGRP metric weights nuk perputhen." `
            -Fix "Perputh metric weights ne neighbors." `
            -Verify "show ip protocols" `
            -NextCommand "show ip protocols" `
            -Confidence 99 `
            -Priority 5
    }

    if ($Text -match '(?i)EIGRP.*stuck in active|EIGRP.*SIA') {

        $findings += New-NetFinding `
            -Category "EIGRP" `
            -Severity "HIGH" `
            -Role "SYMPTOM" `
            -Validation "CONFIRMED" `
            -Problem "EIGRP Stuck-In-Active." `
            -Evidence "Route raportohet SIA." `
            -Fix "Kontrollo query scope, reachability dhe summarization." `
            -Verify "show ip eigrp topology active" `
            -NextCommand "show ip eigrp topology active" `
            -Confidence 96 `
            -Priority 30
    }

    return @($findings)
}
