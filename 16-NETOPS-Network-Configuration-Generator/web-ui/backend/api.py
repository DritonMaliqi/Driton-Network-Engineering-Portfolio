"""
PROJECT 16 - NETOPS Web API Adapter

This API does not replace the existing Python engine.
It provides a web-facing adapter for:
- Vendor discovery
- Platform discovery
- Technology discovery
- Dynamic parameter schemas
- Central NetworkValidator
- Health/status checks

Generation endpoints will be connected to the existing
Project 16 vendor engine after this adapter is verified.
"""

from pathlib import Path
from typing import Any, Dict

import sys

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


# ============================================================
# PROJECT PATHS
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = PROJECT_ROOT / "src"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))


# ============================================================
# PROJECT 16 CORE ENGINE
# ============================================================

from core.validator import NetworkValidator
from core.models import ConfigSection

from ipam import (
    calculate_network,
    split_network,
    vlsm_plan,
    IPAMDatabase,
)

# ============================================================
# PROJECT 16 REAL VENDOR GENERATORS
# ============================================================

from vendors.cisco.classic import (
    generate_vlan as cisco_generate_vlan,
    generate_trunk as cisco_generate_trunk,
    generate_ospf as cisco_generate_ospf,
    generate_dhcp as cisco_generate_dhcp,
    generate_static_route as cisco_generate_static_route,
    generate_acl as cisco_generate_acl,
)

from vendors.cisco.basic import (
    generate_hsrp as cisco_generate_hsrp,
    generate_vrf as cisco_generate_vrf,
)

from vendors.cisco.routing import (
    generate_bgp as cisco_generate_bgp,
    generate_isis as cisco_generate_isis,
)

from vendors.cisco.security import (
    generate_nat_pat as cisco_generate_nat_pat,
)

from vendors.cisco.vpn import (
    generate_ipsec_site_to_site as cisco_generate_ipsec,
)

from vendors.fortigate.firewall import (
    generate_interface as fortigate_generate_interface,
    generate_firewall_policy as fortigate_generate_firewall_policy,
)

from vendors.fortigate.routing import (
    generate_static_route as fortigate_generate_static_route,
    generate_bgp as fortigate_generate_bgp,
    generate_ospf as fortigate_generate_ospf,
)

from vendors.fortigate.sdwan import (
    generate_sdwan as fortigate_generate_sdwan,
)

from vendors.fortigate.vpn import (
    generate_ipsec_site_to_site as fortigate_generate_ipsec,
)

from vendors.paloalto.routing import (
    generate_layer3_interface as paloalto_generate_layer3_interface,
    generate_static_route as paloalto_generate_static_route,
    generate_bgp as paloalto_generate_bgp,
    generate_ospf as paloalto_generate_ospf,
)

from vendors.paloalto.security import (
    generate_zone as paloalto_generate_zone,
    generate_security_policy as paloalto_generate_security_policy,
    generate_nat_policy as paloalto_generate_nat_policy,
)


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(
    title="NETOPS Network Configuration Generator API",
    description=(
        "Web API Adapter for Project 16 - "
        "Cisco, FortiGate and Palo Alto configuration automation."
    ),
    version="2.0.0",
)



# ============================================================
# NETFORGE IPAM DATABASE
# ============================================================

NETFORGE_DATA_DIR = PROJECT_ROOT / "data"
NETFORGE_DATA_DIR.mkdir(parents=True, exist_ok=True)

IPAM_DB_PATH = NETFORGE_DATA_DIR / "netforge_ipam.db"
ipam_db = IPAMDatabase(str(IPAM_DB_PATH))

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# VENDOR DATA
# ============================================================

VENDORS = {
    "Cisco": {
        "platforms": [
            "IOS",
            "IOS-XE",
            "NX-OS",
            "ASA/FTD",
        ],
        "technologies": [
            "OSPF",
            "VLAN",
            "Trunk",
            "DHCP",
            "Static Route",
            "ACL",
            "BGP",
            "IS-IS",
            "NAT/PAT",
            "HSRP",
            "VRF",
            "IPsec VPN",
        ],
    },

    "FortiGate": {
        "platforms": [
            "FortiOS",
        ],
        "technologies": [
            "NAT",
            "IPsec VPN",
            "Interface",
            "Static Route",
            "Firewall Policy",
            "BGP",
            "OSPF",
            "SD-WAN",
        ],
    },

    "Palo Alto": {
        "platforms": [
            "PAN-OS",
        ],
        "technologies": [
            "Layer3 Interface",
            "Zone",
            "Static Route",
            "Security Policy",
            "NAT Policy",
            "BGP",
            "OSPF",
        ],
    },
}


# ============================================================
# DYNAMIC PARAMETER SCHEMAS
#
# IMPORTANT:
# Field names match the working Project 16 Tkinter engine.
# ============================================================

SCHEMAS = {

    # ========================================================
    # CISCO
    # ========================================================

    ("Cisco", "OSPF"): [
        {
            "name": "process",
            "label": "Process ID",
            "default": "1",
            "type": "text",
            "required": True,
        },
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "network",
            "label": "Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "wildcard",
            "label": "Wildcard Mask",
            "default": "0.0.0.255",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "area",
            "label": "Area",
            "default": "0",
            "type": "text",
            "required": True,
        },
    ],

    ("Cisco", "VLAN"): [
        {
            "name": "vlan_id",
            "label": "VLAN ID",
            "default": "10",
            "type": "number",
            "validation": "vlan",
            "required": True,
        },
        {
            "name": "vlan_name",
            "label": "VLAN Name",
            "default": "USERS",
            "type": "text",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Access Interface",
            "default": "GigabitEthernet0/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("Cisco", "Trunk"): [
        {
            "name": "interface",
            "label": "Trunk Interface",
            "default": "GigabitEthernet0/24",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "vlans",
            "label": "Allowed VLANs",
            "default": "10,20,30",
            "type": "text",
            "required": True,
        },
        {
            "name": "native",
            "label": "Native VLAN",
            "default": "99",
            "type": "number",
            "validation": "vlan",
            "required": True,
        },
    ],

    ("Cisco", "DHCP"): [
        {
            "name": "pool",
            "label": "Pool Name",
            "default": "USERS",
            "type": "text",
            "required": True,
        },
        {
            "name": "network",
            "label": "Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "mask",
            "label": "Subnet Mask",
            "default": "255.255.255.0",
            "type": "text",
            "validation": "subnet_mask",
            "required": True,
        },
        {
            "name": "gateway",
            "label": "Default Gateway",
            "default": "192.168.10.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "dns",
            "label": "DNS Server",
            "default": "8.8.8.8",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
    ],

    ("Cisco", "Static Route"): [
        {
            "name": "network",
            "label": "Destination Network",
            "default": "10.10.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "mask",
            "label": "Subnet Mask",
            "default": "255.255.255.0",
            "type": "text",
            "validation": "subnet_mask",
            "required": True,
        },
        {
            "name": "next_hop",
            "label": "Next Hop",
            "default": "192.168.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
    ],

    ("Cisco", "ACL"): [
        {
            "name": "number",
            "label": "ACL Number",
            "default": "10",
            "type": "number",
            "required": True,
        },
        {
            "name": "action",
            "label": "Action",
            "default": "permit",
            "type": "text",
            "required": True,
        },
        {
            "name": "source",
            "label": "Source Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "wildcard",
            "label": "Wildcard Mask",
            "default": "0.0.0.255",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
    ],

    ("Cisco", "BGP"): [
        {
            "name": "local_asn",
            "label": "Local ASN",
            "default": "65001",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "neighbor_ip",
            "label": "Neighbor IP",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "remote_asn",
            "label": "Remote ASN",
            "default": "65002",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
        {
            "name": "network",
            "label": "Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "mask",
            "label": "Subnet Mask",
            "default": "255.255.255.0",
            "type": "text",
            "validation": "subnet_mask",
            "required": True,
        },
        {
            "name": "description",
            "label": "Neighbor Description",
            "default": "ISP-01",
            "type": "text",
            "required": False,
        },
    ],

    ("Cisco", "IS-IS"): [
        {
            "name": "process_name",
            "label": "Process Name",
            "default": "CORE",
            "type": "text",
            "required": True,
        },
        {
            "name": "net",
            "label": "NET",
            "default": "49.0001.0000.0000.0001.00",
            "type": "text",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Interface",
            "default": "GigabitEthernet0/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "level",
            "label": "IS-IS Level",
            "default": "level-2-only",
            "type": "text",
            "required": True,
        },
    ],

    ("Cisco", "NAT/PAT"): [
        {
            "name": "inside_network",
            "label": "Inside Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "wildcard",
            "label": "Wildcard Mask",
            "default": "0.0.0.255",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "inside_interface",
            "label": "Inside Interface",
            "default": "GigabitEthernet0/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "outside_interface",
            "label": "Outside Interface",
            "default": "GigabitEthernet0/0",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("Cisco", "HSRP"): [
        {
            "name": "interface",
            "label": "Interface",
            "default": "GigabitEthernet0/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "group",
            "label": "HSRP Group",
            "default": "10",
            "type": "number",
            "required": True,
        },
        {
            "name": "virtual_ip",
            "label": "Virtual IP",
            "default": "192.168.10.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "priority",
            "label": "Priority",
            "default": "110",
            "type": "number",
            "required": True,
        },
        {
            "name": "preempt",
            "label": "Preempt",
            "default": "True",
            "type": "text",
            "required": True,
        },
    ],

    ("Cisco", "VRF"): [
        {
            "name": "vrf_name",
            "label": "VRF Name",
            "default": "CUSTOMER-A",
            "type": "text",
            "required": True,
        },
        {
            "name": "rd",
            "label": "Route Distinguisher",
            "default": "65001:100",
            "type": "text",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Interface",
            "default": "GigabitEthernet0/2",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "ip_address",
            "label": "IP Address",
            "default": "192.168.100.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "subnet_mask",
            "label": "Subnet Mask",
            "default": "255.255.255.0",
            "type": "text",
            "validation": "subnet_mask",
            "required": True,
        },
    ],

    ("Cisco", "IPsec VPN"): [
        {
            "name": "peer_ip",
            "label": "Peer IP",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "pre_shared_key",
            "label": "Pre-Shared Key",
            "default": "LAB-KEY",
            "type": "password",
            "required": True,
        },
        {
            "name": "local_network",
            "label": "Local Network",
            "default": "192.168.10.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "local_wildcard",
            "label": "Local Wildcard",
            "default": "0.0.0.255",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "remote_network",
            "label": "Remote Network",
            "default": "192.168.20.0",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "remote_wildcard",
            "label": "Remote Wildcard",
            "default": "0.0.0.255",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "outside_interface",
            "label": "Outside Interface",
            "default": "GigabitEthernet0/0",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    # ========================================================
    # FORTIGATE
    # ========================================================

    ("FortiGate", "NAT"): [
        {
            "name": "policy_id",
            "label": "Policy ID",
            "default": "20",
            "type": "number",
            "required": True,
        },
        {
            "name": "name",
            "label": "NAT Policy Name",
            "default": "USERS-NAT",
            "type": "text",
            "required": True,
        },
        {
            "name": "source_interface",
            "label": "Source Interface",
            "default": "internal",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "destination_interface",
            "label": "Destination Interface",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "source_address",
            "label": "Source Address",
            "default": "all",
            "type": "text",
            "required": True,
        },
        {
            "name": "destination_address",
            "label": "Destination Address",
            "default": "all",
            "type": "text",
            "required": True,
        },
        {
            "name": "service",
            "label": "Service",
            "default": "ALL",
            "type": "text",
            "required": True,
        },
    ],

    ("FortiGate", "IPsec VPN"): [
        {
            "name": "tunnel_name",
            "label": "Tunnel Name",
            "default": "HQ-BRANCH",
            "type": "text",
            "required": True,
        },
        {
            "name": "remote_gateway",
            "label": "Remote Gateway",
            "default": "203.0.113.50",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "local_interface",
            "label": "Local Interface",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "pre_shared_key",
            "label": "Pre-Shared Key",
            "default": "NETOPS-LAB-KEY",
            "type": "password",
            "required": True,
        },
        {
            "name": "local_subnet",
            "label": "Local Subnet",
            "default": "192.168.10.0 255.255.255.0",
            "type": "text",
            "required": True,
        },
        {
            "name": "remote_subnet",
            "label": "Remote Subnet",
            "default": "192.168.20.0 255.255.255.0",
            "type": "text",
            "required": True,
        },
        {
            "name": "proposal",
            "label": "Proposal",
            "default": "aes256-sha256",
            "type": "text",
            "required": True,
        },
        {
            "name": "dh_group",
            "label": "DH Group",
            "default": "14",
            "type": "number",
            "required": True,
        },
    ],

    ("FortiGate", "Interface"): [
        {
            "name": "name",
            "label": "Interface Name",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "ip_address",
            "label": "IP Address",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "subnet_mask",
            "label": "Subnet Mask",
            "default": "255.255.255.0",
            "type": "text",
            "validation": "subnet_mask",
            "required": True,
        },
        {
            "name": "alias",
            "label": "Alias",
            "default": "NETOPS",
            "type": "text",
            "required": False,
        },
    ],

    ("FortiGate", "Static Route"): [
        {
            "name": "destination",
            "label": "Destination",
            "default": "0.0.0.0/0",
            "type": "text",
            "validation": "cidr",
            "required": True,
        },
        {
            "name": "gateway",
            "label": "Gateway",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "device",
            "label": "Device",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("FortiGate", "Firewall Policy"): [
        {
            "name": "policy_id",
            "label": "Policy ID",
            "default": "1",
            "type": "number",
            "required": True,
        },
        {
            "name": "name",
            "label": "Policy Name",
            "default": "LAN-to-Internet",
            "type": "text",
            "required": True,
        },
        {
            "name": "source_interface",
            "label": "Source Interface",
            "default": "internal",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "destination_interface",
            "label": "Destination Interface",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "source_address",
            "label": "Source Address",
            "default": "all",
            "type": "text",
            "required": True,
        },
        {
            "name": "destination_address",
            "label": "Destination Address",
            "default": "all",
            "type": "text",
            "required": True,
        },
        {
            "name": "service",
            "label": "Service",
            "default": "ALL",
            "type": "text",
            "required": True,
        },
        {
            "name": "nat",
            "label": "NAT",
            "default": "True",
            "type": "text",
            "required": True,
        },
    ],

    ("FortiGate", "BGP"): [
        {
            "name": "local_asn",
            "label": "Local ASN",
            "default": "65001",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "neighbor_ip",
            "label": "Neighbor IP",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "remote_asn",
            "label": "Remote ASN",
            "default": "65002",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
    ],

    ("FortiGate", "OSPF"): [
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "network",
            "label": "Network CIDR",
            "default": "192.168.10.0/24",
            "type": "text",
            "validation": "cidr",
            "required": True,
        },
    ],

    ("FortiGate", "SD-WAN"): [
        {
            "name": "member1",
            "label": "WAN 1 Interface",
            "default": "wan1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "gateway1",
            "label": "WAN 1 Gateway",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "member2",
            "label": "WAN 2 Interface",
            "default": "wan2",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "gateway2",
            "label": "WAN 2 Gateway",
            "default": "198.51.100.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
    ],

    # ========================================================
    # PALO ALTO
    # ========================================================

    ("Palo Alto", "Layer3 Interface"): [
        {
            "name": "interface",
            "label": "Interface",
            "default": "ethernet1/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
        {
            "name": "ip_cidr",
            "label": "IP / CIDR",
            "default": "203.0.113.2/24",
            "type": "text",
            "validation": "cidr",
            "required": True,
        },
        {
            "name": "virtual_router",
            "label": "Virtual Router",
            "default": "default",
            "type": "text",
            "required": True,
        },
    ],

    ("Palo Alto", "Zone"): [
        {
            "name": "zone_name",
            "label": "Zone Name",
            "default": "UNTRUST",
            "type": "text",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Interface",
            "default": "ethernet1/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("Palo Alto", "Static Route"): [
        {
            "name": "virtual_router",
            "label": "Virtual Router",
            "default": "default",
            "type": "text",
            "required": True,
        },
        {
            "name": "route_name",
            "label": "Route Name",
            "default": "DEFAULT-ROUTE",
            "type": "text",
            "required": True,
        },
        {
            "name": "destination",
            "label": "Destination",
            "default": "0.0.0.0/0",
            "type": "text",
            "validation": "cidr",
            "required": True,
        },
        {
            "name": "next_hop",
            "label": "Next Hop",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Interface",
            "default": "ethernet1/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("Palo Alto", "Security Policy"): [
        {
            "name": "rule_name",
            "label": "Rule Name",
            "default": "LAN-TO-INTERNET",
            "type": "text",
            "required": True,
        },
        {
            "name": "from_zone",
            "label": "From Zone",
            "default": "TRUST",
            "type": "text",
            "required": True,
        },
        {
            "name": "to_zone",
            "label": "To Zone",
            "default": "UNTRUST",
            "type": "text",
            "required": True,
        },
        {
            "name": "source",
            "label": "Source",
            "default": "any",
            "type": "text",
            "required": True,
        },
        {
            "name": "destination",
            "label": "Destination",
            "default": "any",
            "type": "text",
            "required": True,
        },
        {
            "name": "application",
            "label": "Application",
            "default": "any",
            "type": "text",
            "required": True,
        },
        {
            "name": "service",
            "label": "Service",
            "default": "application-default",
            "type": "text",
            "required": True,
        },
        {
            "name": "action",
            "label": "Action",
            "default": "allow",
            "type": "text",
            "required": True,
        },
    ],

    ("Palo Alto", "NAT Policy"): [
        {
            "name": "rule_name",
            "label": "Rule Name",
            "default": "SOURCE-NAT",
            "type": "text",
            "required": True,
        },
        {
            "name": "from_zone",
            "label": "From Zone",
            "default": "TRUST",
            "type": "text",
            "required": True,
        },
        {
            "name": "to_zone",
            "label": "To Zone",
            "default": "UNTRUST",
            "type": "text",
            "required": True,
        },
        {
            "name": "source",
            "label": "Source",
            "default": "any",
            "type": "text",
            "required": True,
        },
        {
            "name": "destination",
            "label": "Destination",
            "default": "any",
            "type": "text",
            "required": True,
        },
        {
            "name": "translated_interface",
            "label": "Translated Interface",
            "default": "ethernet1/1",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],

    ("Palo Alto", "BGP"): [
        {
            "name": "virtual_router",
            "label": "Virtual Router",
            "default": "default",
            "type": "text",
            "required": True,
        },
        {
            "name": "local_asn",
            "label": "Local ASN",
            "default": "65001",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "peer_group",
            "label": "Peer Group",
            "default": "EBGP-PEERS",
            "type": "text",
            "required": True,
        },
        {
            "name": "peer_name",
            "label": "Peer Name",
            "default": "ISP-01",
            "type": "text",
            "required": True,
        },
        {
            "name": "peer_ip",
            "label": "Peer IP",
            "default": "203.0.113.2",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "remote_asn",
            "label": "Remote ASN",
            "default": "65002",
            "type": "number",
            "validation": "asn",
            "required": True,
        },
    ],

    ("Palo Alto", "OSPF"): [
        {
            "name": "virtual_router",
            "label": "Virtual Router",
            "default": "default",
            "type": "text",
            "required": True,
        },
        {
            "name": "router_id",
            "label": "Router ID",
            "default": "1.1.1.1",
            "type": "text",
            "validation": "ipv4",
            "required": True,
        },
        {
            "name": "area",
            "label": "Area",
            "default": "0.0.0.0",
            "type": "text",
            "required": True,
        },
        {
            "name": "interface",
            "label": "Interface",
            "default": "ethernet1/2",
            "type": "text",
            "validation": "interface",
            "required": True,
        },
    ],
}


# ============================================================
# API MODELS
# ============================================================

class ValidationRequest(BaseModel):
    field_name: str
    field_value: Any
    validation_type: str


class GenerateRequest(BaseModel):
    vendor: str
    platform: str
    technology: str
    parameters: Dict[str, Any]


class IPAMCalculateRequest(BaseModel):
    network: str


class IPAMSplitRequest(BaseModel):
    network: str
    new_prefix: int


class VLSMRequirement(BaseModel):
    name: str
    hosts: int


class IPAMVLSMRequest(BaseModel):
    network: str
    requirements: list[VLSMRequirement]


class IPAMAllocationCreateRequest(BaseModel):
    ip_address: str
    prefix: int
    hostname: str = ""
    device_type: str = ""
    vlan: str = ""
    location: str = ""
    status: str = "Assigned"
    description: str = ""


class IPAMAllocationUpdateRequest(BaseModel):
    ip_address: str | None = None
    prefix: int | None = None
    hostname: str | None = None
    device_type: str | None = None
    vlan: str | None = None
    location: str | None = None
    status: str | None = None
    description: str | None = None


# ============================================================
# VALIDATION ADAPTER
# ============================================================

def run_validation(validation_type: str, value: Any, field_name: str):
    validation_type = validation_type.strip().lower()

    if validation_type == "vlan":
        return NetworkValidator.validate_vlan_id(value)

    if validation_type == "ipv4":
        return NetworkValidator.validate_ipv4(
            value,
            field_name,
        )

    if validation_type == "asn":
        return NetworkValidator.validate_asn(value)

    if validation_type == "cidr":
        return NetworkValidator.validate_cidr(
            value,
            field_name,
        )

    if validation_type == "subnet_mask":
        return NetworkValidator.validate_subnet_mask(
            value,
            field_name,
        )

    if validation_type == "interface":
        return NetworkValidator.validate_interface_name(
            value,
            field_name,
        )

    if validation_type == "port":
        return NetworkValidator.validate_port(
            value,
            field_name,
        )

    if validation_type == "required":
        return NetworkValidator.validate_required(
            value,
            field_name,
        )

    raise HTTPException(
        status_code=400,
        detail=f"Unknown validation type: {validation_type}",
    )


# ============================================================
# ROUTES
# ============================================================

@app.get("/")
def root():
    return FileResponse(FRONTEND_DIR / "index.html")


@app.get("/api/health")
def health():
    return {
        "status": "online",
        "engine": "Project 16 Python Engine",
        "validator": "NetworkValidator",
        "vendors": len(VENDORS),
        "schema_count": len(SCHEMAS),
    }


@app.get("/api/vendors")
def get_vendors():
    return {
        "vendors": list(VENDORS.keys())
    }


@app.get("/api/platforms")
def get_platforms(vendor: str):
    vendor_data = VENDORS.get(vendor)

    if vendor_data is None:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown vendor: {vendor}",
        )

    return {
        "vendor": vendor,
        "platforms": vendor_data["platforms"],
    }


@app.get("/api/technologies")
def get_technologies(vendor: str):
    vendor_data = VENDORS.get(vendor)

    if vendor_data is None:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown vendor: {vendor}",
        )

    return {
        "vendor": vendor,
        "technologies": vendor_data["technologies"],
    }


@app.get("/api/schema")
def get_schema(vendor: str, technology: str):
    if vendor not in VENDORS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown vendor: {vendor}",
        )

    schema = SCHEMAS.get(
        (vendor, technology)
    )

    if schema is None:
        raise HTTPException(
            status_code=404,
            detail=(
                f"No parameter schema for "
                f"{vendor} / {technology}"
            ),
        )

    return {
        "vendor": vendor,
        "technology": technology,
        "parameters": schema,
    }


@app.post("/api/validate")
def validate_field(request: ValidationRequest):
    result = run_validation(
        request.validation_type,
        request.field_value,
        request.field_name,
    )

    return {
        "valid": result.valid,
        "errors": result.errors,
        "warnings": result.warnings,
        "message": (
            result.errors[0]
            if result.errors
            else "Valid"
        ),
    }


# ============================================================
# GENERATION HELPERS
# ============================================================

def as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value

    return str(value).strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
        "enable",
        "enabled",
    }


def as_int(value: Any, field_name: str) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=400,
            detail=f"{field_name} must be numeric.",
        )


def validate_generation_parameters(
    vendor: str,
    technology: str,
    parameters: Dict[str, Any],
):
    schema = SCHEMAS.get((vendor, technology))

    if schema is None:
        raise HTTPException(
            status_code=404,
            detail=f"No schema for {vendor} / {technology}",
        )

    errors = []

    for field in schema:
        name = field["name"]
        value = parameters.get(name, "")

        if field.get("required") and (
            value is None or str(value).strip() == ""
        ):
            errors.append(
                f"{field['label']} is required."
            )
            continue

        validation_type = field.get("validation")

        if (
            validation_type
            and value is not None
            and str(value).strip() != ""
        ):
            try:
                result = run_validation(
                    validation_type,
                    value,
                    field["label"],
                )

                if not result.valid:
                    errors.extend(result.errors)

            except HTTPException as exc:
                errors.append(str(exc.detail))

    if errors:
        unique_errors = []

        for error in errors:
            if error not in unique_errors:
                unique_errors.append(error)

        raise HTTPException(
            status_code=400,
            detail={
                "message": "Validation failed.",
                "errors": unique_errors,
            },
        )


# ============================================================
# PROJECT 16 GENERATOR DISPATCH
# ============================================================

def dispatch_generator(
    vendor: str,
    technology: str,
    p: Dict[str, Any],
) -> ConfigSection:

    # ========================================================
    # CISCO
    # ========================================================

    if vendor == "Cisco":

        if technology == "BGP":
            return cisco_generate_bgp(
                local_asn=as_int(
                    p["local_asn"],
                    "Local ASN",
                ),
                router_id=p["router_id"],
                neighbor_ip=p["neighbor_ip"],
                remote_asn=as_int(
                    p["remote_asn"],
                    "Remote ASN",
                ),
                network=p["network"],
                mask=p["mask"],
                description=p.get(
                    "description",
                    "",
                ),
            )

        if technology == "IS-IS":
            return cisco_generate_isis(
                process_name=p["process_name"],
                net=p["net"],
                interface=p["interface"],
                level=p.get(
                    "level",
                    "level-2-only",
                ),
            )

        if technology == "NAT/PAT":
            return cisco_generate_nat_pat(
                inside_network=p["inside_network"],
                wildcard=p["wildcard"],
                inside_interface=p["inside_interface"],
                outside_interface=p["outside_interface"],
            )

        if technology == "HSRP":
            return cisco_generate_hsrp(
                interface=p["interface"],
                group=as_int(
                    p["group"],
                    "HSRP Group",
                ),
                virtual_ip=p["virtual_ip"],
                priority=as_int(
                    p.get("priority", 110),
                    "Priority",
                ),
                preempt=as_bool(
                    p.get("preempt", True)
                ),
            )

        if technology == "VRF":
            return cisco_generate_vrf(
                vrf_name=p["vrf_name"],
                route_distinguisher=p["rd"],
                interface=p["interface"],
                ip_address=p["ip_address"],
                subnet_mask=p["subnet_mask"],
            )

        if technology == "IPsec VPN":
            return cisco_generate_ipsec(
                peer_ip=p["peer_ip"],
                pre_shared_key=p["pre_shared_key"],
                local_network=p["local_network"],
                local_wildcard=p["local_wildcard"],
                remote_network=p["remote_network"],
                remote_wildcard=p["remote_wildcard"],
                outside_interface=p.get(
                    "outside_interface",
                    "GigabitEthernet0/0",
                ),
            )

        if technology == "VLAN":
            return cisco_generate_vlan(
                vlan_id=as_int(
                    p["vlan_id"],
                    "VLAN ID",
                ),
                vlan_name=p["vlan_name"],
                interface=p["interface"],
            )

        if technology == "Trunk":
            return cisco_generate_trunk(
                interface=p["interface"],
                vlans=p["vlans"],
                native=p.get(
                    "native",
                    "",
                ),
            )

        if technology == "OSPF":
            return cisco_generate_ospf(
                process=p["process"],
                router_id=p["router_id"],
                network=p["network"],
                wildcard=p["wildcard"],
                area=p["area"],
            )

        if technology == "DHCP":
            return cisco_generate_dhcp(
                pool=p["pool"],
                network=p["network"],
                mask=p["mask"],
                gateway=p["gateway"],
                dns=p["dns"],
            )

        if technology == "Static Route":
            return cisco_generate_static_route(
                network=p["network"],
                mask=p["mask"],
                next_hop=p["next_hop"],
            )

        if technology == "ACL":
            return cisco_generate_acl(
                number=p["number"],
                action=p["action"],
                source=p["source"],
                wildcard=p["wildcard"],
            )

    # ========================================================
    # FORTIGATE
    # ========================================================

    elif vendor == "FortiGate":

        if technology == "Interface":
            return fortigate_generate_interface(
                name=p["name"],
                ip_address=p["ip_address"],
                subnet_mask=p["subnet_mask"],
                alias=p.get("alias", ""),
            )

        if technology == "Static Route":
            return fortigate_generate_static_route(
                destination=p["destination"],
                gateway=p["gateway"],
                device=p["device"],
            )

        if technology == "Firewall Policy":
            return fortigate_generate_firewall_policy(
                policy_id=as_int(
                    p["policy_id"],
                    "Policy ID",
                ),
                name=p["name"],
                source_interface=p["source_interface"],
                destination_interface=p[
                    "destination_interface"
                ],
                source_address=p.get(
                    "source_address",
                    "all",
                ),
                destination_address=p.get(
                    "destination_address",
                    "all",
                ),
                service=p.get(
                    "service",
                    "ALL",
                ),
                nat=as_bool(
                    p.get("nat", True)
                ),
            )

        if technology == "NAT":
            return fortigate_generate_firewall_policy(
                policy_id=as_int(
                    p["policy_id"],
                    "Policy ID",
                ),
                name=p["name"],
                source_interface=p["source_interface"],
                destination_interface=p[
                    "destination_interface"
                ],
                source_address=p.get(
                    "source_address",
                    "all",
                ),
                destination_address=p.get(
                    "destination_address",
                    "all",
                ),
                service=p.get(
                    "service",
                    "ALL",
                ),
                nat=True,
            )

        if technology == "BGP":
            return fortigate_generate_bgp(
                local_asn=as_int(
                    p["local_asn"],
                    "Local ASN",
                ),
                router_id=p["router_id"],
                neighbor_ip=p["neighbor_ip"],
                remote_asn=as_int(
                    p["remote_asn"],
                    "Remote ASN",
                ),
            )

        if technology == "OSPF":
            return fortigate_generate_ospf(
                router_id=p["router_id"],
                network=p["network"],
            )

        if technology == "SD-WAN":
            return fortigate_generate_sdwan(
                member1=p["member1"],
                member2=p["member2"],
                gateway1=p["gateway1"],
                gateway2=p["gateway2"],
            )

        if technology == "IPsec VPN":
            return fortigate_generate_ipsec(
                tunnel_name=p["tunnel_name"],
                remote_gateway=p["remote_gateway"],
                local_interface=p["local_interface"],
                pre_shared_key=p["pre_shared_key"],
                local_subnet=p["local_subnet"],
                remote_subnet=p["remote_subnet"],
                proposal=p.get(
                    "proposal",
                    "aes256-sha256",
                ),
                dh_group=str(
                    p.get("dh_group", "14")
                ),
            )

    # ========================================================
    # PALO ALTO
    # ========================================================

    elif vendor == "Palo Alto":

        if technology == "Layer3 Interface":
            return paloalto_generate_layer3_interface(
                interface=p["interface"],
                ip_cidr=p["ip_cidr"],
                virtual_router=p.get(
                    "virtual_router",
                    "default",
                ),
            )

        if technology == "Zone":
            return paloalto_generate_zone(
                zone_name=p["zone_name"],
                interface=p["interface"],
            )

        if technology == "Static Route":
            return paloalto_generate_static_route(
                virtual_router=p["virtual_router"],
                route_name=p["route_name"],
                destination=p["destination"],
                next_hop=p["next_hop"],
                interface=p["interface"],
            )

        if technology == "Security Policy":
            return paloalto_generate_security_policy(
                rule_name=p["rule_name"],
                from_zone=p["from_zone"],
                to_zone=p["to_zone"],
                source=p.get("source", "any"),
                destination=p.get(
                    "destination",
                    "any",
                ),
                application=p.get(
                    "application",
                    "any",
                ),
                service=p.get(
                    "service",
                    "application-default",
                ),
                action=p.get(
                    "action",
                    "allow",
                ),
            )

        if technology == "NAT Policy":
            return paloalto_generate_nat_policy(
                rule_name=p["rule_name"],
                from_zone=p["from_zone"],
                to_zone=p["to_zone"],
                source=p["source"],
                destination=p["destination"],
                translated_interface=p[
                    "translated_interface"
                ],
            )

        if technology == "BGP":
            return paloalto_generate_bgp(
                virtual_router=p["virtual_router"],
                local_asn=as_int(
                    p["local_asn"],
                    "Local ASN",
                ),
                router_id=p["router_id"],
                peer_group=p["peer_group"],
                peer_name=p["peer_name"],
                peer_ip=p["peer_ip"],
                remote_asn=as_int(
                    p["remote_asn"],
                    "Remote ASN",
                ),
            )

        if technology == "OSPF":
            return paloalto_generate_ospf(
                virtual_router=p["virtual_router"],
                router_id=p["router_id"],
                area=p["area"],
                interface=p["interface"],
            )

    raise HTTPException(
        status_code=404,
        detail=(
            f"Generator not available for "
            f"{vendor} / {technology}"
        ),
    )


# ============================================================
# GENERATE API
# ============================================================

@app.post("/api/generate")
def generate_configuration(
    request: GenerateRequest
):

    if request.vendor not in VENDORS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown vendor: {request.vendor}",
        )

    if (
        request.technology
        not in VENDORS[
            request.vendor
        ]["technologies"]
    ):
        raise HTTPException(
            status_code=404,
            detail=(
                f"Unknown technology "
                f"{request.vendor} / "
                f"{request.technology}"
            ),
        )

    validate_generation_parameters(
        request.vendor,
        request.technology,
        request.parameters,
    )

    section = dispatch_generator(
        request.vendor,
        request.technology,
        request.parameters,
    )

    return {
        "success": True,
        "vendor": section.vendor,
        "platform": section.platform,
        "technology": section.technology,
        "name": section.name,
        "config": section.config,
    }


# ============================================================
# NETFORGE IPAM API
# ============================================================

@app.post("/api/ipam/calculate")
def ipam_calculate(request: IPAMCalculateRequest):

    try:
        result = calculate_network(
            request.network
        )

        return {
            "success": True,
            "input": request.network,
            "result": result,
        }

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.post("/api/ipam/split")
def ipam_split(request: IPAMSplitRequest):

    try:
        result = split_network(
            request.network,
            request.new_prefix,
        )

        return {
            "success": True,
            "input": request.network,
            "new_prefix": request.new_prefix,
            "count": len(result),
            "subnets": result,
        }

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.post("/api/ipam/vlsm")
def ipam_vlsm(request: IPAMVLSMRequest):

    try:

        requirements = [
            (
                item.name,
                item.hosts,
            )
            for item in request.requirements
        ]

        result = vlsm_plan(
            request.network,
            requirements,
        )

        return {
            "success": True,
            "input": request.network,
            "count": len(result),
            "plan": result,
        }

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


# ============================================================
# NETFORGE IPAM DATABASE API
# ============================================================

@app.post("/api/ipam/allocations")
def ipam_add_allocation(
    request: IPAMAllocationCreateRequest
):
    try:
        record_id = ipam_db.add(
            request.ip_address,
            request.prefix,
            hostname=request.hostname,
            device_type=request.device_type,
            vlan=request.vlan,
            location=request.location,
            status=request.status,
            description=request.description,
        )

        return {
            "success": True,
            "record_id": record_id,
            "record": ipam_db.get(record_id),
        }

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.get("/api/ipam/allocations")
def ipam_list_allocations(
    search: str = ""
):
    try:
        records = ipam_db.list(search)

        return {
            "success": True,
            "count": len(records),
            "records": records,
        }

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.get("/api/ipam/allocations/{record_id}")
def ipam_get_allocation(
    record_id: int
):
    try:
        record = ipam_db.get(record_id)

        if record is None:
            raise HTTPException(
                status_code=404,
                detail="IPAM record not found.",
            )

        return {
            "success": True,
            "record": record,
        }

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.put("/api/ipam/allocations/{record_id}")
def ipam_update_allocation(
    record_id: int,
    request: IPAMAllocationUpdateRequest
):
    try:
        existing = ipam_db.get(record_id)

        if existing is None:
            raise HTTPException(
                status_code=404,
                detail="IPAM record not found.",
            )

        fields = {
            key: value
            for key, value in request.model_dump().items()
            if value is not None
        }

        if not fields:
            raise HTTPException(
                status_code=400,
                detail="No update fields provided.",
            )

        ipam_db.update(
            record_id,
            **fields,
        )

        return {
            "success": True,
            "record": ipam_db.get(record_id),
        }

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.delete("/api/ipam/allocations/{record_id}")
def ipam_delete_allocation(
    record_id: int
):
    try:
        existing = ipam_db.get(record_id)

        if existing is None:
            raise HTTPException(
                status_code=404,
                detail="IPAM record not found.",
            )

        ipam_db.delete(record_id)

        return {
            "success": True,
            "deleted_id": record_id,
        }

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


# ============================================================
# NETFORGE IPAM CSV API
# ============================================================

@app.post("/api/ipam/import-csv")
async def ipam_import_csv(
    file: UploadFile = File(...)
):
    try:

        if not file.filename.lower().endswith(".csv"):
            raise HTTPException(
                status_code=400,
                detail="Only CSV files are supported.",
            )

        import_dir = NETFORGE_DATA_DIR / "imports"
        import_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        import_path = (
            import_dir /
            f"ipam-import-{file.filename}"
        )

        content = await file.read()

        with open(
            import_path,
            "wb"
        ) as handle:
            handle.write(content)

        result = ipam_db.import_csv(
            str(import_path)
        )

        return {
            "success": True,
            "filename": file.filename,
            "result": result,
        }

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.get("/api/ipam/export-csv")
def ipam_export_csv():

    try:

        export_dir = NETFORGE_DATA_DIR / "exports"

        export_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        export_path = (
            export_dir /
            "netforge-ipam-export.csv"
        )

        ipam_db.export_csv(
            str(export_path)
        )

        if not export_path.exists():
            raise HTTPException(
                status_code=500,
                detail="CSV export file was not created.",
            )

        return FileResponse(
            path=str(export_path),
            media_type="text/csv",
            filename="netforge-ipam-export.csv",
        )

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


# ============================================================
# LOCAL DEVELOPMENT
# ============================================================

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "api:app",
        host="127.0.0.1",
        port=8000,
        reload=False,
    )

# ============================================================
# NETFORGE WEB FRONTEND
# ============================================================

FRONTEND_DIR = PROJECT_ROOT / "web-ui" / "frontend"

app.mount("/css", StaticFiles(directory=FRONTEND_DIR / "css"), name="css")
app.mount("/js", StaticFiles(directory=FRONTEND_DIR / "js"), name="js")
app.mount("/assets", StaticFiles(directory=FRONTEND_DIR / "assets"), name="assets")

@app.get("/")
def netforge_web_ui():
    return FileResponse(FRONTEND_DIR / "index.html")


@app.get("/manifest.webmanifest", include_in_schema=False)
def netforge_manifest():
    return FileResponse(FRONTEND_DIR / "manifest.webmanifest", media_type="application/manifest+json")

@app.get("/sw.js", include_in_schema=False)
def netforge_service_worker():
    return FileResponse(FRONTEND_DIR / "sw.js", media_type="application/javascript")
