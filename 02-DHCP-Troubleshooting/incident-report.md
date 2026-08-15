# Incident Report – NET-002

## Incident Details

| Field | Information |
|---|---|
| Incident ID | NET-002 |
| Date | 16 August 2026 |
| Status | Resolved and verified |
| Priority | Medium |
| Assigned engineer | Driton Maliqi |
| Department | Human Resources |
| Affected devices | PC-HR-01 and PC-HR-02 |
| Client VLAN | VLAN 20 – HUMAN_RESOURCES |
| Router | R-HQ-01 |
| Affected interface | GigabitEthernet0/0.20 |
| DHCP server | 192.168.50.20 |

## Symptom

Human Resources workstations could not obtain valid IPv4 configuration from the centralized DHCP server. PC-HR-01 assigned itself APIPA address 169.254.190.128/16 and had no IPv4 default gateway or DNS server.

## Business Impact

The simulated incident prevented HR clients from joining the corporate IPv4 network and accessing routed services. Finance clients and the centralized server infrastructure remained operational.

## Evidence Collected

- PC-HR-01 displayed an APIPA address and no gateway or DNS server.
- PC-FIN-01 in VLAN 10 received a valid DHCP lease.
- FastEthernet0/3 and FastEthernet0/4 were up/up.
- Both HR access ports were assigned to VLAN 20.
- VLAN 20 was allowed, active, and forwarding on the 802.1Q trunk.
- R-HQ-01 GigabitEthernet0/0.20 was up/up with address 192.168.20.1/24.
- The DHCP server contained a valid HR pool.
- The working VLAN 10 subinterface contained `ip helper-address 192.168.50.20`.
- The failing VLAN 20 subinterface did not contain a helper address.

## Root Cause

R-HQ-01 GigabitEthernet0/0.20 was missing the DHCP relay statement `ip helper-address 192.168.50.20`. DHCP Discover broadcasts from VLAN 20 could not reach the DHCP server located in VLAN 50.

## Corrective Action

    configure terminal
    interface GigabitEthernet0/0.20
     ip helper-address 192.168.50.20
    end

No unrelated configuration was changed.

## Verification Performed

- Confirmed the helper address was applied to GigabitEthernet0/0.20.
- PC-HR-01 received 192.168.20.20/24.
- PC-HR-02 received 192.168.20.21/24.
- Both clients received gateway 192.168.20.1.
- Both clients received DNS server 192.168.50.10.
- The DHCP server was identified as 192.168.50.20.
- Ping to 192.168.20.1 succeeded with 4/4 replies.
- Ping to 192.168.50.10 succeeded after initial ARP resolution.
- `server.company.local` resolved successfully to 192.168.50.10.

## Rollback Plan

If the relay change caused unexpected impact, the new statement could be removed:

    configure terminal
    interface GigabitEthernet0/0.20
     no ip helper-address 192.168.50.20
    end

Rollback was not required.

## Preventive Actions

- Use a standard router subinterface template for every client VLAN.
- Include DHCP relay verification in VLAN deployment checklists.
- Compare new VLAN configurations with a known-good VLAN before activation.
- Test the complete DHCP DORA process after network changes.
- Maintain an addressing, VLAN, gateway, and DHCP-relay table.
- Preserve before-and-after device configurations for change review.

## Closure Summary

The incident was caused by a missing DHCP relay statement on the VLAN 20 router subinterface. The helper address was added as the single corrective change. Two HR workstations then received valid DHCP leases, and gateway, server, and DNS tests confirmed service restoration. Incident NET-002 was resolved, verified, documented, and closed.

