# Incident Report - NET-003

## Incident Details

| Field | Information |
|---|---|
| Incident ID | NET-003 |
| Date | 16 August 2026 |
| Status | Resolved and verified |
| Priority | Medium |
| Assigned engineer | Driton Maliqi |
| Department | Human Resources |
| Affected device | PC-HR-03 |
| Access switch | SW-ACCESS-02 |
| Remote trunk endpoint | SW-ACCESS-01 G0/2 |

## Symptom

`PC-HR-03` had a valid `192.168.20.22/24` DHCP configuration but could not reach its default gateway `192.168.20.1`, the internal server, or DNS services.

## Business Impact

The newly connected HR workstation could not access internal network resources. Finance users on the same downstream switch and HR users attached directly to the primary access switch remained operational.

## Evidence Collected

- Valid endpoint IP address, mask, gateway, DHCP server, and DNS server.
- `100%` packet loss from `PC-HR-03` to `192.168.20.1`.
- Successful Finance control test from the same downstream switch.
- Correct VLAN 20 membership on `SW-ACCESS-02 Fa0/3`.
- VLAN 20 allowed and forwarding on `SW-ACCESS-02 G0/1`.
- VLAN 20 missing from the allowed VLAN list on `SW-ACCESS-01 G0/2`.

## Root Cause

The inter-switch trunk was operational, but `SW-ACCESS-01 G0/2` allowed only VLANs 10 and 50. VLAN 20 traffic was dropped at the remote trunk endpoint.

## Resolution

The missing VLAN was added without replacing the existing allowed VLAN list:

```cisco
configure terminal
interface gigabitethernet0/2
 switchport trunk allowed vlan add 20
end
```

## Verification

- `SW-ACCESS-01 G0/2` allowed VLANs 10, 20, and 50.
- `PC-HR-03` reached `192.168.20.1` with `0%` packet loss.
- `PC-HR-03` reached `192.168.50.10`.
- `server.company.local` resolved to `192.168.50.10`.
- VLAN 10 connectivity remained operational.

## Preventive Actions

- Use a documented trunk VLAN standard for inter-switch links.
- Validate allowed VLAN lists on both trunk endpoints after changes.
- Run one control test from each required VLAN.
- Capture `show interfaces trunk` before and after trunk modifications.
- Prefer `switchport trunk allowed vlan add <vlan>` for additive changes.

## Closure Note

Incident NET-003 was resolved by restoring VLAN 20 to the allowed list on `SW-ACCESS-01 G0/2`. Gateway, internal-server, and DNS services were successfully verified from the affected endpoint.

