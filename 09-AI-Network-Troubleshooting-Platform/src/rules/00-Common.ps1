function New-NetFinding {
    param(
        [string]$Category,
        [string]$Severity,
        [string]$Role,
        [string]$Validation,
        [string]$Problem,
        [string]$Evidence,
        [string]$Fix,
        [string]$Verify,
        [string]$NextCommand,
        [int]$Confidence = 90,
        [int]$Priority = 50,
        [string]$Interface = ""
    )

    [PSCustomObject]@{
        Category    = $Category
        Severity    = $Severity
        Role        = $Role
        Validation  = $Validation
        Problem     = $Problem
        Evidence    = $Evidence
        Fix         = $Fix
        Verify      = $Verify
        NextCommand = $NextCommand
        Confidence  = $Confidence
        Priority    = $Priority
        Interface   = $Interface
    }
}

function Get-UniqueMatches {
    param(
        [string]$Text,
        [string]$Pattern,
        [int]$Group = 1
    )

    @(
        [regex]::Matches($Text,$Pattern) |
        ForEach-Object {
            $_.Groups[$Group].Value.Trim()
        } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )
}
