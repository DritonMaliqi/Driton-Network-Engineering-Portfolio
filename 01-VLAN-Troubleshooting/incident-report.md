# Incident Report – NET-001

## Incident Details

| Field | Information |
|---|---|
| Incident ID | NET-001 |
| Date | 15 August 2026 |
| Status | Resolved and verified |
| Priority | Medium |
| Assigned engineer | Driton Maliqi |
| Department | Finance |
| Affected device | PC-FIN-02 |
| Access switch | SW-ACCESS-01 |
| Affected interface | FastEthernet0/2 |

## Symptom

PC-FIN-02 had a valid DHCP configuration but could not reach its default gateway, internal company server, or Internet services.

## Business Impact

One Finance department workstation was unable to access internal and external network resources. Other Finance users remained operational.

## Evidence Collected

- PC-FIN-02 received IPv4 address 192.168.10.22/24.
- The configured default gateway was 192.168.10.1.
- The configured DNS server was 192.168.50.10.
- Ping to 192.168.10.1 failed with 100% packet loss.
- FastEthernet0/2 was operational and reported up/up.
- `show vlan brief` displayed FastEthernet0/2 in VLAN 1.
- The approved network design required FastEthernet0/2 in VLAN 10.
- The switchport command confirmed Access Mode VLAN 1.

## Root Cause

SW-ACCESS-01 FastEthernet0/2 was incorrectly assigned to VLAN 1 instead of VLAN 10 – FINANCE.

## Corrective Action

    configure terminal
    interface fastethernet0/2
     switchport mode access
     switchport access vlan 10
    end

## Verification Performed

- Confirmed FastEthernet0/2 appeared in VLAN 10.
- Successfully pinged gateway 192.168.10.1.
- Successfully pinged server 192.168.50.10.
- Successfully resolved `server.company.local`.
- Confirmed restoration of the required service.

## Rollback Plan

If the change caused unexpected impact, the interface could be returned to its previous VLAN:

    configure terminal
    interface fastethernet0/2
     switchport access vlan 1
    end

Rollback was not required.

## Preventive Actions

- Verify access-port assignments against network documentation.
- Label switchports according to connected devices and departments.
- Maintain an approved VLAN and port-assignment table.
- Test connectivity after moving or reconnecting endpoints.

## Closure Summary

The incident was caused by an incorrect access VLAN assignment. FastEthernet0/2 was moved from VLAN 1 to VLAN 10. Gateway, server, and DNS connectivity were successfully verified. Service was restored and the incident was closed.
