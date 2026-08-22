$WorkerPath = Join-Path $PSScriptRoot "Network-Engine-Worker.ps1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# PATHS
# ============================================================

$Desktop  = [Environment]::GetFolderPath("Desktop")
$Engine = Join-Path $PSScriptRoot "AI-Offline.ps1"

$IncidentManager = Join-Path $PSScriptRoot "Incident-Manager.ps1"

if (Test-Path $IncidentManager) {
    . $IncidentManager
}
$Reports  = Join-Path $Desktop "Network-Troubleshooter-Reports"
$History  = Join-Path $Reports "Incident-History.csv"
$Workflow = Join-Path $Desktop "Network-Troubleshooter-v4.2.ps1"

# ============================================================
# COLORS
# ============================================================

$BG      = [System.Drawing.Color]::FromArgb(15,23,42)
$SideBG  = [System.Drawing.Color]::FromArgb(17,28,46)
$CardBG  = [System.Drawing.Color]::FromArgb(30,41,59)
$PanelBG = [System.Drawing.Color]::FromArgb(21,32,51)

$Text    = [System.Drawing.Color]::FromArgb(226,232,240)
$Muted   = [System.Drawing.Color]::FromArgb(148,163,184)

$Cyan    = [System.Drawing.Color]::FromArgb(34,211,238)
$Green   = [System.Drawing.Color]::FromArgb(34,197,94)
$Yellow  = [System.Drawing.Color]::FromArgb(250,204,21)
$Red     = [System.Drawing.Color]::FromArgb(239,68,68)

# ============================================================
# DATA / ENGINE
# ============================================================

function Get-HistoryData {

    # NETOPS v5.8 - Always resolve history from Project 09\data
    $projectRoot = Split-Path $PSScriptRoot
    $historyFile = Join-Path $projectRoot "data\Incident-History.csv"

    if (-not (Test-Path $historyFile)) {
        return @()
    }

    try {
        $rows = @(Import-Csv $historyFile)
        return $rows
    }
    catch {
        return @()
    }
}
function Invoke-TroubleshooterEngine {
    param(
        [string]$Prompt = "",
        [string[]]$Files = @(),

        [ValidateSet("Fast","Hybrid")]
        [string]$Mode = "Fast"
    )

    if (-not (Test-Path $Engine)) {
        return "ERROR: AI-Offline.ps1 nuk u gjet.`r`n$Engine"
    }

    $tempPromptFile = $null

    try {

        $allFiles = @()

        foreach ($file in $Files) {
            if (
                -not [string]::IsNullOrWhiteSpace($file) -and
                (Test-Path $file)
            ) {
                $allFiles += $file
            }
        }

        # GUI incident description behet temporary evidence file.
        # Kjo metode u testua direkt dhe funksionon me v3.9.
        if (-not [string]::IsNullOrWhiteSpace($Prompt)) {

            $tempPromptFile = Join-Path `
                $env:TEMP `
                ("NetTroubleshooter-" + [guid]::NewGuid().ToString() + ".txt")

            Set-Content `
                -Path $tempPromptFile `
                -Value $Prompt `
                -Encoding ASCII

            $allFiles += $tempPromptFile
        }

        if ($allFiles.Count -eq 0) {
            return "Vendos incident description ose evidence file."
        }

        $output = (
            & $Engine `
                -Engine $Mode `
                -FilePath $allFiles `
                *>&1 |
            Out-String
        )

        return $output
    }
    catch {

        return @"
ENGINE ERROR

$($_.Exception.Message)
"@
    }
    finally {

        if (
            $tempPromptFile -and
            (Test-Path $tempPromptFile)
        ) {
            Remove-Item `
                -Path $tempPromptFile `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}
# ============================================================
# STYLE HELPERS
# ============================================================

function Style-NavButton {
    param([System.Windows.Forms.Button]$Button)

    $Button.Dock = "Fill"
    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $CardBG
    $Button.ForeColor = $Text
    $Button.TextAlign = "MiddleLeft"
    $Button.Padding = New-Object System.Windows.Forms.Padding(18,0,0,0)
    $Button.Margin = New-Object System.Windows.Forms.Padding(12,5,12,5)
    $Button.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
}

function Style-ActionButton {
    param([System.Windows.Forms.Button]$Button)

    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $CardBG
    $Button.ForeColor = $Text
    $Button.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
}

function Style-Grid {
    param([System.Windows.Forms.DataGridView]$Grid)

    $Grid.BackgroundColor = $CardBG
    $Grid.BorderStyle = "None"
    $Grid.ReadOnly = $true
    $Grid.AllowUserToAddRows = $false
    $Grid.AllowUserToDeleteRows = $false
    $Grid.RowHeadersVisible = $false
    $Grid.AutoSizeColumnsMode = "Fill"
    $Grid.SelectionMode = "FullRowSelect"
    $Grid.MultiSelect = $false

    $Grid.ColumnHeadersDefaultCellStyle.BackColor = $PanelBG
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $Grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = $PanelBG

    $Grid.DefaultCellStyle.BackColor = $CardBG
    $Grid.DefaultCellStyle.ForeColor = $Text
    $Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(51,65,85)

    $Grid.EnableHeadersVisualStyles = $false
}

function New-StatCard {
    param(
        [string]$Title,
        [System.Drawing.Color]$ValueColor
    )

    $outer = New-Object System.Windows.Forms.Panel
    $outer.Dock = "Fill"
    $outer.Margin = New-Object System.Windows.Forms.Padding(8)
    $outer.BackColor = $CardBG

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = "Fill"
    $layout.RowCount = 2
    $layout.ColumnCount = 1
    $layout.BackColor = $CardBG

    $layout.RowStyles.Add(
        (New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Percent,
            40
        ))
    )

    $layout.RowStyles.Add(
        (New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Percent,
            60
        ))
    )

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Dock = "Fill"
    $titleLabel.TextAlign = "MiddleLeft"
    $titleLabel.Padding = New-Object System.Windows.Forms.Padding(16,4,0,0)
    $titleLabel.ForeColor = $Muted
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI",9)

    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Text = "0"
    $valueLabel.Dock = "Fill"
    $valueLabel.TextAlign = "MiddleLeft"
    $valueLabel.Padding = New-Object System.Windows.Forms.Padding(16,0,0,6)
    $valueLabel.ForeColor = $ValueColor
    $valueLabel.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        24,
        [System.Drawing.FontStyle]::Bold
    )

    $layout.Controls.Add($titleLabel,0,0)
    $layout.Controls.Add($valueLabel,0,1)

    $outer.Controls.Add($layout)

    return [PSCustomObject]@{
        Panel = $outer
        Value = $valueLabel
    }
}

# ============================================================
# MAIN FORM
# ============================================================

# ============================================================
# NETOPS_CORE_TOOLS_V1
# ============================================================

function Show-NetOpsPingTool {

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Ping Tool"
    $toolForm.Size = New-Object System.Drawing.Size(620,500)
    $toolForm.StartPosition = "CenterScreen"

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "Target IP / Hostname:"
    $lblTarget.Location = New-Object System.Drawing.Point(20,20)
    $lblTarget.Size = New-Object System.Drawing.Size(180,25)
    $toolForm.Controls.Add($lblTarget)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(20,50)
    $txtTarget.Size = New-Object System.Drawing.Size(400,30)
    $toolForm.Controls.Add($txtTarget)

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Ping"
    $btnRun.Location = New-Object System.Drawing.Point(440,48)
    $btnRun.Size = New-Object System.Drawing.Size(130,32)
    $toolForm.Controls.Add($btnRun)

    $txtOutput = New-Object System.Windows.Forms.RichTextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20,100)
    $txtOutput.Size = New-Object System.Drawing.Size(550,320)
    $txtOutput.ReadOnly = $true
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas",10)
    $toolForm.Controls.Add($txtOutput)

    $btnRun.Add_Click({

        $target = $txtTarget.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Enter an IP address or hostname.",
                "NETOPS Ping"
            )
            return
        }

        $txtOutput.Clear()
        $txtOutput.AppendText("Pinging $target ...`r`n`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $result = ping.exe $target -n 4 2>&1 | Out-String
            $txtOutput.AppendText($result)
        }
        catch {
            $txtOutput.AppendText($_.Exception.Message)
        }
    })

# ============================================================
# NETOPS CORE TOOLS TOOLBAR
# ============================================================

$grpQuickTools = New-Object System.Windows.Forms.GroupBox
$grpQuickTools.Text = "Quick Network Tools"
$grpQuickTools.Location = New-Object System.Drawing.Point(20,10)
$grpQuickTools.Size = New-Object System.Drawing.Size(700,70)

$btnNetPing = New-Object System.Windows.Forms.Button
$btnNetPing.Text = "PING"
$btnNetPing.Location = New-Object System.Drawing.Point(15,25)
$btnNetPing.Size = New-Object System.Drawing.Size(120,30)
$btnNetPing.Add_Click({
    Show-NetOpsPingTool
})
$grpQuickTools.Controls.Add($btnNetPing)

$btnNetTrace = New-Object System.Windows.Forms.Button
$btnNetTrace.Text = "TRACEROUTE"
$btnNetTrace.Location = New-Object System.Drawing.Point(145,25)
$btnNetTrace.Size = New-Object System.Drawing.Size(130,30)
$btnNetTrace.Add_Click({
    Show-NetOpsTracerouteTool
})
$grpQuickTools.Controls.Add($btnNetTrace)

$btnShowCommands = New-Object System.Windows.Forms.Button
$btnShowCommands.Text = "SHOW COMMANDS"
$btnShowCommands.Location = New-Object System.Drawing.Point(285,25)
$btnShowCommands.Size = New-Object System.Drawing.Size(160,30)
$btnShowCommands.Add_Click({
    Show-NetOpsCommandsTool
})
$grpQuickTools.Controls.Add($btnShowCommands)

$btnInventory = New-Object System.Windows.Forms.Button
$btnInventory.Text = "DEVICE INVENTORY"
$btnInventory.Location = New-Object System.Drawing.Point(455,25)
$btnInventory.Size = New-Object System.Drawing.Size(170,30)
$btnInventory.Add_Click({
    Open-NetOpsDeviceInventorySafe
})
$grpQuickTools.Controls.Add($btnInventory)

$form.Controls.Add($grpQuickTools)


    [void]$toolForm.ShowDialog()
}


function Show-NetOpsTracerouteTool {

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Traceroute Tool"
    $toolForm.Size = New-Object System.Drawing.Size(650,520)
    $toolForm.StartPosition = "CenterScreen"

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "Target IP / Hostname:"
    $lblTarget.Location = New-Object System.Drawing.Point(20,20)
    $lblTarget.Size = New-Object System.Drawing.Size(180,25)
    $toolForm.Controls.Add($lblTarget)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(20,50)
    $txtTarget.Size = New-Object System.Drawing.Size(420,30)
    $toolForm.Controls.Add($txtTarget)

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Traceroute"
    $btnRun.Location = New-Object System.Drawing.Point(455,48)
    $btnRun.Size = New-Object System.Drawing.Size(145,32)
    $toolForm.Controls.Add($btnRun)

    $txtOutput = New-Object System.Windows.Forms.RichTextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20,100)
    $txtOutput.Size = New-Object System.Drawing.Size(580,330)
    $txtOutput.ReadOnly = $true
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas",10)
    $toolForm.Controls.Add($txtOutput)

    $btnRun.Add_Click({

        $target = $txtTarget.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Enter an IP address or hostname.",
                "NETOPS Traceroute"
            )
            return
        }

        $txtOutput.Clear()
        $txtOutput.AppendText("Tracing route to $target ...`r`n`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $result = tracert.exe $target 2>&1 | Out-String
            $txtOutput.AppendText($result)
        }
        catch {
            $txtOutput.AppendText($_.Exception.Message)
        }
    })

    [void]$toolForm.ShowDialog()
}


# ============================================================
# NETOPS_SHOW_COMMANDS_PRO_V1
# ============================================================

function Show-NetOpsCommandsTool {

    # --------------------------------------------------------
    # COLORS
    # --------------------------------------------------------

    $Bg       = [System.Drawing.Color]::FromArgb(14,25,42)
    $PanelBg  = [System.Drawing.Color]::FromArgb(28,43,64)
    $PanelBg2 = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text     = [System.Drawing.Color]::White
    $Muted    = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent   = [System.Drawing.Color]::FromArgb(25,205,235)

    # --------------------------------------------------------
    # FORM
    # --------------------------------------------------------

    $toolForm = New-Object System.Windows.Forms.Form

    $toolForm.Text = "NETOPS - Cisco Show Commands PRO"
    $toolForm.Size = New-Object System.Drawing.Size(1050,700)
    $toolForm.StartPosition = "CenterScreen"
    $toolForm.BackColor = $Bg
    $toolForm.ForeColor = $Text
    $toolForm.MinimumSize = New-Object System.Drawing.Size(900,600)

    # --------------------------------------------------------
    # TITLE
    # --------------------------------------------------------

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "CISCO SHOW COMMANDS"
    $lblTitle.Location = New-Object System.Drawing.Point(25,20)
    $lblTitle.Size = New-Object System.Drawing.Size(500,35)

    $lblTitle.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )

    $lblTitle.ForeColor = $Accent
    $toolForm.Controls.Add($lblTitle)

    $lblSubtitle = New-Object System.Windows.Forms.Label

    $lblSubtitle.Text =
        "CCNA / CCNP command reference for evidence collection and troubleshooting"

    $lblSubtitle.Location = New-Object System.Drawing.Point(27,57)
    $lblSubtitle.Size = New-Object System.Drawing.Size(700,25)
    $lblSubtitle.ForeColor = $Muted

    $toolForm.Controls.Add($lblSubtitle)

    # --------------------------------------------------------
    # CATEGORY
    # --------------------------------------------------------

    $lblCategory = New-Object System.Windows.Forms.Label
    $lblCategory.Text = "Category"
    $lblCategory.Location = New-Object System.Drawing.Point(25,105)
    $lblCategory.Size = New-Object System.Drawing.Size(100,25)
    $lblCategory.ForeColor = $Muted

    $toolForm.Controls.Add($lblCategory)

    $cmbCategory = New-Object System.Windows.Forms.ComboBox
    $cmbCategory.Location = New-Object System.Drawing.Point(25,132)
    $cmbCategory.Size = New-Object System.Drawing.Size(300,30)
    $cmbCategory.DropDownStyle = "DropDownList"

    [void]$cmbCategory.Items.AddRange(@(
        "All Commands",
        "Interface & IP",
        "Switching & VLAN",
        "Routing",
        "OSPF",
        "EIGRP",
        "BGP",
        "ACL & NAT",
        "STP & EtherChannel",
        "IPv6",
        "VPN & Security",
        "System & Troubleshooting"
    ))

    $toolForm.Controls.Add($cmbCategory)

    # --------------------------------------------------------
    # SEARCH
    # --------------------------------------------------------

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Search command - press ENTER"
    $lblSearch.Location = New-Object System.Drawing.Point(350,105)
    $lblSearch.Size = New-Object System.Drawing.Size(150,25)
    $lblSearch.ForeColor = $Muted

    $toolForm.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(350,132)
    $txtSearch.Size = New-Object System.Drawing.Size(360,30)

    $toolForm.Controls.Add($txtSearch)

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = "CLEAR"
    $btnClear.Location = New-Object System.Drawing.Point(725,130)
    $btnClear.Size = New-Object System.Drawing.Size(100,32)
    $btnClear.FlatStyle = "Flat"
    $btnClear.BackColor = $PanelBg
    $btnClear.ForeColor = $Text

    $toolForm.Controls.Add($btnClear)

    # --------------------------------------------------------
    # LIST
    # --------------------------------------------------------

    $lstCommands = New-Object System.Windows.Forms.ListBox
    $lstCommands.Location = New-Object System.Drawing.Point(25,185)
    $lstCommands.Size = New-Object System.Drawing.Size(390,405)
    $lstCommands.BackColor = $PanelBg2
    $lstCommands.ForeColor = $Text
    $lstCommands.BorderStyle = "FixedSingle"

    $lstCommands.Font = New-Object System.Drawing.Font(
        "Consolas",
        10
    )

    $toolForm.Controls.Add($lstCommands)

    # --------------------------------------------------------
    # DETAILS
    # --------------------------------------------------------

    $txtDescription = New-Object System.Windows.Forms.RichTextBox
    $txtDescription.Location = New-Object System.Drawing.Point(440,185)
    $txtDescription.Size = New-Object System.Drawing.Size(565,405)
    $txtDescription.ReadOnly = $true
    $txtDescription.BackColor = $PanelBg2
    $txtDescription.ForeColor = $Text
    $txtDescription.BorderStyle = "FixedSingle"

    $txtDescription.Font = New-Object System.Drawing.Font(
        "Consolas",
        10
    )

    $toolForm.Controls.Add($txtDescription)

    # --------------------------------------------------------
    # COPY BUTTON
    # --------------------------------------------------------

    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "COPY COMMAND"
    $btnCopy.Location = New-Object System.Drawing.Point(440,610)
    $btnCopy.Size = New-Object System.Drawing.Size(160,35)
    $btnCopy.FlatStyle = "Flat"
    $btnCopy.BackColor = $PanelBg
    $btnCopy.ForeColor = $Text

    $toolForm.Controls.Add($btnCopy)

    $lblCopyStatus = New-Object System.Windows.Forms.Label
    $lblCopyStatus.Location = New-Object System.Drawing.Point(620,618)
    $lblCopyStatus.Size = New-Object System.Drawing.Size(300,25)
    $lblCopyStatus.ForeColor = $Accent

    $toolForm.Controls.Add($lblCopyStatus)

    # ========================================================
    # COMMAND DATABASE
    # ========================================================

    $CommandDB = @{

        "Interface & IP" = @(
            "show ip interface brief",
            "show interfaces",
            "show interfaces description",
            "show interfaces counters errors",
            "show arp",
            "show ip protocols"
        )

        "Switching & VLAN" = @(
            "show vlan brief",
            "show interfaces trunk",
            "show interfaces switchport",
            "show mac address-table",
            "show spanning-tree",
            "show cdp neighbors detail",
            "show lldp neighbors detail"
        )

        "Routing" = @(
            "show ip route",
            "show ip route connected",
            "show ip route static",
            "show ip route ospf",
            "show ip route eigrp",
            "show ip route bgp"
        )

        "OSPF" = @(
            "show ip ospf neighbor",
            "show ip ospf interface brief",
            "show ip ospf interface",
            "show ip ospf database",
            "show ip ospf",
            "show ip route ospf",
            "show ip protocols"
        )

        "EIGRP" = @(
            "show ip eigrp neighbors",
            "show ip eigrp topology",
            "show ip eigrp interfaces",
            "show ip route eigrp",
            "show ip protocols"
        )

        "BGP" = @(
            "show bgp ipv4 unicast summary",
            "show ip bgp",
            "show bgp neighbors",
            "show ip route bgp"
        )

        "ACL & NAT" = @(
            "show access-lists",
            "show ip access-lists",
            "show ip nat translations",
            "show ip nat statistics",
            "show running-config | section access-list",
            "show running-config | include ip nat"
        )

        "STP & EtherChannel" = @(
            "show spanning-tree",
            "show spanning-tree root",
            "show spanning-tree vlan 10",
            "show etherchannel summary",
            "show interfaces port-channel"
        )

        "IPv6" = @(
            "show ipv6 interface brief",
            "show ipv6 route",
            "show ipv6 neighbors",
            "show ipv6 ospf neighbor",
            "show ipv6 protocols"
        )

        "VPN & Security" = @(
            "show crypto isakmp sa",
            "show crypto ipsec sa",
            "show crypto session",
            "show access-lists",
            "show logging"
        )

        "System & Troubleshooting" = @(
            "show running-config",
            "show startup-config",
            "show logging",
            "show version",
            "show inventory",
            "show processes cpu",
            "show memory",
            "show clock",
            "show users"
        )
    }

    # ========================================================
    # DETAILED HELP
    # ========================================================

    $CommandHelp = @{

        "show ip interface brief" = @{
            Purpose = "Quick summary of interface IP addresses and line/protocol status."
            Use = "Use early in troubleshooting to identify down interfaces, missing IP addresses or administratively disabled ports."
            Look = "Look for Status and Protocol. Ideally active Layer 3 interfaces should show up/up."
            Problems = "administratively down, down/down, up/down, wrong IP address."
        }

        "show vlan brief" = @{
            Purpose = "Displays VLANs and access-port membership."
            Use = "Use when an endpoint cannot communicate inside its expected VLAN."
            Look = "Confirm that the expected VLAN exists and the access interface appears under the correct VLAN."
            Problems = "Port in VLAN 1 instead of user VLAN, missing VLAN, inactive VLAN."
        }

        "show interfaces trunk" = @{
            Purpose = "Displays active trunks, native VLAN and allowed VLANs."
            Use = "Use when traffic between switches or router-on-a-stick VLANs fails."
            Look = "Confirm trunk status and that the required VLAN appears in the allowed and forwarding lists."
            Problems = "Missing allowed VLAN, wrong native VLAN, interface not trunking."
        }

        "show interfaces switchport" = @{
            Purpose = "Displays operational Layer 2 switchport configuration."
            Use = "Use to validate access VLAN, trunk mode and native VLAN."
            Look = "Check Administrative Mode, Operational Mode and Access Mode VLAN."
            Problems = "Access VLAN mismatch, dynamic mode, incorrect trunk parameters."
        }

        "show mac address-table" = @{
            Purpose = "Displays MAC addresses learned by the switch."
            Use = "Use to verify whether the switch is learning the endpoint MAC on the expected interface and VLAN."
            Look = "Correct MAC address, VLAN and physical interface."
            Problems = "MAC learned on wrong port, no MAC learned, unexpected VLAN."
        }

        "show ip route" = @{
            Purpose = "Displays the IPv4 routing table."
            Use = "Use whenever Layer 3 reachability fails beyond the local subnet."
            Look = "Verify destination prefix, next hop, exit interface and route source."
            Problems = "Missing route, wrong next hop, unexpected default route, route preference issue."
        }

        "show ip ospf neighbor" = @{
            Purpose = "Displays OSPF neighbor adjacency."
            Use = "Use when OSPF routes are missing or adjacency is suspected."
            Look = "Expected neighbors should normally reach FULL state."
            Problems = "INIT, EXSTART, EXCHANGE, missing neighbor, area mismatch, authentication issue."
        }

        "show ip ospf database" = @{
            Purpose = "Displays the OSPF link-state database."
            Use = "Use for deeper OSPF troubleshooting after adjacency validation."
            Look = "Expected LSAs, router IDs and network information."
            Problems = "Missing LSAs, stale topology information, area inconsistencies."
        }

        "show ip eigrp neighbors" = @{
            Purpose = "Displays EIGRP neighbor relationships."
            Use = "Use when EIGRP routes are missing."
            Look = "Expected neighbor addresses and interfaces."
            Problems = "Missing neighbor, AS mismatch, passive interface, authentication issue."
        }

        "show bgp ipv4 unicast summary" = @{
            Purpose = "Summarizes BGP neighbor sessions and learned prefixes."
            Use = "Use as the first BGP health check."
            Look = "Neighbor state should normally show a prefix count instead of Idle or Active."
            Problems = "Idle, Active, AS mismatch, reachability issue, TCP/179 blocked."
        }

        "show access-lists" = @{
            Purpose = "Displays ACL rules and match counters."
            Use = "Use when traffic appears to be selectively blocked."
            Look = "Permit/deny order and increasing hit counters."
            Problems = "Implicit deny, incorrect wildcard mask, ACL applied in wrong direction."
        }

        "show ip nat translations" = @{
            Purpose = "Displays active NAT translation entries."
            Use = "Use when inside clients cannot reach outside networks through NAT."
            Look = "Inside local and inside global mappings."
            Problems = "No translations, unexpected addresses, stale translations."
        }

        "show spanning-tree" = @{
            Purpose = "Displays STP topology and port roles."
            Use = "Use for Layer 2 loops, blocked paths and switching redundancy issues."
            Look = "Root bridge, root port, designated ports and forwarding/blocking state."
            Problems = "Unexpected root bridge, blocked uplink, topology instability."
        }

        "show etherchannel summary" = @{
            Purpose = "Displays EtherChannel groups and member-port state."
            Use = "Use when bundled links do not operate as expected."
            Look = "Port-channel status and member flags."
            Problems = "Suspended ports, protocol mismatch, inconsistent interface settings."
        }

        "show ipv6 interface brief" = @{
            Purpose = "Quick summary of IPv6-enabled interfaces."
            Use = "Use as an initial IPv6 connectivity check."
            Look = "Expected IPv6 addresses and interface status."
            Problems = "Missing IPv6 address, interface down, wrong prefix."
        }

        "show logging" = @{
            Purpose = "Displays Cisco IOS log messages."
            Use = "Use to correlate interface, routing, security and system events with an incident timeline."
            Look = "Link changes, routing neighbor transitions, ACL/security messages and errors."
            Problems = "Interface flapping, neighbor resets, authentication failures, hardware warnings."
        }

        "show running-config" = @{
            Purpose = "Displays the active device configuration."
            Use = "Use after operational show commands indicate a configuration issue."
            Look = "Relevant interface, routing, VLAN, ACL, NAT and service configuration."
            Problems = "Configuration drift, missing command, wrong IP/VLAN/ACL/routing statement."
        }
    }

    # ========================================================
    # GET ALL COMMANDS
    # ========================================================

    function Get-AllNetOpsCommands {

        $all = @()

        foreach ($categoryName in $CommandDB.Keys) {

            foreach ($cmd in $CommandDB[$categoryName]) {

                if ($all -notcontains $cmd) {
                    $all += $cmd
                }
            }
        }

        return $all | Sort-Object
    }

    # ========================================================
    # REFRESH LIST
    # ========================================================

    function Refresh-CommandList {

        $lstCommands.Items.Clear()
        $txtDescription.Clear()

        $category = $cmbCategory.SelectedItem

        if ($null -eq $category) {
            return
        }

        if ($category.ToString() -eq "All Commands") {

            $commands = @(Get-AllNetOpsCommands)

        }
        else {

            $commands = @($CommandDB[$category.ToString()])
        }

        $search = $txtSearch.Text.Trim()

        if (-not [string]::IsNullOrWhiteSpace($search)) {

            $commands = @(
                $commands |
                Where-Object {
                    $WorkerPath = Join-Path $PSScriptRoot "Network-Engine-Worker.ps1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# PATHS
# ============================================================

$Desktop  = [Environment]::GetFolderPath("Desktop")
$Engine = Join-Path $PSScriptRoot "AI-Offline.ps1"

$IncidentManager = Join-Path $PSScriptRoot "Incident-Manager.ps1"

if (Test-Path $IncidentManager) {
    . $IncidentManager
}
$Reports  = Join-Path $Desktop "Network-Troubleshooter-Reports"
$History  = Join-Path $Reports "Incident-History.csv"
$Workflow = Join-Path $Desktop "Network-Troubleshooter-v4.2.ps1"

# ============================================================
# COLORS
# ============================================================

$BG      = [System.Drawing.Color]::FromArgb(15,23,42)
$SideBG  = [System.Drawing.Color]::FromArgb(17,28,46)
$CardBG  = [System.Drawing.Color]::FromArgb(30,41,59)
$PanelBG = [System.Drawing.Color]::FromArgb(21,32,51)

$Text    = [System.Drawing.Color]::FromArgb(226,232,240)
$Muted   = [System.Drawing.Color]::FromArgb(148,163,184)

$Cyan    = [System.Drawing.Color]::FromArgb(34,211,238)
$Green   = [System.Drawing.Color]::FromArgb(34,197,94)
$Yellow  = [System.Drawing.Color]::FromArgb(250,204,21)
$Red     = [System.Drawing.Color]::FromArgb(239,68,68)

# ============================================================
# DATA / ENGINE
# ============================================================

function Get-HistoryData {

    # NETOPS v5.8 - Always resolve history from Project 09\data
    $projectRoot = Split-Path $PSScriptRoot
    $historyFile = Join-Path $projectRoot "data\Incident-History.csv"

    if (-not (Test-Path $historyFile)) {
        return @()
    }

    try {
        $rows = @(Import-Csv $historyFile)
        return $rows
    }
    catch {
        return @()
    }
}
function Invoke-TroubleshooterEngine {
    param(
        [string]$Prompt = "",
        [string[]]$Files = @(),

        [ValidateSet("Fast","Hybrid")]
        [string]$Mode = "Fast"
    )

    if (-not (Test-Path $Engine)) {
        return "ERROR: AI-Offline.ps1 nuk u gjet.`r`n$Engine"
    }

    $tempPromptFile = $null

    try {

        $allFiles = @()

        foreach ($file in $Files) {
            if (
                -not [string]::IsNullOrWhiteSpace($file) -and
                (Test-Path $file)
            ) {
                $allFiles += $file
            }
        }

        # GUI incident description behet temporary evidence file.
        # Kjo metode u testua direkt dhe funksionon me v3.9.
        if (-not [string]::IsNullOrWhiteSpace($Prompt)) {

            $tempPromptFile = Join-Path `
                $env:TEMP `
                ("NetTroubleshooter-" + [guid]::NewGuid().ToString() + ".txt")

            Set-Content `
                -Path $tempPromptFile `
                -Value $Prompt `
                -Encoding ASCII

            $allFiles += $tempPromptFile
        }

        if ($allFiles.Count -eq 0) {
            return "Vendos incident description ose evidence file."
        }

        $output = (
            & $Engine `
                -Engine $Mode `
                -FilePath $allFiles `
                *>&1 |
            Out-String
        )

        return $output
    }
    catch {

        return @"
ENGINE ERROR

$($_.Exception.Message)
"@
    }
    finally {

        if (
            $tempPromptFile -and
            (Test-Path $tempPromptFile)
        ) {
            Remove-Item `
                -Path $tempPromptFile `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}
# ============================================================
# STYLE HELPERS
# ============================================================

function Style-NavButton {
    param([System.Windows.Forms.Button]$Button)

    $Button.Dock = "Fill"
    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $CardBG
    $Button.ForeColor = $Text
    $Button.TextAlign = "MiddleLeft"
    $Button.Padding = New-Object System.Windows.Forms.Padding(18,0,0,0)
    $Button.Margin = New-Object System.Windows.Forms.Padding(12,5,12,5)
    $Button.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
}

function Style-ActionButton {
    param([System.Windows.Forms.Button]$Button)

    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $CardBG
    $Button.ForeColor = $Text
    $Button.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
}

function Style-Grid {
    param([System.Windows.Forms.DataGridView]$Grid)

    $Grid.BackgroundColor = $CardBG
    $Grid.BorderStyle = "None"
    $Grid.ReadOnly = $true
    $Grid.AllowUserToAddRows = $false
    $Grid.AllowUserToDeleteRows = $false
    $Grid.RowHeadersVisible = $false
    $Grid.AutoSizeColumnsMode = "Fill"
    $Grid.SelectionMode = "FullRowSelect"
    $Grid.MultiSelect = $false

    $Grid.ColumnHeadersDefaultCellStyle.BackColor = $PanelBG
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $Grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = $PanelBG

    $Grid.DefaultCellStyle.BackColor = $CardBG
    $Grid.DefaultCellStyle.ForeColor = $Text
    $Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(51,65,85)

    $Grid.EnableHeadersVisualStyles = $false
}

function New-StatCard {
    param(
        [string]$Title,
        [System.Drawing.Color]$ValueColor
    )

    $outer = New-Object System.Windows.Forms.Panel
    $outer.Dock = "Fill"
    $outer.Margin = New-Object System.Windows.Forms.Padding(8)
    $outer.BackColor = $CardBG

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = "Fill"
    $layout.RowCount = 2
    $layout.ColumnCount = 1
    $layout.BackColor = $CardBG

    $layout.RowStyles.Add(
        (New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Percent,
            40
        ))
    )

    $layout.RowStyles.Add(
        (New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Percent,
            60
        ))
    )

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Dock = "Fill"
    $titleLabel.TextAlign = "MiddleLeft"
    $titleLabel.Padding = New-Object System.Windows.Forms.Padding(16,4,0,0)
    $titleLabel.ForeColor = $Muted
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI",9)

    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Text = "0"
    $valueLabel.Dock = "Fill"
    $valueLabel.TextAlign = "MiddleLeft"
    $valueLabel.Padding = New-Object System.Windows.Forms.Padding(16,0,0,6)
    $valueLabel.ForeColor = $ValueColor
    $valueLabel.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        24,
        [System.Drawing.FontStyle]::Bold
    )

    $layout.Controls.Add($titleLabel,0,0)
    $layout.Controls.Add($valueLabel,0,1)

    $outer.Controls.Add($layout)

    return [PSCustomObject]@{
        Panel = $outer
        Value = $valueLabel
    }
}

# ============================================================
# MAIN FORM
# ============================================================

# ============================================================
# NETOPS_CORE_TOOLS_V1
# ============================================================

function Show-NetOpsPingTool {

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Ping Tool"
    $toolForm.Size = New-Object System.Drawing.Size(620,500)
    $toolForm.StartPosition = "CenterScreen"

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "Target IP / Hostname:"
    $lblTarget.Location = New-Object System.Drawing.Point(20,20)
    $lblTarget.Size = New-Object System.Drawing.Size(180,25)
    $toolForm.Controls.Add($lblTarget)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(20,50)
    $txtTarget.Size = New-Object System.Drawing.Size(400,30)
    $toolForm.Controls.Add($txtTarget)

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Ping"
    $btnRun.Location = New-Object System.Drawing.Point(440,48)
    $btnRun.Size = New-Object System.Drawing.Size(130,32)
    $toolForm.Controls.Add($btnRun)

    $txtOutput = New-Object System.Windows.Forms.RichTextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20,100)
    $txtOutput.Size = New-Object System.Drawing.Size(550,320)
    $txtOutput.ReadOnly = $true
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas",10)
    $toolForm.Controls.Add($txtOutput)

    $btnRun.Add_Click({

        $target = $txtTarget.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Enter an IP address or hostname.",
                "NETOPS Ping"
            )
            return
        }

        $txtOutput.Clear()
        $txtOutput.AppendText("Pinging $target ...`r`n`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $result = ping.exe $target -n 4 2>&1 | Out-String
            $txtOutput.AppendText($result)
        }
        catch {
            $txtOutput.AppendText($_.Exception.Message)
        }
    })

# ============================================================
# NETOPS CORE TOOLS TOOLBAR
# ============================================================

$grpQuickTools = New-Object System.Windows.Forms.GroupBox
$grpQuickTools.Text = "Quick Network Tools"
$grpQuickTools.Location = New-Object System.Drawing.Point(20,10)
$grpQuickTools.Size = New-Object System.Drawing.Size(700,70)

$btnNetPing = New-Object System.Windows.Forms.Button
$btnNetPing.Text = "PING"
$btnNetPing.Location = New-Object System.Drawing.Point(15,25)
$btnNetPing.Size = New-Object System.Drawing.Size(120,30)
$btnNetPing.Add_Click({
    Show-NetOpsPingTool
})
$grpQuickTools.Controls.Add($btnNetPing)

$btnNetTrace = New-Object System.Windows.Forms.Button
$btnNetTrace.Text = "TRACEROUTE"
$btnNetTrace.Location = New-Object System.Drawing.Point(145,25)
$btnNetTrace.Size = New-Object System.Drawing.Size(130,30)
$btnNetTrace.Add_Click({
    Show-NetOpsTracerouteTool
})
$grpQuickTools.Controls.Add($btnNetTrace)

$btnShowCommands = New-Object System.Windows.Forms.Button
$btnShowCommands.Text = "SHOW COMMANDS"
$btnShowCommands.Location = New-Object System.Drawing.Point(285,25)
$btnShowCommands.Size = New-Object System.Drawing.Size(160,30)
$btnShowCommands.Add_Click({
    Show-NetOpsCommandsTool
})
$grpQuickTools.Controls.Add($btnShowCommands)

$btnInventory = New-Object System.Windows.Forms.Button
$btnInventory.Text = "DEVICE INVENTORY"
$btnInventory.Location = New-Object System.Drawing.Point(455,25)
$btnInventory.Size = New-Object System.Drawing.Size(170,30)
$btnInventory.Add_Click({
    Open-NetOpsDeviceInventorySafe
})
$grpQuickTools.Controls.Add($btnInventory)

$form.Controls.Add($grpQuickTools)


    [void]$toolForm.ShowDialog()
}


function Show-NetOpsTracerouteTool {

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Traceroute Tool"
    $toolForm.Size = New-Object System.Drawing.Size(650,520)
    $toolForm.StartPosition = "CenterScreen"

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "Target IP / Hostname:"
    $lblTarget.Location = New-Object System.Drawing.Point(20,20)
    $lblTarget.Size = New-Object System.Drawing.Size(180,25)
    $toolForm.Controls.Add($lblTarget)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(20,50)
    $txtTarget.Size = New-Object System.Drawing.Size(420,30)
    $toolForm.Controls.Add($txtTarget)

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Traceroute"
    $btnRun.Location = New-Object System.Drawing.Point(455,48)
    $btnRun.Size = New-Object System.Drawing.Size(145,32)
    $toolForm.Controls.Add($btnRun)

    $txtOutput = New-Object System.Windows.Forms.RichTextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20,100)
    $txtOutput.Size = New-Object System.Drawing.Size(580,330)
    $txtOutput.ReadOnly = $true
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas",10)
    $toolForm.Controls.Add($txtOutput)

    $btnRun.Add_Click({

        $target = $txtTarget.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Enter an IP address or hostname.",
                "NETOPS Traceroute"
            )
            return
        }

        $txtOutput.Clear()
        $txtOutput.AppendText("Tracing route to $target ...`r`n`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $result = tracert.exe $target 2>&1 | Out-String
            $txtOutput.AppendText($result)
        }
        catch {
            $txtOutput.AppendText($_.Exception.Message)
        }
    })

    [void]$toolForm.ShowDialog()
}


function Show-NetOpsCommandsTool {

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Cisco Show Commands"
    $toolForm.Size = New-Object System.Drawing.Size(760,600)
    $toolForm.StartPosition = "CenterScreen"

    $lblCategory = New-Object System.Windows.Forms.Label
    $lblCategory.Text = "Category:"
    $lblCategory.Location = New-Object System.Drawing.Point(20,20)
    $lblCategory.Size = New-Object System.Drawing.Size(100,25)
    $toolForm.Controls.Add($lblCategory)

    $cmbCategory = New-Object System.Windows.Forms.ComboBox
    $cmbCategory.Location = New-Object System.Drawing.Point(120,18)
    $cmbCategory.Size = New-Object System.Drawing.Size(250,30)
    $cmbCategory.DropDownStyle = "DropDownList"

    [void]$cmbCategory.Items.AddRange(@(
        "Interface & IP",
        "Switching & VLAN",
        "Routing",
        "OSPF",
        "EIGRP",
        "BGP",
        "ACL & NAT",
        "STP & EtherChannel",
        "Troubleshooting"
    ))

    $toolForm.Controls.Add($cmbCategory)

    $lstCommands = New-Object System.Windows.Forms.ListBox
    $lstCommands.Location = New-Object System.Drawing.Point(20,70)
    $lstCommands.Size = New-Object System.Drawing.Size(320,430)
    $toolForm.Controls.Add($lstCommands)

    $txtDescription = New-Object System.Windows.Forms.RichTextBox
    $txtDescription.Location = New-Object System.Drawing.Point(360,70)
    $txtDescription.Size = New-Object System.Drawing.Size(350,430)
    $txtDescription.ReadOnly = $true
    $txtDescription.Font = New-Object System.Drawing.Font("Consolas",10)
    $toolForm.Controls.Add($txtDescription)

    $CommandDB = @{

        "Interface & IP" = @(
            "show ip interface brief",
            "show interfaces",
            "show interfaces description",
            "show arp",
            "show ip protocols"
        )

        "Switching & VLAN" = @(
            "show vlan brief",
            "show interfaces trunk",
            "show interfaces switchport",
            "show mac address-table",
            "show spanning-tree"
        )

        "Routing" = @(
            "show ip route",
            "show ip route connected",
            "show ip route static",
            "show ip route ospf",
            "show ip route eigrp"
        )

        "OSPF" = @(
            "show ip ospf neighbor",
            "show ip ospf interface brief",
            "show ip ospf database",
            "show ip protocols",
            "show ip route ospf"
        )

        "EIGRP" = @(
            "show ip eigrp neighbors",
            "show ip eigrp topology",
            "show ip protocols",
            "show ip route eigrp"
        )

        "BGP" = @(
            "show bgp ipv4 unicast summary",
            "show ip bgp",
            "show bgp neighbors",
            "show ip route bgp"
        )

        "ACL & NAT" = @(
            "show access-lists",
            "show ip access-lists",
            "show ip nat translations",
            "show ip nat statistics",
            "show running-config | section access-list"
        )

        "STP & EtherChannel" = @(
            "show spanning-tree",
            "show spanning-tree vlan 10",
            "show etherchannel summary",
            "show interfaces port-channel"
        )

        "Troubleshooting" = @(
            "show running-config",
            "show startup-config",
            "show logging",
            "show cdp neighbors detail",
            "show lldp neighbors detail",
            "show processes cpu",
            "show memory"
        )
    }

    $CommandHelp = @{

        "show ip interface brief" =
            "Quick overview of interface IP addresses and line/protocol status."

        "show vlan brief" =
            "Displays configured VLANs and access-port membership."

        "show interfaces trunk" =
            "Displays trunk ports, native VLAN and allowed/forwarding VLANs."

        "show interfaces switchport" =
            "Displays Layer 2 switchport mode, access VLAN and trunk parameters."

        "show mac address-table" =
            "Displays learned MAC addresses and their associated interfaces."

        "show ip route" =
            "Displays the IPv4 routing table and route sources."

        "show ip ospf neighbor" =
            "Displays OSPF neighbor adjacency state."

        "show ip ospf database" =
            "Displays the OSPF link-state database."

        "show ip eigrp neighbors" =
            "Displays active EIGRP neighbors."

        "show bgp ipv4 unicast summary" =
            "Displays BGP neighbor state and prefix counters."

        "show access-lists" =
            "Displays ACL entries and packet-match counters."

        "show ip nat translations" =
            "Displays active NAT translations."

        "show spanning-tree" =
            "Displays STP root, port roles and forwarding states."

        "show etherchannel summary" =
            "Displays EtherChannel groups and member-port states."

        "show logging" =
            "Displays device log messages useful for incident correlation."

        "show running-config" =
            "Displays the currently active configuration."
    }

    $cmbCategory.Add_SelectedIndexChanged({

        $lstCommands.Items.Clear()
        $txtDescription.Clear()

        $category = $cmbCategory.SelectedItem.ToString()

        foreach ($cmd in $CommandDB[$category]) {
            [void]$lstCommands.Items.Add($cmd)
        }
    })

    $lstCommands.Add_SelectedIndexChanged({

        if ($null -eq $lstCommands.SelectedItem) {
            return
        }

        $cmd = $lstCommands.SelectedItem.ToString()

        $desc = $CommandHelp[$cmd]

        if ([string]::IsNullOrWhiteSpace($desc)) {
            $desc = "Cisco IOS diagnostic command."
        }

        $txtDescription.Text = @"
COMMAND
============================================================
$cmd

PURPOSE
============================================================
$desc

USAGE
============================================================
Use this command during evidence collection before making
configuration changes.

NETOPS TIP
============================================================
Copy the command output into an evidence TXT file and analyze
it with FAST or HYBRID AI.
"@
    })

    $cmbCategory.SelectedIndex = 0

    [void]$toolForm.ShowDialog()
}


# ============================================================
# NETOPS_DEVICE_INVENTORY_PRO_SAFE_V3
# ============================================================

function Show-NetOpsDeviceInventory {

    $inventoryDir  = Join-Path $env:USERPROFILE "Documents\NETOPS"
    $inventoryFile = Join-Path $inventoryDir "devices.csv"

    if (-not (Test-Path $inventoryDir)) {
        New-Item -Path $inventoryDir -ItemType Directory -Force | Out-Null
    }

    # ========================================================
    # CREATE INITIAL FILE IF REQUIRED
    # ========================================================

    if (-not (Test-Path $inventoryFile)) {

        $initialDevices = @()

        $initialDevices += [PSCustomObject]@{
            DeviceName   = "R-HQ-01"
            Type         = "Router"
            Vendor       = "Cisco"
            Model        = "2911"
            ManagementIP = "192.168.1.1"
            Site         = "HQ"
            Status       = "Unknown"
        }

        $initialDevices += [PSCustomObject]@{
            DeviceName   = "SW-CORE-01"
            Type         = "Switch"
            Vendor       = "Cisco"
            Model        = "3560"
            ManagementIP = "192.168.1.2"
            Site         = "HQ"
            Status       = "Unknown"
        }

        $initialDevices += [PSCustomObject]@{
            DeviceName   = "SW-ACCESS-01"
            Type         = "Switch"
            Vendor       = "Cisco"
            Model        = "2960"
            ManagementIP = "192.168.1.10"
            Site         = "HQ"
            Status       = "Unknown"
        }

        $initialDevices += [PSCustomObject]@{
            DeviceName   = "R-BRANCH-01"
            Type         = "Router"
            Vendor       = "Cisco"
            Model        = "2911"
            ManagementIP = "192.168.30.1"
            Site         = "Branch"
            Status       = "Unknown"
        }

        $initialDevices |
            Export-Csv `
                -Path $inventoryFile `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ========================================================
    # THEME
    # ========================================================

    $Bg       = [System.Drawing.Color]::FromArgb(14,25,42)
    $PanelBg  = [System.Drawing.Color]::FromArgb(28,43,64)
    $PanelBg2 = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text     = [System.Drawing.Color]::White
    $Muted    = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent   = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green    = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red      = [System.Drawing.Color]::FromArgb(255,85,85)

    # ========================================================
    # FORM
    # ========================================================

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Device Inventory PRO"
    $toolForm.Size = New-Object System.Drawing.Size(1180,700)
    $toolForm.StartPosition = "CenterScreen"
    $toolForm.BackColor = $Bg
    $toolForm.ForeColor = $Text

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "DEVICE INVENTORY"
    $lblTitle.Location = New-Object System.Drawing.Point(25,20)
    $lblTitle.Size = New-Object System.Drawing.Size(500,35)
    $lblTitle.ForeColor = $Accent
    $lblTitle.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )
    $toolForm.Controls.Add($lblTitle)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = "Network devices, management IPs and reachability status"
    $lblSubtitle.Location = New-Object System.Drawing.Point(27,58)
    $lblSubtitle.Size = New-Object System.Drawing.Size(700,25)
    $lblSubtitle.ForeColor = $Muted
    $toolForm.Controls.Add($lblSubtitle)

    # ========================================================
    # GRID
    # ========================================================

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(25,100)
    $grid.Size = New-Object System.Drawing.Size(1110,390)
    $grid.BackgroundColor = $PanelBg2
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.SelectionMode = "FullRowSelect"
    $grid.MultiSelect = $false
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.RowHeadersVisible = $false

    $grid.ColumnHeadersDefaultCellStyle.BackColor = $PanelBg
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $grid.EnableHeadersVisualStyles = $false

    $grid.DefaultCellStyle.BackColor = $PanelBg2
    $grid.DefaultCellStyle.ForeColor = $Text
    $grid.DefaultCellStyle.SelectionBackColor = $PanelBg
    $grid.DefaultCellStyle.SelectionForeColor = $Accent

    $toolForm.Controls.Add($grid)

    # ========================================================
    # BUTTON FACTORY
    # ========================================================

    function New-InventoryButton {

        param(
            [string]$Caption,
            [int]$X,
            [int]$Width
        )

        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Caption
        $button.Location = New-Object System.Drawing.Point($X,515)
        $button.Size = New-Object System.Drawing.Size($Width,38)
        $button.FlatStyle = "Flat"
        $button.BackColor = $PanelBg
        $button.ForeColor = $Text
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand

        return $button
    }

    $btnAdd = New-InventoryButton "ADD DEVICE" 25 140
    $toolForm.Controls.Add($btnAdd)

    $btnEdit = New-InventoryButton "EDIT DEVICE" 175 140
    $toolForm.Controls.Add($btnEdit)

    $btnDelete = New-InventoryButton "DELETE DEVICE" 325 145
    $toolForm.Controls.Add($btnDelete)

    $btnPing = New-InventoryButton "PING SELECTED" 480 160
    $toolForm.Controls.Add($btnPing)

    $btnCheckAll = New-InventoryButton "CHECK ALL STATUS" 650 175
    $toolForm.Controls.Add($btnCheckAll)

    $btnOpen = New-InventoryButton "OPEN CSV" 835 130
    $toolForm.Controls.Add($btnOpen)

    $btnRefresh = New-InventoryButton "REFRESH" 975 160
    $toolForm.Controls.Add($btnRefresh)

    # ========================================================
    # STATUS
    # ========================================================

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(25,575)
    $lblStatus.Size = New-Object System.Drawing.Size(1050,25)
    $lblStatus.ForeColor = $Muted
    $toolForm.Controls.Add($lblStatus)

    $lblSummary = New-Object System.Windows.Forms.Label
    $lblSummary.Location = New-Object System.Drawing.Point(25,610)
    $lblSummary.Size = New-Object System.Drawing.Size(1050,30)
    $lblSummary.ForeColor = $Accent
    $toolForm.Controls.Add($lblSummary)

    # ========================================================
    # DATA
    # ========================================================

    function Get-InventoryData {

        $rows = @(
            Import-Csv `
                -Path $inventoryFile `
                -ErrorAction SilentlyContinue
        )

        $result = @()

        foreach ($row in $rows) {

            $managementIP = ""

            if ($null -ne $row.PSObject.Properties["ManagementIP"]) {
                $managementIP = [string]$row.ManagementIP
            }
            elseif ($null -ne $row.PSObject.Properties["IP"]) {
                $managementIP = [string]$row.IP
            }

            $vendor = "Cisco"

            if ($null -ne $row.PSObject.Properties["Vendor"]) {

                if (-not [string]::IsNullOrWhiteSpace([string]$row.Vendor)) {
                    $vendor = [string]$row.Vendor
                }
            }

            $model = ""

            if ($null -ne $row.PSObject.Properties["Model"]) {
                $model = [string]$row.Model
            }

            $status = "Unknown"

            if ($null -ne $row.PSObject.Properties["Status"]) {

                if (-not [string]::IsNullOrWhiteSpace([string]$row.Status)) {
                    $status = [string]$row.Status
                }
            }

            $result += [PSCustomObject]@{
                DeviceName   = [string]$row.DeviceName
                Type         = [string]$row.Type
                Vendor       = $vendor
                Model        = $model
                ManagementIP = $managementIP
                Site         = [string]$row.Site
                Status       = $status
            }
        }

        return @($result)
    }


    function Save-InventoryData {

        param(
            [array]$Devices
        )

        $Devices |
            Select-Object `
                DeviceName,
                Type,
                Vendor,
                Model,
                ManagementIP,
                Site,
                Status |
            Export-Csv `
                -Path $inventoryFile `
                -NoTypeInformation `
                -Encoding UTF8
    }


    function Refresh-InventoryGrid {

        $devices = @(Get-InventoryData)

        $grid.DataSource = $null
        $grid.DataSource = $devices

        $onlineCount = @(
            $devices |
            Where-Object {
                $_.Status -eq "Online"
            }
        ).Count

        $offlineCount = @(
            $devices |
            Where-Object {
                $_.Status -eq "Offline"
            }
        ).Count

        $unknownCount = @(
            $devices |
            Where-Object {
                $_.Status -eq "Unknown"
            }
        ).Count

        $lblSummary.Text =
            "Devices: $($devices.Count)   |   Online: $onlineCount   |   Offline: $offlineCount   |   Unknown: $unknownCount"

        $lblStatus.ForeColor = $Muted
        $lblStatus.Text = "Inventory: $inventoryFile"
    }

    # ========================================================
    # DEVICE EDITOR
    # ========================================================

    function Open-DeviceEditor {

        param(
            $Device
        )

        $editMode = ($null -ne $Device)

        $editor = New-Object System.Windows.Forms.Form
        $editor.Size = New-Object System.Drawing.Size(520,525)
        $editor.StartPosition = "CenterParent"
        $editor.BackColor = $Bg
        $editor.ForeColor = $Text
        $editor.FormBorderStyle = "FixedDialog"
        $editor.MaximizeBox = $false

        if ($editMode) {
            $editor.Text = "NETOPS - Edit Device"
        }
        else {
            $editor.Text = "NETOPS - Add Device"
        }

        $fieldLabels = @(
            "Device Name",
            "Device Type",
            "Vendor",
            "Model",
            "Management IP",
            "Site / Location"
        )

        $currentY = 35

        foreach ($caption in $fieldLabels) {

            $label = New-Object System.Windows.Forms.Label
            $label.Text = $caption
            $label.Location = New-Object System.Drawing.Point(30,$currentY)
            $label.Size = New-Object System.Drawing.Size(160,25)
            $label.ForeColor = $Muted
            $editor.Controls.Add($label)

            $currentY += 60
        }

        $txtName = New-Object System.Windows.Forms.TextBox
        $txtName.Location = New-Object System.Drawing.Point(200,32)
        $txtName.Size = New-Object System.Drawing.Size(270,28)
        $editor.Controls.Add($txtName)

        $cmbType = New-Object System.Windows.Forms.ComboBox
        $cmbType.Location = New-Object System.Drawing.Point(200,92)
        $cmbType.Size = New-Object System.Drawing.Size(270,28)
        $cmbType.DropDownStyle = "DropDownList"
        [void]$cmbType.Items.AddRange(@(
            "Router",
            "Switch",
            "Firewall",
            "Wireless",
            "Server",
            "Other"
        ))
        $editor.Controls.Add($cmbType)

        $cmbVendor = New-Object System.Windows.Forms.ComboBox
        $cmbVendor.Location = New-Object System.Drawing.Point(200,152)
        $cmbVendor.Size = New-Object System.Drawing.Size(270,28)
        [void]$cmbVendor.Items.AddRange(@(
            "Cisco",
            "Fortinet",
            "Palo Alto",
            "Juniper",
            "Aruba",
            "MikroTik",
            "Other"
        ))
        $editor.Controls.Add($cmbVendor)

        $txtModel = New-Object System.Windows.Forms.TextBox
        $txtModel.Location = New-Object System.Drawing.Point(200,212)
        $txtModel.Size = New-Object System.Drawing.Size(270,28)
        $editor.Controls.Add($txtModel)

        $txtIP = New-Object System.Windows.Forms.TextBox
        $txtIP.Location = New-Object System.Drawing.Point(200,272)
        $txtIP.Size = New-Object System.Drawing.Size(270,28)
        $editor.Controls.Add($txtIP)

        $txtSite = New-Object System.Windows.Forms.TextBox
        $txtSite.Location = New-Object System.Drawing.Point(200,332)
        $txtSite.Size = New-Object System.Drawing.Size(270,28)
        $editor.Controls.Add($txtSite)

        if ($editMode) {

            $txtName.Text = $Device.DeviceName
            $cmbType.Text = $Device.Type
            $cmbVendor.Text = $Device.Vendor
            $txtModel.Text = $Device.Model
            $txtIP.Text = $Device.ManagementIP
            $txtSite.Text = $Device.Site

        }
        else {

            $cmbType.SelectedIndex = 0
            $cmbVendor.Text = "Cisco"
        }

        $btnSave = New-Object System.Windows.Forms.Button
        $btnSave.Text = "SAVE DEVICE"
        $btnSave.Location = New-Object System.Drawing.Point(200,402)
        $btnSave.Size = New-Object System.Drawing.Size(160,40)
        $btnSave.FlatStyle = "Flat"
        $btnSave.BackColor = $PanelBg
        $btnSave.ForeColor = $Text
        $editor.Controls.Add($btnSave)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "CANCEL"
        $btnCancel.Location = New-Object System.Drawing.Point(370,402)
        $btnCancel.Size = New-Object System.Drawing.Size(100,40)
        $btnCancel.FlatStyle = "Flat"
        $btnCancel.BackColor = $PanelBg
        $btnCancel.ForeColor = $Text
        $editor.Controls.Add($btnCancel)

        $btnCancel.Add_Click({

            $editor.DialogResult =
                [System.Windows.Forms.DialogResult]::Cancel

            $editor.Close()
        })

        $btnSave.Add_Click({

            $deviceName = $txtName.Text.Trim()
            $deviceIP   = $txtIP.Text.Trim()

            if ([string]::IsNullOrWhiteSpace($deviceName)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Device Name is required.",
                    "NETOPS Device Inventory"
                )

                return
            }

            if ([string]::IsNullOrWhiteSpace($deviceIP)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Management IP is required.",
                    "NETOPS Device Inventory"
                )

                return
            }

            $deviceStatus = "Unknown"

            if ($editMode) {
                $deviceStatus = $Device.Status
            }

            $resultDevice = [PSCustomObject]@{
                DeviceName   = $deviceName
                Type         = $cmbType.Text
                Vendor       = $cmbVendor.Text.Trim()
                Model        = $txtModel.Text.Trim()
                ManagementIP = $deviceIP
                Site         = $txtSite.Text.Trim()
                Status       = $deviceStatus
            }

            $editor.Tag = $resultDevice

            $editor.DialogResult =
                [System.Windows.Forms.DialogResult]::OK

            $editor.Close()
        })

        $dialogResult = $editor.ShowDialog($toolForm)

        if (
            $dialogResult -eq
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return $editor.Tag
        }

        return $null
    }

    # ========================================================
    # ADD
    # ========================================================

    $btnAdd.Add_Click({

        $newDevice = Open-DeviceEditor -Device $null

        if ($null -eq $newDevice) {
            return
        }

        $devices = @(Get-InventoryData)

        $exists = $false

        foreach ($existing in $devices) {

            if (
                $existing.DeviceName -eq $newDevice.DeviceName -or
                $existing.ManagementIP -eq $newDevice.ManagementIP
            ) {
                $exists = $true
                break
            }
        }

        if ($exists) {

            [System.Windows.Forms.MessageBox]::Show(
                "Device Name or Management IP already exists.",
                "NETOPS Device Inventory"
            )

            return
        }

        $devices += $newDevice

        Save-InventoryData -Devices $devices
        Refresh-InventoryGrid

        $lblStatus.ForeColor = $Green
        $lblStatus.Text = "Device added: $($newDevice.DeviceName)"
    })

    # ========================================================
    # EDIT
    # ========================================================

    $btnEdit.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a device first.",
                "NETOPS Device Inventory"
            )

            return
        }

        $selectedName = [string](
            $grid.SelectedRows[0].Cells["DeviceName"].Value
        )

        $devices = @(Get-InventoryData)
        $selectedDevice = $null

        foreach ($device in $devices) {

            if ($device.DeviceName -eq $selectedName) {
                $selectedDevice = $device
                break
            }
        }

        if ($null -eq $selectedDevice) {
            return
        }

        $updatedDevice = Open-DeviceEditor -Device $selectedDevice

        if ($null -eq $updatedDevice) {
            return
        }

        $result = @()

        foreach ($device in $devices) {

            if ($device.DeviceName -eq $selectedName) {
                $result += $updatedDevice
            }
            else {
                $result += $device
            }
        }

        Save-InventoryData -Devices $result
        Refresh-InventoryGrid

        $lblStatus.ForeColor = $Green
        $lblStatus.Text = "Device updated: $($updatedDevice.DeviceName)"
    })

    # ========================================================
    # DELETE
    # ========================================================

    $btnDelete.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a device first.",
                "NETOPS Device Inventory"
            )

            return
        }

        $selectedName = [string](
            $grid.SelectedRows[0].Cells["DeviceName"].Value
        )

        $confirmation = [System.Windows.Forms.MessageBox]::Show(
            "Delete device '$selectedName'?",
            "NETOPS Device Inventory",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if (
            $confirmation -ne
            [System.Windows.Forms.DialogResult]::Yes
        ) {
            return
        }

        $devices = @(Get-InventoryData)
        $result = @()

        foreach ($device in $devices) {

            if ($device.DeviceName -ne $selectedName) {
                $result += $device
            }
        }

        Save-InventoryData -Devices $result
        Refresh-InventoryGrid

        $lblStatus.ForeColor = $Red
        $lblStatus.Text = "Device deleted: $selectedName"
    })

    # ========================================================
    # PING SELECTED
    # ========================================================

    $btnPing.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a device first.",
                "NETOPS Device Inventory"
            )

            return
        }

        $selectedName = [string](
            $grid.SelectedRows[0].Cells["DeviceName"].Value
        )

        $selectedIP = [string](
            $grid.SelectedRows[0].Cells["ManagementIP"].Value
        )

        $lblStatus.ForeColor = $Muted
        $lblStatus.Text = "Pinging $selectedName ($selectedIP)..."

        [System.Windows.Forms.Application]::DoEvents()

        $alive = Test-Connection `
            -ComputerName $selectedIP `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        $devices = @(Get-InventoryData)

        foreach ($device in $devices) {

            if ($device.DeviceName -eq $selectedName) {

                if ($alive) {
                    $device.Status = "Online"
                }
                else {
                    $device.Status = "Offline"
                }
            }
        }

        Save-InventoryData -Devices $devices
        Refresh-InventoryGrid

        if ($alive) {

            $lblStatus.ForeColor = $Green
            $lblStatus.Text = "$selectedName is ONLINE"

        }
        else {

            $lblStatus.ForeColor = $Red
            $lblStatus.Text = "$selectedName is OFFLINE"
        }
    })

    # ========================================================
    # CHECK ALL
    # ========================================================

    $btnCheckAll.Add_Click({

        $devices = @(Get-InventoryData)

        if ($devices.Count -eq 0) {
            return
        }

        $btnCheckAll.Enabled = $false

        try {

            $counter = 0

            foreach ($device in $devices) {

                $counter++

                $lblStatus.ForeColor = $Muted
                $lblStatus.Text =
                    "Checking $counter/$($devices.Count): $($device.DeviceName)"

                [System.Windows.Forms.Application]::DoEvents()

                $alive = Test-Connection `
                    -ComputerName $device.ManagementIP `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction SilentlyContinue

                if ($alive) {
                    $device.Status = "Online"
                }
                else {
                    $device.Status = "Offline"
                }
            }

            Save-InventoryData -Devices $devices
            Refresh-InventoryGrid

            $lblStatus.ForeColor = $Green
            $lblStatus.Text = "All device checks completed."

        }
        finally {

            $btnCheckAll.Enabled = $true
        }
    })

    # ========================================================
    # OTHER BUTTONS
    # ========================================================

    $btnOpen.Add_Click({
        Start-Process notepad.exe $inventoryFile
    })

    $btnRefresh.Add_Click({

        Refresh-InventoryGrid

        $lblStatus.ForeColor = $Muted
        $lblStatus.Text = "Inventory refreshed."
    })

    $grid.Add_CellDoubleClick({

        if ($_.RowIndex -ge 0) {
            $btnEdit.PerformClick()
        }
    })

    # ========================================================
    # START
    # ========================================================

    Refresh-InventoryGrid

    [void]$toolForm.ShowDialog()
}



# ============================================================
# NETOPS_DEVICE_INVENTORY_PRO_DIRECT_V1
# ============================================================

function Show-NetOpsDeviceInventoryPRO {

    $inventoryDir = Join-Path $env:USERPROFILE "Documents\NETOPS"
    $inventoryFile = Join-Path $inventoryDir "devices.csv"

    if (-not (Test-Path $inventoryDir)) {
        New-Item -Path $inventoryDir -ItemType Directory -Force | Out-Null
    }

    # --------------------------------------------------------
    # CREATE / MIGRATE INVENTORY
    # --------------------------------------------------------

    if (-not (Test-Path $inventoryFile)) {

        @(
            [PSCustomObject]@{
                DeviceName="R-HQ-01"
                Type="Router"
                Vendor="Cisco"
                Model="2911"
                ManagementIP="192.168.1.1"
                Site="HQ"
                Status="Unknown"
            }

            [PSCustomObject]@{
                DeviceName="SW-CORE-01"
                Type="Switch"
                Vendor="Cisco"
                Model="3560"
                ManagementIP="192.168.1.2"
                Site="HQ"
                Status="Unknown"
            }
        ) |
        Export-Csv $inventoryFile -NoTypeInformation -Encoding UTF8
    }

    # --------------------------------------------------------
    # THEME
    # --------------------------------------------------------

    $Bg      = [System.Drawing.Color]::FromArgb(14,25,42)
    $Panel   = [System.Drawing.Color]::FromArgb(28,43,64)
    $Panel2  = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text    = [System.Drawing.Color]::White
    $Muted   = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent  = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green   = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red     = [System.Drawing.Color]::FromArgb(255,85,85)

    # --------------------------------------------------------
    # FORM
    # --------------------------------------------------------

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "NETOPS - Device Inventory PRO"
    $f.Size = New-Object System.Drawing.Size(1180,700)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $Bg
    $f.ForeColor = $Text

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "DEVICE INVENTORY"
    $title.Location = New-Object System.Drawing.Point(25,20)
    $title.Size = New-Object System.Drawing.Size(500,35)
    $title.ForeColor = $Accent
    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI",17,[System.Drawing.FontStyle]::Bold
    )
    $f.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = "Network devices, management IPs and reachability"
    $sub.Location = New-Object System.Drawing.Point(27,58)
    $sub.Size = New-Object System.Drawing.Size(700,25)
    $sub.ForeColor = $Muted
    $f.Controls.Add($sub)

    # --------------------------------------------------------
    # GRID
    # --------------------------------------------------------

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(25,100)
    $grid.Size = New-Object System.Drawing.Size(1110,390)
    $grid.BackgroundColor = $Panel2
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.SelectionMode = "FullRowSelect"
    $grid.MultiSelect = $false
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.RowHeadersVisible = $false

    $grid.EnableHeadersVisualStyles = $false
    $grid.ColumnHeadersDefaultCellStyle.BackColor = $Panel
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $grid.DefaultCellStyle.BackColor = $Panel2
    $grid.DefaultCellStyle.ForeColor = $Text
    $grid.DefaultCellStyle.SelectionBackColor = $Panel
    $grid.DefaultCellStyle.SelectionForeColor = $Accent

    $f.Controls.Add($grid)

    # --------------------------------------------------------
    # BUTTON HELPER
    # --------------------------------------------------------

    function MakeButton {

        param(
            [string]$TextValue,
            [int]$X,
            [int]$Width
        )

        $b = New-Object System.Windows.Forms.Button
        $b.Text = $TextValue
        $b.Location = New-Object System.Drawing.Point($X,515)
        $b.Size = New-Object System.Drawing.Size($Width,38)
        $b.FlatStyle = "Flat"
        $b.BackColor = $Panel
        $b.ForeColor = $Text

        return $b
    }

    $btnAdd     = MakeButton "ADD DEVICE"       25 140
    $btnEdit    = MakeButton "EDIT DEVICE"     175 140
    $btnDelete  = MakeButton "DELETE DEVICE"   325 145
    $btnPing    = MakeButton "PING SELECTED"   480 160
    $btnAll     = MakeButton "CHECK ALL STATUS" 650 175
    $btnOpen    = MakeButton "OPEN CSV"        835 130
    $btnRefresh = MakeButton "REFRESH"         975 160

    $f.Controls.Add($btnAdd)
    $f.Controls.Add($btnEdit)
    $f.Controls.Add($btnDelete)
    $f.Controls.Add($btnPing)
    $f.Controls.Add($btnAll)
    $f.Controls.Add($btnOpen)
    $f.Controls.Add($btnRefresh)

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(25,575)
    $status.Size = New-Object System.Drawing.Size(1000,25)
    $status.ForeColor = $Muted
    $f.Controls.Add($status)

    $summary = New-Object System.Windows.Forms.Label
    $summary.Location = New-Object System.Drawing.Point(25,610)
    $summary.Size = New-Object System.Drawing.Size(1000,30)
    $summary.ForeColor = $Accent
    $f.Controls.Add($summary)

    # --------------------------------------------------------
    # DATA FUNCTIONS
    # --------------------------------------------------------

    function LoadDevices {

        $raw = @(Import-Csv $inventoryFile -ErrorAction SilentlyContinue)
        $result = @()

        foreach ($r in $raw) {

            $ip = ""

            if ($r.PSObject.Properties["ManagementIP"]) {
                $ip = [string]$r.ManagementIP
            }
            elseif ($r.PSObject.Properties["IP"]) {
                $ip = [string]$r.IP
            }

            $vendor = "Cisco"

            if ($r.PSObject.Properties["Vendor"]) {
                if (-not [string]::IsNullOrWhiteSpace([string]$r.Vendor)) {
                    $vendor = [string]$r.Vendor
                }
            }

            $model = ""

            if ($r.PSObject.Properties["Model"]) {
                $model = [string]$r.Model
            }

            $deviceStatus = "Unknown"

            if ($r.PSObject.Properties["Status"]) {
                if (-not [string]::IsNullOrWhiteSpace([string]$r.Status)) {
                    $deviceStatus = [string]$r.Status
                }
            }

            $result += [PSCustomObject]@{
                DeviceName   = [string]$r.DeviceName
                Type         = [string]$r.Type
                Vendor       = $vendor
                Model        = $model
                ManagementIP = $ip
                Site         = [string]$r.Site
                Status       = $deviceStatus
            }
        }

        return @($result)
    }

    function SaveDevices {

        param([array]$Devices)

        $Devices |
        Select-Object DeviceName,Type,Vendor,Model,ManagementIP,Site,Status |
        Export-Csv $inventoryFile -NoTypeInformation -Encoding UTF8
    }

    function RefreshGrid {

        $devices = @(LoadDevices)

        # ----------------------------------------------------
        # Build a real DataTable for stable WinForms binding
        # ----------------------------------------------------

        $table = New-Object System.Data.DataTable

        [void]$table.Columns.Add("DeviceName")
        [void]$table.Columns.Add("Type")
        [void]$table.Columns.Add("Vendor")
        [void]$table.Columns.Add("Model")
        [void]$table.Columns.Add("ManagementIP")
        [void]$table.Columns.Add("Site")
        [void]$table.Columns.Add("Status")

        foreach ($device in $devices) {

            $row = $table.NewRow()

            $row["DeviceName"]   = [string]$device.DeviceName
            $row["Type"]         = [string]$device.Type
            $row["Vendor"]       = [string]$device.Vendor
            $row["Model"]        = [string]$device.Model
            $row["ManagementIP"] = [string]$device.ManagementIP
            $row["Site"]         = [string]$device.Site
            $row["Status"]       = [string]$device.Status

            $table.Rows.Add($row)
        }

        $grid.SuspendLayout()

        try {

            $grid.DataSource = $null
            $grid.AutoGenerateColumns = $true
            $grid.DataSource = $table

            $grid.AutoSizeColumnsMode =
                [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

            $grid.ClearSelection()

            # Friendly headers
            if ($grid.Columns["DeviceName"]) {
                $grid.Columns["DeviceName"].HeaderText = "DEVICE NAME"
            }

            if ($grid.Columns["Type"]) {
                $grid.Columns["Type"].HeaderText = "TYPE"
            }

            if ($grid.Columns["Vendor"]) {
                $grid.Columns["Vendor"].HeaderText = "VENDOR"
            }

            if ($grid.Columns["Model"]) {
                $grid.Columns["Model"].HeaderText = "MODEL"
            }

            if ($grid.Columns["ManagementIP"]) {
                $grid.Columns["ManagementIP"].HeaderText = "MANAGEMENT IP"
            }

            if ($grid.Columns["Site"]) {
                $grid.Columns["Site"].HeaderText = "SITE"
            }

            if ($grid.Columns["Status"]) {
                $grid.Columns["Status"].HeaderText = "STATUS"
            }

        }
        finally {

            $grid.ResumeLayout()
            $grid.Refresh()
        }

        # ----------------------------------------------------
        # Summary
        # ----------------------------------------------------

        $online = @(
            $devices |
            Where-Object {
                $_.Status -eq "Online"
            }
        ).Count

        $offline = @(
            $devices |
            Where-Object {
                $_.Status -eq "Offline"
            }
        ).Count

        $unknown = @(
            $devices |
            Where-Object {
                $_.Status -eq "Unknown"
            }
        ).Count

        $summary.Text =
            "Devices: $($devices.Count)   |   Online: $online   |   Offline: $offline   |   Unknown: $unknown"

        $status.ForeColor = $Muted
        $status.Text = "Inventory: $inventoryFile"
    }

    # --------------------------------------------------------
    # DEVICE EDITOR
    # --------------------------------------------------------

    function DeviceEditor {

        param($Device)

        $editing = ($null -ne $Device)

        $e = New-Object System.Windows.Forms.Form

        if ($editing) {
            $e.Text = "NETOPS - Edit Device"
        }
        else {
            $e.Text = "NETOPS - Add Device"
        }

        $e.Size = New-Object System.Drawing.Size(520,530)
        $e.StartPosition = "CenterParent"
        $e.BackColor = $Bg
        $e.ForeColor = $Text
        $e.FormBorderStyle = "FixedDialog"
        $e.MaximizeBox = $false

        $names = @(
            "Device Name",
            "Device Type",
            "Vendor",
            "Model",
            "Management IP",
            "Site / Location"
        )

        $y = 35

        foreach ($n in $names) {

            $l = New-Object System.Windows.Forms.Label
            $l.Text = $n
            $l.Location = New-Object System.Drawing.Point(30,$y)
            $l.Size = New-Object System.Drawing.Size(160,25)
            $l.ForeColor = $Muted
            $e.Controls.Add($l)

            $y += 60
        }

        $nameBox = New-Object System.Windows.Forms.TextBox
        $nameBox.Location = New-Object System.Drawing.Point(200,32)
        $nameBox.Size = New-Object System.Drawing.Size(270,28)
        $e.Controls.Add($nameBox)

        $typeBox = New-Object System.Windows.Forms.ComboBox
        $typeBox.Location = New-Object System.Drawing.Point(200,92)
        $typeBox.Size = New-Object System.Drawing.Size(270,28)
        $typeBox.DropDownStyle = "DropDownList"

        [void]$typeBox.Items.AddRange(@(
            "Router","Switch","Firewall","Wireless","Server","Other"
        ))

        $e.Controls.Add($typeBox)

        $vendorBox = New-Object System.Windows.Forms.ComboBox
        $vendorBox.Location = New-Object System.Drawing.Point(200,152)
        $vendorBox.Size = New-Object System.Drawing.Size(270,28)

        [void]$vendorBox.Items.AddRange(@(
            "Cisco",
            "Fortinet",
            "Palo Alto",
            "Juniper",
            "Aruba",
            "MikroTik",
            "Other"
        ))

        $e.Controls.Add($vendorBox)

        $modelBox = New-Object System.Windows.Forms.TextBox
        $modelBox.Location = New-Object System.Drawing.Point(200,212)
        $modelBox.Size = New-Object System.Drawing.Size(270,28)
        $e.Controls.Add($modelBox)

        $ipBox = New-Object System.Windows.Forms.TextBox
        $ipBox.Location = New-Object System.Drawing.Point(200,272)
        $ipBox.Size = New-Object System.Drawing.Size(270,28)
        $e.Controls.Add($ipBox)

        $siteBox = New-Object System.Windows.Forms.TextBox
        $siteBox.Location = New-Object System.Drawing.Point(200,332)
        $siteBox.Size = New-Object System.Drawing.Size(270,28)
        $e.Controls.Add($siteBox)

        if ($editing) {

            $nameBox.Text   = $Device.DeviceName
            $typeBox.Text   = $Device.Type
            $vendorBox.Text = $Device.Vendor
            $modelBox.Text  = $Device.Model
            $ipBox.Text     = $Device.ManagementIP
            $siteBox.Text   = $Device.Site

        }
        else {

            $typeBox.SelectedIndex = 0
            $vendorBox.Text = "Cisco"
        }

        $save = New-Object System.Windows.Forms.Button
        $save.Text = "SAVE DEVICE"
        $save.Location = New-Object System.Drawing.Point(200,402)
        $save.Size = New-Object System.Drawing.Size(160,40)
        $save.BackColor = $Panel
        $save.ForeColor = $Text
        $save.FlatStyle = "Flat"
        $e.Controls.Add($save)

        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "CANCEL"
        $cancel.Location = New-Object System.Drawing.Point(370,402)
        $cancel.Size = New-Object System.Drawing.Size(100,40)
        $cancel.BackColor = $Panel
        $cancel.ForeColor = $Text
        $cancel.FlatStyle = "Flat"
        $e.Controls.Add($cancel)

        $cancel.Add_Click({
            $e.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $e.Close()
        })

        $save.Add_Click({

            if ([string]::IsNullOrWhiteSpace($nameBox.Text)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Device Name is required."
                )

                return
            }

            if ([string]::IsNullOrWhiteSpace($ipBox.Text)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Management IP is required."
                )

                return
            }

            $currentStatus = "Unknown"

            if ($editing) {
                $currentStatus = $Device.Status
            }

            $e.Tag = [PSCustomObject]@{
                DeviceName   = $nameBox.Text.Trim()
                Type         = $typeBox.Text
                Vendor       = $vendorBox.Text.Trim()
                Model        = $modelBox.Text.Trim()
                ManagementIP = $ipBox.Text.Trim()
                Site         = $siteBox.Text.Trim()
                Status       = $currentStatus
            }

            $e.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $e.Close()
        })

        $r = $e.ShowDialog($f)

        if ($r -eq [System.Windows.Forms.DialogResult]::OK) {
            return $e.Tag
        }

        return $null
    }

    # --------------------------------------------------------
    # ADD
    # --------------------------------------------------------

    $btnAdd.Add_Click({

        $new = DeviceEditor $null

        if ($null -eq $new) {
            return
        }

        $devices = @(LoadDevices)

        foreach ($d in $devices) {

            if (
                $d.DeviceName -eq $new.DeviceName -or
                $d.ManagementIP -eq $new.ManagementIP
            ) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Device Name or Management IP already exists."
                )

                return
            }
        }

        $devices += $new

        SaveDevices $devices
        RefreshGrid

        $status.ForeColor = $Green
        $status.Text = "Device added: $($new.DeviceName)"
    })

    # --------------------------------------------------------
    # EDIT
    # --------------------------------------------------------

    $btnEdit.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $selected =
            [string]$grid.SelectedRows[0].Cells["DeviceName"].Value

        $devices = @(LoadDevices)

        $old = $null

        foreach ($d in $devices) {

            if ($d.DeviceName -eq $selected) {
                $old = $d
                break
            }
        }

        if ($null -eq $old) {
            return
        }

        $edited = DeviceEditor $old

        if ($null -eq $edited) {
            return
        }

        $result = @()

        foreach ($d in $devices) {

            if ($d.DeviceName -eq $selected) {
                $result += $edited
            }
            else {
                $result += $d
            }
        }

        SaveDevices $result
        RefreshGrid

        $status.ForeColor = $Green
        $status.Text = "Device updated: $($edited.DeviceName)"
    })

    # --------------------------------------------------------
    # DELETE
    # --------------------------------------------------------

    $btnDelete.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $selected =
            [string]$grid.SelectedRows[0].Cells["DeviceName"].Value

        $answer = [System.Windows.Forms.MessageBox]::Show(
            "Delete device '$selected'?",
            "NETOPS",
            [System.Windows.Forms.MessageBoxButtons]::YesNo
        )

        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        $result = @()

        foreach ($d in @(LoadDevices)) {

            if ($d.DeviceName -ne $selected) {
                $result += $d
            }
        }

        SaveDevices $result
        RefreshGrid

        $status.ForeColor = $Red
        $status.Text = "Deleted: $selected"
    })

    # --------------------------------------------------------
    # PING
    # --------------------------------------------------------

    $btnPing.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $name = [string]$grid.SelectedRows[0].Cells["DeviceName"].Value
        $ip   = [string]$grid.SelectedRows[0].Cells["ManagementIP"].Value

        $status.Text = "Pinging $name ($ip)..."
        $status.ForeColor = $Muted

        [System.Windows.Forms.Application]::DoEvents()

        $alive = Test-Connection `
            -ComputerName $ip `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        $devices = @(LoadDevices)

        foreach ($d in $devices) {

            if ($d.DeviceName -eq $name) {

                if ($alive) {
                    $d.Status = "Online"
                }
                else {
                    $d.Status = "Offline"
                }
            }
        }

        SaveDevices $devices
        RefreshGrid

        if ($alive) {
            $status.ForeColor = $Green
            $status.Text = "$name is ONLINE"
        }
        else {
            $status.ForeColor = $Red
            $status.Text = "$name is OFFLINE"
        }
    })

    # --------------------------------------------------------
    # CHECK ALL
    # --------------------------------------------------------

    $btnAll.Add_Click({

        $devices = @(LoadDevices)

        $btnAll.Enabled = $false

        try {

            $i = 0

            foreach ($d in $devices) {

                $i++

                $status.Text =
                    "Checking $i/$($devices.Count): $($d.DeviceName)"

                [System.Windows.Forms.Application]::DoEvents()

                $alive = Test-Connection `
                    -ComputerName $d.ManagementIP `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction SilentlyContinue

                if ($alive) {
                    $d.Status = "Online"
                }
                else {
                    $d.Status = "Offline"
                }
            }

            SaveDevices $devices
            RefreshGrid

            $status.ForeColor = $Green
            $status.Text = "Status check completed."

        }
        finally {

            $btnAll.Enabled = $true
        }
    })

    $btnOpen.Add_Click({
        Start-Process notepad.exe $inventoryFile
    })

    $btnRefresh.Add_Click({
        RefreshGrid
    })

    $grid.Add_CellDoubleClick({

        if ($_.RowIndex -ge 0) {
            $btnEdit.PerformClick()
        }
    })

    RefreshGrid

    [void]$f.ShowDialog()
}



# ============================================================
# NETOPS_DEVICE_INVENTORY_DIAGNOSTIC_V1
# ============================================================

function Open-NetOpsDeviceInventorySafe {

    try {

        Show-NetOpsDeviceInventoryPRO

    }
    catch {

        $msg = @"
DEVICE INVENTORY ERROR
============================================================

$($_.Exception.Message)

============================================================
LOCATION

$($_.InvocationInfo.PositionMessage)

============================================================
"@

        [System.Windows.Forms.MessageBox]::Show(
            $msg,
            "NETOPS - Device Inventory Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}


# ============================================================
# NETOPS_INVENTORY_PERSISTENT_BIND_V1
# Preserve direct executable reference for WinForms events
# ============================================================

$script:NetOpsInventoryAction = {
    Show-NetOpsDeviceInventoryPRO
}


# ============================================================
# NETOPS_TOPOLOGY_VIEW_V1
# ============================================================

function Show-NetOpsTopologyView {

    $inventoryFile = Join-Path `
        $env:USERPROFILE `
        "Documents\NETOPS\devices.csv"

    if (-not (Test-Path $inventoryFile)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Device Inventory was not found.",
            "NETOPS Topology View"
        )

        return
    }

    # --------------------------------------------------------
    # THEME
    # --------------------------------------------------------

    $Bg       = [System.Drawing.Color]::FromArgb(14,25,42)
    $Panel    = [System.Drawing.Color]::FromArgb(28,43,64)
    $Panel2   = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text     = [System.Drawing.Color]::White
    $Muted    = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent   = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green    = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red      = [System.Drawing.Color]::FromArgb(255,85,85)
    $Yellow   = [System.Drawing.Color]::FromArgb(255,210,50)

    # --------------------------------------------------------
    # FORM
    # --------------------------------------------------------

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "NETOPS - Topology View"
    $f.Size = New-Object System.Drawing.Size(1250,760)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $Bg
    $f.ForeColor = $Text
    $f.MinimumSize = New-Object System.Drawing.Size(1000,650)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "NETWORK TOPOLOGY"
    $title.Location = New-Object System.Drawing.Point(25,20)
    $title.Size = New-Object System.Drawing.Size(500,35)
    $title.ForeColor = $Accent
    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )

    $f.Controls.Add($title)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = "Auto-generated from Device Inventory"
    $subtitle.Location = New-Object System.Drawing.Point(27,58)
    $subtitle.Size = New-Object System.Drawing.Size(600,25)
    $subtitle.ForeColor = $Muted

    $f.Controls.Add($subtitle)

    # --------------------------------------------------------
    # TOOLBAR
    # --------------------------------------------------------

    function New-TopologyButton {

        param(
            [string]$Caption,
            [int]$X,
            [int]$Width
        )

        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Caption
        $b.Location = New-Object System.Drawing.Point($X,95)
        $b.Size = New-Object System.Drawing.Size($Width,36)
        $b.FlatStyle = "Flat"
        $b.BackColor = $Panel
        $b.ForeColor = $Text

        return $b
    }

    $btnRefresh = New-TopologyButton "REFRESH TOPOLOGY" 25 170
    $f.Controls.Add($btnRefresh)

    $btnAll = New-TopologyButton "SHOW ALL" 205 120
    $f.Controls.Add($btnAll)

    $btnOnline = New-TopologyButton "ONLINE ONLY" 335 140
    $f.Controls.Add($btnOnline)

    $btnInventory = New-TopologyButton "DEVICE INVENTORY" 485 175
    $f.Controls.Add($btnInventory)

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(690,103)
    $lblStatus.Size = New-Object System.Drawing.Size(500,25)
    $lblStatus.ForeColor = $Muted

    $f.Controls.Add($lblStatus)

    # --------------------------------------------------------
    # SCROLLABLE CANVAS
    # --------------------------------------------------------

    $canvas = New-Object System.Windows.Forms.Panel
    $canvas.Location = New-Object System.Drawing.Point(25,150)
    $canvas.Size = New-Object System.Drawing.Size(1180,520)
    $canvas.BackColor = $Panel2
    $canvas.BorderStyle = "FixedSingle"
    $canvas.AutoScroll = $true

    $f.Controls.Add($canvas)

    # --------------------------------------------------------
    # DATA
    # --------------------------------------------------------

    $script:TopologyOnlineOnly = $false

    function Get-TopologyDevices {

        $raw = @(
            Import-Csv `
                -Path $inventoryFile `
                -ErrorAction SilentlyContinue
        )

        $result = @()

        foreach ($r in $raw) {

            $ip = ""

            if ($r.PSObject.Properties["ManagementIP"]) {
                $ip = [string]$r.ManagementIP
            }
            elseif ($r.PSObject.Properties["IP"]) {
                $ip = [string]$r.IP
            }

            $status = "Unknown"

            if ($r.PSObject.Properties["Status"]) {

                if (-not [string]::IsNullOrWhiteSpace([string]$r.Status)) {
                    $status = [string]$r.Status
                }
            }

            $site = "UNASSIGNED"

            if (-not [string]::IsNullOrWhiteSpace([string]$r.Site)) {
                $site = [string]$r.Site
            }

            $result += [PSCustomObject]@{
                DeviceName   = [string]$r.DeviceName
                Type         = [string]$r.Type
                Vendor       = [string]$r.Vendor
                Model        = [string]$r.Model
                ManagementIP = $ip
                Site         = $site
                Status       = $status
            }
        }

        return @($result)
    }

    # --------------------------------------------------------
    # DRAW DEVICE CARD
    # --------------------------------------------------------

    function New-DeviceCard {

        param(
            $Device,
            [int]$X,
            [int]$Y
        )

        $card = New-Object System.Windows.Forms.Panel
        $card.Location = New-Object System.Drawing.Point($X,$Y)
        $card.Size = New-Object System.Drawing.Size(245,125)
        $card.BackColor = $Panel
        $card.BorderStyle = "FixedSingle"

        $name = New-Object System.Windows.Forms.Label
        $name.Text = [string]$Device.DeviceName
        $name.Location = New-Object System.Drawing.Point(12,10)
        $name.Size = New-Object System.Drawing.Size(215,25)
        $name.ForeColor = $Accent
        $name.Font = New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )

        $card.Controls.Add($name)

        $type = New-Object System.Windows.Forms.Label
        $type.Text = "Type: $($Device.Type)"
        $type.Location = New-Object System.Drawing.Point(12,40)
        $type.Size = New-Object System.Drawing.Size(215,20)
        $type.ForeColor = $Text

        $card.Controls.Add($type)

        $ip = New-Object System.Windows.Forms.Label
        $ip.Text = "IP: $($Device.ManagementIP)"
        $ip.Location = New-Object System.Drawing.Point(12,63)
        $ip.Size = New-Object System.Drawing.Size(215,20)
        $ip.ForeColor = $Muted

        $card.Controls.Add($ip)

        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Text = "Status: $($Device.Status)"
        $statusLabel.Location = New-Object System.Drawing.Point(12,88)
        $statusLabel.Size = New-Object System.Drawing.Size(215,22)

        if ($Device.Status -eq "Online") {
            $statusLabel.ForeColor = $Green
        }
        elseif ($Device.Status -eq "Offline") {
            $statusLabel.ForeColor = $Red
        }
        else {
            $statusLabel.ForeColor = $Yellow
        }

        $card.Controls.Add($statusLabel)

        return $card
    }

    # --------------------------------------------------------
    # DRAW TOPOLOGY
    # --------------------------------------------------------

    function Refresh-Topology {

        $canvas.SuspendLayout()

        try {

            $canvas.Controls.Clear()

            $devices = @(Get-TopologyDevices)

            if ($script:TopologyOnlineOnly) {

                $devices = @(
                    $devices |
                    Where-Object {
                        $_.Status -eq "Online"
                    }
                )
            }

            if ($devices.Count -eq 0) {

                $empty = New-Object System.Windows.Forms.Label
                $empty.Text = "No devices available for this view."
                $empty.Location = New-Object System.Drawing.Point(30,30)
                $empty.Size = New-Object System.Drawing.Size(400,30)
                $empty.ForeColor = $Muted

                $canvas.Controls.Add($empty)

                $lblStatus.Text = "0 devices"

                return
            }

            $sites = @(
                $devices |
                Group-Object Site |
                Sort-Object Name
            )

            $currentY = 20

            foreach ($siteGroup in $sites) {

                $siteTitle = New-Object System.Windows.Forms.Label
                $siteTitle.Text = "SITE: $($siteGroup.Name)"
                $siteTitle.Location = New-Object System.Drawing.Point(
                    20,
                    $currentY
                )

                $siteTitle.Size = New-Object System.Drawing.Size(500,30)
                $siteTitle.ForeColor = $Accent

                $siteTitle.Font = New-Object System.Drawing.Font(
                    "Segoe UI",
                    12,
                    [System.Drawing.FontStyle]::Bold
                )

                $canvas.Controls.Add($siteTitle)

                $currentY += 40

                $column = 0
                $row = 0

                foreach ($device in $siteGroup.Group) {

                    $x = 25 + ($column * 270)
                    $y = $currentY + ($row * 145)

                    $card = New-DeviceCard `
                        -Device $device `
                        -X $x `
                        -Y $y

                    $canvas.Controls.Add($card)

                    $column++

                    if ($column -ge 4) {
                        $column = 0
                        $row++
                    }
                }

                $rowsUsed = $row + 1

                if ($column -eq 0 -and $row -gt 0) {
                    $rowsUsed = $row
                }

                $currentY += ($rowsUsed * 145) + 30
            }

            $onlineCount = @(
                $devices |
                Where-Object {
                    $_.Status -eq "Online"
                }
            ).Count

            $offlineCount = @(
                $devices |
                Where-Object {
                    $_.Status -eq "Offline"
                }
            ).Count

            $unknownCount = @(
                $devices |
                Where-Object {
                    $_.Status -eq "Unknown"
                }
            ).Count

            $lblStatus.Text =
                "Devices: $($devices.Count) | Online: $onlineCount | Offline: $offlineCount | Unknown: $unknownCount"

        }
        finally {

            $canvas.ResumeLayout()
            $canvas.Refresh()
        }
    }

    # --------------------------------------------------------
    # BUTTON EVENTS
    # --------------------------------------------------------

    $btnRefresh.Add_Click({

        Refresh-Topology
    })

    $btnAll.Add_Click({

        $script:TopologyOnlineOnly = $false
        Refresh-Topology
    })

    $btnOnline.Add_Click({

        $script:TopologyOnlineOnly = $true
        Refresh-Topology
    })

    $btnInventory.Add_Click({

        $launcher = "$env:TEMP\NETOPS-Open-DeviceInventory.ps1"

        if (Test-Path $launcher) {

            Start-Process powershell.exe `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""

        }
        else {

            [System.Windows.Forms.MessageBox]::Show(
                "Device Inventory launcher was not found.",
                "NETOPS Topology"
            )
        }
    })

    # --------------------------------------------------------
    # INITIAL DRAW
    # --------------------------------------------------------

    Refresh-Topology

    [void]$f.ShowDialog()
}


function Show-NetOpsNetworkToolbox {

    $toolbox = New-Object System.Windows.Forms.Form
    $toolbox.Text = "NETOPS - Network Toolbox"
    $toolbox.Size = New-Object System.Drawing.Size(720,500)
    $toolbox.StartPosition = "CenterScreen"
    $toolbox.BackColor = [System.Drawing.Color]::FromArgb(15,27,45)
    $toolbox.ForeColor = [System.Drawing.Color]::White
    $toolbox.FormBorderStyle = "FixedDialog"
    $toolbox.MaximizeBox = $false

    # --------------------------------------------------------
    # TITLE
    # --------------------------------------------------------

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "NETWORK TOOLS"
    $lblTitle.Location = New-Object System.Drawing.Point(30,25)
    $lblTitle.Size = New-Object System.Drawing.Size(400,40)
    $lblTitle.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        18,
        [System.Drawing.FontStyle]::Bold
    )
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(30,210,245)

    $toolbox.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "CCNA / CCNP troubleshooting and diagnostic utilities"
    $lblSub.Location = New-Object System.Drawing.Point(32,65)
    $lblSub.Size = New-Object System.Drawing.Size(550,25)
    $lblSub.ForeColor = [System.Drawing.Color]::LightGray

    $toolbox.Controls.Add($lblSub)

    # --------------------------------------------------------
    # PING
    # --------------------------------------------------------

    $btnPingTool = New-Object System.Windows.Forms.Button
    $btnPingTool.Text = "PING"
    $btnPingTool.Location = New-Object System.Drawing.Point(35,120)
    $btnPingTool.Size = New-Object System.Drawing.Size(300,80)
    $btnPingTool.FlatStyle = "Flat"
    $btnPingTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnPingTool.ForeColor = [System.Drawing.Color]::White
    $btnPingTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnPingTool.Add_Click({
        Show-NetOpsPingTool
    })

    $toolbox.Controls.Add($btnPingTool)

    # --------------------------------------------------------
    # TRACEROUTE
    # --------------------------------------------------------

    $btnTraceTool = New-Object System.Windows.Forms.Button
    $btnTraceTool.Text = "TRACEROUTE"
    $btnTraceTool.Location = New-Object System.Drawing.Point(365,120)
    $btnTraceTool.Size = New-Object System.Drawing.Size(300,80)
    $btnTraceTool.FlatStyle = "Flat"
    $btnTraceTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnTraceTool.ForeColor = [System.Drawing.Color]::White
    $btnTraceTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnTraceTool.Add_Click({
        Show-NetOpsTracerouteTool
    })

    $toolbox.Controls.Add($btnTraceTool)

    # --------------------------------------------------------
    # SHOW COMMANDS
    # --------------------------------------------------------

    $btnCommandsTool = New-Object System.Windows.Forms.Button
    $btnCommandsTool.Text = "SHOW COMMANDS"
    $btnCommandsTool.Location = New-Object System.Drawing.Point(35,225)
    $btnCommandsTool.Size = New-Object System.Drawing.Size(300,80)
    $btnCommandsTool.FlatStyle = "Flat"
    $btnCommandsTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnCommandsTool.ForeColor = [System.Drawing.Color]::White
    $btnCommandsTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnCommandsTool.Add_Click({
        Show-NetOpsCommandsTool
    })

    $toolbox.Controls.Add($btnCommandsTool)

    # --------------------------------------------------------
    # INVENTORY
    # --------------------------------------------------------

    $btnInventoryTool = New-Object System.Windows.Forms.Button
    $btnInventoryTool.Text = "DEVICE INVENTORY"
    $btnInventoryTool.Location = New-Object System.Drawing.Point(365,225)
    $btnInventoryTool.Size = New-Object System.Drawing.Size(300,80)
    $btnInventoryTool.FlatStyle = "Flat"
    $btnInventoryTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnInventoryTool.ForeColor = [System.Drawing.Color]::White
    $btnInventoryTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnInventoryTool.Add_Click({
        Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Acer\AppData\Local\Temp\NETOPS-Open-DeviceInventory.ps1"'
    })

    $toolbox.Controls.Add($btnInventoryTool)


    # --------------------------------------------------------
    # TOPOLOGY VIEW
    # --------------------------------------------------------

    $btnTopologyTool = New-Object System.Windows.Forms.Button
    $btnTopologyTool.Text = "TOPOLOGY VIEW"
    $btnTopologyTool.Location = New-Object System.Drawing.Point(35,330)
    $btnTopologyTool.Size = New-Object System.Drawing.Size(630,55)
    $btnTopologyTool.FlatStyle = "Flat"
    $btnTopologyTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnTopologyTool.ForeColor = [System.Drawing.Color]::White
    $btnTopologyTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10,
        [System.Drawing.FontStyle]::Bold
    )

    $btnTopologyTool.Add_Click({

        Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Acer\AppData\Local\Temp\NETOPS-Open-TopologyView.ps1"'

    })

    $toolbox.Controls.Add($btnTopologyTool)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "NETOPS Core Network Tools v1"
    $lblStatus.Location = New-Object System.Drawing.Point(35,410)
    $lblStatus.Size = New-Object System.Drawing.Size(400,25)
    $lblStatus.ForeColor = [System.Drawing.Color]::Gray

    $toolbox.Controls.Add($lblStatus)

    [void]$toolbox.ShowDialog()
}


# ============================================================
# MAIN NETOPS NETWORK TOOLS BUTTON
# ============================================================

$btnNetworkToolsLauncher = New-Object System.Windows.Forms.Button

$btnNetworkToolsLauncher.Text = "NETWORK TOOLS"

$btnNetworkToolsLauncher.Size = New-Object System.Drawing.Size(
    180,
    42
)

$btnNetworkToolsLauncher.Location = New-Object System.Drawing.Point(
    1150,
    20
)

$btnNetworkToolsLauncher.Anchor = 
    [System.Windows.Forms.AnchorStyles]::Top 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Right

$btnNetworkToolsLauncher.FlatStyle = "Flat"

$btnNetworkToolsLauncher.BackColor = 
    [System.Drawing.Color]::FromArgb(30,48,70)

$btnNetworkToolsLauncher.ForeColor = 
    [System.Drawing.Color]::White

$btnNetworkToolsLauncher.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9,
    [System.Drawing.FontStyle]::Bold
)

$btnNetworkToolsLauncher.Add_Click({

    Show-NetOpsNetworkToolbox

})

$toolForm.Controls.Add($btnNetworkToolsLauncher)

$btnNetworkToolsLauncher.BringToFront()

# ============================================================
# NETOPS_NETWORK_TOOLS_SIDEBAR_V1
# ============================================================

$btnNetworkToolsSidebar = New-Object System.Windows.Forms.Button

$btnNetworkToolsSidebar.Text = "Network Tools"

$btnNetworkToolsSidebar.Size = $btnSystem.Size

$btnNetworkToolsSidebar.Location = New-Object System.Drawing.Point(
    $btnSystem.Left,
    ($btnSystem.Bottom + 10)
)

$btnNetworkToolsSidebar.Anchor = 
    [System.Windows.Forms.AnchorStyles]::Top 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Left 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Right

$btnNetworkToolsSidebar.FlatStyle = "Flat"

$btnNetworkToolsSidebar.FlatAppearance.BorderSize = 0

$btnNetworkToolsSidebar.BackColor = 
    [System.Drawing.Color]::FromArgb(30,45,66)

$btnNetworkToolsSidebar.ForeColor = 
    [System.Drawing.Color]::White

$btnNetworkToolsSidebar.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$btnNetworkToolsSidebar.TextAlign = 
    [System.Drawing.ContentAlignment]::MiddleLeft

$btnNetworkToolsSidebar.Padding = 
    New-Object System.Windows.Forms.Padding(22,0,0,0)

$btnNetworkToolsSidebar.Cursor = 
    [System.Windows.Forms.Cursors]::Hand

$btnNetworkToolsSidebar.Add_Click({

    Show-NetOpsNetworkToolbox

})

if ($btnSystem.Parent) {

    $btnSystem.Parent.Controls.Add($btnNetworkToolsSidebar)

    $btnNetworkToolsSidebar.BringToFront()

}
else {

    $form.Controls.Add($btnNetworkToolsSidebar)

    $btnNetworkToolsSidebar.BringToFront()
}



[System.Windows.Forms.Application]::Run($form)

































 -like "*$search*"
                }
            )
        }

        foreach ($cmd in $commands) {
            [void]$lstCommands.Items.Add($cmd)
        }

        if ($lstCommands.Items.Count -gt 0) {
            $lstCommands.SelectedIndex = 0
        }
    }

    # ========================================================
    # CATEGORY CHANGE
    # ========================================================

    $cmbCategory.Add_SelectedIndexChanged({
        Refresh-CommandList
    })

    # ========================================================
    # SEARCH LIVE
    # ========================================================

    # ========================================================
    # NETOPS_SHOW_COMMANDS_STABLE_SEARCH_V1
    # Search executes only when ENTER is pressed.
    # This avoids UI-thread refresh loops in PowerShell WinForms.
    # ========================================================

    $txtSearch.Add_KeyDown({

        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {

            $_.SuppressKeyPress = $true

            try {

                $lstCommands.BeginUpdate()

                $lstCommands.Items.Clear()
                $txtDescription.Clear()

                $category = $cmbCategory.SelectedItem

                if ($null -eq $category) {
                    return
                }

                $commands = @()

                if ($category.ToString() -eq "All Commands") {

                    foreach ($categoryName in $CommandDB.Keys) {

                        foreach ($commandItem in $CommandDB[$categoryName]) {

                            if ($commands -notcontains $commandItem) {
                                $commands += $commandItem
                            }
                        }
                    }

                    $commands = @($commands | Sort-Object)

                }
                else {

                    $commands = @(
                        $CommandDB[$category.ToString()]
                    )
                }

                $searchValue = $txtSearch.Text.Trim()

                if (-not [string]::IsNullOrWhiteSpace($searchValue)) {

                    $filtered = @()

                    foreach ($commandItem in $commands) {

                        if (
                            $commandItem.IndexOf(
                                $searchValue,
                                [System.StringComparison]::OrdinalIgnoreCase
                            ) -ge 0
                        ) {

                            $filtered += $commandItem
                        }
                    }

                    $commands = $filtered
                }

                foreach ($commandItem in $commands) {

                    [void]$lstCommands.Items.Add(
                        $commandItem
                    )
                }

                if ($lstCommands.Items.Count -gt 0) {

                    $lstCommands.SelectedIndex = 0

                }
                else {

                    $txtDescription.Text = @"
NO COMMAND FOUND
============================================================

Search:
$searchValue

Try another keyword such as:

ospf
vlan
trunk
route
nat
bgp
ipv6
interface
"@
                }

            }
            finally {

                $lstCommands.EndUpdate()
            }
        }
    })

    # ========================================================
    # CLEAR
    # ========================================================

    $btnClear.Add_Click({

        try {

            $txtSearch.Text = ""

            if ($cmbCategory.SelectedIndex -ne 0) {
                $cmbCategory.SelectedIndex = 0
            }
            else {

                $lstCommands.BeginUpdate()

                try {

                    $lstCommands.Items.Clear()
                    $txtDescription.Clear()

                    $allCommands = @()

                    foreach ($categoryName in $CommandDB.Keys) {

                        foreach ($commandItem in $CommandDB[$categoryName]) {

                            if ($allCommands -notcontains $commandItem) {
                                $allCommands += $commandItem
                            }
                        }
                    }

                    foreach ($commandItem in ($allCommands | Sort-Object)) {

                        [void]$lstCommands.Items.Add(
                            $commandItem
                        )
                    }

                    if ($lstCommands.Items.Count -gt 0) {
                        $lstCommands.SelectedIndex = 0
                    }

                }
                finally {

                    $lstCommands.EndUpdate()
                }
            }

            $txtSearch.Focus()

        }
        catch {

            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "NETOPS Search"
            )
        }
    })

    # ========================================================
    # COMMAND SELECTION
    # ========================================================

    $lstCommands.Add_SelectedIndexChanged({

        if ($null -eq $lstCommands.SelectedItem) {
            return
        }

        $cmd = $lstCommands.SelectedItem.ToString()

        $help = $CommandHelp[$cmd]

        if ($null -eq $help) {

            $purpose =
                "Cisco IOS diagnostic command used for operational verification."

            $use =
                "Use this command during structured evidence collection."

            $look =
                "Review the output for values that differ from the expected network design."

            $problems =
                "Interpret the output together with topology, configuration and incident context."

        }
        else {

            $purpose  = $help.Purpose
            $use      = $help.Use
            $look     = $help.Look
            $problems = $help.Problems
        }

        $txtDescription.Text = @"
COMMAND
============================================================
$cmd


PURPOSE
============================================================
$purpose


WHEN TO USE
============================================================
$use


WHAT TO LOOK FOR
============================================================
$look


COMMON PROBLEMS
============================================================
$problems


NETOPS WORKFLOW
============================================================
1. Run the command on the affected Cisco device.
2. Save the output as TXT evidence.
3. Open Analyze Incident.
4. Attach the evidence file.
5. Run FAST or HYBRID AI analysis.
"@

        $lblCopyStatus.Text = ""
    })

    # ========================================================
    # COPY COMMAND
    # ========================================================

    $btnCopy.Add_Click({

        if ($null -eq $lstCommands.SelectedItem) {

            $lblCopyStatus.Text = "Select a command first."
            return
        }

        $cmd = $lstCommands.SelectedItem.ToString()

        [System.Windows.Forms.Clipboard]::SetText($cmd)

        $lblCopyStatus.Text = "Copied: $cmd"
    })

    # ========================================================
    # INITIALIZE
    # ========================================================

    $cmbCategory.SelectedIndex = 0

    [void]$toolForm.ShowDialog()
}

function Show-NetOpsDeviceInventory {

    $inventoryDir = Join-Path $env:USERPROFILE "Documents\NETOPS"
    $inventoryFile = Join-Path $inventoryDir "devices.csv"

    if (-not (Test-Path $inventoryDir)) {
        New-Item `
            -Path $inventoryDir `
            -ItemType Directory `
            -Force |
            Out-Null
    }

    if (-not (Test-Path $inventoryFile)) {

        @(
            [PSCustomObject]@{
                DeviceName = "R-HQ-01"
                Type       = "Router"
                IP         = "192.168.1.1"
                Site       = "HQ"
                Status     = "Unknown"
            }

            [PSCustomObject]@{
                DeviceName = "SW-CORE-01"
                Type       = "Switch"
                IP         = "192.168.1.2"
                Site       = "HQ"
                Status     = "Unknown"
            }

            [PSCustomObject]@{
                DeviceName = "SW-ACCESS-01"
                Type       = "Switch"
                IP         = "192.168.1.10"
                Site       = "HQ"
                Status     = "Unknown"
            }

            [PSCustomObject]@{
                DeviceName = "R-BRANCH-01"
                Type       = "Router"
                IP         = "192.168.30.1"
                Site       = "Branch"
                Status     = "Unknown"
            }
        ) |
        Export-Csv `
            -Path $inventoryFile `
            -NoTypeInformation `
            -Encoding UTF8
    }

    $toolForm = New-Object System.Windows.Forms.Form
    $toolForm.Text = "NETOPS - Device Inventory"
    $toolForm.Size = New-Object System.Drawing.Size(850,520)
    $toolForm.StartPosition = "CenterScreen"

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(20,20)
    $grid.Size = New-Object System.Drawing.Size(790,360)
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $toolForm.Controls.Add($grid)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Check Status"
    $btnRefresh.Location = New-Object System.Drawing.Point(20,400)
    $btnRefresh.Size = New-Object System.Drawing.Size(140,35)
    $toolForm.Controls.Add($btnRefresh)

    $btnOpen = New-Object System.Windows.Forms.Button
    $btnOpen.Text = "Open CSV"
    $btnOpen.Location = New-Object System.Drawing.Point(180,400)
    $btnOpen.Size = New-Object System.Drawing.Size(120,35)
    $toolForm.Controls.Add($btnOpen)

    function Refresh-NetOpsInventory {

        $devices = Import-Csv $inventoryFile

        foreach ($device in $devices) {

            try {

                $alive = Test-Connection `
                    -ComputerName $device.IP `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction SilentlyContinue

                if ($alive) {
                    $device.Status = "Online"
                }
                else {
                    $device.Status = "Offline"
                }

            }
            catch {
                $device.Status = "Unknown"
            }
        }

        $devices |
            Export-Csv `
                -Path $inventoryFile `
                -NoTypeInformation `
                -Encoding UTF8

        $grid.DataSource = $null
        $grid.DataSource = @($devices)
    }

    $btnRefresh.Add_Click({
        Refresh-NetOpsInventory
    })

    $btnOpen.Add_Click({
        Start-Process notepad.exe $inventoryFile
    })

    $grid.DataSource = @(Import-Csv $inventoryFile)

    [void]$toolForm.ShowDialog()
}


$form = New-Object System.Windows.Forms.Form

$form.Text = "NETOPS Network Troubleshooter v6.0"
$form.StartPosition = "CenterScreen"
$form.WindowState = "Maximized"
$form.MinimumSize = New-Object System.Drawing.Size(1200,760)
$form.BackColor = $BG
$form.ForeColor = $Text

$form.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10
)

# ============================================================
# ROOT LAYOUT
# ============================================================

$root = New-Object System.Windows.Forms.TableLayoutPanel

$root.Dock = "Fill"
$root.ColumnCount = 2
$root.RowCount = 1
$root.BackColor = $BG

$root.ColumnStyles.Add(
    (New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Absolute,
        280
    ))
)

$root.ColumnStyles.Add(
    (New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Percent,
        100
    ))
)

$form.Controls.Add($root)

# ============================================================
# SIDEBAR
# ============================================================

$sidebar = New-Object System.Windows.Forms.TableLayoutPanel

$sidebar.Dock = "Fill"
$sidebar.ColumnCount = 1
$sidebar.RowCount = 9
$sidebar.BackColor = $SideBG

$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",110)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",100)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",45)))
$sidebar.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",10)))

$root.Controls.Add($sidebar,0,0)

# Branding
$brandPanel = New-Object System.Windows.Forms.Panel
$brandPanel.Dock = "Fill"
$brandPanel.BackColor = $SideBG

$logo = New-Object System.Windows.Forms.Label
$logo.Text = "NETOPS"
$logo.Location = New-Object System.Drawing.Point(24,20)
$logo.Size = New-Object System.Drawing.Size(220,42)
$logo.ForeColor = $Cyan
$logo.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    22,
    [System.Drawing.FontStyle]::Bold
)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Network Troubleshooting Console"
$subtitle.Location = New-Object System.Drawing.Point(26,66)
$subtitle.Size = New-Object System.Drawing.Size(225,25)
$subtitle.ForeColor = $Muted
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI",9)

$brandPanel.Controls.Add($logo)
$brandPanel.Controls.Add($subtitle)

$sidebar.Controls.Add($brandPanel,0,0)

# Navigation
$btnDashboard = New-Object System.Windows.Forms.Button
$btnDashboard.Text = "Dashboard"
Style-NavButton $btnDashboard

$btnAnalyze = New-Object System.Windows.Forms.Button
$btnAnalyze.Text = "Analyze Incident"
Style-NavButton $btnAnalyze

$btnHistory = New-Object System.Windows.Forms.Button
$btnHistory.Text = "Incident History"
Style-NavButton $btnHistory

$btnWorkflow = New-Object System.Windows.Forms.Button
$btnWorkflow.Text = "Guided Workflow"
Style-NavButton $btnWorkflow

$btnSystem = New-Object System.Windows.Forms.Button
$btnSystem.Text = "System Status"
Style-NavButton $btnSystem

$sidebar.Controls.Add($btnDashboard,0,1)
$sidebar.Controls.Add($btnAnalyze,0,2)
$sidebar.Controls.Add($btnHistory,0,3)
$sidebar.Controls.Add($btnWorkflow,0,4)
$sidebar.Controls.Add($btnSystem,0,5)

$version = New-Object System.Windows.Forms.Label
$version.Text = "v6.0 | Incident Lifecycle / RCA / Hybrid AI"
$version.Dock = "Fill"
$version.Padding = New-Object System.Windows.Forms.Padding(26,0,0,0)
$version.TextAlign = "MiddleLeft"
$version.ForeColor = $Muted
$version.Font = New-Object System.Drawing.Font("Segoe UI",9)

$sidebar.Controls.Add($version,0,7)

# ============================================================
# WORKSPACE
# ============================================================

$workspace = New-Object System.Windows.Forms.Panel
$workspace.Dock = "Fill"
$workspace.BackColor = $BG
$workspace.Padding = New-Object System.Windows.Forms.Padding(28)

$root.Controls.Add($workspace,1,0)

# Pages
$pageDashboard = New-Object System.Windows.Forms.Panel
$pageDashboard.Dock = "Fill"
$pageDashboard.BackColor = $BG

$pageAnalyze = New-Object System.Windows.Forms.Panel
$pageAnalyze.Dock = "Fill"
$pageAnalyze.BackColor = $BG
$pageAnalyze.Visible = $false

$pageHistory = New-Object System.Windows.Forms.Panel
$pageHistory.Dock = "Fill"
$pageHistory.BackColor = $BG
$pageHistory.Visible = $false

$pageSystem = New-Object System.Windows.Forms.Panel
$pageSystem.Dock = "Fill"
$pageSystem.BackColor = $BG
$pageSystem.Visible = $false

$workspace.Controls.Add($pageDashboard)
$workspace.Controls.Add($pageAnalyze)
$workspace.Controls.Add($pageHistory)
$workspace.Controls.Add($pageSystem)

function Show-Page {
    param($Page)

    foreach ($p in @(
        $pageDashboard,
        $pageAnalyze,
        $pageHistory,
        $pageSystem
    )) {
        $p.Visible = $false
    }

    $Page.Visible = $true
    $Page.BringToFront()
}

# ============================================================
# DASHBOARD
# ============================================================

$dash = New-Object System.Windows.Forms.TableLayoutPanel

$dash.Dock = "Fill"
$dash.ColumnCount = 1
$dash.RowCount = 6
$dash.BackColor = $BG

$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",85)))
$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",140)))
$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",65)))
$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",50)))
$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",100)))
$dash.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",10)))

$pageDashboard.Controls.Add($dash)

# Header
$dashHeader = New-Object System.Windows.Forms.TableLayoutPanel
$dashHeader.Dock = "Fill"
$dashHeader.ColumnCount = 2
$dashHeader.RowCount = 1

$dashHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Percent",100)))
$dashHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Absolute",190)))

$headerLeft = New-Object System.Windows.Forms.Panel
$headerLeft.Dock = "Fill"
$headerLeft.BackColor = $BG

$title = New-Object System.Windows.Forms.Label
$title.Text = "Incident Dashboard"
$title.Location = New-Object System.Drawing.Point(0,0)
$title.Size = New-Object System.Drawing.Size(600,42)
$title.ForeColor = $Text
$title.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    22,
    [System.Drawing.FontStyle]::Bold
)

$description = New-Object System.Windows.Forms.Label
$description.Text = "Network incident overview and operational health"
$description.Location = New-Object System.Drawing.Point(2,47)
$description.Size = New-Object System.Drawing.Size(650,25)
$description.ForeColor = $Muted
$description.Font = New-Object System.Drawing.Font("Segoe UI",9)

$headerLeft.Controls.Add($title)
$headerLeft.Controls.Add($description)

$btnRefreshDash = New-Object System.Windows.Forms.Button
$btnRefreshDash.Text = "Refresh Dashboard"
$btnRefreshDash.Dock = "Fill"
$btnRefreshDash.Margin = New-Object System.Windows.Forms.Padding(10,8,0,28)
Style-ActionButton $btnRefreshDash

$dashHeader.Controls.Add($headerLeft,0,0)
$dashHeader.Controls.Add($btnRefreshDash,1,0)

$dash.Controls.Add($dashHeader,0,0)

# Cards
$cards = New-Object System.Windows.Forms.TableLayoutPanel
$cards.Dock = "Fill"
$cards.ColumnCount = 4
$cards.RowCount = 1
$cards.BackColor = $BG

for ($i = 0; $i -lt 4; $i++) {
    $cards.ColumnStyles.Add(
        (New-Object System.Windows.Forms.ColumnStyle("Percent",25))
    )
}

$cardTotal = New-StatCard "TOTAL INCIDENTS" $Cyan
$cardOpen = New-StatCard "OPEN" $Red
$cardMonitoring = New-StatCard "MONITORING" $Yellow
$cardResolved = New-StatCard "RESOLVED" $Green

$cards.Controls.Add($cardTotal.Panel,0,0)
$cards.Controls.Add($cardOpen.Panel,1,0)
$cards.Controls.Add($cardMonitoring.Panel,2,0)
$cards.Controls.Add($cardResolved.Panel,3,0)

$dash.Controls.Add($cards,0,1)

# Health row
$healthPanel = New-Object System.Windows.Forms.TableLayoutPanel
$healthPanel.Dock = "Fill"
$healthPanel.ColumnCount = 3
$healthPanel.RowCount = 1

$healthPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Percent",60)))
$healthPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Percent",20)))
$healthPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Percent",20)))

$healthLabel = New-Object System.Windows.Forms.Label
$healthLabel.Dock = "Fill"
$healthLabel.TextAlign = "MiddleLeft"
$healthLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    16,
    [System.Drawing.FontStyle]::Bold
)

$engineStatus = New-Object System.Windows.Forms.Label
$engineStatus.Dock = "Fill"
$engineStatus.TextAlign = "MiddleCenter"
$engineStatus.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9,
    [System.Drawing.FontStyle]::Bold
)

$ollamaStatus = New-Object System.Windows.Forms.Label
$ollamaStatus.Dock = "Fill"
$ollamaStatus.TextAlign = "MiddleCenter"
$ollamaStatus.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9,
    [System.Drawing.FontStyle]::Bold
)

$healthPanel.Controls.Add($healthLabel,0,0)
$healthPanel.Controls.Add($engineStatus,1,0)
$healthPanel.Controls.Add($ollamaStatus,2,0)

$dash.Controls.Add($healthPanel,0,2)

$recentTitle = New-Object System.Windows.Forms.Label
$recentTitle.Text = "Recent Incidents"
$recentTitle.Dock = "Fill"
$recentTitle.TextAlign = "BottomLeft"
$recentTitle.ForeColor = $Text
$recentTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    14,
    [System.Drawing.FontStyle]::Bold
)

$dash.Controls.Add($recentTitle,0,3)

$recentGrid = New-Object System.Windows.Forms.DataGridView
$recentGrid.Dock = "Fill"
Style-Grid $recentGrid

$dash.Controls.Add($recentGrid,0,4)

function Refresh-Dashboard {
    $rows = @(Get-HistoryData)

    $total = $rows.Count
    $open = @($rows | Where-Object { $_.Status -eq "OPEN" }).Count
    $monitoring = @($rows | Where-Object { $_.Status -eq "MONITORING" }).Count
    $resolved = @($rows | Where-Object { $_.Status -eq "RESOLVED" }).Count

    $cardTotal.Value.Text = "$total"
    $cardOpen.Value.Text = "$open"
    $cardMonitoring.Value.Text = "$monitoring"
    $cardResolved.Value.Text = "$resolved"

    if ($total -eq 0) {
        $healthLabel.Text = "Health Score: N/A"
        $healthLabel.ForeColor = $Muted
    }
    else {
        $score = 100 - ($open * 25) - ($monitoring * 10)

        if ($score -lt 0) {
            $score = 0
        }

        if ($score -ge 90) {
            $healthLabel.Text = "Health Score: $score/100 - HEALTHY"
            $healthLabel.ForeColor = $Green
        }
        elseif ($score -ge 70) {
            $healthLabel.Text = "Health Score: $score/100 - ATTENTION"
            $healthLabel.ForeColor = $Yellow
        }
        else {
            $healthLabel.Text = "Health Score: $score/100 - DEGRADED"
            $healthLabel.ForeColor = $Red
        }
    }

    if (Test-Path $Engine) {
        $engineStatus.Text = "ENGINE  READY"
        $engineStatus.ForeColor = $Green
    }
    else {
        $engineStatus.Text = "ENGINE  OFFLINE"
        $engineStatus.ForeColor = $Red
    }

    try {
        ollama --version | Out-Null
        $ollamaStatus.Text = "OLLAMA  READY"
        $ollamaStatus.ForeColor = $Green
    }
    catch {
        $ollamaStatus.Text = "OLLAMA  OFFLINE"
        $ollamaStatus.ForeColor = $Red
    }

        $recent = @(
    $rows |
    Sort-Object IncidentID -Descending |
    Select-Object -First 10
)

    $table = New-Object System.Data.DataTable

    foreach ($column in @(
        "IncidentID",
        "Created",
        "Status",
        "Category",
        "Severity",
        "Confidence",
        "Decision"
    )) {
        [void]$table.Columns.Add($column)
    }

    foreach ($incident in $recent) {

        $row = $table.NewRow()

        $row["IncidentID"] = [string]$incident.IncidentID
        $row["Created"]    = [string]$incident.Created
        $row["Status"]     = [string]$incident.Status
        $row["Category"]   = [string]$incident.Category
        $row["Severity"]   = [string]$incident.Severity
        $row["Confidence"] = [string]$incident.Confidence
        $row["Decision"]   = [string]$incident.Decision

        [void]$table.Rows.Add($row)
    }

    $recentGrid.DataSource = $null
    $recentGrid.DataSource = $table

    if ($recentGrid.Columns.Count -gt 0) {
        $recentGrid.Columns["IncidentID"].HeaderText = "Incident ID"
        $recentGrid.Columns["Created"].HeaderText    = "Created"
        $recentGrid.Columns["Status"].HeaderText     = "Status"
        $recentGrid.Columns["Category"].HeaderText   = "Category"
        $recentGrid.Columns["Severity"].HeaderText   = "Severity"
        $recentGrid.Columns["Confidence"].HeaderText = "Confidence"
        $recentGrid.Columns["Decision"].HeaderText   = "Decision"
    }
}

# ============================================================
# ANALYZE INCIDENT PAGE
# ============================================================

$analyze = New-Object System.Windows.Forms.TableLayoutPanel

$analyze.Dock = "Fill"
$analyze.ColumnCount = 1
$analyze.RowCount = 8

$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",70)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",28)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",120)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",28)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",48)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",60)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",35)))
$analyze.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",100)))

$pageAnalyze.Controls.Add($analyze)

$analyzeTitle = New-Object System.Windows.Forms.Label
$analyzeTitle.Text = "Analyze Incident"
$analyzeTitle.Dock = "Fill"
$analyzeTitle.TextAlign = "MiddleLeft"
$analyzeTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    22,
    [System.Drawing.FontStyle]::Bold
)

$analyze.Controls.Add($analyzeTitle,0,0)

$lblPrompt = New-Object System.Windows.Forms.Label
$lblPrompt.Text = "Incident description"
$lblPrompt.Dock = "Fill"
$lblPrompt.ForeColor = $Muted

$analyze.Controls.Add($lblPrompt,0,1)

$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Dock = "Fill"
$txtPrompt.Multiline = $true
$txtPrompt.ScrollBars = "Vertical"
$txtPrompt.BackColor = $CardBG
$txtPrompt.ForeColor = $Text
$txtPrompt.BorderStyle = "FixedSingle"
$txtPrompt.Font = New-Object System.Drawing.Font("Segoe UI",10)

$analyze.Controls.Add($txtPrompt,0,2)

$lblFiles = New-Object System.Windows.Forms.Label
$lblFiles.Text = "Evidence files"
$lblFiles.Dock = "Fill"
$lblFiles.ForeColor = $Muted

$analyze.Controls.Add($lblFiles,0,3)

$fileRow = New-Object System.Windows.Forms.TableLayoutPanel
$fileRow.Dock = "Fill"
$fileRow.ColumnCount = 2
$fileRow.RowCount = 1

$fileRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Percent",100)))
$fileRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle("Absolute",180)))

$txtFiles = New-Object System.Windows.Forms.TextBox
$txtFiles.Dock = "Fill"
$txtFiles.BackColor = $CardBG
$txtFiles.ForeColor = $Text

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse Files"
$btnBrowse.Dock = "Fill"
$btnBrowse.Margin = New-Object System.Windows.Forms.Padding(10,0,0,0)
Style-ActionButton $btnBrowse

$fileRow.Controls.Add($txtFiles,0,0)
$fileRow.Controls.Add($btnBrowse,1,0)

$analyze.Controls.Add($fileRow,0,4)

$actionRow = New-Object System.Windows.Forms.FlowLayoutPanel
$actionRow.Dock = "Fill"
$actionRow.FlowDirection = "LeftToRight"
$actionRow.WrapContents = $false
$actionRow.Padding = New-Object System.Windows.Forms.Padding(0,10,0,0)

$btnFast = New-Object System.Windows.Forms.Button
$btnFast.Text = "Analyze - FAST"
$btnFast.Size = New-Object System.Drawing.Size(190,42)
Style-ActionButton $btnFast
$btnFast.BackColor = [System.Drawing.Color]::FromArgb(8,145,178)

$btnHybrid = New-Object System.Windows.Forms.Button
$btnHybrid.Text = "Analyze - HYBRID AI"
$btnHybrid.Size = New-Object System.Drawing.Size(210,42)
$btnHybrid.Margin = New-Object System.Windows.Forms.Padding(12,0,0,0)
Style-ActionButton $btnHybrid

$actionRow.Controls.Add($btnFast)
$actionRow.Controls.Add($btnHybrid)

$analyze.Controls.Add($actionRow,0,5)

$resultTitle = New-Object System.Windows.Forms.Label
$resultTitle.Text = "Analysis Result"
$resultTitle.Dock = "Fill"
$resultTitle.TextAlign = "BottomLeft"
$resultTitle.ForeColor = $Text
$resultTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    12,
    [System.Drawing.FontStyle]::Bold
)

$analyze.Controls.Add($resultTitle,0,6)

$txtResult = New-Object System.Windows.Forms.RichTextBox
$txtResult.Dock = "Fill"
$txtResult.BackColor = [System.Drawing.Color]::FromArgb(2,8,23)
$txtResult.ForeColor = $Text
$txtResult.BorderStyle = "None"
$txtResult.ReadOnly = $true
$txtResult.Font = New-Object System.Drawing.Font("Consolas",10)

$analyze.Controls.Add($txtResult,0,7)

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog

    $dialog.Title = "Select Network Evidence Files"
    $dialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $dialog.Multiselect = $true

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFiles.Text = $dialog.FileNames -join ";"
    }
})

function Get-SelectedEvidenceFiles {
    $list = @()

    foreach ($file in ($txtFiles.Text -split ";")) {
        $clean = $file.Trim()

        if ($clean -and (Test-Path $clean)) {
            $list += $clean
        }
    }

    return $list
}

$btnFast.Add_Click({

    $txtResult.Text = "Analyzing..."
    $form.Refresh()

    try {

        if ([string]::IsNullOrWhiteSpace($txtPrompt.Text)) {
            $txtResult.Text = "Vendos incident description."
            return
        }

        $desktopPath = [Environment]::GetFolderPath("Desktop")

        $inputFile = Join-Path `
            $desktopPath `
            "GUI-LAST-INPUT.txt"

        $workerFile = $WorkerPath

        # Shkruaj incidentin si ASCII evidence
        [System.IO.File]::WriteAllText(
            $inputFile,
            [string]$txtPrompt.Text,
            [System.Text.Encoding]::ASCII
        )

        if (-not (Test-Path $workerFile)) {

            $txtResult.Text = "ERROR: Network-Engine-Worker.ps1 nuk u gjet."
            return
        }

        # IMPORTANT:
        # powershell.exe eshte proces i RI dhe i izoluar nga WinForms.
        $args = @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            $workerFile
            "-EnginePath"
            $Engine
            "-InputFile"
            $inputFile
            "-Mode"
            "Fast"
        )

        $output = (
            & powershell.exe @args 2>&1 |
            Out-String
        )

        if ([string]::IsNullOrWhiteSpace($output)) {

            $txtResult.Text = "Worker perfundoi pa output."
        }
        else {

            $txtResult.Text = $output

            # NETOPS v5.4 AUTO-SAVE
            if (
                (Get-Command Save-NetOpsIncident -ErrorAction SilentlyContinue) -and
                $output -match '(?im)^FINDINGS:\s*[1-9]'
            ) {
                try {
                    $script:CurrentIncident = Save-NetOpsIncident `
                        -Description $txtPrompt.Text `
                        -Analysis $output `
                        -Status "Open"

                    $txtResult.AppendText(
                        "`r`n`r`n[AUTO-SAVED] Incident ID: $($script:CurrentIncident.IncidentID)"
                    )
                }
                catch {
                    $txtResult.AppendText(
                        "`r`nAUTO-SAVE ERROR: $($_.Exception.Message)"
                    )
                }
            }
        }
    }
    catch {

        $txtResult.Text = @"
GUI / WORKER ERROR

$($_.Exception.Message)
"@
    }
})
$btnHybrid.Add_Click({

    try {

        $txtResult.Clear()

        $txtResult.AppendText(
            "NETOPS HYBRID AI ANALYSIS`r`n" +
            "============================================================`r`n" +
            "Status: Connecting to local AI...`r`n"
        )

        [System.Windows.Forms.Application]::DoEvents()

        $incidentText = $txtPrompt.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($incidentText)) {

            [System.Windows.Forms.MessageBox]::Show(
                "Enter an incident description first.",
                "NETOPS HYBRID AI"
            )

            return
        }

        $evidenceText = "No evidence files supplied."

        $evidencePath = $txtFiles.Text.Trim()

        if (-not [string]::IsNullOrWhiteSpace($evidencePath)) {

            $evidenceParts = $evidencePath -split '[;|]'

            $evidenceBuffer = New-Object System.Text.StringBuilder

            foreach ($item in $evidenceParts) {

                $item = $item.Trim().Trim('"')

                if (Test-Path $item) {

                    try {

                        $fileContent = Get-Content `
                            -Path $item `
                            -Raw `
                            -ErrorAction Stop

                        [void]$evidenceBuffer.AppendLine("")
                        [void]$evidenceBuffer.AppendLine("EVIDENCE FILE:")
                        [void]$evidenceBuffer.AppendLine($item)
                        [void]$evidenceBuffer.AppendLine("------------------------------------------------------------")
                        [void]$evidenceBuffer.AppendLine($fileContent)

                    }
                    catch {

                        [void]$evidenceBuffer.AppendLine(
                            "Could not read evidence file: $item"
                        )
                    }
                }
            }

            if ($evidenceBuffer.Length -gt 0) {
                $evidenceText = $evidenceBuffer.ToString()
            }
        }

        $promptLines = @(
            "You are NETOPS Hybrid AI.",
            "Act as a Senior Network Engineer and NOC escalation engineer.",
            "",
            "Analyze the incident using only the information provided.",
            "",
            "RULES:",
            "1. Do not invent IP addresses, VLAN IDs, interfaces or device names.",
            "2. Separate confirmed facts from assumptions.",
            "3. If evidence is insufficient, clearly state that.",
            "4. Prefer diagnostic commands before configuration changes.",
            "5. Use professional Cisco IOS troubleshooting methodology.",
            "",
            "Return these sections:",
            "NETOPS HYBRID AI ANALYSIS",
            "INCIDENT CLASSIFICATION",
            "SEVERITY",
            "CONFIDENCE",
            "INCIDENT SUMMARY",
            "EVIDENCE FINDINGS",
            "LIKELY ROOT CAUSE",
            "RECOMMENDED TROUBLESHOOTING",
            "RECOMMENDED COMMANDS",
            "VERIFICATION",
            "INCIDENT CLOSURE NOTE",
            "",
            "============================================================",
            "INCIDENT DESCRIPTION",
            "============================================================",
            $incidentText,
            "",
            "============================================================",
            "EVIDENCE",
            "============================================================",
            $evidenceText
        )

        # ======================================================

        # NETOPS_FAST_AI_FUSION_V2

        # Deterministic FAST Engine -> Ollama Hybrid Analysis

        # ======================================================


        $fastStatus   = "NOT RUN"

        $fastFindings = ""


        try {


            $fastEnginePath = 'C:\Users\Acer\Documents\GitHub\Driton-Network-Engineering-Portfolio\09-AI-Network-Troubleshooting-Platform\src\AI-Offline.ps1'

            $fastEvidence = @()


            if (

                -not [string]::IsNullOrWhiteSpace($evidencePath)

            ) {


                foreach ($fastFile in ($evidencePath -split '[;|]')) {


                    $fastFile = $fastFile.Trim().Trim('"')


                    if (

                        -not [string]::IsNullOrWhiteSpace($fastFile) -and

                        (Test-Path $fastFile)

                    ) {


                        $fastEvidence += $fastFile

                    }

                }

            }


            if ($fastEvidence.Count -gt 0) {


                $fastArgs = @{
    Prompt = $incidentText
    Engine = "Fast"
}

if ($fastEvidence.Count -gt 0) {
    $fastArgs["FilePath"] = $fastEvidence
}

$fastOutput = & $fastEnginePath @fastArgs 2>&1 | Out-String


            }

            else {


                $fastArgs = @{
    Prompt = $incidentText
    Engine = "Fast"
}

if ($fastEvidence.Count -gt 0) {
    $fastArgs["FilePath"] = $fastEvidence
}

$fastOutput = & $fastEnginePath @fastArgs 2>&1 | Out-String

            }


            if ([string]::IsNullOrWhiteSpace($fastOutput)) {


                $fastStatus = "NO DETERMINISTIC FINDINGS"


                $fastFindings = @(

                    "FAST Engine returned no confirmed findings.",

                    "Do not treat missing findings as proof that the network is healthy."

                ) -join "`n"


            }

            else {


                $fastStatus = "COMPLETED"

                $fastFindings = $fastOutput.Trim()

            }


        }

        catch {


            $fastStatus = "ERROR"


            $fastFindings = @(

                "FAST Engine encountered an error.",

                $_.Exception.Message,

                "Do not treat this error as network evidence."

            ) -join "`n"

        }


        $fullPrompt = $promptLines -join "`n"



        $hybridContext = @(

            "",

            "============================================================",

            "NETOPS FAST ENGINE - DETERMINISTIC ANALYSIS",

            "============================================================",

            "FAST STATUS: $fastStatus",

            "",

            $fastFindings,

            "",

            "============================================================",

            "HYBRID DECISION POLICY",

            "============================================================",

            "FAST Engine is the deterministic validation layer.",

            "Ollama is the interpretation and reporting layer.",

            "",

            "When explicit incident data proves a mismatch, treat it as confirmed.",

            "Example: endpoint VLAN 10 and access port VLAN 1 means VLAN mismatch.",

            "",

            "Do not downgrade explicit deterministic mismatches to vague possibilities.",

            "Do not claim that a fix was completed unless verification confirms recovery.",

            "Proposed remediation is not the same as incident resolution.",

            "Never invent missing evidence.",

            "",

            "For confirmed mismatches, explain the exact expected and observed values.",
"",
"============================================================",
"NETOPS_EVIDENCE_CONFIDENCE_POLICY_V1",
"============================================================",
"EVIDENCE CONFIDENCE RULES:",
"",
"1. CLI output from show commands is direct technical evidence.",
"",
"2. If show vlan brief explicitly places an interface in VLAN X,",
"   that observed VLAN assignment is CONFIRMED evidence.",
"",
"3. If show interfaces <interface> switchport explicitly reports",
"   Access Mode VLAN: X, that access VLAN is CONFIRMED evidence.",
"",
"4. When the incident states the expected VLAN and CLI evidence",
"   proves a different observed VLAN on the connected access port,",
"   classify the fault as a CONFIRMED ACCESS VLAN MISMATCH.",
"",
"5. Example:",
"   Expected: PC1 / Fa0/2 -> VLAN 10",
"   Observed by CLI: Fa0/2 -> VLAN 1",
"   Decision: CONFIRMED VLAN MISMATCH",
"   Confidence: HIGH",
"",
"6. Do NOT say 'insufficient evidence' when two independent CLI",
"   outputs directly prove the same configuration state.",
"",
"7. Do NOT claim connectivity is restored until a post-fix ping",
"   or equivalent verification succeeds.",
"",
"8. Distinguish these two states:",
"   ROOT CAUSE CONFIRMED = configuration evidence proves the fault.",
"   INCIDENT RESOLVED = post-fix verification proves recovery.",
"",
"9. A confirmed root cause may have HIGH confidence even when",
"   the incident is not yet resolved.",
"",
"10. Prefer these confidence labels:",
"    HIGH / CONFIRMED BY EVIDENCE",
"    MEDIUM / PROBABLE",
"    LOW / INSUFFICIENT EVIDENCE"

        ) -join "`n"


        $fullPrompt = $fullPrompt + "`n" + $hybridContext

        $bodyObject = @{
            model  = "llama3.2:3b"
            prompt = $fullPrompt
            stream = $false
            options = @{
                temperature = 0.15
            }
        }

        $jsonBody = $bodyObject | ConvertTo-Json -Depth 6

        $txtResult.Clear()

        $txtResult.AppendText(
            "NETOPS HYBRID AI`r`n" +
            "============================================================`r`n" +
            "Analyzing with llama3.2:3b ...`r`n`r`n"
        )

        [System.Windows.Forms.Application]::DoEvents()

        $aiResponse = Invoke-RestMethod `
            -Uri "http://127.0.0.1:11434/api/generate" `
            -Method Post `
            -ContentType "application/json" `
            -Body $jsonBody `
            -TimeoutSec 180

        if (
            $null -eq $aiResponse -or
            [string]::IsNullOrWhiteSpace($aiResponse.response)
        ) {
            throw "Ollama returned an empty response."
        }

        $txtResult.Clear()

        $txtResult.AppendText(
            $aiResponse.response.Trim()
        )

        $txtResult.AppendText(
            "`r`n`r`n============================================================`r`n" +
            "Engine: NETOPS HYBRID AI`r`n" +
            "Model: llama3.2:3b`r`n" +
            "AI: Local Ollama`r`n"
        )

    }
    catch {

        $txtResult.Clear()

        $txtResult.AppendText(
            "NETOPS HYBRID AI ERROR`r`n" +
            "============================================================`r`n`r`n" +
            $_.Exception.Message +
            "`r`n`r`nFAST Engine remains available."
        )
    }

})

# ============================================================
# INCIDENT HISTORY PAGE
# ============================================================

$historyLayout = New-Object System.Windows.Forms.TableLayoutPanel

$historyLayout.Dock = "Fill"
$historyLayout.ColumnCount = 1
$historyLayout.RowCount = 4

$historyLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",75)))
$historyLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",62)))
$historyLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",38)))
$historyLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",65)))

$pageHistory.Controls.Add($historyLayout)

$historyTitle = New-Object System.Windows.Forms.Label
$historyTitle.Text = "Incident History"
$historyTitle.Dock = "Fill"
$historyTitle.TextAlign = "MiddleLeft"
$historyTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    22,
    [System.Drawing.FontStyle]::Bold
)

$historyLayout.Controls.Add($historyTitle,0,0)

$historyGrid = New-Object System.Windows.Forms.DataGridView
$historyGrid.Dock = "Fill"
Style-Grid $historyGrid

$historyLayout.Controls.Add($historyGrid,0,1)

# ============================================================
# INCIDENT DETAILS PANEL - v5.6
# ============================================================

$historyDetailsPanel = New-Object System.Windows.Forms.Panel
$historyDetailsPanel.Dock = "Fill"
$historyDetailsPanel.BackColor = $CardBG
$historyDetailsPanel.Padding = New-Object System.Windows.Forms.Padding(12)

$historyDetailsTitle = New-Object System.Windows.Forms.Label
$historyDetailsTitle.Text = "Incident Details"
$historyDetailsTitle.Dock = "Top"
$historyDetailsTitle.Height = 32
$historyDetailsTitle.ForeColor = $Text
$historyDetailsTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    12,
    [System.Drawing.FontStyle]::Bold
)

$historyDetailsBox = New-Object System.Windows.Forms.RichTextBox
$historyDetailsBox.Dock = "Fill"
$historyDetailsBox.BackColor = [System.Drawing.Color]::FromArgb(2,8,23)
$historyDetailsBox.ForeColor = $Text
$historyDetailsBox.BorderStyle = "None"
$historyDetailsBox.ReadOnly = $true
$historyDetailsBox.Font = New-Object System.Drawing.Font("Consolas",10)
$historyDetailsBox.Text = "Select an incident to view details."

$historyDetailsPanel.Controls.Add($historyDetailsBox)
$historyDetailsPanel.Controls.Add($historyDetailsTitle)

$historyLayout.Controls.Add($historyDetailsPanel,0,2)

$historyActions = New-Object System.Windows.Forms.FlowLayoutPanel
$historyActions.Dock = "Fill"
$historyActions.Padding = New-Object System.Windows.Forms.Padding(0,10,0,0)

$btnRefreshHistory = New-Object System.Windows.Forms.Button
$btnRefreshHistory.Text = "Refresh"
$btnRefreshHistory.Size = New-Object System.Drawing.Size(140,42)
Style-ActionButton $btnRefreshHistory

$btnOpenReport = New-Object System.Windows.Forms.Button
$btnOpenReport.Text = "Open Report"
$btnOpenReport.Size = New-Object System.Drawing.Size(160,42)
$btnOpenReport.Margin = New-Object System.Windows.Forms.Padding(12,0,0,0)
Style-ActionButton $btnOpenReport

$btnResolveIncident = New-Object System.Windows.Forms.Button
$btnResolveIncident.Text = "Mark Resolved"
$btnResolveIncident.Size = New-Object System.Drawing.Size(160,42)
$btnResolveIncident.Margin = New-Object System.Windows.Forms.Padding(12,0,0,0)
Style-ActionButton $btnResolveIncident

$btnOpenIncidentFolder = New-Object System.Windows.Forms.Button
$btnOpenIncidentFolder.Text = "Open Incident Folder"
$btnOpenIncidentFolder.Size = New-Object System.Drawing.Size(185,42)
$btnOpenIncidentFolder.Margin = New-Object System.Windows.Forms.Padding(12,0,0,0)
Style-ActionButton $btnOpenIncidentFolder

$historyActions.Controls.Add($btnRefreshHistory)
$historyActions.Controls.Add($btnOpenReport)
$historyActions.Controls.Add($btnResolveIncident)
$historyActions.Controls.Add($btnOpenIncidentFolder)

$historyLayout.Controls.Add($historyActions,0,3)

function Show-HistoryIncidentDetails {

    if ($historyGrid.SelectedRows.Count -eq 0) {

        $historyDetailsBox.Text = "Select an incident to view details."
        $btnResolveIncident.Enabled = $false

        return
    }

    if (-not $historyGrid.Columns.Contains("IncidentID")) {
        return
    }

    $incidentId = [string]$historyGrid.SelectedRows[0].Cells["IncidentID"].Value
    $status = ""

    if ($historyGrid.Columns.Contains("Status")) {
        $status = [string]$historyGrid.SelectedRows[0].Cells["Status"].Value
    }

    # Disable Resolve when already resolved/closed
    if (
        $status -eq "Resolved" -or
        $status -eq "Closed"
    ) {

        $btnResolveIncident.Enabled = $false
        $btnResolveIncident.Text = "Already Resolved"
    }
    else {

        $btnResolveIncident.Enabled = $true
        $btnResolveIncident.Text = "Mark Resolved"
    }

    if ([string]::IsNullOrWhiteSpace($incidentId)) {
        return
    }

    $incident = $null

    if (Get-Command Get-NetOpsIncident -ErrorAction SilentlyContinue) {

        try {
            $incident = Get-NetOpsIncident -IncidentID $incidentId
        }
        catch {
            $incident = $null
        }
    }

    if ($incident) {

        $description = [string]$incident.Description
        $rootCause = [string]$incident.RootCause
        $nextStep = [string]$incident.SmartNextStep
        $notes = [string]$incident.Notes
        $decision = [string]$incident.Decision
        $confidence = [string]$incident.Confidence
        $category = [string]$incident.Category
        $severity = [string]$incident.Severity
        $incidentStatus = [string]$incident.Status

        $reportPath = Join-Path `
            (Join-Path `
                (Join-Path (Split-Path $PSScriptRoot) "data\Incidents") `
                $incidentId
            ) `
            "incident-report.md"

        $historyDetailsBox.Text = @"
INCIDENT ID
$incidentId

STATUS
$incidentStatus

CATEGORY
$category

SEVERITY
$severity

CONFIDENCE
$confidence%

DECISION
$decision

DESCRIPTION
$description

ROOT CAUSE
$rootCause

SMART NEXT STEP
$nextStep

RESOLUTION NOTES
$notes

REPORT
$reportPath
"@
    }
    else {

        $historyDetailsBox.Text = @"
INCIDENT ID
$incidentId

STATUS
$status

Incident JSON could not be loaded.
Use Open Incident Folder to inspect the saved files.
"@
    }
}


function Refresh-History {

    $historyFile = Join-Path `
        (Split-Path $PSScriptRoot) `
        "data\Incident-History.csv"

    $historyGrid.DataSource = $null

    if (-not (Test-Path $historyFile)) {
        return
    }

    $rows = @(
        Import-Csv $historyFile |
        Where-Object { $_.IncidentID } |
        Sort-Object Updated -Descending
    )

    if ($rows.Count -gt 0) {

        $table = New-Object System.Data.DataTable

        foreach ($column in @(
            "IncidentID",
            "Created",
            "Updated",
            "Title",
            "Category",
            "Severity",
            "Status",
            "Findings",
            "Confidence",
            "Decision",
            "RootCause",
            "ReportPath"
        )) {
            [void]$table.Columns.Add($column)
        }

        foreach ($item in $rows) {

            $row = $table.NewRow()

            foreach ($column in $table.Columns.ColumnName) {
                $row[$column] = [string]$item.$column
            }

            [void]$table.Rows.Add($row)
        }

        $historyGrid.DataSource = $table
    }
}

$btnResolveIncident.Add_Click({

    if ($historyGrid.SelectedRows.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "Select an incident first.",
            "NETOPS v5.5"
        )

        return
    }

    if (-not $historyGrid.Columns.Contains("IncidentID")) {

        [System.Windows.Forms.MessageBox]::Show(
            "IncidentID column is missing.",
            "NETOPS v5.5"
        )

        return
    }

    $incidentId = [string]$historyGrid.SelectedRows[0].Cells["IncidentID"].Value

    if ([string]::IsNullOrWhiteSpace($incidentId)) {
        return
    }

    $notes = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Write resolution notes / verification performed:",
        "Resolve Incident",
        "Issue fixed and connectivity verified."
    )

    if (-not (Get-Command Set-NetOpsIncidentStatus -ErrorAction SilentlyContinue)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Incident Manager status function is not available.",
            "NETOPS v5.5"
        )

        return
    }

    try {

        Set-NetOpsIncidentStatus `
            -IncidentID $incidentId `
            -Status "Resolved" `
            -Notes $notes

        Refresh-History
        Refresh-Dashboard
        Show-HistoryIncidentDetails

        [System.Windows.Forms.MessageBox]::Show(
            "$incidentId marked RESOLVED.",
            "NETOPS v5.5"
        )
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Resolution Error"
        )
    }
})


$btnOpenIncidentFolder.Add_Click({

    if ($historyGrid.SelectedRows.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "Select an incident first.",
            "NETOPS v5.5"
        )

        return
    }

    if (-not $historyGrid.Columns.Contains("IncidentID")) {
        return
    }

    $incidentId = [string]$historyGrid.SelectedRows[0].Cells["IncidentID"].Value

    if (-not $incidentId) {
        return
    }

    $incidentFolder = Join-Path `
        (Join-Path (Split-Path $PSScriptRoot) "data\Incidents") `
        $incidentId

    if (Test-Path $incidentFolder) {
        Start-Process explorer.exe $incidentFolder
    }
    else {

        [System.Windows.Forms.MessageBox]::Show(
            "Incident folder was not found.",
            "NETOPS v5.5"
        )
    }
})


$historyGrid.Add_SelectionChanged({

    try {
        Show-HistoryIncidentDetails
    }
    catch {
        $historyDetailsBox.Text = "Details error: $($_.Exception.Message)"
    }
})


$btnOpenReport.Add_Click({
    if ($historyGrid.SelectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Select an incident first.",
            "Network Troubleshooter"
        )
        return
    }

    if (-not $historyGrid.Columns.Contains("ReportPath")) {
        [System.Windows.Forms.MessageBox]::Show(
            "ReportPath column is missing.",
            "Network Troubleshooter"
        )
        return
    }

    $path = [string]$historyGrid.SelectedRows[0].Cells["ReportPath"].Value

    if ($path -and (Test-Path $path)) {
        Start-Process notepad.exe -ArgumentList "`"$path`""
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Report file was not found.",
            "Network Troubleshooter"
        )
    }
})

# ============================================================
# SYSTEM STATUS PAGE
# ============================================================

$systemLayout = New-Object System.Windows.Forms.TableLayoutPanel

$systemLayout.Dock = "Fill"
$systemLayout.ColumnCount = 1
$systemLayout.RowCount = 3

$systemLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",75)))
$systemLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Percent",100)))
$systemLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle("Absolute",65)))

$pageSystem.Controls.Add($systemLayout)

$systemTitle = New-Object System.Windows.Forms.Label
$systemTitle.Text = "System Status"
$systemTitle.Dock = "Fill"
$systemTitle.TextAlign = "MiddleLeft"
$systemTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    22,
    [System.Drawing.FontStyle]::Bold
)

$systemLayout.Controls.Add($systemTitle,0,0)

$systemBox = New-Object System.Windows.Forms.RichTextBox
$systemBox.Dock = "Fill"
$systemBox.BackColor = [System.Drawing.Color]::FromArgb(2,8,23)
$systemBox.ForeColor = $Text
$systemBox.ReadOnly = $true
$systemBox.BorderStyle = "None"
$systemBox.Font = New-Object System.Drawing.Font("Consolas",10)

$systemLayout.Controls.Add($systemBox,0,1)

$systemActions = New-Object System.Windows.Forms.FlowLayoutPanel
$systemActions.Dock = "Fill"
$systemActions.Padding = New-Object System.Windows.Forms.Padding(0,10,0,0)

$btnRefreshSystem = New-Object System.Windows.Forms.Button
$btnRefreshSystem.Text = "Refresh Status"
$btnRefreshSystem.Size = New-Object System.Drawing.Size(170,42)
Style-ActionButton $btnRefreshSystem

$systemActions.Controls.Add($btnRefreshSystem)

$systemLayout.Controls.Add($systemActions,0,2)

function Refresh-SystemStatus {
    $lines = @()

    $lines += "NETWORK TROUBLESHOOTER v5.5"
    $lines += ""

    $lines += "Troubleshooting Engine:"
    $lines += $Engine
    $lines += $(if (Test-Path $Engine) { "STATUS: READY" } else { "STATUS: NOT FOUND" })

    $lines += ""
    $lines += "Guided Workflow:"
    $lines += $Workflow
    $lines += $(if (Test-Path $Workflow) { "STATUS: READY" } else { "STATUS: NOT FOUND" })

    $lines += ""
    $lines += "Incident Reports:"
    $lines += $Reports

    $reportCount = @(
        Get-ChildItem `
            -Path $Reports `
            -Filter "INC-*.txt" `
            -ErrorAction SilentlyContinue
    ).Count

    $lines += "Reports Found: $reportCount"

    $lines += ""
    $lines += "Incident History:"
    $lines += $History
    $lines += $(if (Test-Path $History) { "STATUS: READY" } else { "STATUS: NOT FOUND" })

    $lines += ""
    $lines += "Ollama:"

    try {
        $lines += (ollama --version | Out-String).Trim()
        $lines += "STATUS: READY"
        $lines += ""
        $lines += "Installed Models:"
        $lines += (ollama list | Out-String)
    }
    catch {
        $lines += "STATUS: NOT READY"
    }

    $systemBox.Text = $lines -join "`r`n"
}

# ============================================================
# EVENTS
# ============================================================

$btnDashboard.Add_Click({
    Show-Page $pageDashboard
    Refresh-Dashboard
})

$btnAnalyze.Add_Click({
    Show-Page $pageAnalyze
})

$btnHistory.Add_Click({
    Show-Page $pageHistory
    Refresh-History
})

$btnSystem.Add_Click({
    Show-Page $pageSystem
    Refresh-SystemStatus
})

$btnWorkflow.Add_Click({
    if (Test-Path $Workflow) {
        Start-Process `
            powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Workflow`""
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Network-Troubleshooter-v4.2.ps1 nuk u gjet.",
            "Network Troubleshooter"
        )
    }
})

$btnRefreshDash.Add_Click({
    Refresh-Dashboard
})

$btnRefreshHistory.Add_Click({
    Refresh-History
})

$btnRefreshSystem.Add_Click({
    Refresh-SystemStatus
})

# ============================================================
# INITIAL LOAD
# ============================================================

$form.Add_Shown({
    Show-Page $pageDashboard
    Refresh-Dashboard
})


# ============================================================
# NETOPS v5.8 DASHBOARD LIVE REFRESH FIX
# ============================================================

$btnRefreshDash.Add_Click({
    Refresh-Dashboard
})

$btnDashboard.Add_Click({
    Show-Page $pageDashboard
    Refresh-Dashboard
})

$form.Add_Shown({
    Refresh-Dashboard
})

# ============================================================
# NETOPS_NETWORK_TOOLS_LAUNCHER_V1
# ============================================================


# ============================================================
# NETOPS_TOPOLOGY_LINKS_V1
# ============================================================

function Show-NetOpsTopologyViewV2 {

    $netopsDir = Join-Path $env:USERPROFILE "Documents\NETOPS"
    $inventoryFile = Join-Path $netopsDir "devices.csv"
    $linksFile = Join-Path $netopsDir "links.csv"

    if (-not (Test-Path $netopsDir)) {
        New-Item -Path $netopsDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $inventoryFile)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Device Inventory was not found.",
            "NETOPS Topology"
        )

        return
    }

    if (-not (Test-Path $linksFile)) {

        @(
            [PSCustomObject]@{
                SourceDevice      = "R-HQ-01"
                SourcePort        = "G0/0"
                DestinationDevice = "SW-CORE-01"
                DestinationPort   = "G0/1"
                LinkType          = "Ethernet"
                Status            = "Up"
            }

            [PSCustomObject]@{
                SourceDevice      = "SW-CORE-01"
                SourcePort        = "G0/2"
                DestinationDevice = "SW-ACCESS-01"
                DestinationPort   = "G0/1"
                LinkType          = "Trunk"
                Status            = "Up"
            }
        ) |
        Export-Csv `
            -Path $linksFile `
            -NoTypeInformation `
            -Encoding UTF8
    }

    # ========================================================
    # THEME
    # ========================================================

    $Bg       = [System.Drawing.Color]::FromArgb(14,25,42)
    $Panel    = [System.Drawing.Color]::FromArgb(28,43,64)
    $Panel2   = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text     = [System.Drawing.Color]::White
    $Muted    = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent   = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green    = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red      = [System.Drawing.Color]::FromArgb(255,85,85)
    $Yellow   = [System.Drawing.Color]::FromArgb(255,210,50)

    # ========================================================
    # FORM
    # ========================================================

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "NETOPS - Topology View PRO"
    $f.Size = New-Object System.Drawing.Size(1320,820)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $Bg
    $f.ForeColor = $Text
    $f.MinimumSize = New-Object System.Drawing.Size(1100,700)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "NETWORK TOPOLOGY"
    $title.Location = New-Object System.Drawing.Point(25,20)
    $title.Size = New-Object System.Drawing.Size(500,35)
    $title.ForeColor = $Accent
    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )
    $f.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = "Devices + physical/logical links"
    $sub.Location = New-Object System.Drawing.Point(27,58)
    $sub.Size = New-Object System.Drawing.Size(600,25)
    $sub.ForeColor = $Muted
    $f.Controls.Add($sub)

    # ========================================================
    # TOOLBAR
    # ========================================================

    function New-TopoButton {

        param(
            [string]$Caption,
            [int]$X,
            [int]$Width
        )

        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Caption
        $b.Location = New-Object System.Drawing.Point($X,95)
        $b.Size = New-Object System.Drawing.Size($Width,36)
        $b.FlatStyle = "Flat"
        $b.BackColor = $Panel
        $b.ForeColor = $Text

        return $b
    }

    $btnRefresh = New-TopoButton "REFRESH" 25 120
    $f.Controls.Add($btnRefresh)

    $btnAll = New-TopoButton "SHOW ALL" 155 120
    $f.Controls.Add($btnAll)

    $btnOnline = New-TopoButton "ONLINE ONLY" 285 140
    $f.Controls.Add($btnOnline)

    $btnAddLink = New-TopoButton "ADD LINK" 435 120
    $f.Controls.Add($btnAddLink)

    $btnEditLink = New-TopoButton "EDIT LINK" 565 120
    $f.Controls.Add($btnEditLink)

    $btnDeleteLink = New-TopoButton "DELETE LINK" 695 130
    $f.Controls.Add($btnDeleteLink)

    $btnInventory = New-TopoButton "DEVICE INVENTORY" 835 175
    $f.Controls.Add($btnInventory)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(1030,102)
    $lblStatus.Size = New-Object System.Drawing.Size(240,30)
    $lblStatus.ForeColor = $Muted
    $f.Controls.Add($lblStatus)

    # ========================================================
    # CANVAS
    # ========================================================

    $canvas = New-Object System.Windows.Forms.Panel
    $canvas.Location = New-Object System.Drawing.Point(25,150)
    $canvas.Size = New-Object System.Drawing.Size(1245,500)
    $canvas.BackColor = $Panel2
    $canvas.BorderStyle = "FixedSingle"
    $canvas.AutoScroll = $true

    $f.Controls.Add($canvas)

    # ========================================================
    # LINK GRID
    # ========================================================

    $gridLinks = New-Object System.Windows.Forms.DataGridView
    $gridLinks.Location = New-Object System.Drawing.Point(25,670)
    $gridLinks.Size = New-Object System.Drawing.Size(1245,90)
    $gridLinks.ReadOnly = $true
    $gridLinks.AllowUserToAddRows = $false
    $gridLinks.AllowUserToDeleteRows = $false
    $gridLinks.RowHeadersVisible = $false
    $gridLinks.SelectionMode = "FullRowSelect"
    $gridLinks.MultiSelect = $false
    $gridLinks.AutoSizeColumnsMode = "Fill"

    $gridLinks.EnableHeadersVisualStyles = $false
    $gridLinks.BackgroundColor = $Panel2
    $gridLinks.ColumnHeadersDefaultCellStyle.BackColor = $Panel
    $gridLinks.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $gridLinks.DefaultCellStyle.BackColor = $Panel2
    $gridLinks.DefaultCellStyle.ForeColor = $Text
    $gridLinks.DefaultCellStyle.SelectionBackColor = $Panel
    $gridLinks.DefaultCellStyle.SelectionForeColor = $Accent

    $f.Controls.Add($gridLinks)

    $script:TopoOnlineOnly = $false

    # ========================================================
    # DATA FUNCTIONS
    # ========================================================

    function LoadDevices {

        $rows = @(Import-Csv $inventoryFile)

        $result = @()

        foreach ($r in $rows) {

            $ip = ""

            if ($r.PSObject.Properties["ManagementIP"]) {
                $ip = [string]$r.ManagementIP
            }
            elseif ($r.PSObject.Properties["IP"]) {
                $ip = [string]$r.IP
            }

            $site = "UNASSIGNED"

            if (-not [string]::IsNullOrWhiteSpace([string]$r.Site)) {
                $site = [string]$r.Site
            }

            $status = "Unknown"

            if (-not [string]::IsNullOrWhiteSpace([string]$r.Status)) {
                $status = [string]$r.Status
            }

            $result += [PSCustomObject]@{
                DeviceName   = [string]$r.DeviceName
                Type         = [string]$r.Type
                ManagementIP = $ip
                Site         = $site
                Status       = $status
            }
        }

        return @($result)
    }


    function LoadLinks {

        return @(
            Import-Csv `
                -Path $linksFile `
                -ErrorAction SilentlyContinue
        )
    }


    function SaveLinks {

        param(
            [array]$Links
        )

        $Links |
            Select-Object `
                SourceDevice,
                SourcePort,
                DestinationDevice,
                DestinationPort,
                LinkType,
                Status |
            Export-Csv `
                -Path $linksFile `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ========================================================
    # LINK EDITOR
    # ========================================================

    function Open-LinkEditor {

        param(
            $Existing
        )

        $editing = ($null -ne $Existing)

        $e = New-Object System.Windows.Forms.Form
        $e.Size = New-Object System.Drawing.Size(560,520)
        $e.StartPosition = "CenterParent"
        $e.BackColor = $Bg
        $e.ForeColor = $Text
        $e.FormBorderStyle = "FixedDialog"
        $e.MaximizeBox = $false

        if ($editing) {
            $e.Text = "NETOPS - Edit Link"
        }
        else {
            $e.Text = "NETOPS - Add Link"
        }

        $labels = @(
            "Source Device",
            "Source Port",
            "Destination Device",
            "Destination Port",
            "Link Type",
            "Status"
        )

        $y = 35

        foreach ($caption in $labels) {

            $l = New-Object System.Windows.Forms.Label
            $l.Text = $caption
            $l.Location = New-Object System.Drawing.Point(30,$y)
            $l.Size = New-Object System.Drawing.Size(180,25)
            $l.ForeColor = $Muted
            $e.Controls.Add($l)

            $y += 60
        }

        $devices = @(LoadDevices)
        $deviceNames = @($devices | ForEach-Object { $_.DeviceName })

        $srcDevice = New-Object System.Windows.Forms.ComboBox
        $srcDevice.Location = New-Object System.Drawing.Point(220,32)
        $srcDevice.Size = New-Object System.Drawing.Size(280,28)
        $srcDevice.DropDownStyle = "DropDownList"
        [void]$srcDevice.Items.AddRange($deviceNames)
        $e.Controls.Add($srcDevice)

        $srcPort = New-Object System.Windows.Forms.TextBox
        $srcPort.Location = New-Object System.Drawing.Point(220,92)
        $srcPort.Size = New-Object System.Drawing.Size(280,28)
        $e.Controls.Add($srcPort)

        $dstDevice = New-Object System.Windows.Forms.ComboBox
        $dstDevice.Location = New-Object System.Drawing.Point(220,152)
        $dstDevice.Size = New-Object System.Drawing.Size(280,28)
        $dstDevice.DropDownStyle = "DropDownList"
        [void]$dstDevice.Items.AddRange($deviceNames)
        $e.Controls.Add($dstDevice)

        $dstPort = New-Object System.Windows.Forms.TextBox
        $dstPort.Location = New-Object System.Drawing.Point(220,212)
        $dstPort.Size = New-Object System.Drawing.Size(280,28)
        $e.Controls.Add($dstPort)

        $linkType = New-Object System.Windows.Forms.ComboBox
        $linkType.Location = New-Object System.Drawing.Point(220,272)
        $linkType.Size = New-Object System.Drawing.Size(280,28)
        [void]$linkType.Items.AddRange(@(
            "Ethernet",
            "Trunk",
            "Routed",
            "VPN",
            "Tunnel",
            "Wireless",
            "Other"
        ))
        $e.Controls.Add($linkType)

        $linkStatus = New-Object System.Windows.Forms.ComboBox
        $linkStatus.Location = New-Object System.Drawing.Point(220,332)
        $linkStatus.Size = New-Object System.Drawing.Size(280,28)
        $linkStatus.DropDownStyle = "DropDownList"
        [void]$linkStatus.Items.AddRange(@(
            "Up",
            "Down",
            "Unknown"
        ))
        $e.Controls.Add($linkStatus)

        if ($editing) {

            $srcDevice.Text = $Existing.SourceDevice
            $srcPort.Text = $Existing.SourcePort
            $dstDevice.Text = $Existing.DestinationDevice
            $dstPort.Text = $Existing.DestinationPort
            $linkType.Text = $Existing.LinkType
            $linkStatus.Text = $Existing.Status

        }
        else {

            if ($srcDevice.Items.Count -gt 0) {
                $srcDevice.SelectedIndex = 0
            }

            if ($dstDevice.Items.Count -gt 1) {
                $dstDevice.SelectedIndex = 1
            }

            $linkType.Text = "Ethernet"
            $linkStatus.SelectedIndex = 0
        }

        $save = New-Object System.Windows.Forms.Button
        $save.Text = "SAVE LINK"
        $save.Location = New-Object System.Drawing.Point(220,400)
        $save.Size = New-Object System.Drawing.Size(150,40)
        $save.FlatStyle = "Flat"
        $save.BackColor = $Panel
        $save.ForeColor = $Text
        $e.Controls.Add($save)

        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "CANCEL"
        $cancel.Location = New-Object System.Drawing.Point(380,400)
        $cancel.Size = New-Object System.Drawing.Size(120,40)
        $cancel.FlatStyle = "Flat"
        $cancel.BackColor = $Panel
        $cancel.ForeColor = $Text
        $e.Controls.Add($cancel)

        $cancel.Add_Click({

            $e.DialogResult =
                [System.Windows.Forms.DialogResult]::Cancel

            $e.Close()
        })

        $save.Add_Click({

            if (
                $null -eq $srcDevice.SelectedItem -or
                $null -eq $dstDevice.SelectedItem
            ) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Select source and destination devices."
                )

                return
            }

            if (
                $srcDevice.Text -eq
                $dstDevice.Text
            ) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Source and destination cannot be the same device."
                )

                return
            }

            $e.Tag = [PSCustomObject]@{
                SourceDevice      = $srcDevice.Text
                SourcePort        = $srcPort.Text.Trim()
                DestinationDevice = $dstDevice.Text
                DestinationPort   = $dstPort.Text.Trim()
                LinkType          = $linkType.Text
                Status            = $linkStatus.Text
            }

            $e.DialogResult =
                [System.Windows.Forms.DialogResult]::OK

            $e.Close()
        })

        $r = $e.ShowDialog($f)

        if (
            $r -eq
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return $e.Tag
        }

        return $null
    }

    # ========================================================
    # DRAW DEVICE CARD
    # ========================================================

    function New-Card {

        param(
            $Device,
            [int]$X,
            [int]$Y
        )

        $card = New-Object System.Windows.Forms.Panel
        $card.Location = New-Object System.Drawing.Point($X,$Y)
        $card.Size = New-Object System.Drawing.Size(240,120)
        $card.BackColor = $Panel
        $card.BorderStyle = "FixedSingle"

        $name = New-Object System.Windows.Forms.Label
        $name.Text = $Device.DeviceName
        $name.Location = New-Object System.Drawing.Point(12,10)
        $name.Size = New-Object System.Drawing.Size(210,22)
        $name.ForeColor = $Accent
        $name.Font = New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )
        $card.Controls.Add($name)

        $type = New-Object System.Windows.Forms.Label
        $type.Text = "Type: $($Device.Type)"
        $type.Location = New-Object System.Drawing.Point(12,38)
        $type.Size = New-Object System.Drawing.Size(210,20)
        $type.ForeColor = $Text
        $card.Controls.Add($type)

        $ip = New-Object System.Windows.Forms.Label
        $ip.Text = "IP: $($Device.ManagementIP)"
        $ip.Location = New-Object System.Drawing.Point(12,61)
        $ip.Size = New-Object System.Drawing.Size(210,20)
        $ip.ForeColor = $Muted
        $card.Controls.Add($ip)

        $s = New-Object System.Windows.Forms.Label
        $s.Text = "Status: $($Device.Status)"
        $s.Location = New-Object System.Drawing.Point(12,86)
        $s.Size = New-Object System.Drawing.Size(210,20)

        if ($Device.Status -eq "Online") {
            $s.ForeColor = $Green
        }
        elseif ($Device.Status -eq "Offline") {
            $s.ForeColor = $Red
        }
        else {
            $s.ForeColor = $Yellow
        }

        $card.Controls.Add($s)

        return $card
    }

    # ========================================================
    # REFRESH VIEW
    # ========================================================


    # ========================================================
    # NETOPS NATIVE LINK PAINT ENGINE
    # ========================================================

    $canvas.Add_Paint({

        param(
            $sender,
            $paintEvent
        )

        if (
            $null -eq $script:NetOpsTopoPositions -or
            $null -eq $script:NetOpsTopoLinks
        ) {
            return
        }

        $g = $paintEvent.Graphics

        $g.SmoothingMode =
            [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # Canvas scroll offset
        $scrollX = [int]$canvas.AutoScrollPosition.X
        $scrollY = [int]$canvas.AutoScrollPosition.Y

        foreach ($link in @($script:NetOpsTopoLinks)) {

            $sourceName =
                [string]$link.SourceDevice

            $destinationName =
                [string]$link.DestinationDevice

            if (
                -not $script:NetOpsTopoPositions.ContainsKey(
                    $sourceName
                )
            ) {
                continue
            }

            if (
                -not $script:NetOpsTopoPositions.ContainsKey(
                    $destinationName
                )
            ) {
                continue
            }

            $src =
                $script:NetOpsTopoPositions[$sourceName]

            $dst =
                $script:NetOpsTopoPositions[$destinationName]

            # ------------------------------------------------
            # Force every coordinate to a scalar Int32
            # ------------------------------------------------

            $srcX = [int]$src.X
            $srcY = [int]$src.Y
            $srcW = [int]$src.Width
            $srcH = [int]$src.Height

            $dstX = [int]$dst.X
            $dstY = [int]$dst.Y
            $dstW = [int]$dst.Width
            $dstH = [int]$dst.Height

            # Start/end points
            $x1 = [int](
                $srcX +
                $srcW +
                $scrollX
            )

            $y1 = [int](
                $srcY +
                [int]($srcH / 2) +
                $scrollY
            )

            $x2 = [int](
                $dstX +
                $scrollX
            )

            $y2 = [int](
                $dstY +
                [int]($dstH / 2) +
                $scrollY
            )

            # If destination is on the left,
            # connect opposite sides.

            if ($x2 -lt $x1) {

                $x1 = [int](
                    $srcX +
                    $scrollX
                )

                $x2 = [int](
                    $dstX +
                    $dstW +
                    $scrollX
                )
            }

            $midX = [int](
                ($x1 + $x2) / 2
            )

            # ------------------------------------------------
            # LINK COLOR
            # ------------------------------------------------

            $lineColor = $Yellow

            if (
                [string]$link.Status -eq "Up"
            ) {
                $lineColor = $Green
            }
            elseif (
                [string]$link.Status -eq "Down"
            ) {
                $lineColor = $Red
            }

            $pen = New-Object System.Drawing.Pen(
                $lineColor,
                3
            )

            try {

                # Horizontal -> vertical -> horizontal
                $g.DrawLine(
                    $pen,
                    $x1,
                    $y1,
                    $midX,
                    $y1
                )

                $g.DrawLine(
                    $pen,
                    $midX,
                    $y1,
                    $midX,
                    $y2
                )

                $g.DrawLine(
                    $pen,
                    $midX,
                    $y2,
                    $x2,
                    $y2
                )

                # --------------------------------------------
                # CONNECTION DOTS
                # --------------------------------------------

                $dotBrush =
                    New-Object System.Drawing.SolidBrush(
                        $lineColor
                    )

                try {

                    $g.FillEllipse(
                        $dotBrush,
                        [int]($x1 - 4),
                        [int]($y1 - 4),
                        8,
                        8
                    )

                    $g.FillEllipse(
                        $dotBrush,
                        [int]($x2 - 4),
                        [int]($y2 - 4),
                        8,
                        8
                    )
                }
                finally {

                    $dotBrush.Dispose()
                }

                # --------------------------------------------
                # LABEL
                # --------------------------------------------

                $labelText =
                    "$([string]$link.SourcePort) <-> $([string]$link.DestinationPort) [$([string]$link.LinkType)]"

                $font =
                    New-Object System.Drawing.Font(
                        "Segoe UI",
                        8
                    )

                $textBrush =
                    New-Object System.Drawing.SolidBrush(
                        $Text
                    )

                $backgroundBrush =
                    New-Object System.Drawing.SolidBrush(
                        $Panel2
                    )

                try {

                    $textSize =
                        $g.MeasureString(
                            $labelText,
                            $font
                        )

                    $textWidth =
                        [int][Math]::Ceiling(
                            $textSize.Width
                        )

                    $textHeight =
                        [int][Math]::Ceiling(
                            $textSize.Height
                        )

                    $labelX =
                        [int](
                            $midX -
                            [int]($textWidth / 2)
                        )

                    $labelY =
                        [int](
                            (($y1 + $y2) / 2) -
                            [int]($textHeight / 2)
                        )

                    $rect =
                        New-Object System.Drawing.Rectangle(
                            [int]($labelX - 5),
                            [int]($labelY - 2),
                            [int]($textWidth + 10),
                            [int]($textHeight + 4)
                        )

                    $g.FillRectangle(
                        $backgroundBrush,
                        $rect
                    )

                    $g.DrawString(
                        $labelText,
                        $font,
                        $textBrush,
                        [float]$labelX,
                        [float]$labelY
                    )
                }
                finally {

                    $font.Dispose()
                    $textBrush.Dispose()
                    $backgroundBrush.Dispose()
                }
            }
            finally {

                $pen.Dispose()
            }
        }
    })

    function Refresh-Topology {

        # ====================================================
        # NETOPS_TOPOLOGY_NATIVE_PAINT_V3
        # ====================================================

        $canvas.SuspendLayout()

        try {

            $canvas.Controls.Clear()

            $devices = @(LoadDevices)
            $links   = @(LoadLinks)

            if ($script:TopoOnlineOnly) {

                $devices = @(
                    $devices |
                    Where-Object {
                        $_.Status -eq "Online"
                    }
                )
            }

            # ------------------------------------------------
            # Store coordinates for Paint event
            # ------------------------------------------------

            $script:NetOpsTopoPositions = @{}
            $script:NetOpsTopoLinks = @($links)

            $sites = @(
                $devices |
                Group-Object Site |
                Sort-Object Name
            )

            $currentY = 20

            foreach ($siteGroup in $sites) {

                $siteLabel = New-Object System.Windows.Forms.Label

                $siteLabel.Text =
                    "SITE: $($siteGroup.Name)"

                $siteLabel.Location =
                    New-Object System.Drawing.Point(
                        20,
                        $currentY
                    )

                $siteLabel.Size =
                    New-Object System.Drawing.Size(
                        500,
                        28
                    )

                $siteLabel.ForeColor = $Accent

                $siteLabel.BackColor = $Panel2

                $siteLabel.Font =
                    New-Object System.Drawing.Font(
                        "Segoe UI",
                        11,
                        [System.Drawing.FontStyle]::Bold
                    )

                $canvas.Controls.Add($siteLabel)

                $currentY += 38

                $column = 0
                $row = 0

                foreach ($device in $siteGroup.Group) {

                    $x = [int](25 + ($column * 275))
                    $y = [int]($currentY + ($row * 170))

                    $card = New-Card `
                        -Device $device `
                        -X $x `
                        -Y $y

                    $canvas.Controls.Add($card)

                    $script:NetOpsTopoPositions[
                        [string]$device.DeviceName
                    ] = [PSCustomObject]@{

                        X      = [int]$x
                        Y      = [int]$y
                        Width  = [int]240
                        Height = [int]120
                    }

                    $column++

                    if ($column -ge 4) {

                        $column = 0
                        $row++
                    }
                }

                $rowsUsed = $row + 1

                if (
                    $column -eq 0 -and
                    $row -gt 0
                ) {
                    $rowsUsed = $row
                }

                $currentY +=
                    [int](($rowsUsed * 170) + 55)
            }

            # ------------------------------------------------
            # Ensure enough virtual scrolling space
            # ------------------------------------------------

            $canvas.AutoScrollMinSize =
                New-Object System.Drawing.Size(
                    1180,
                    [Math]::Max(
                        520,
                        $currentY + 80
                    )
                )

            # ------------------------------------------------
            # LINK TABLE
            # ------------------------------------------------

            $table = New-Object System.Data.DataTable

            [void]$table.Columns.Add("SourceDevice")
            [void]$table.Columns.Add("SourcePort")
            [void]$table.Columns.Add("DestinationDevice")
            [void]$table.Columns.Add("DestinationPort")
            [void]$table.Columns.Add("LinkType")
            [void]$table.Columns.Add("Status")

            foreach ($link in $links) {

                $r = $table.NewRow()

                $r["SourceDevice"] =
                    [string]$link.SourceDevice

                $r["SourcePort"] =
                    [string]$link.SourcePort

                $r["DestinationDevice"] =
                    [string]$link.DestinationDevice

                $r["DestinationPort"] =
                    [string]$link.DestinationPort

                $r["LinkType"] =
                    [string]$link.LinkType

                $r["Status"] =
                    [string]$link.Status

                $table.Rows.Add($r)
            }

            $gridLinks.DataSource = $null
            $gridLinks.DataSource = $table

            # ------------------------------------------------
            # SUMMARY
            # ------------------------------------------------

            $online = @(
                $devices |
                Where-Object {
                    $_.Status -eq "Online"
                }
            ).Count

            $offline = @(
                $devices |
                Where-Object {
                    $_.Status -eq "Offline"
                }
            ).Count

            $upLinks = @(
                $links |
                Where-Object {
                    $_.Status -eq "Up"
                }
            ).Count

            $downLinks = @(
                $links |
                Where-Object {
                    $_.Status -eq "Down"
                }
            ).Count

            $lblStatus.Text =
                "Devices: $($devices.Count) | Links: $($links.Count) | Up: $upLinks | Down: $downLinks | Online: $online | Offline: $offline"

        }
        finally {

            $canvas.ResumeLayout()
            $canvas.Invalidate()
            $canvas.Refresh()
        }
    }

    # ========================================================
    # BUTTON EVENTS
    # ========================================================

    $btnRefresh.Add_Click({
        Refresh-Topology
    })

    $btnAll.Add_Click({

        $script:TopoOnlineOnly = $false
        Refresh-Topology
    })

    $btnOnline.Add_Click({

        $script:TopoOnlineOnly = $true
        Refresh-Topology
    })

    $btnAddLink.Add_Click({

        $newLink = Open-LinkEditor -Existing $null

        if ($null -eq $newLink) {
            return
        }

        $links = @(LoadLinks)
        $links += $newLink

        SaveLinks -Links $links
        Refresh-Topology
    })

    $btnEditLink.Add_Click({

        if ($gridLinks.SelectedRows.Count -eq 0) {
            return
        }

        $source = [string](
            $gridLinks.SelectedRows[0].Cells["SourceDevice"].Value
        )

        $destination = [string](
            $gridLinks.SelectedRows[0].Cells["DestinationDevice"].Value
        )

        $links = @(LoadLinks)
        $existing = $null

        foreach ($link in $links) {

            if (
                $link.SourceDevice -eq $source -and
                $link.DestinationDevice -eq $destination
            ) {
                $existing = $link
                break
            }
        }

        if ($null -eq $existing) {
            return
        }

        $edited = Open-LinkEditor -Existing $existing

        if ($null -eq $edited) {
            return
        }

        $result = @()

        foreach ($link in $links) {

            if (
                $link.SourceDevice -eq $source -and
                $link.DestinationDevice -eq $destination
            ) {
                $result += $edited
            }
            else {
                $result += $link
            }
        }

        SaveLinks -Links $result
        Refresh-Topology
    })

    $btnDeleteLink.Add_Click({

        if ($gridLinks.SelectedRows.Count -eq 0) {
            return
        }

        $source = [string](
            $gridLinks.SelectedRows[0].Cells["SourceDevice"].Value
        )

        $destination = [string](
            $gridLinks.SelectedRows[0].Cells["DestinationDevice"].Value
        )

        $answer = [System.Windows.Forms.MessageBox]::Show(
            "Delete link $source -> $destination ?",
            "NETOPS Topology",
            [System.Windows.Forms.MessageBoxButtons]::YesNo
        )

        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        $result = @()

        foreach ($link in @(LoadLinks)) {

            if (
                -not (
                    $link.SourceDevice -eq $source -and
                    $link.DestinationDevice -eq $destination
                )
            ) {
                $result += $link
            }
        }

        SaveLinks -Links $result
        Refresh-Topology
    })

    $btnInventory.Add_Click({

        $launcher = "$env:TEMP\NETOPS-Open-DeviceInventory.ps1"

        if (Test-Path $launcher) {

            Start-Process powershell.exe `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
        }
    })

    Refresh-Topology

    [void]$f.ShowDialog()
}



# ============================================================
# NETOPS_CONFIG_BACKUP_RESTORE_V1
# ============================================================

function Show-NetOpsConfigManager {

    $netopsDir = Join-Path $env:USERPROFILE "Documents\NETOPS"

    $inventoryFile =
        Join-Path $netopsDir "devices.csv"

    $backupRoot =
        Join-Path $netopsDir "ConfigBackups"

    if (-not (Test-Path $netopsDir)) {
        New-Item -Path $netopsDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $backupRoot)) {
        New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
    }

    # ========================================================
    # THEME
    # ========================================================

    $Bg      = [System.Drawing.Color]::FromArgb(14,25,42)
    $Panel   = [System.Drawing.Color]::FromArgb(28,43,64)
    $Panel2  = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text    = [System.Drawing.Color]::White
    $Muted   = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent  = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green   = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red     = [System.Drawing.Color]::FromArgb(255,85,85)
    $Yellow  = [System.Drawing.Color]::FromArgb(255,210,50)

    # ========================================================
    # FORM
    # ========================================================

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "NETOPS - Config Backup / Restore"
    $f.Size = New-Object System.Drawing.Size(1220,760)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $Bg
    $f.ForeColor = $Text
    $f.MinimumSize = New-Object System.Drawing.Size(1000,650)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "CONFIG BACKUP / RESTORE"
    $title.Location = New-Object System.Drawing.Point(25,20)
    $title.Size = New-Object System.Drawing.Size(600,35)
    $title.ForeColor = $Accent

    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )

    $f.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = "Archive, inspect, compare and restore device configurations"
    $sub.Location = New-Object System.Drawing.Point(27,58)
    $sub.Size = New-Object System.Drawing.Size(700,25)
    $sub.ForeColor = $Muted
    $f.Controls.Add($sub)

    # ========================================================
    # DEVICE SELECTOR
    # ========================================================

    $lblDevice = New-Object System.Windows.Forms.Label
    $lblDevice.Text = "Device"
    $lblDevice.Location = New-Object System.Drawing.Point(25,105)
    $lblDevice.Size = New-Object System.Drawing.Size(100,25)
    $lblDevice.ForeColor = $Muted
    $f.Controls.Add($lblDevice)

    $cmbDevice = New-Object System.Windows.Forms.ComboBox
    $cmbDevice.Location = New-Object System.Drawing.Point(25,132)
    $cmbDevice.Size = New-Object System.Drawing.Size(300,30)
    $cmbDevice.DropDownStyle = "DropDownList"
    $f.Controls.Add($cmbDevice)

    if (Test-Path $inventoryFile) {

        foreach ($d in @(Import-Csv $inventoryFile)) {

            if (-not [string]::IsNullOrWhiteSpace([string]$d.DeviceName)) {
                [void]$cmbDevice.Items.Add(
                    [string]$d.DeviceName
                )
            }
        }
    }

    if ($cmbDevice.Items.Count -gt 0) {
        $cmbDevice.SelectedIndex = 0
    }

    # ========================================================
    # BUTTON FACTORY
    # ========================================================

    function New-ConfigButton {

        param(
            [string]$Caption,
            [int]$X,
            [int]$Width
        )

        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Caption
        $b.Location = New-Object System.Drawing.Point($X,180)
        $b.Size = New-Object System.Drawing.Size($Width,38)
        $b.FlatStyle = "Flat"
        $b.BackColor = $Panel
        $b.ForeColor = $Text

        return $b
    }

    $btnImport =
        New-ConfigButton "BACKUP CONFIG FILE" 25 180

    $btnCompare =
        New-ConfigButton "COMPARE" 215 130

    $btnRestore =
        New-ConfigButton "RESTORE COPY" 355 150

    $btnOpen =
        New-ConfigButton "OPEN BACKUP" 515 145

    $btnFolder =
        New-ConfigButton "OPEN FOLDER" 670 140

    $btnRefresh =
        New-ConfigButton "REFRESH" 820 120

    $f.Controls.Add($btnImport)
    $f.Controls.Add($btnCompare)
    $f.Controls.Add($btnRestore)
    $f.Controls.Add($btnOpen)
    $f.Controls.Add($btnFolder)
    $f.Controls.Add($btnRefresh)

    # ========================================================
    # BACKUP GRID
    # ========================================================

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(25,240)
    $grid.Size = New-Object System.Drawing.Size(650,390)

    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.RowHeadersVisible = $false
    $grid.SelectionMode = "FullRowSelect"
    $grid.MultiSelect = $false
    $grid.AutoSizeColumnsMode = "Fill"

    $grid.EnableHeadersVisualStyles = $false
    $grid.BackgroundColor = $Panel2
    $grid.ColumnHeadersDefaultCellStyle.BackColor = $Panel
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = $Text
    $grid.DefaultCellStyle.BackColor = $Panel2
    $grid.DefaultCellStyle.ForeColor = $Text
    $grid.DefaultCellStyle.SelectionBackColor = $Panel
    $grid.DefaultCellStyle.SelectionForeColor = $Accent

    $f.Controls.Add($grid)

    # ========================================================
    # PREVIEW
    # ========================================================

    $preview = New-Object System.Windows.Forms.RichTextBox
    $preview.Location = New-Object System.Drawing.Point(700,240)
    $preview.Size = New-Object System.Drawing.Size(475,390)
    $preview.ReadOnly = $true
    $preview.BackColor = $Panel2
    $preview.ForeColor = $Text

    $preview.Font = New-Object System.Drawing.Font(
        "Consolas",
        9
    )

    $f.Controls.Add($preview)

    # ========================================================
    # STATUS
    # ========================================================

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(25,655)
    $lblStatus.Size = New-Object System.Drawing.Size(1100,30)
    $lblStatus.ForeColor = $Muted
    $f.Controls.Add($lblStatus)

    # ========================================================
    # HELPER: DEVICE FOLDER
    # ========================================================

    function Get-SelectedDeviceFolder {

        if ($null -eq $cmbDevice.SelectedItem) {
            return $null
        }

        $deviceName =
            [string]$cmbDevice.SelectedItem

        $deviceFolder =
            Join-Path $backupRoot $deviceName

        if (-not (Test-Path $deviceFolder)) {
            New-Item `
                -Path $deviceFolder `
                -ItemType Directory `
                -Force |
                Out-Null
        }

        return $deviceFolder
    }

    # ========================================================
    # REFRESH BACKUPS
    # ========================================================

    function Refresh-Backups {

        $preview.Clear()

        $folder =
            Get-SelectedDeviceFolder

        if ($null -eq $folder) {

            $grid.DataSource = $null

            $lblStatus.Text =
                "No device selected."

            return
        }

        $files = @(
            Get-ChildItem `
                -Path $folder `
                -File `
                -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        )

        $table =
            New-Object System.Data.DataTable

        [void]$table.Columns.Add("FileName")
        [void]$table.Columns.Add("Created")
        [void]$table.Columns.Add("SizeKB")
        [void]$table.Columns.Add("FullPath")

        foreach ($file in $files) {

            $row = $table.NewRow()

            $row["FileName"] =
                $file.Name

            $row["Created"] =
                $file.LastWriteTime.ToString(
                    "yyyy-MM-dd HH:mm:ss"
                )

            $row["SizeKB"] =
                [Math]::Round(
                    ($file.Length / 1KB),
                    2
                )

            $row["FullPath"] =
                $file.FullName

            $table.Rows.Add($row)
        }

        $grid.DataSource = $null
        $grid.DataSource = $table

        if ($grid.Columns["FullPath"]) {
            $grid.Columns["FullPath"].Visible = $false
        }

        $lblStatus.Text =
            "Device: $($cmbDevice.Text) | Backups: $($files.Count) | Folder: $folder"
    }

    # ========================================================
    # SELECT BACKUP
    # ========================================================

    $grid.Add_SelectionChanged({

        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $path = [string](
            $grid.SelectedRows[0].Cells["FullPath"].Value
        )

        if (-not (Test-Path $path)) {
            return
        }

        try {

            $preview.Text =
                Get-Content `
                    -Path $path `
                    -Raw `
                    -ErrorAction Stop

        }
        catch {

            $preview.Text =
                $_.Exception.Message
        }
    })

    # ========================================================
    # DEVICE CHANGE
    # ========================================================

    $cmbDevice.Add_SelectedIndexChanged({
        Refresh-Backups
    })

    # ========================================================
    # BACKUP CONFIG FILE
    # ========================================================

    $btnImport.Add_Click({

        if ($null -eq $cmbDevice.SelectedItem) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a device first.",
                "NETOPS Config Manager"
            )

            return
        }

        $dialog =
            New-Object System.Windows.Forms.OpenFileDialog

        $dialog.Title =
            "Select configuration file"

        $dialog.Filter =
            "Configuration files (*.txt;*.cfg;*.conf)|*.txt;*.cfg;*.conf|All files (*.*)|*.*"

        if (
            $dialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return
        }

        $folder =
            Get-SelectedDeviceFolder

        $timestamp =
            Get-Date -Format "yyyyMMdd-HHmmss"

        $extension =
            [System.IO.Path]::GetExtension(
                $dialog.FileName
            )

        if ([string]::IsNullOrWhiteSpace($extension)) {
            $extension = ".txt"
        }

        $deviceName =
            [string]$cmbDevice.SelectedItem

        $backupName =
            "$deviceName-CONFIG-$timestamp$extension"

        $destination =
            Join-Path $folder $backupName

        Copy-Item `
            -Path $dialog.FileName `
            -Destination $destination `
            -Force

        Refresh-Backups

        $lblStatus.ForeColor = $Green
        $lblStatus.Text =
            "Backup created: $backupName"
    })

    # ========================================================
    # OPEN BACKUP
    # ========================================================

    $btnOpen.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $path =
            [string]$grid.SelectedRows[0].Cells["FullPath"].Value

        if (Test-Path $path) {
            Start-Process notepad.exe $path
        }
    })

    # ========================================================
    # OPEN DEVICE BACKUP FOLDER
    # ========================================================

    $btnFolder.Add_Click({

        $folder =
            Get-SelectedDeviceFolder

        if ($null -ne $folder) {
            Start-Process explorer.exe $folder
        }
    })

    # ========================================================
    # RESTORE COPY
    # ========================================================

    $btnRestore.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a backup first.",
                "NETOPS Config Manager"
            )

            return
        }

        $source =
            [string]$grid.SelectedRows[0].Cells["FullPath"].Value

        if (-not (Test-Path $source)) {
            return
        }

        $saveDialog =
            New-Object System.Windows.Forms.SaveFileDialog

        $saveDialog.Title =
            "Restore configuration copy"

        $saveDialog.FileName =
            [System.IO.Path]::GetFileName($source)

        $saveDialog.Filter =
            "Configuration files (*.txt;*.cfg;*.conf)|*.txt;*.cfg;*.conf|All files (*.*)|*.*"

        if (
            $saveDialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return
        }

        Copy-Item `
            -Path $source `
            -Destination $saveDialog.FileName `
            -Force

        $lblStatus.ForeColor = $Green
        $lblStatus.Text =
            "Restore copy created: $($saveDialog.FileName)"
    })

    # ========================================================
    # COMPARE
    # ========================================================

    $btnCompare.Add_Click({

        if ($grid.SelectedRows.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Select a backup first.",
                "NETOPS Config Manager"
            )

            return
        }

        $backupPath =
            [string]$grid.SelectedRows[0].Cells["FullPath"].Value

        if (-not (Test-Path $backupPath)) {
            return
        }

        $dialog =
            New-Object System.Windows.Forms.OpenFileDialog

        $dialog.Title =
            "Select current configuration to compare"

        $dialog.Filter =
            "Configuration files (*.txt;*.cfg;*.conf)|*.txt;*.cfg;*.conf|All files (*.*)|*.*"

        if (
            $dialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return
        }

        $oldConfig =
            @(Get-Content $backupPath)

        $newConfig =
            @(Get-Content $dialog.FileName)

        $diff =
            Compare-Object `
                -ReferenceObject $oldConfig `
                -DifferenceObject $newConfig

        $compareForm =
            New-Object System.Windows.Forms.Form

        $compareForm.Text =
            "NETOPS - Configuration Compare"

        $compareForm.Size =
            New-Object System.Drawing.Size(
                1000,
                700
            )

        $compareForm.StartPosition =
            "CenterParent"

        $compareForm.BackColor = $Bg
        $compareForm.ForeColor = $Text

        $compareText =
            New-Object System.Windows.Forms.RichTextBox

        $compareText.Dock = "Fill"
        $compareText.ReadOnly = $true
        $compareText.BackColor = $Panel2
        $compareText.ForeColor = $Text

        $compareText.Font =
            New-Object System.Drawing.Font(
                "Consolas",
                10
            )

        if ($null -eq $diff) {

            $compareText.Text = @"
CONFIGURATION COMPARE
============================================================

No differences found.

Backup:
$backupPath

Current:
$($dialog.FileName)
"@

        }
        else {

            $output =
                New-Object System.Collections.Generic.List[string]

            $output.Add("CONFIGURATION COMPARE")
            $output.Add("============================================================")
            $output.Add("")
            $output.Add("<= only in BACKUP")
            $output.Add("=> only in CURRENT CONFIG")
            $output.Add("")
            $output.Add("------------------------------------------------------------")

            foreach ($item in $diff) {

                $prefix = ""

                if ($item.SideIndicator -eq "<=") {
                    $prefix = "<= "
                }
                elseif ($item.SideIndicator -eq "=>") {
                    $prefix = "=> "
                }

                $output.Add(
                    "$prefix$($item.InputObject)"
                )
            }

            $compareText.Text =
                $output -join "`r`n"
        }

        $compareForm.Controls.Add($compareText)

        [void]$compareForm.ShowDialog($f)
    })

    # ========================================================
    # REFRESH
    # ========================================================

    $btnRefresh.Add_Click({
        Refresh-Backups
    })

    # ========================================================
    # START
    # ========================================================

    Refresh-Backups

    [void]$f.ShowDialog()
}



# ============================================================
# NETOPS_ROUTING_ANALYSIS_PRO_V1
# ============================================================

function Show-NetOpsRoutingAnalysis {

    $Bg      = [System.Drawing.Color]::FromArgb(14,25,42)
    $Panel   = [System.Drawing.Color]::FromArgb(28,43,64)
    $Panel2  = [System.Drawing.Color]::FromArgb(20,34,53)
    $Text    = [System.Drawing.Color]::White
    $Muted   = [System.Drawing.Color]::FromArgb(170,185,205)
    $Accent  = [System.Drawing.Color]::FromArgb(25,205,235)
    $Green   = [System.Drawing.Color]::FromArgb(30,220,120)
    $Red     = [System.Drawing.Color]::FromArgb(255,85,85)
    $Yellow  = [System.Drawing.Color]::FromArgb(255,210,50)

    # ========================================================
    # FORM
    # ========================================================

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "NETOPS - Routing Analysis PRO"
    $f.Size = New-Object System.Drawing.Size(1260,800)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $Bg
    $f.ForeColor = $Text
    $f.MinimumSize = New-Object System.Drawing.Size(1050,680)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ROUTING ANALYSIS"
    $title.Location = New-Object System.Drawing.Point(25,20)
    $title.Size = New-Object System.Drawing.Size(550,35)
    $title.ForeColor = $Accent

    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        17,
        [System.Drawing.FontStyle]::Bold
    )

    $f.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = "OSPF / EIGRP / BGP / Routing Table evidence analysis"
    $sub.Location = New-Object System.Drawing.Point(27,58)
    $sub.Size = New-Object System.Drawing.Size(700,25)
    $sub.ForeColor = $Muted
    $f.Controls.Add($sub)

    # ========================================================
    # INPUT FILES
    # ========================================================

    $lblFiles = New-Object System.Windows.Forms.Label
    $lblFiles.Text = "Evidence files"
    $lblFiles.Location = New-Object System.Drawing.Point(25,100)
    $lblFiles.Size = New-Object System.Drawing.Size(120,25)
    $lblFiles.ForeColor = $Muted
    $f.Controls.Add($lblFiles)

    $lstFiles = New-Object System.Windows.Forms.ListBox
    $lstFiles.Location = New-Object System.Drawing.Point(25,130)
    $lstFiles.Size = New-Object System.Drawing.Size(450,150)
    $lstFiles.BackColor = $Panel2
    $lstFiles.ForeColor = $Text
    $lstFiles.SelectionMode = "MultiExtended"
    $f.Controls.Add($lstFiles)

    # ========================================================
    # BUTTON FACTORY
    # ========================================================

    function New-RoutingButton {

        param(
            [string]$Caption,
            [int]$X,
            [int]$Y,
            [int]$Width
        )

        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Caption
        $b.Location = New-Object System.Drawing.Point($X,$Y)
        $b.Size = New-Object System.Drawing.Size($Width,38)
        $b.FlatStyle = "Flat"
        $b.BackColor = $Panel
        $b.ForeColor = $Text

        return $b
    }

    $btnAdd =
        New-RoutingButton "ADD FILES" 500 130 130

    $btnRemove =
        New-RoutingButton "REMOVE" 500 178 130

    $btnClear =
        New-RoutingButton "CLEAR" 500 226 130

    $btnAnalyze =
        New-RoutingButton "ANALYZE ROUTING" 660 130 180

    $btnExport =
        New-RoutingButton "EXPORT REPORT" 850 130 160

    $f.Controls.Add($btnAdd)
    $f.Controls.Add($btnRemove)
    $f.Controls.Add($btnClear)
    $f.Controls.Add($btnAnalyze)
    $f.Controls.Add($btnExport)

    # ========================================================
    # DETECTION PANEL
    # ========================================================

    $lblDetected = New-Object System.Windows.Forms.Label
    $lblDetected.Text = "Detected routing evidence"
    $lblDetected.Location = New-Object System.Drawing.Point(660,190)
    $lblDetected.Size = New-Object System.Drawing.Size(250,25)
    $lblDetected.ForeColor = $Muted
    $f.Controls.Add($lblDetected)

    $txtDetected = New-Object System.Windows.Forms.TextBox
    $txtDetected.Location = New-Object System.Drawing.Point(660,220)
    $txtDetected.Size = New-Object System.Drawing.Size(550,60)
    $txtDetected.Multiline = $true
    $txtDetected.ReadOnly = $true
    $txtDetected.BackColor = $Panel2
    $txtDetected.ForeColor = $Accent
    $f.Controls.Add($txtDetected)

    # ========================================================
    # REPORT
    # ========================================================

    $report = New-Object System.Windows.Forms.RichTextBox
    $report.Location = New-Object System.Drawing.Point(25,310)
    $report.Size = New-Object System.Drawing.Size(1185,390)
    $report.ReadOnly = $true
    $report.BackColor = $Panel2
    $report.ForeColor = $Text

    $report.Font = New-Object System.Drawing.Font(
        "Consolas",
        9
    )

    $f.Controls.Add($report)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(25,720)
    $lblStatus.Size = New-Object System.Drawing.Size(1150,28)
    $lblStatus.ForeColor = $Muted
    $f.Controls.Add($lblStatus)

    # ========================================================
    # READ ALL FILES
    # ========================================================

    function Get-RoutingEvidence {

        $content = New-Object System.Collections.Generic.List[string]

        foreach ($item in @($lstFiles.Items)) {

            $path = [string]$item

            if (-not (Test-Path $path)) {
                continue
            }

            $content.Add("")
            $content.Add("============================================================")
            $content.Add("FILE: $path")
            $content.Add("============================================================")

            try {

                foreach ($line in @(Get-Content $path)) {
                    $content.Add([string]$line)
                }

            }
            catch {

                $content.Add(
                    "ERROR: $($_.Exception.Message)"
                )
            }
        }

        return $content -join "`r`n"
    }

    # ========================================================
    # ANALYSIS ENGINE
    # ========================================================

    function Analyze-RoutingEvidence {

        param(
            [string]$Content
        )

        # ====================================================
        # NETOPS_ROUTING_ACCURACY_V2
        # ====================================================

        $lines = $Content -split "`r?`n"

        $findings =
            New-Object System.Collections.Generic.List[string]

        $recommendations =
            New-Object System.Collections.Generic.List[string]

        $commands =
            New-Object System.Collections.Generic.List[string]

        $detected =
            New-Object System.Collections.Generic.List[string]

        $issues =
            New-Object System.Collections.Generic.List[string]

        # ----------------------------------------------------
        # STRICT EVIDENCE FLAGS
        # ----------------------------------------------------

        $hasRoutingTable = $false
        $hasProtocols    = $false
        $hasOSPF         = $false
        $hasEIGRP        = $false
        $hasBGP          = $false

        # IPv4 routing table
        if (
            $Content -match '(?im)show\s+ip\s+route\b' -or
            $Content -match '(?im)Gateway of last resort'
        ) {
            $hasRoutingTable = $true
        }

        # show ip protocols / routing process config
        if (
            $Content -match '(?im)show\s+ip\s+protocols\b' -or
            $Content -match '(?im)^Routing Protocol is\s+"'
        ) {
            $hasProtocols = $true
        }

        # ----------------------------------------------------
        # STRICT OSPF DETECTION
        # ----------------------------------------------------

        if (
            $Content -match '(?im)show\s+ip\s+ospf\b' -or
            $Content -match '(?im)show\s+ip\s+ospf\s+neighbor\b' -or
            $Content -match '(?im)show\s+ip\s+ospf\s+interface' -or
            $Content -match '(?im)Routing Protocol is\s+"ospf\s+\d+"' -or
            $Content -match '(?im)Routing Process "ospf\s+\d+"' -or
            $Content -match '(?im)%OSPF-\d+-ADJCHG' -or
            $Content -match '(?im)\bFULL/(DR|BDR|DROTHER|-)\b'
        ) {
            $hasOSPF = $true
        }

        # ----------------------------------------------------
        # STRICT EIGRP DETECTION
        # ----------------------------------------------------

        if (
            $Content -match '(?im)show\s+ip\s+eigrp\b' -or
            $Content -match '(?im)Routing Protocol is\s+"eigrp\s+\d+"' -or
            $Content -match '(?im)router\s+eigrp\s+\d+' -or
            $Content -match '(?im)%DUAL-\d+-NBRCHANGE' -or
            $Content -match '(?im)EIGRP-IPv4\s+Neighbors' -or
            $Content -match '(?im)EIGRP.*Topology Table'
        ) {
            $hasEIGRP = $true
        }

        # ----------------------------------------------------
        # STRICT BGP DETECTION
        # ----------------------------------------------------

        if (
            $Content -match '(?im)show\s+(ip\s+)?bgp\b' -or
            $Content -match '(?im)router\s+bgp\s+\d+' -or
            $Content -match '(?im)BGP router identifier' -or
            $Content -match '(?im)Neighbor\s+V\s+AS\s+MsgRcvd' -or
            $Content -match '(?im)%BGP-\d+-ADJCHANGE'
        ) {
            $hasBGP = $true
        }

        # ----------------------------------------------------
        # REGISTER DETECTED EVIDENCE
        # ----------------------------------------------------

        if ($hasRoutingTable) {
            $detected.Add("IPv4 Routing Table")
        }

        if ($hasOSPF) {
            $detected.Add("OSPF")
        }

        if ($hasEIGRP) {
            $detected.Add("EIGRP")
        }

        if ($hasBGP) {
            $detected.Add("BGP")
        }

        if ($hasProtocols) {
            $detected.Add("Routing Protocol Configuration")
        }

        # ----------------------------------------------------
        # DEFAULT ROUTE
        # ----------------------------------------------------

        if (
            $Content -match '(?im)Gateway of last resort is not set'
        ) {

            $issues.Add(
                "No IPv4 default route / gateway of last resort is installed."
            )

            $recommendations.Add(
                "Verify whether this router should have a default route toward the WAN/ISP/upstream router."
            )

            $commands.Add(
                "show ip route 0.0.0.0"
            )
        }
        elseif (
            $Content -match '(?im)Gateway of last resort is\s+([0-9\.]+)'
        ) {

            $gateway = $Matches[1]

            $findings.Add(
                "Gateway of last resort detected: $gateway"
            )
        }

        # ----------------------------------------------------
        # OSPF ANALYSIS
        # ----------------------------------------------------

        if ($hasOSPF) {

            $ospfFull =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '\bFULL/(DR|BDR|DROTHER|-)\b'
                    }
                )

            if ($ospfFull.Count -gt 0) {

                $findings.Add(
                    "OSPF FULL adjacencies detected: $($ospfFull.Count)"
                )
            }

            $ospfBadStates =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '\b(INIT|EXSTART|EXCHANGE|LOADING|ATTEMPT)\b'
                    }
                )

            if ($ospfBadStates.Count -gt 0) {

                $issues.Add(
                    "OSPF neighbor state is not FULL on one or more adjacencies."
                )

                foreach ($stateLine in ($ospfBadStates | Select-Object -First 5)) {

                    $findings.Add(
                        "OSPF state evidence: $($stateLine.Trim())"
                    )
                }

                $recommendations.Add(
                    "Check area ID, subnet, timers, MTU, authentication, network type and passive-interface configuration."
                )
            }

            if (
                $Content -match '(?im)Router ID\s+([0-9\.]+)'
            ) {

                $findings.Add(
                    "OSPF Router ID detected: $($Matches[1])"
                )
            }

            if (
                $Content -match '(?im)Routing Process "ospf\s+(\d+)"'
            ) {

                $findings.Add(
                    "OSPF process ID detected: $($Matches[1])"
                )
            }

            if (
                $Content -match '(?im)Routing Protocol is\s+"ospf\s+(\d+)"'
            ) {

                $findings.Add(
                    "OSPF process ID detected: $($Matches[1])"
                )
            }

            $ospfRoutes =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '^\s*O(\s|IA\s|E1\s|E2\s|N1\s|N2\s)'
                    }
                )

            if ($ospfRoutes.Count -gt 0) {

                $findings.Add(
                    "OSPF routes detected in routing table: $($ospfRoutes.Count)"
                )
            }

            foreach ($cmd in @(
                "show ip ospf neighbor",
                "show ip ospf interface brief",
                "show ip route ospf"
            )) {

                if ($commands -notcontains $cmd) {
                    $commands.Add($cmd)
                }
            }
        }

        # ----------------------------------------------------
        # EIGRP ANALYSIS
        # ----------------------------------------------------

        if ($hasEIGRP) {

            $eigrpRoutes =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '^\s*D(\s|EX\s)'
                    }
                )

            if ($eigrpRoutes.Count -gt 0) {

                $findings.Add(
                    "EIGRP routes detected in routing table: $($eigrpRoutes.Count)"
                )
            }

            if (
                $Content -match '(?im)%DUAL-\d+-NBRCHANGE'
            ) {

                $findings.Add(
                    "EIGRP neighbor change syslog messages detected."
                )
            }

            if (
                $Content -match '(?im)EIGRP.*(?:neighbor|adjacency).*(?:down|reset)'
            ) {

                $issues.Add(
                    "EIGRP adjacency instability detected."
                )

                $recommendations.Add(
                    "Verify AS number, K-values, authentication, passive interfaces and Layer 3 reachability."
                )
            }

            foreach ($cmd in @(
                "show ip eigrp neighbors",
                "show ip eigrp topology",
                "show ip route eigrp"
            )) {

                if ($commands -notcontains $cmd) {
                    $commands.Add($cmd)
                }
            }
        }

        # ----------------------------------------------------
        # BGP ANALYSIS
        # ----------------------------------------------------

        if ($hasBGP) {

            $bgpRoutes =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '^\s*B\s+'
                    }
                )

            if ($bgpRoutes.Count -gt 0) {

                $findings.Add(
                    "BGP routes detected in routing table: $($bgpRoutes.Count)"
                )
            }

            $bgpProblemLines =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '\b(Idle|Active|Connect)\b'
                    }
                )

            if ($bgpProblemLines.Count -gt 0) {

                $issues.Add(
                    "One or more BGP peers appear to be below Established state."
                )

                foreach ($bgpLine in ($bgpProblemLines | Select-Object -First 5)) {

                    $findings.Add(
                        "BGP state evidence: $($bgpLine.Trim())"
                    )
                }

                $recommendations.Add(
                    "Verify neighbor IP reachability, remote-as, source interface/update-source, TCP 179 and authentication."
                )
            }

            if (
                $Content -match '(?im)%BGP-\d+-ADJCHANGE'
            ) {

                $findings.Add(
                    "BGP adjacency change syslog messages detected."
                )
            }

            foreach ($cmd in @(
                "show bgp ipv4 unicast summary",
                "show bgp neighbors",
                "show ip route bgp"
            )) {

                if ($commands -notcontains $cmd) {
                    $commands.Add($cmd)
                }
            }
        }

        # ----------------------------------------------------
        # STATIC ROUTES
        # ----------------------------------------------------

        if ($hasRoutingTable) {

            $staticRoutes =
                @(
                    $lines |
                    Where-Object {
                        $_ -match '^\s*S(\*|\s)'
                    }
                )

            if ($staticRoutes.Count -gt 0) {

                $findings.Add(
                    "Static routes detected: $($staticRoutes.Count)"
                )
            }
        }

        # ----------------------------------------------------
        # BASE COMMANDS
        # ----------------------------------------------------

        foreach ($cmd in @(
            "show ip route",
            "show ip protocols"
        )) {

            if ($commands -notcontains $cmd) {
                $commands.Add($cmd)
            }
        }

        # ----------------------------------------------------
        # CONFIDENCE
        # ----------------------------------------------------

        $confidence = "LOW"

        if ($detected.Count -ge 1) {
            $confidence = "MEDIUM"
        }

        if (
            $findings.Count -ge 2 -or
            $issues.Count -ge 1
        ) {
            $confidence = "HIGH"
        }

        # ----------------------------------------------------
        # BUILD REPORT
        # ----------------------------------------------------

        $out =
            New-Object System.Collections.Generic.List[string]

        $out.Add("NETOPS ROUTING ANALYSIS")
        $out.Add("============================================================")
        $out.Add("")

        $out.Add("DETECTED EVIDENCE")
        $out.Add("------------------------------------------------------------")

        if ($detected.Count -eq 0) {

            $out.Add(
                "No recognized routing evidence was detected."
            )

        }
        else {

            foreach ($item in ($detected | Select-Object -Unique)) {
                $out.Add("* $item")
            }
        }

        $out.Add("")
        $out.Add("CONFIDENCE")
        $out.Add("------------------------------------------------------------")
        $out.Add($confidence)

        $out.Add("")
        $out.Add("FINDINGS")
        $out.Add("------------------------------------------------------------")

        if ($findings.Count -eq 0) {

            $out.Add(
                "No strong routing findings detected."
            )

        }
        else {

            foreach ($item in ($findings | Select-Object -Unique)) {
                $out.Add("* $item")
            }
        }

        $out.Add("")
        $out.Add("POTENTIAL PROBLEMS")
        $out.Add("------------------------------------------------------------")

        if ($issues.Count -eq 0) {

            $out.Add(
                "No obvious routing failure was identified from the supplied evidence."
            )

        }
        else {

            foreach ($item in ($issues | Select-Object -Unique)) {
                $out.Add("* $item")
            }
        }

        $out.Add("")
        $out.Add("RECOMMENDED TROUBLESHOOTING")
        $out.Add("------------------------------------------------------------")

        if ($recommendations.Count -eq 0) {

            $out.Add(
                "Validate route presence, next-hop reachability and routing protocol neighbor state."
            )

        }
        else {

            $number = 1

            foreach ($item in ($recommendations | Select-Object -Unique)) {

                $out.Add(
                    "$number. $item"
                )

                $number++
            }
        }

        $out.Add("")
        $out.Add("RECOMMENDED COMMANDS")
        $out.Add("------------------------------------------------------------")

        foreach ($cmd in ($commands | Select-Object -Unique)) {
            $out.Add("* $cmd")
        }

        $out.Add("")
        $out.Add("VERIFICATION")
        $out.Add("------------------------------------------------------------")
        $out.Add(
            "Confirm expected routes exist and that the selected next hop / exit interface matches the intended topology."
        )
        $out.Add(
            "For dynamic routing, confirm neighbor adjacency is stable and expected prefixes are installed."
        )
        $out.Add("")

        return [PSCustomObject]@{
            Report   = ($out -join "`r`n")
            Detected = (($detected | Select-Object -Unique) -join " | ")
        }
    }

    # ========================================================
    # ADD FILES
    # ========================================================

    $btnAdd.Add_Click({

        $dialog =
            New-Object System.Windows.Forms.OpenFileDialog

        $dialog.Title =
            "Select routing evidence files"

        $dialog.Filter =
            "Evidence files (*.txt;*.log;*.cfg;*.conf)|*.txt;*.log;*.cfg;*.conf|All files (*.*)|*.*"

        $dialog.Multiselect = $true

        if (
            $dialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return
        }

        foreach ($file in $dialog.FileNames) {

            if (-not $lstFiles.Items.Contains($file)) {
                [void]$lstFiles.Items.Add($file)
            }
        }

        $lblStatus.Text =
            "Evidence files loaded: $($lstFiles.Items.Count)"
    })

    # ========================================================
    # REMOVE
    # ========================================================

    $btnRemove.Add_Click({

        $selected =
            @($lstFiles.SelectedItems)

        foreach ($item in $selected) {
            $lstFiles.Items.Remove($item)
        }

        $lblStatus.Text =
            "Evidence files loaded: $($lstFiles.Items.Count)"
    })

    # ========================================================
    # CLEAR
    # ========================================================

    $btnClear.Add_Click({

        $lstFiles.Items.Clear()
        $report.Clear()
        $txtDetected.Clear()

        $lblStatus.Text =
            "Routing analysis cleared."
    })

    # ========================================================
    # ANALYZE
    # ========================================================

    $btnAnalyze.Add_Click({

        if ($lstFiles.Items.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "Add at least one evidence file first.",
                "NETOPS Routing Analysis"
            )

            return
        }

        $lblStatus.ForeColor = $Muted
        $lblStatus.Text =
            "Analyzing routing evidence..."

        [System.Windows.Forms.Application]::DoEvents()

        try {

            $content =
                Get-RoutingEvidence

            $result =
                Analyze-RoutingEvidence `
                    -Content $content

            $report.Text =
                $result.Report

            $txtDetected.Text =
                $result.Detected

            $lblStatus.ForeColor = $Green
            $lblStatus.Text =
                "Routing analysis completed."

        }
        catch {

            $lblStatus.ForeColor = $Red
            $lblStatus.Text =
                "Analysis error: $($_.Exception.Message)"
        }
    })

    # ========================================================
    # EXPORT
    # ========================================================

    $btnExport.Add_Click({

        if ([string]::IsNullOrWhiteSpace($report.Text)) {

            [System.Windows.Forms.MessageBox]::Show(
                "Run an analysis first.",
                "NETOPS Routing Analysis"
            )

            return
        }

        $dialog =
            New-Object System.Windows.Forms.SaveFileDialog

        $dialog.Title =
            "Export routing analysis report"

        $dialog.Filter =
            "Text report (*.txt)|*.txt"

        $dialog.FileName =
            "NETOPS-Routing-Analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

        if (
            $dialog.ShowDialog() -ne
            [System.Windows.Forms.DialogResult]::OK
        ) {
            return
        }

        $report.Text |
            Set-Content `
                -Path $dialog.FileName `
                -Encoding UTF8

        $lblStatus.ForeColor = $Green
        $lblStatus.Text =
            "Report exported: $($dialog.FileName)"
    })

    [void]$f.ShowDialog()
}


function Show-NetOpsNetworkToolbox {

    $toolbox = New-Object System.Windows.Forms.Form
    $toolbox.Text = "NETOPS - Network Toolbox"
    $toolbox.Size = New-Object System.Drawing.Size(760,880)
    $toolbox.StartPosition = "CenterScreen"
    $toolbox.BackColor = [System.Drawing.Color]::FromArgb(15,27,45)
    $toolbox.AutoScroll = $true
    $toolbox.AutoScrollMinSize = New-Object System.Drawing.Size(700,1220)
    $toolbox.ForeColor = [System.Drawing.Color]::White
    $toolbox.FormBorderStyle = "FixedDialog"
    $toolbox.MaximizeBox = $false

    # --------------------------------------------------------
    # TITLE
    # --------------------------------------------------------

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "NETWORK TOOLS"
    $lblTitle.Location = New-Object System.Drawing.Point(30,25)
    $lblTitle.Size = New-Object System.Drawing.Size(400,40)
    $lblTitle.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        18,
        [System.Drawing.FontStyle]::Bold
    )
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(30,210,245)

    $toolbox.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "CCNA / CCNP troubleshooting and diagnostic utilities"
    $lblSub.Location = New-Object System.Drawing.Point(32,65)
    $lblSub.Size = New-Object System.Drawing.Size(550,25)
    $lblSub.ForeColor = [System.Drawing.Color]::LightGray

    $toolbox.Controls.Add($lblSub)

    # --------------------------------------------------------
    # PING
    # --------------------------------------------------------

    $btnPingTool = New-Object System.Windows.Forms.Button
    $btnPingTool.Text = "PING"
    $btnPingTool.Location = New-Object System.Drawing.Point(35,120)
    $btnPingTool.Size = New-Object System.Drawing.Size(300,80)
    $btnPingTool.FlatStyle = "Flat"
    $btnPingTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnPingTool.ForeColor = [System.Drawing.Color]::White
    $btnPingTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnPingTool.Add_Click({
        Show-NetOpsPingTool
    })

    $toolbox.Controls.Add($btnPingTool)

    # --------------------------------------------------------
    # TRACEROUTE
    # --------------------------------------------------------

    $btnTraceTool = New-Object System.Windows.Forms.Button
    $btnTraceTool.Text = "TRACEROUTE"
    $btnTraceTool.Location = New-Object System.Drawing.Point(365,120)
    $btnTraceTool.Size = New-Object System.Drawing.Size(300,80)
    $btnTraceTool.FlatStyle = "Flat"
    $btnTraceTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnTraceTool.ForeColor = [System.Drawing.Color]::White
    $btnTraceTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnTraceTool.Add_Click({
        Show-NetOpsTracerouteTool
    })

    $toolbox.Controls.Add($btnTraceTool)

    # --------------------------------------------------------
    # SHOW COMMANDS
    # --------------------------------------------------------

    $btnCommandsTool = New-Object System.Windows.Forms.Button
    $btnCommandsTool.Text = "SHOW COMMANDS"
    $btnCommandsTool.Location = New-Object System.Drawing.Point(35,225)
    $btnCommandsTool.Size = New-Object System.Drawing.Size(300,80)
    $btnCommandsTool.FlatStyle = "Flat"
    $btnCommandsTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnCommandsTool.ForeColor = [System.Drawing.Color]::White
    $btnCommandsTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnCommandsTool.Add_Click({
        Show-NetOpsCommandsTool
    })

    $toolbox.Controls.Add($btnCommandsTool)

    # --------------------------------------------------------
    # INVENTORY
    # --------------------------------------------------------

    $btnInventoryTool = New-Object System.Windows.Forms.Button
    $btnInventoryTool.Text = "DEVICE INVENTORY"
    $btnInventoryTool.Location = New-Object System.Drawing.Point(365,225)
    $btnInventoryTool.Size = New-Object System.Drawing.Size(300,80)
    $btnInventoryTool.FlatStyle = "Flat"
    $btnInventoryTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnInventoryTool.ForeColor = [System.Drawing.Color]::White
    $btnInventoryTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        11,
        [System.Drawing.FontStyle]::Bold
    )

    $btnInventoryTool.Add_Click({
        Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Acer\AppData\Local\Temp\NETOPS-Open-DeviceInventory.ps1"'
    })

    $toolbox.Controls.Add($btnInventoryTool)


    # --------------------------------------------------------
    # TOPOLOGY VIEW
    # --------------------------------------------------------

    $btnTopologyTool = New-Object System.Windows.Forms.Button
    $btnTopologyTool.Text = "TOPOLOGY VIEW"
    $btnTopologyTool.Location = New-Object System.Drawing.Point(35,335)
    $btnTopologyTool.Size = New-Object System.Drawing.Size(630,55)
    $btnTopologyTool.FlatStyle = "Flat"
    $btnTopologyTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnTopologyTool.ForeColor = [System.Drawing.Color]::White

    $btnTopologyTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10,
        [System.Drawing.FontStyle]::Bold
    )

    $btnTopologyTool.Add_Click({

        Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Acer\AppData\Local\Temp\NETOPS-Open-TopologyView.ps1"'

    })

    $toolbox.Controls.Add($btnTopologyTool)


    # --------------------------------------------------------
    # CONFIG BACKUP / RESTORE
    # --------------------------------------------------------

    $btnConfigTool = New-Object System.Windows.Forms.Button
    $btnConfigTool.Text = "CONFIG BACKUP / RESTORE"
    $btnConfigTool.Location = New-Object System.Drawing.Point(35,400)
    $btnConfigTool.Size = New-Object System.Drawing.Size(630,55)
    $btnConfigTool.FlatStyle = "Flat"
    $btnConfigTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnConfigTool.ForeColor = [System.Drawing.Color]::White

    $btnConfigTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10,
        [System.Drawing.FontStyle]::Bold
    )

    $btnConfigTool.Add_Click({

        Start-Process powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$env:TEMP\NETOPS-Open-ConfigManager.ps1`""

    })

    $toolbox.Controls.Add($btnConfigTool)


    # --------------------------------------------------------
    # ROUTING ANALYSIS
    # --------------------------------------------------------

    $btnRoutingTool = New-Object System.Windows.Forms.Button
    $btnRoutingTool.Text = "ROUTING ANALYSIS"
    $btnRoutingTool.Location = New-Object System.Drawing.Point(35,470)
    $btnRoutingTool.Size = New-Object System.Drawing.Size(630,55)
    $btnRoutingTool.FlatStyle = "Flat"
    $btnRoutingTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnRoutingTool.ForeColor = [System.Drawing.Color]::White

    $btnRoutingTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10,
        [System.Drawing.FontStyle]::Bold
    )

    $btnRoutingTool.Add_Click({

        Start-Process powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$env:TEMP\NETOPS-Open-RoutingAnalysis.ps1`""

    })

    $toolbox.Controls.Add($btnRoutingTool)


    # ========================================================
    # LOG CORRELATION - STANDALONE TOOL
    # ========================================================

    $btnLogCorrelationTool = New-Object System.Windows.Forms.Button
    $btnLogCorrelationTool.Text = "LOG CORRELATION"
    $btnLogCorrelationTool.Location = New-Object System.Drawing.Point(35,610)
    $btnLogCorrelationTool.Size = New-Object System.Drawing.Size(630,55)
    $btnLogCorrelationTool.FlatStyle = "Flat"
    $btnLogCorrelationTool.BackColor = [System.Drawing.Color]::FromArgb(30,48,70)
    $btnLogCorrelationTool.ForeColor = [System.Drawing.Color]::White

    $btnLogCorrelationTool.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        10,
        [System.Drawing.FontStyle]::Bold
    )

    $btnLogCorrelationTool.Add_Click({

        Start-Process powershell.exe -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            'C:\Users\Acer\Documents\NETOPS\Tools\NETOPS-Log-Correlation.ps1'
        )

    })

    $toolbox.Controls.Add($btnLogCorrelationTool)


    # ========================================================
    # PACKET CAPTURE / WIRESHARK
    # ========================================================

    $btnPacketCaptureTool =
        New-Object System.Windows.Forms.Button

    $btnPacketCaptureTool.Text =
        "PACKET CAPTURE / WIRESHARK"

    $btnPacketCaptureTool.Location =
        New-Object System.Drawing.Point(
            35,
            680
        )

    $btnPacketCaptureTool.Size =
        New-Object System.Drawing.Size(
            630,
            55
        )

    $btnPacketCaptureTool.FlatStyle =
        "Flat"

    $btnPacketCaptureTool.BackColor =
        [System.Drawing.Color]::FromArgb(
            30,
            48,
            70
        )

    $btnPacketCaptureTool.ForeColor =
        [System.Drawing.Color]::White

    $btnPacketCaptureTool.Font =
        New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )

    $btnPacketCaptureTool.Add_Click({

    $psi = New-Object System.Diagnostics.ProcessStartInfo

    $psi.FileName = "powershell.exe"

    $psi.Arguments =
        '-NoProfile -ExecutionPolicy Bypass -File "' +
        'C:\Users\Acer\Documents\NETOPS\Tools\NETOPS-Packet-Capture.ps1' +
        '"'

    $psi.UseShellExecute = $true

    [System.Diagnostics.Process]::Start($psi) | Out-Null

})

    $toolbox.Controls.Add(
        $btnPacketCaptureTool
    )


    # ========================================================
    # PACKET ANALYSIS
    # ========================================================

    $btnPacketAnalysisTool =
        New-Object System.Windows.Forms.Button

    $btnPacketAnalysisTool.Text =
        "PACKET ANALYSIS"

    $btnPacketAnalysisTool.Location =
        New-Object System.Drawing.Point(
            35,
            750
        )

    $btnPacketAnalysisTool.Size =
        New-Object System.Drawing.Size(
            630,
            55
        )

    $btnPacketAnalysisTool.FlatStyle =
        "Flat"

    $btnPacketAnalysisTool.BackColor =
        [System.Drawing.Color]::FromArgb(
            30,
            48,
            70
        )

    $btnPacketAnalysisTool.ForeColor =
        [System.Drawing.Color]::White

    $btnPacketAnalysisTool.Font =
        New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )

    $btnPacketAnalysisTool.Add_Click({

        $psi =
            New-Object System.Diagnostics.ProcessStartInfo

        $psi.FileName =
            "powershell.exe"

        $psi.Arguments =
            '-NoProfile -ExecutionPolicy Bypass -File "' +
            'C:\Users\Acer\Documents\NETOPS\Tools\NETOPS-Packet-Analysis.ps1' +
            '"'

        $psi.UseShellExecute =
            $true

        [System.Diagnostics.Process]::Start(
            $psi
        ) | Out-Null

    })

    $toolbox.Controls.Add(
        $btnPacketAnalysisTool
    )


    # ========================================================
    # ROOT CAUSE ANALYSIS
    # ========================================================

    $btnRootCauseTool =
        New-Object System.Windows.Forms.Button

    $btnRootCauseTool.Text =
        "ROOT CAUSE ANALYSIS"

    $btnRootCauseTool.Location =
        New-Object System.Drawing.Point(
            35,
            820
        )

    $btnRootCauseTool.Size =
        New-Object System.Drawing.Size(
            630,
            55
        )

    $btnRootCauseTool.FlatStyle =
        "Flat"

    $btnRootCauseTool.BackColor =
        [System.Drawing.Color]::FromArgb(
            30,
            48,
            70
        )

    $btnRootCauseTool.ForeColor =
        [System.Drawing.Color]::White

    $btnRootCauseTool.Font =
        New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )

    $btnRootCauseTool.Add_Click({

        $psi =
            New-Object System.Diagnostics.ProcessStartInfo

        $psi.FileName =
            "powershell.exe"

        $psi.Arguments =
            '-NoProfile -ExecutionPolicy Bypass -File "' +
            'C:\Users\Acer\Documents\NETOPS\Tools\NETOPS-Root-Cause-Analysis.ps1' +
            '"'

        $psi.UseShellExecute =
            $true

        [System.Diagnostics.Process]::Start(
            $psi
        ) | Out-Null

    })

    $toolbox.Controls.Add(
        $btnRootCauseTool
    )


    # ========================================================
    # RCA + HYBRID AI FUSION
    # ========================================================

    $btnRcaHybridTool =
        New-Object System.Windows.Forms.Button

    $btnRcaHybridTool.Text =
        "RCA + HYBRID AI"

    $btnRcaHybridTool.Location =
        New-Object System.Drawing.Point(
            35,
            890
        )

    $btnRcaHybridTool.Size =
        New-Object System.Drawing.Size(
            630,
            55
        )

    $btnRcaHybridTool.FlatStyle =
        "Flat"

    $btnRcaHybridTool.BackColor =
        [System.Drawing.Color]::FromArgb(
            30,
            48,
            70
        )

    $btnRcaHybridTool.ForeColor =
        [System.Drawing.Color]::White

    $btnRcaHybridTool.Font =
        New-Object System.Drawing.Font(
            "Segoe UI",
            10,
            [System.Drawing.FontStyle]::Bold
        )

    $btnRcaHybridTool.Add_Click({

        $psi =
            New-Object System.Diagnostics.ProcessStartInfo

        $psi.FileName =
            "powershell.exe"

        $psi.Arguments =
            '-NoProfile -ExecutionPolicy Bypass -File "' +
            'C:\Users\Acer\Documents\NETOPS\Tools\NETOPS-RCA-Hybrid-AI.ps1' +
            '"'

        $psi.UseShellExecute = $true

        [System.Diagnostics.Process]::Start($psi) | Out-Null

    })

    $toolbox.Controls.Add(
        $btnRcaHybridTool
    )

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "NETOPS Core Network Tools v1"
    $lblStatus.Location = New-Object System.Drawing.Point(35,980)
    $lblStatus.Size = New-Object System.Drawing.Size(400,25)
    $lblStatus.ForeColor = [System.Drawing.Color]::Gray

    $toolbox.Controls.Add($lblStatus)

    [void]$toolbox.ShowDialog()
}


# ============================================================
# MAIN NETOPS NETWORK TOOLS BUTTON
# ============================================================

$btnNetworkToolsLauncher = New-Object System.Windows.Forms.Button

$btnNetworkToolsLauncher.Text = "NETWORK TOOLS"

$btnNetworkToolsLauncher.Size = New-Object System.Drawing.Size(
    180,
    42
)

$btnNetworkToolsLauncher.Location = New-Object System.Drawing.Point(
    1150,
    20
)

$btnNetworkToolsLauncher.Anchor = 
    [System.Windows.Forms.AnchorStyles]::Top 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Right

$btnNetworkToolsLauncher.FlatStyle = "Flat"

$btnNetworkToolsLauncher.BackColor = 
    [System.Drawing.Color]::FromArgb(30,48,70)

$btnNetworkToolsLauncher.ForeColor = 
    [System.Drawing.Color]::White

$btnNetworkToolsLauncher.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9,
    [System.Drawing.FontStyle]::Bold
)

$btnNetworkToolsLauncher.Add_Click({

    Show-NetOpsNetworkToolbox

})

$toolForm.Controls.Add($btnNetworkToolsLauncher)

$btnNetworkToolsLauncher.BringToFront()

# ============================================================
# NETOPS_NETWORK_TOOLS_SIDEBAR_V1
# ============================================================

$btnNetworkToolsSidebar = New-Object System.Windows.Forms.Button

$btnNetworkToolsSidebar.Text = "Network Tools"

$btnNetworkToolsSidebar.Size = $btnSystem.Size

$btnNetworkToolsSidebar.Location = New-Object System.Drawing.Point(
    $btnSystem.Left,
    ($btnSystem.Bottom + 10)
)

$btnNetworkToolsSidebar.Anchor = 
    [System.Windows.Forms.AnchorStyles]::Top 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Left 
    -bor 
    [System.Windows.Forms.AnchorStyles]::Right

$btnNetworkToolsSidebar.FlatStyle = "Flat"

$btnNetworkToolsSidebar.FlatAppearance.BorderSize = 0

$btnNetworkToolsSidebar.BackColor = 
    [System.Drawing.Color]::FromArgb(30,45,66)

$btnNetworkToolsSidebar.ForeColor = 
    [System.Drawing.Color]::White

$btnNetworkToolsSidebar.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$btnNetworkToolsSidebar.TextAlign = 
    [System.Drawing.ContentAlignment]::MiddleLeft

$btnNetworkToolsSidebar.Padding = 
    New-Object System.Windows.Forms.Padding(22,0,0,0)

$btnNetworkToolsSidebar.Cursor = 
    [System.Windows.Forms.Cursors]::Hand

$btnNetworkToolsSidebar.Add_Click({

    Show-NetOpsNetworkToolbox

})

if ($btnSystem.Parent) {

    $btnSystem.Parent.Controls.Add($btnNetworkToolsSidebar)

    $btnNetworkToolsSidebar.BringToFront()

}
else {

    $form.Controls.Add($btnNetworkToolsSidebar)

    $btnNetworkToolsSidebar.BringToFront()
}



[System.Windows.Forms.Application]::Run($form)















































