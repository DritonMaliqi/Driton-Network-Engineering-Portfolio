from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_nat_pat(
    inside_network,
    wildcard,
    inside_interface,
    outside_interface,
    access_list=10
):
    network_result = NetworkValidator.validate_ipv4(
        inside_network,
        "Inside Network"
    )

    if not network_result.valid:
        raise ValueError("\n".join(network_result.errors))

    lines = [
        "!",
        f"access-list {access_list} permit {inside_network} {wildcard}",
        "!",
        f"interface {inside_interface}",
        " ip nat inside",
        "!",
        f"interface {outside_interface}",
        " ip nat outside",
        "!",
        f"ip nat inside source list {access_list} interface {outside_interface} overload",
        "!"
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="NAT/PAT",
        name="Dynamic PAT",
        config="\n".join(lines)
    )
