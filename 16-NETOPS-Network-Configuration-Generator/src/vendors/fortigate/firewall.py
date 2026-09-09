from core.models import ConfigSection


def generate_interface(
    name,
    ip_address,
    subnet_mask,
    alias=""
):
    lines = [
        "config system interface",
        f'    edit "{name}"',
        f"        set ip {ip_address} {subnet_mask}",
        "        set allowaccess ping https ssh"
    ]

    if alias:
        lines.append(
            f'        set alias "{alias}"'
        )

    lines.extend([
        "    next",
        "end"
    ])

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="Interface",
        name=name,
        config="\n".join(lines)
    )


def generate_firewall_policy(
    policy_id,
    name,
    source_interface,
    destination_interface,
    source_address="all",
    destination_address="all",
    service="ALL",
    nat=True
):
    lines = [
        "config firewall policy",
        f"    edit {policy_id}",
        f'        set name "{name}"',
        f'        set srcintf "{source_interface}"',
        f'        set dstintf "{destination_interface}"',
        f'        set srcaddr "{source_address}"',
        f'        set dstaddr "{destination_address}"',
        "        set action accept",
        f'        set service "{service}"',
        "        set schedule \"always\""
    ]

    if nat:
        lines.append(
            "        set nat enable"
        )

    lines.extend([
        "    next",
        "end"
    ])

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="Firewall Policy",
        name=name,
        config="\n".join(lines)
    )
