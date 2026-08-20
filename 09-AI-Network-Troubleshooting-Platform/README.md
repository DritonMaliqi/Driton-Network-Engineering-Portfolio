# 09 - AI-Assisted Network Troubleshooting Platform

A practical Network Engineering and NOC troubleshooting platform built with PowerShell, deterministic rule-based diagnostics, evidence correlation, root-cause analysis, incident management, Windows GUI and optional local Ollama AI integration.

**Status:** In Progress

## Overview

This project started as a PowerShell troubleshooting rule engine and evolved into a local Network Operations troubleshooting platform.

The platform can:

- Analyze network incident descriptions
- Analyze Cisco and Windows evidence files
- Identify likely root causes
- Separate root causes from symptoms
- Detect contradictory or stale evidence
- Recommend verification commands
- Guide incident troubleshooting
- Track incident status
- Generate incident reports
- Display incident statistics
- Provide a Windows GUI
- Optionally use local Ollama AI

## Technologies

- PowerShell
- Windows Forms
- Cisco IOS troubleshooting concepts
- IPv4
- VLAN
- 802.1Q Trunking
- DHCP
- DNS
- OSPF
- Static Routing
- ACL
- NAT / PAT
- Regular Expressions
- Evidence Correlation
- Root Cause Analysis
- Incident Management
- Ollama
- Llama 3.2

## Supported Scenarios

- Access Port VLAN mismatch
- Missing VLAN from trunk allowed list
- DHCP failure
- APIPA addressing
- Missing default gateway
- Interface administratively down
- Duplicate IP / IP conflict
- ACL traffic blocking
- NAT inside/outside problems
- OSPF area mismatch
- OSPF passive-interface problems
- OSPF network statement mismatch
- Missing default route
- Incorrect static route next-hop
- DNS resolution problems
- Routing reachability problems
- Contradictory or stale network evidence

## Decision Engine

- FIX
- VERIFY
- COLLECT_MORE
- STOP

## Guided Incident Workflow

1. Analyze
2. Primary Root Cause
3. Pre-Change Check
4. Proposed Fix
5. Verify Root Cause
6. Secondary Issues
7. Verify Services
8. Close Incident

Incident states:

- OPEN
- MONITORING
- RESOLVED

## Skills Demonstrated

- Network troubleshooting
- Cisco IOS troubleshooting
- Layer 2 diagnostics
- Layer 3 diagnostics
- OSPF
- DHCP / DNS
- ACL / NAT
- Root Cause Analysis
- Evidence correlation
- PowerShell automation
- Incident management
- Windows GUI development
- Local AI integration
- Technical documentation

## Intended Roles

- Junior Network Engineer
- NOC Technician
- Network Support Engineer
- Network Administrator
- Junior Network Automation / DevNet

## Disclaimer

This is a lab and portfolio project. Configuration recommendations must be validated before use in production.
