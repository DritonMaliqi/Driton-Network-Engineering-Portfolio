"""
Project 16 - Cisco Classic Configuration Generators

These functions were extracted from the original Tkinter GUI so
the same configuration engine can be reused by the Web UI.

Technologies:
- VLAN
- Trunk
- OSPF
- DHCP
- Static Route
- ACL
"""

from core.models import ConfigSection


def generate_vlan(
    vlan_id,
    vlan_name,
    interface
):
    lines = [
        "!",
        f"vlan {vlan_id}",
        f" name {vlan_name}",
        "!",
        f"interface {interface}",
        " switchport mode access",
        f" switchport access vlan {vlan_id}",
        " spanning-tree portfast",
        " no shutdown",
        "!",
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="VLAN",
        name=f"VLAN {vlan_id}",
        config="\n".join(lines),
    )


def generate_trunk(
    interface,
    vlans,
    native=""
):
    lines = [
        "!",
        f"interface {interface}",
        " switchport mode trunk",
        f" switchport trunk allowed vlan {vlans}",
    ]

    if str(native).strip():
        lines.append(
            f" switchport trunk native vlan {native}"
        )

    lines.extend([
        " no shutdown",
        "!",
    ])

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="Trunk",
        name=f"Trunk {interface}",
        config="\n".join(lines),
    )


def generate_ospf(
    process,
    router_id,
    network,
    wildcard,
    area
):
    lines = [
        "!",
        f"router ospf {process}",
        f" router-id {router_id}",
        f" network {network} {wildcard} area {area}",
        "!",
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="OSPF",
        name=f"OSPF {process}",
        config="\n".join(lines),
    )


def generate_dhcp(
    pool,
    network,
    mask,
    gateway,
    dns
):
    lines = [
        "!",
        f"ip dhcp pool {pool}",
        f" network {network} {mask}",
        f" default-router {gateway}",
        f" dns-server {dns}",
        "!",
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="DHCP",
        name=f"DHCP {pool}",
        config="\n".join(lines),
    )


def generate_static_route(
    network,
    mask,
    next_hop
):
    lines = [
        "!",
        f"ip route {network} {mask} {next_hop}",
        "!",
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="Static Route",
        name=f"Route {network}",
        config="\n".join(lines),
    )


def generate_acl(
    number,
    action,
    source,
    wildcard
):
    lines = [
        "!",
        f"access-list {number} {action} {source} {wildcard}",
        "!",
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS",
        technology="ACL",
        name=f"ACL {number}",
        config="\n".join(lines),
    )