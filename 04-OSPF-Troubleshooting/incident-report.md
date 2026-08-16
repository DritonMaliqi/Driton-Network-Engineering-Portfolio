# Incident Report – NET-004

## Incident Details

| Field | Information |
|---|---|
| Incident ID | NET-004 |
| Date | 16 August 2026 |
| Status | Resolved and verified |
| Priority | Medium |
| Assigned engineer | Driton Maliqi |
| Source device | PC-BR-01 |
| Source network | 192.168.30.0/24 |
| Affected service | HQ network and internal DNS/Web server access |
| Destination | SRV-DNS-WEB – 192.168.50.10 |
| Routing protocol | OSPF process 100 |

## Symptom

The Branch workstation could reach its local gateway `192.168.30.1`, but could not reach the HQ server `192.168.50.10`. The local router returned `Destination host unreachable`.

## Business Impact

The Branch site lost access to HQ Finance, Human Resources, and Server networks. Local Branch connectivity remained available.

## Evidence Collected

- `PC-BR-01` had the correct static IPv4 configuration.
- The Branch default gateway responded with 0% packet loss.
- The Branch router successfully pinged the HQ WAN address `10.0.12.1`.
- `show ip ospf neighbor` returned no neighbors.
- `show ip route ospf` returned no learned OSPF routes.
- `R-HQ-01` placed the WAN in area 0.
- `R-BRANCH-01` placed the same WAN in area 1.

## Root-Cause Analysis

The two routers used different OSPF area IDs on the shared WAN network `10.0.12.0/30`. OSPF Hello packets were exchanged on interfaces assigned to different areas, so the routers could not become neighbors.

## Resolution

The incorrect Branch WAN statement was removed and replaced with the correct area:

```cisco
router ospf 100
 no network 10.0.12.0 0.0.0.3 area 1
 network 10.0.12.0 0.0.0.3 area 0
```

## Verification Results

| Test | Result |
|---|---|
| Branch gateway `192.168.30.1` | Passed |
| WAN peer `10.0.12.1` | Passed – 5/5 |
| OSPF adjacency | Passed – FULL |
| HQ routes on R-BRANCH-01 | Passed – three OSPF routes installed |
| Branch to server `192.168.50.10` | Passed – 4/4 |
| DNS `server.company.local` | Passed – resolved to 192.168.50.10 |
| HQ to Branch `192.168.30.10` | Passed – 4/4 |

## Preventive Action

- Maintain an addressing and OSPF-area plan for both ends of every routed link.
- Compare `show ip protocols` and `show ip ospf interface` before making routing changes.
- Include OSPF neighbor and route verification in the post-change checklist.
- Change one routing variable at a time and repeat the original failed test.

## Closure Statement

Service was restored after correcting the OSPF area mismatch on `R-BRANCH-01`. OSPF adjacency, route exchange, Branch-to-HQ access, DNS resolution, and the return path were verified successfully.

