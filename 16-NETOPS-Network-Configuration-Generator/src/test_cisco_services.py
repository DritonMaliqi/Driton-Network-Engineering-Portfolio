from pathlib import Path
import sys

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

from core.builder import ConfigurationBuilder

from vendors.cisco import (
    generate_ipsec_site_to_site,
    generate_nat_pat,
    generate_hsrp,
    generate_vrf
)


def main():
    builder = ConfigurationBuilder()

    vpn = generate_ipsec_site_to_site(
        peer_ip="203.0.113.2",
        pre_shared_key="LAB-KEY-123",
        local_network="192.168.10.0",
        local_wildcard="0.0.0.255",
        remote_network="192.168.20.0",
        remote_wildcard="0.0.0.255",
        outside_interface="GigabitEthernet0/0"
    )

    nat = generate_nat_pat(
        inside_network="192.168.10.0",
        wildcard="0.0.0.255",
        inside_interface="GigabitEthernet0/1",
        outside_interface="GigabitEthernet0/0"
    )

    hsrp = generate_hsrp(
        interface="GigabitEthernet0/1",
        group=10,
        virtual_ip="192.168.10.254",
        priority=110,
        preempt=True
    )

    vrf = generate_vrf(
        vrf_name="CUSTOMER-A",
        route_distinguisher="65001:100",
        interface="GigabitEthernet0/2",
        ip_address="10.10.10.1",
        subnet_mask="255.255.255.0"
    )

    builder.add_section(vpn)
    builder.add_section(nat)
    builder.add_section(hsrp)
    builder.add_section(vrf)

    print()
    print("=" * 65)
    print(" PROJECT 16 - CISCO VPN / NAT / HSRP / VRF TEST")
    print("=" * 65)
    print()
    print(builder.build())
    print()


if __name__ == "__main__":
    main()
