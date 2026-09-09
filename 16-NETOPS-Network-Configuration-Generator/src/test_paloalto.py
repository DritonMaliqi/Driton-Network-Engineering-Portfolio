from pathlib import Path
import sys

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

from core.builder import ConfigurationBuilder

from vendors.paloalto import (
    generate_layer3_interface,
    generate_static_route,
    generate_bgp,
    generate_ospf,
    generate_zone,
    generate_security_policy,
    generate_nat_policy
)


def main():
    builder = ConfigurationBuilder()

    interface = generate_layer3_interface(
        interface="ethernet1/1",
        ip_cidr="203.0.113.10/24",
        virtual_router="default"
    )

    zone = generate_zone(
        zone_name="UNTRUST",
        interface="ethernet1/1"
    )

    route = generate_static_route(
        virtual_router="default",
        route_name="DEFAULT-ROUTE",
        destination="0.0.0.0/0",
        next_hop="203.0.113.1",
        interface="ethernet1/1"
    )

    policy = generate_security_policy(
        rule_name="LAN-TO-INTERNET",
        from_zone="TRUST",
        to_zone="UNTRUST",
        source="any",
        destination="any",
        application="any",
        service="application-default",
        action="allow"
    )

    nat = generate_nat_policy(
        rule_name="SOURCE-NAT",
        from_zone="TRUST",
        to_zone="UNTRUST",
        source="any",
        destination="any",
        translated_interface="ethernet1/1"
    )

    bgp = generate_bgp(
        virtual_router="default",
        local_asn=65001,
        router_id="1.1.1.1",
        peer_group="EBGP-PEERS",
        peer_name="ISP-01",
        peer_ip="203.0.113.2",
        remote_asn=65002
    )

    ospf = generate_ospf(
        virtual_router="default",
        router_id="1.1.1.1",
        area="0.0.0.0",
        interface="ethernet1/2"
    )

    builder.add_section(interface)
    builder.add_section(zone)
    builder.add_section(route)
    builder.add_section(policy)
    builder.add_section(nat)
    builder.add_section(bgp)
    builder.add_section(ospf)

    print()
    print("=" * 65)
    print(" PROJECT 16 - PALO ALTO ENGINE TEST")
    print("=" * 65)
    print()
    print(builder.build())
    print()


if __name__ == "__main__":
    main()
