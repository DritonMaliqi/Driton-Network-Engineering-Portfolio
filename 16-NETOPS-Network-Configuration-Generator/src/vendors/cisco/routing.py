from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_bgp(
    local_asn,
    router_id,
    neighbor_ip,
    remote_asn,
    network,
    mask,
    description=""
):
    errors = []

    local_asn_result = NetworkValidator.validate_asn(local_asn)
    remote_asn_result = NetworkValidator.validate_asn(remote_asn)
    router_id_result = NetworkValidator.validate_ipv4(
        router_id,
        "Router ID"
    )
    neighbor_result = NetworkValidator.validate_ipv4(
        neighbor_ip,
        "Neighbor IP"
    )
    network_result = NetworkValidator.validate_ipv4(
        network,
        "Network"
    )

    errors.extend(local_asn_result.errors)
    errors.extend(remote_asn_result.errors)
    errors.extend(router_id_result.errors)
    errors.extend(neighbor_result.errors)
    errors.extend(network_result.errors)

    if errors:
        raise ValueError("\n".join(errors))

    lines = [
        "!",
        f"router bgp {local_asn}",
        f" bgp router-id {router_id}"
    ]

    if description:
        lines.append(
            f" neighbor {neighbor_ip} description {description}"
        )

    lines.extend([
        f" neighbor {neighbor_ip} remote-as {remote_asn}",
        f" network {network} mask {mask}",
        "!"
    ])

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="BGP",
        name=f"BGP AS{local_asn}",
        config="\n".join(lines)
    )


def generate_isis(
    process_name,
    net,
    interface,
    level="level-2-only"
):
    if not process_name:
        raise ValueError("IS-IS process name is required.")

    if not net:
        raise ValueError("IS-IS NET is required.")

    if not interface:
        raise ValueError("Interface is required.")

    valid_levels = {
        "level-1",
        "level-1-2",
        "level-2-only"
    }

    if level not in valid_levels:
        raise ValueError(
            "IS-IS level must be level-1, "
            "level-1-2, or level-2-only."
        )

    lines = [
        "!",
        f"router isis {process_name}",
        f" net {net}",
        f" is-type {level}",
        "!",
        f"interface {interface}",
        f" ip router isis {process_name}",
        "!"
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="IS-IS",
        name=f"IS-IS {process_name}",
        config="\n".join(lines)
    )
