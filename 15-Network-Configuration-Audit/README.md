# Project 15 - Automated Network Configuration Audit & Compliance Tool

## Overview

This project demonstrates an automated network configuration auditing and compliance workflow for Cisco-style router and switch configurations.

The solution combines Python, PowerShell, network troubleshooting, security validation, remediation, and automated reporting.

## Project Workflow

```text
Network Configuration
        |
        v
Automated Audit
        |
        v
Problem Detection
        |
        v
Remediation
        |
        v
Re-Audit
        |
        v
Compliance Verification
```

## Lab Devices

| Device | Type | Purpose |
|---|---|---|
| R-HQ-01 | Router | Headquarters router |
| R-BRANCH-01 | Router | Branch router |
| SW-ACCESS-01 | Switch | Access-layer switch |

## Problems Detected

- OSPF area mismatch between routers
- Telnet permitted on R-HQ-01 VTY lines
- FastEthernet0/2 assigned to VLAN 1 instead of VLAN 10
- VLAN 10 missing from the trunk allowed VLAN list
- Unused FastEthernet0/24 administratively enabled

## Audit Capabilities

- SSH version validation
- Telnet / VTY security validation
- Password-encryption validation
- OSPF configuration checks
- Cross-device OSPF area consistency
- Access VLAN validation
- Trunk VLAN validation
- Unused interface security validation
- Severity classification
- Remediation recommendations
- CSV reporting
- TXT reporting
- HTML dashboard generation

## Project Structure

```text
15-Network-Configuration-Audit
|
|-- Config-Samples
|   |-- R-HQ-01.txt
|   |-- R-BRANCH-01.txt
|   -- SW-ACCESS-01.txt
|
|-- Config-Remediated
|   |-- R-HQ-01.txt
|   |-- R-BRANCH-01.txt
|   -- SW-ACCESS-01.txt
|
|-- Scripts
|   |-- network_audit.py
|   -- Run-NetworkAudit.ps1
|
|-- Reports
|-- Screenshots
|-- Documentation
-- README.md
```

## Running the Audit

### BEFORE Remediation

```powershell
python ".\Scripts\network_audit.py" --config-dir "Config-Samples" --label "BEFORE"
```

### AFTER Remediation

```powershell
python ".\Scripts\network_audit.py" --config-dir "Config-Remediated" --label "AFTER"
```

### PowerShell Launcher

```powershell
& ".\Scripts\Run-NetworkAudit.ps1"
```

## Audit Results

### BEFORE Remediation

```text
PASS    : 7
WARNING : 1
FAIL    : 5
SCORE   : 54%
```

### AFTER Remediation

```text
PASS    : 11
WARNING : 0
FAIL    : 0
SCORE   : 100%
```

## Compliance Improvement

```text
54%  --->  100%
Improvement: +46%
```

## Technologies

- Cisco IOS concepts
- VLANs
- 802.1Q trunking
- OSPF
- SSH / VTY security
- Python
- PowerShell
- Regular expressions
- CSV / TXT reporting
- HTML dashboards

## Skills Demonstrated

- Network configuration auditing
- Cisco troubleshooting
- Network automation
- Configuration compliance
- Root-cause analysis
- Security hardening
- Automated reporting
- Remediation verification

## Future Improvements

- ACL validation
- DHCP helper validation
- STP checks
- Native VLAN validation
- Port-security validation
- NTP validation
- SNMP security checks
- AAA / TACACS+ validation
- YAML-based compliance policies
- Multi-vendor configuration support
- Real-device SSH collection with Netmiko

## Author

**Driton Maliqi**

Network Engineering Portfolio

Focus: CCNA / CCNP, Network Troubleshooting, Python, PowerShell and Network Automation.

## Dashboard Screenshot

The following dashboard demonstrates the compliance improvement from 54% to 100% after remediation.

![Before vs After Network Audit Dashboard](Screenshots/before-after-dashboard.png)
