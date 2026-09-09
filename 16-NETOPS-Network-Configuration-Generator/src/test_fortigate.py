from pathlib import Path
import sys

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

from core.builder import ConfigurationBuilder

from vendors.fortigate import (
    generate_interface,
    generate_static_route,
    generate_firewall_policy,
    generate_bgp,
    generate_ospf,
    generate_sdwan
)


def main():
    builder = ConfigurationBuilder()

    wan = generate_interface(
        name="wan1",
        ip_address="203.0.113.10",
        subnet_mask="255.255.255.0",
        alias="INTERNET"
    )

    route = generate_static_route(
        destination="0.0.0.0/0",
        gateway="203.0.113.1",
        device="wan1"
    )

    policy = generate_firewall_policy(
        policy_id=1,
        name="LAN-to-Internet",
        source_interface="internal",
        destination_interface="wan1",
        nat=True
    )

    bgp = generate_bgp(
        local_asn=65001,
        router_id="1.1.1.1",
        neighbor_ip="203.0.113.2",
        remote_asn=65002
    )

    ospf = generate_ospf(
        router_id="1.1.1.1",
        network="10.10.10.0/24"
    )

    sdwan = generate_sdwan(
        member1="wan1",
        member2="wan2",
        gateway1="203.0.113.1",
        gateway2="198.51.100.1"
    )

    builder.add_section(wan)
    builder.add_section(route)
    builder.add_section(policy)
    builder.add_section(bgp)
    builder.add_section(ospf)
    builder.add_section(sdwan)

    print()
    print("=" * 65)
    print(" PROJECT 16 - FORTIGATE ENGINE TEST")
    print("=" * 65)
    print()
    print(builder.build())
    print()


if __name__ == "__main__":
    main()
