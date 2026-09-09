from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_layer3_interface(
    interface,
    ip_cidr,
    virtual_router="default"
):
    ip_part = ip_cidr.split("/")[0]

    result = NetworkValidator.validate_ipv4(
        ip_part,
        "Interface IP"
    )

    if not result.valid:
        raise ValueError("\n".join(result.errors))

    lines = [
        f"set network interface ethernet {interface} layer3 ip {ip_cidr}",
        f"set network virtual-router {virtual_router} interface {interface}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="Layer3 Interface",
        name=interface,
        config="\n".join(lines)
    )


def generate_static_route(
    virtual_router,
    route_name,
    destination,
    next_hop,
    interface
):
    result = NetworkValidator.validate_ipv4(
        next_hop,
        "Next Hop"
    )

    if not result.valid:
        raise ValueError("\n".join(result.errors))

    lines = [
        f"set network virtual-router {virtual_router} routing-table ip static-route {route_name} destination {destination}",
        f"set network virtual-router {virtual_router} routing-table ip static-route {route_name} interface {interface}",
        f"set network virtual-router {virtual_router} routing-table ip static-route {route_name} nexthop ip-address {next_hop}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="Static Route",
        name=route_name,
        config="\n".join(lines)
    )


def generate_bgp(
    virtual_router,
    local_asn,
    router_id,
    peer_group,
    peer_name,
    peer_ip,
    remote_asn
):
    errors = []

    errors.extend(
        NetworkValidator.validate_asn(local_asn).errors
    )

    errors.extend(
        NetworkValidator.validate_asn(remote_asn).errors
    )

    errors.extend(
        NetworkValidator.validate_ipv4(
            router_id,
            "Router ID"
        ).errors
    )

    errors.extend(
        NetworkValidator.validate_ipv4(
            peer_ip,
            "Peer IP"
        ).errors
    )

    if errors:
        raise ValueError("\n".join(errors))

    base = f"set network virtual-router {virtual_router} protocol bgp"

    lines = [
        f"{base} enable yes",
        f"{base} router-id {router_id}",
        f"{base} local-as {local_asn}",
        f"{base} peer-group {peer_group} type ebgp",
        f"{base} peer-group {peer_group} peer {peer_name} peer-address ip {peer_ip}",
        f"{base} peer-group {peer_group} peer {peer_name} peer-as {remote_asn}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="BGP",
        name=f"BGP {local_asn}",
        config="\n".join(lines)
    )


def generate_ospf(
    virtual_router,
    router_id,
    area,
    interface
):
    result = NetworkValidator.validate_ipv4(
        router_id,
        "Router ID"
    )

    if not result.valid:
        raise ValueError("\n".join(result.errors))

    base = f"set network virtual-router {virtual_router} protocol ospf"

    lines = [
        f"{base} enable yes",
        f"{base} router-id {router_id}",
        f"{base} area {area} type normal",
        f"{base} area {area} interface {interface} enable yes"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="OSPF",
        name=f"OSPF Area {area}",
        config="\n".join(lines)
    )
