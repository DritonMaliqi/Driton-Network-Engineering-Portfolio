from core.models import ConfigSection


def generate_zone(
    zone_name,
    interface
):
    lines = [
        f"set zone {zone_name} network layer3 {interface}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="Zone",
        name=zone_name,
        config="\n".join(lines)
    )


def generate_security_policy(
    rule_name,
    from_zone,
    to_zone,
    source="any",
    destination="any",
    application="any",
    service="application-default",
    action="allow"
):
    base = f"set rulebase security rules {rule_name}"

    lines = [
        f"{base} from {from_zone}",
        f"{base} to {to_zone}",
        f"{base} source {source}",
        f"{base} destination {destination}",
        f"{base} application {application}",
        f"{base} service {service}",
        f"{base} action {action}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="Security Policy",
        name=rule_name,
        config="\n".join(lines)
    )


def generate_nat_policy(
    rule_name,
    from_zone,
    to_zone,
    source,
    destination,
    translated_interface
):
    base = f"set rulebase nat rules {rule_name}"

    lines = [
        f"{base} from {from_zone}",
        f"{base} to {to_zone}",
        f"{base} source {source}",
        f"{base} destination {destination}",
        f"{base} service any",
        f"{base} source-translation dynamic-ip-and-port interface-address interface {translated_interface}"
    ]

    return ConfigSection(
        vendor="Palo Alto Networks",
        platform="PAN-OS",
        technology="NAT Policy",
        name=rule_name,
        config="\n".join(lines)
    )
