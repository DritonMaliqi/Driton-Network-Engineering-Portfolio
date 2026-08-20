# Troubleshooting Workflow

The platform follows a verify-before-change troubleshooting methodology.

## Phase 1 - Analyze
Analyze the incident and available evidence.

## Phase 2 - Primary Root Cause
Identify the primary root cause and separate it from downstream symptoms.

## Phase 3 - Pre-Change Check
Verify current configuration before making changes.

Example:
show running-config interface GigabitEthernet0/1

## Phase 4 - Proposed Fix
Recommend the corrective action.

## Phase 5 - Verify Root Cause
Verify that the primary fault has been corrected.

## Phase 6 - Secondary Issues
Re-test Routing, DHCP, IP addressing, Gateway, ACL, NAT and DNS.

## Phase 7 - Verify Services
Use ping, traceroute, nslookup and routing verification.

## Phase 8 - Close Incident
Record Incident ID, Root Cause, Evidence, Fix, Verification and Closure Notes.

## Decisions

- FIX
- VERIFY
- COLLECT_MORE
- STOP

## Incident States

- OPEN
- MONITORING
- RESOLVED
