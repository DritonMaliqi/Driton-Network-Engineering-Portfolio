from pathlib import Path
import sys

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

from core.builder import ConfigurationBuilder
from vendors.cisco.routing import generate_bgp, generate_isis


def main():
    builder = ConfigurationBuilder()

    bgp = generate_bgp(
        local_asn=65001,
        router_id="1.1.1.1",
        neighbor_ip="10.0.12.2",
        remote_asn=65002,
        network="192.168.10.0",
        mask="255.255.255.0",
        description="BRANCH-PEER"
    )

    isis = generate_isis(
        process_name="CORE",
        net="49.0001.0000.0000.0001.00",
        interface="GigabitEthernet0/1",
        level="level-2-only"
    )

    builder.add_section(bgp)
    builder.add_section(isis)

    print()
    print("=" * 65)
    print(" PROJECT 16 - CISCO ADVANCED GENERATOR TEST")
    print("=" * 65)
    print()
    print(builder.build())
    print()


if __name__ == "__main__":
    main()
