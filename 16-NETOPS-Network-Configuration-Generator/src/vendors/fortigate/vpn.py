from core.models import ConfigSection


def generate_ipsec_site_to_site(
    tunnel_name,
    remote_gateway,
    local_interface,
    pre_shared_key,
    local_subnet,
    remote_subnet,
    proposal="aes256-sha256",
    dh_group="14"
):
    lines = [
        "config vpn ipsec phase1-interface",
        f'    edit "{tunnel_name}"',
        f'        set interface "{local_interface}"',
        "        set ike-version 2",
        f"        set remote-gw {remote_gateway}",
        f"        set proposal {proposal}",
        f"        set dhgrp {dh_group}",
        f'        set psksecret "{pre_shared_key}"',
        "    next",
        "end",
        "",
        "config vpn ipsec phase2-interface",
        f'    edit "{tunnel_name}-P2"',
        f'        set phase1name "{tunnel_name}"',
        f"        set proposal {proposal}",
        f"        set src-subnet {local_subnet}",
        f"        set dst-subnet {remote_subnet}",
        "    next",
        "end"
    ]

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="IPsec VPN",
        name=tunnel_name,
        config="\n".join(lines)
    )