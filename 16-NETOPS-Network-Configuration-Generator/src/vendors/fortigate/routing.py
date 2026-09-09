from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_static_route(
    destination,
    gateway,
    device
):
    dest_result = NetworkValidator.validate_ipv4(
        destination.split("/")[0],
        "Destination Network"
    )

    gw_result = NetworkValidator.validate_ipv4(
        gateway,
        "Gateway"
    )

    errors = []
    errors.extend(dest_result.errors)
    errors.extend(gw_result.errors)

    if errors:
        raise ValueError("\n".join(errors))

    lines = [
        "config router static",
        "    edit 1",
        f'        set dst {destination}',
        f'        set gateway {gateway}',
        f'        set device "{device}"',
        "    next",
        "end"
    ]

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="Static Route",
        name=f"Route {destination}",
        config="\n".join(lines)
    )


def generate_bgp(
    local_asn,
    router_id,
    neighbor_ip,
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
            neighbor_ip,
            "Neighbor IP"
        ).errors
    )

    if errors:
        raise ValueError("\n".join(errors))

    lines = [
        "config router bgp",
        f"    set as {local_asn}",
        f"    set router-id {router_id}",
        "    config neighbor",
        f'        edit "{neighbor_ip}"',
        f"            set remote-as {remote_asn}",
        "        next",
        "    end",
        "end"
    ]

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="BGP",
        name=f"BGP AS{local_asn}",
        config="\n".join(lines)
    )


def generate_ospf(
    router_id,
    network,
    area="0.0.0.0"
):
    errors = []

    errors.extend(
        NetworkValidator.validate_ipv4(
            router_id,
            "Router ID"
        ).errors
    )

    errors.extend(
        NetworkValidator.validate_ipv4(
            network.split("/")[0],
            "OSPF Network"
        ).errors
    )

    if errors:
        raise ValueError("\n".join(errors))

    lines = [
        "config router ospf",
        f"    set router-id {router_id}",
        "    config area",
        f'        edit "{area}"',
        "        next",
        "    end",
        "    config network",
        "        edit 1",
        f"            set prefix {network}",
        f"            set area {area}",
        "        next",
        "    end",
        "end"
    ]

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="OSPF",
        name=f"OSPF {network}",
        config="\n".join(lines)
    )
