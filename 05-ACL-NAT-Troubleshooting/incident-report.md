# Incident Report - NET-005

## Incident Details

| Field | Information |
|---|---|
| Incident ID | NET-005 |
| Date | 16 August 2026 |
| Status | Resolved and verified |
| Priority | Medium |
| Assigned engineer | Driton Maliqi |
| Affected site | Branch |
| Affected device | PC-BR-01 |
| Affected network | `192.168.30.0/24` |
| Failed service | Public web / simulated Internet access |
| Destination | `198.51.100.10` |

## Symptom

Branch user `PC-BR-01` could reach the local gateway and internal HQ services, but ICMP and HTTP access to `SRV-PUBLIC-WEB` failed. Finance users at HQ continued to access the public server.

## Business Impact

The Branch site lost public-server/Internet access. HQ departments and internal inter-site communication remained operational, limiting the incident to one source subnet.

## Expected Traffic Path

```text
PC-BR-01 -> R-BRANCH-01 -> OSPF WAN -> R-HQ-01 PAT
         -> R-ISP-01 -> SRV-PUBLIC-WEB
```

## Evidence Collected

- `PC-BR-01` had `192.168.30.10/24` with gateway `192.168.30.1`.
- The Branch gateway replied with 0% packet loss.
- Internal server `192.168.50.10` was reachable.
- Public server `198.51.100.10` failed from Branch.
- `R-BRANCH-01` contained `O*E2 0.0.0.0/0` via `10.0.12.1`.
- `R-HQ-01` reached `198.51.100.10` successfully.
- `show ip nat translations` contained no Branch translation.
- NAT interfaces and overload configuration were correct.
- `NAT_INSIDE` did not contain `192.168.30.0/24`.

## Root-Cause Analysis

PAT on `R-HQ-01` used the standard named ACL `NAT_INSIDE` to identify eligible inside-local source networks. The ACL permitted VLAN 10, VLAN 20, and VLAN 50 but omitted the Branch LAN. Branch traffic was routed to HQ correctly but did not match the NAT policy, so no translation was created.

## Corrective Action

```cisco
configure terminal
ip access-list standard NAT_INSIDE
 permit 192.168.30.0 0.0.0.255
end
```

No unrelated routing, OSPF, interface, or ISP configuration was modified.

## Verification Results

- Original failing ping repeated successfully: 4 sent, 4 received.
- NAT translations showed `192.168.30.10` translated through `203.0.113.2`.
- Branch HTTP access to `http://198.51.100.10` succeeded.
- Internal server access remained operational.
- HQ public-server access remained operational.

## Preventive Action

- Maintain an explicit inventory of every inside subnet requiring PAT.
- Compare the routing table with the NAT selection ACL after adding a new site or VLAN.
- Include one end-to-end Internet test per inside subnet in change validation.
- Capture `show ip nat statistics`, `show ip nat translations`, and ACL counters before closing similar incidents.

## Closure Statement

Branch Internet access was restored by adding the missing Branch subnet to the NAT selection ACL. Routing, PAT translation, ICMP, and HTTP tests confirmed full service restoration.

