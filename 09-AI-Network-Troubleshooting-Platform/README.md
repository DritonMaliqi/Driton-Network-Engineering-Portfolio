# 09 - NETOPS AI-Assisted Network Troubleshooting Platform

![NETOPS v5.7 Rev.2 GUI](./screenshots/NETOPS-v5.7-Rev2-GUI.jpg)

A practical Network Engineering and NOC troubleshooting platform built with PowerShell, deterministic rule-based diagnostics, evidence correlation, root-cause analysis, incident management, Windows Forms GUI, automated reporting, and optional local Ollama AI integration.

**Current Version:** NETOPS v5.7 Rev.2  
**Status:** Stable Lab / Portfolio Release  
**Focus:** CCNA + CCNP troubleshooting workflows

## Project Overview

This project started as a PowerShell troubleshooting rule engine and evolved into a local Network Operations troubleshooting platform. It is designed to accept incident descriptions and technical evidence, identify root causes and symptoms, recommend the next troubleshooting command, and automatically document incidents for later review.

The current release includes:

- Windows Forms troubleshooting GUI
- FAST deterministic analysis mode
- Optional HYBRID / local Ollama AI workflow
- Modular CCNA / CCNP rule pack
- Root-cause vs symptom classification
- Confidence scoring
- FIX / VERIFY / COLLECT_MORE / STOP decisions
- Smart next-step recommendations
- Automatic incident saving
- Incident History dashboard
- Incident Details panel
- Open Report / Open Incident Folder workflow
- Mark Resolved workflow
- Markdown + JSON incident documentation
- CSV incident history
- Reliability regression testing
- Professional Desktop shortcut / application icon workflow

## v5.7 Rev.2 Reliability Patch

The v5.7 Rev.2 update focused on reliability after practical CCNA and CCNP incident testing.

### Fixes added

1. **IPv6 Default Gateway false-positive fix**
   - Windows-style output can place an IPv6 gateway on the line after `Default Gateway:`.
   - The engine no longer reports `Default Gateway missing` when a valid IPv6 gateway is present on the next line.

2. **GRE Tunnel Source / Destination mismatch detection**
   - Added support for phrases such as:
     - tunnel destination mismatch
     - incorrect tunnel destination
     - wrong tunnel source
     - GRE source/destination mismatch

3. **Multi-root-cause VLAN + DHCP analysis**
   - The engine can detect an explicit access-port VLAN mismatch while simultaneously diagnosing DHCP/APIPA problems.

4. **Version synchronization**
   - Engine header updated to v5.7.
   - GUI title and footer updated to v5.7 Rev.2.

## Validation Results

### Full Rule Pack Regression Suite

The CCNA / CCNP rule pack completed:

```text
PASSED : 27
FAILED : 0
NETOPS v5.3 RULE PACK: READY
```

### v5.7 Rev.2 Reliability Regression Suite

```text
PASSED : 8
FAILED : 0
NETOPS v5.7 RELIABILITY PATCH REV.2: READY
```

### Real GUI Retests

All three previously problematic scenarios were successfully retested through the actual GUI:

| Test | Result | Key Finding |
|---|---|---|
| IPv6 default route | PASS | IPv6 Default Route Missing, 98% confidence |
| GRE destination mismatch | PASS | GRE Tunnel Source/Destination Misconfiguration, 98% confidence |
| VLAN + DHCP multi-root cause | PASS | VLAN mismatch + DHCP Relay Missing + APIPA symptoms |

The multi-root-cause test produced four findings and correctly prioritized the access-port VLAN mismatch as the first troubleshooting action.

## Practical CCNA / CCNP Tests Completed

The platform has been manually tested with scenarios including:

- VLAN access-port mismatch
- Trunk allowed VLAN mismatch
- DHCP relay missing
- APIPA addressing
- Missing default gateway
- IPv6 default route missing
- OSPF area mismatch
- OSPF MTU mismatch / EXSTART
- EIGRP autonomous-system mismatch
- BGP remote-AS mismatch
- NAT ACL missing source subnet
- IPsec crypto parameter mismatch
- GRE tunnel endpoint mismatch
- Multiple simultaneous network faults

## Modular Rule Coverage

The engine uses modular PowerShell rules covering:

- Layer 2 / VLAN / trunking
- DHCP / DNS / IPv4
- Routing
- OSPF
- EIGRP
- BGP
- ACL / NAT
- Network security controls
- VPN / WAN / GRE / IPsec
- IPv6

## Incident Management

Every analyzed incident can be stored under the project data directory with structured documentation.

Example artifacts:

```text
data/
├── Incident-History.csv
├── Incidents/
│   └── INC-YYYYMMDD-XXX/
│       ├── incident.json
│       └── incident-report.md
└── Reports/
```

The GUI supports:

- Refresh History
- View Incident Details
- Open Report
- Open Incident Folder
- Mark Resolved
- Resolution status tracking

## Decision Engine

NETOPS uses four primary decisions:

- **FIX** - a root cause is confirmed strongly enough to proceed with a controlled correction.
- **VERIFY** - a probable root cause exists but should be validated before configuration changes.
- **COLLECT_MORE** - additional evidence is required.
- **STOP** - available evidence is insufficient for a safe diagnosis.

## Example Troubleshooting Output

```text
[HIGH] [CONFIRMED] [ROOT_CAUSE] VLAN
Problem    : Access Port VLAN Mismatch.
Evidence   : Fa0/2 should be in VLAN 10 but is configured in VLAN 20.
Confidence : 99%
Interface  : Fa0/2

[HIGH] [CONFIRMED] [ROOT_CAUSE] DHCP
Problem    : DHCP Relay Missing.
Confidence : 98%

DECISION
FIX

SMART NEXT STEP
show interfaces Fa0/2 switchport
```

## Technologies

- PowerShell
- Windows Forms
- Cisco IOS troubleshooting concepts
- IPv4 / IPv6
- VLAN / 802.1Q trunking
- DHCP / DNS
- Static and dynamic routing
- OSPF / EIGRP / BGP
- ACL / NAT / PAT
- GRE / IPsec VPN
- Regular expressions
- Evidence correlation
- Root Cause Analysis
- Incident Management
- Markdown / JSON / CSV reporting
- Ollama
- Llama 3.2

## Skills Demonstrated

- Network troubleshooting methodology
- Cisco IOS diagnostics
- Layer 2 and Layer 3 fault isolation
- Routing-protocol troubleshooting
- Network security troubleshooting
- Root Cause Analysis
- Evidence correlation
- PowerShell automation
- GUI application development
- Incident lifecycle management
- Regression testing
- Technical documentation
- Network automation / DevNet fundamentals

## Intended Roles

- Junior Network Engineer
- NOC Technician
- Network Support Engineer
- Network Administrator
- Junior Network Automation / DevNet Engineer

## Release Notes

Detailed v5.7 Rev.2 notes are available in [`docs/NETOPS-v5.7-Rev2-Release.md`](./docs/NETOPS-v5.7-Rev2-Release.md).

## Disclaimer

This is a lab and portfolio project. Diagnostic rules and configuration recommendations must be validated before use in production networks.
