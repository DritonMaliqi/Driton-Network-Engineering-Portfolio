from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_hsrp(
    interface,
    group,
    virtual_ip,
    priority=110,
    preempt=True
):
    ip_result = NetworkValidator.validate_ipv4(
        virtual_ip,
        "HSRP Virtual IP"
    )

    if not ip_result.valid:
        raise ValueError("\n".join(ip_result.errors))

    lines = [
        "!",
        f"interface {interface}",
        f" standby {group} ip {virtual_ip}",
        f" standby {group} priority {priority}"
    ]

    if preempt:
        lines.append(
            f" standby {group} preempt"
        )

    lines.append("!")

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="HSRP",
        name=f"HSRP Group {group}",
        config="\n".join(lines)
    )


def generate_vrf(
    vrf_name,
    route_distinguisher,
    interface,
    ip_address,
    subnet_mask
):
    ip_result = NetworkValidator.validate_ipv4(
        ip_address,
        "VRF Interface IP"
    )

    if not ip_result.valid:
        raise ValueError("\n".join(ip_result.errors))

    if not vrf_name:
        raise ValueError("VRF name is required.")

    if not route_distinguisher:
        raise ValueError(
            "Route distinguisher is required."
        )

    lines = [
        "!",
        f"ip vrf {vrf_name}",
        f" rd {route_distinguisher}",
        "!",
        f"interface {interface}",
        f" ip vrf forwarding {vrf_name}",
        f" ip address {ip_address} {subnet_mask}",
        " no shutdown",
        "!"
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="VRF",
        name=f"VRF {vrf_name}",
        config="\n".join(lines)
    )
