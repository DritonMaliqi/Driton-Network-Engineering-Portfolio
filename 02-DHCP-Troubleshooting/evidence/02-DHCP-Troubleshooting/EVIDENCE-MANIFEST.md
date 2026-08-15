# DHCP Troubleshooting Evidence Pack — Before Fix

This pack contains the curated evidence collected before correcting the DHCP failure affecting VLAN 20 (Human Resources).

## Topology

- `topology/DHCP-Troubleshooting-Topology-Raw.png` — Actual Cisco Packet Tracer topology.

## Evidence order

1. `01-HR-DHCP-Failure-APIPA.png` — PC-HR-01 receives an APIPA address and has no gateway or DNS server.
2. `02-Finance-DHCP-Control-Success.png` — Finance DHCP works, providing a healthy comparison.
3. `03-Switch-Interfaces-Up.png` — HR access ports and the uplink are operational.
4. `04-VLAN20-Membership.png` — Fa0/3 and Fa0/4 are assigned to VLAN 20.
5. `05-HR-Access-Port-VLAN20.png` — Fa0/3 is a static access port in VLAN 20.
6. `06-Trunk-VLAN20-Allowed.png` — VLAN 20 is allowed, active, and forwarding on Gig0/1.
7. `07-Router-Subinterfaces-Up.png` — Router subinterfaces for VLANs 10, 20, and 50 are up/up.
8. `08-DHCP-Pools-Configured.png` — DHCP service and HR/Finance pools are present.
9. `09-Root-Cause-Missing-DHCP-Relay.png` — VLAN 10 has a helper address while VLAN 20 does not.

## Excluded screenshot

The Windows Explorer screenshot was intentionally excluded because it proves only that local files exist; it does not provide network troubleshooting evidence.

## Still required after the fix

- Router configuration showing `ip helper-address 192.168.50.20` under `GigabitEthernet0/0.20`.
- PC-HR-01 valid DHCP lease in `192.168.20.0/24`.
- End-to-end tests to the gateway, DNS/web server, and DNS name.

