# Architecture

## Overview

The platform uses a deterministic PowerShell troubleshooting engine as its primary diagnostic layer.

## Main Components

1. Incident Input
2. Evidence Parser
3. PowerShell Rule Engine
4. Evidence Correlation
5. Root Cause Engine
6. Dependency Engine
7. Contradiction Detection
8. Decision Engine
9. Smart Next-Step Engine
10. Incident Workflow
11. Reporting
12. Dashboard
13. Windows GUI
14. Optional Ollama AI

## Architecture Flow

Incident Text / Evidence Files
        |
        v
Evidence Parser
        |
        v
PowerShell Rule Engine
        |
        v
Findings + Contradictions
        |
        v
Root Cause Engine
        |
        v
Decision Engine
        |
        v
FIX / VERIFY / COLLECT_MORE / STOP
        |
        v
Smart Next Step
        |
        v
Incident Workflow / Reports / Dashboard

## Design Principle

The deterministic rule engine remains the primary technical validation mechanism.

Local AI assists with explanation and interpretation rather than replacing deterministic network validation.
