from core.models import ConfigSection


def generate_sdwan(
    member1,
    member2,
    gateway1,
    gateway2
):
    lines = [
        "config system sdwan",
        "    set status enable",
        "    config members",
        "        edit 1",
        f'            set interface "{member1}"',
        f"            set gateway {gateway1}",
        "        next",
        "        edit 2",
        f'            set interface "{member2}"',
        f"            set gateway {gateway2}",
        "        next",
        "    end",
        "    config service",
        "        edit 1",
        '            set name "NETOPS-SDWAN"',
        "            set mode priority",
        "            set dst \"all\"",
        "            set src \"all\"",
        "            set priority-members 1 2",
        "        next",
        "    end",
        "end"
    ]

    return ConfigSection(
        vendor="Fortinet",
        platform="FortiGate",
        technology="SD-WAN",
        name="Dual WAN SD-WAN",
        config="\n".join(lines)
    )
