import random
from models import Device, LabScenario


def vlan_scenario(lab_id: str, level: str) -> LabScenario:
    if level == "Hard":
        return LabScenario(
            lab_id=lab_id,
            level=level,
            topic="VLAN Troubleshooting",
            incident="Finance users have partial connectivity problems between local and remote network segments.",
            symptom=(
                "PC-FIN-02 cannot communicate with PC-FIN-01, "
                "and Finance traffic also fails across the uplink."
            ),
            devices=[
                Device("SW-ACCESS-01", "Access Switch"),
                Device("SW-DIST-01", "Distribution Switch"),
                Device("PC-FIN-01", "Finance Workstation"),
                Device("PC-FIN-02", "Finance Workstation"),
            ],
            fault="Multiple Layer 2 faults are present.",
            expected_command="show vlan brief",
            expected_fix="Correct the access VLAN and trunk configuration.",
            faults=[
                "Fa0/2 is assigned to VLAN 1 instead of VLAN 10.",
                "VLAN 10 is missing from the Gi0/1 trunk allowed VLAN list.",
            ],
            expected_commands=[
                "show vlan brief",
                "show interfaces trunk",
                "show interfaces fa0/2 switchport",
            ],
            expected_fixes=[
                "Configure Fa0/2 as an access port in VLAN 10.",
                "Add VLAN 10 to the Gi0/1 trunk allowed VLAN list.",
            ],
        )

    return LabScenario(
        lab_id=lab_id,
        level=level,
        topic="VLAN Troubleshooting",
        incident="PC-FIN-02 cannot communicate with PC-FIN-01.",
        symptom=(
            "Both devices are connected to the same access switch, "
            "but Layer 2 communication fails."
        ),
        devices=[
            Device("SW-ACCESS-01", "Access Switch"),
            Device("PC-FIN-01", "Finance Workstation"),
            Device("PC-FIN-02", "Finance Workstation"),
        ],
        fault="Fa0/2 is assigned to VLAN 1 instead of VLAN 10.",
        expected_command="show vlan brief",
        expected_fix="interface fa0/2 -> switchport access vlan 10",
    )


def trunk_scenario(lab_id: str, level: str) -> LabScenario:
    return LabScenario(
        lab_id=lab_id,
        level=level,
        topic="Trunk Troubleshooting",
        incident="Finance users cannot reach resources across the uplink.",
        symptom="Local VLAN communication works, but VLAN 10 traffic does not cross the trunk.",
        devices=[
            Device("SW-ACCESS-01", "Access Switch"),
            Device("SW-DIST-01", "Distribution Switch"),
        ],
        fault="VLAN 10 is missing from the trunk allowed VLAN list.",
        expected_command="show interfaces trunk",
        expected_fix="switchport trunk allowed vlan add 10",
    )


def ospf_scenario(lab_id: str, level: str) -> LabScenario:
    if level == "Hard":
        return LabScenario(
            lab_id=lab_id,
            level=level,
            topic="OSPF Troubleshooting",
            incident="Branch routes are missing and OSPF adjacency does not form correctly.",
            symptom=(
                "The WAN link is reachable at Layer 3, but routing information "
                "is not exchanged between HQ and Branch."
            ),
            devices=[
                Device("R-HQ-01", "HQ Router"),
                Device("R-BRANCH-01", "Branch Router"),
            ],
            fault="Multiple OSPF configuration problems are present.",
            expected_command="show ip ospf interface brief",
            expected_fix="Correct the OSPF area and network advertisement.",
            faults=[
                "The shared 10.0.12.0/30 link uses area 0 on R-HQ-01 and area 1 on R-BRANCH-01.",
                "The Branch LAN network is not advertised correctly into OSPF.",
            ],
            expected_commands=[
                "show ip ospf neighbor",
                "show ip ospf interface brief",
                "show running-config",
            ],
            expected_fixes=[
                "Place the shared WAN link in the same OSPF area on both routers.",
                "Add the correct Branch LAN network statement to OSPF.",
            ],
        )

    return LabScenario(
        lab_id=lab_id,
        level=level,
        topic="OSPF Troubleshooting",
        incident="Branch routes are not appearing at HQ.",
        symptom="OSPF adjacency between R-HQ-01 and R-BRANCH-01 does not form.",
        devices=[
            Device("R-HQ-01", "HQ Router"),
            Device("R-BRANCH-01", "Branch Router"),
        ],
        fault="10.0.12.0/30 is configured in area 0 on R-HQ-01 and area 1 on R-BRANCH-01.",
        expected_command="show ip ospf interface brief",
        expected_fix="Configure the shared link in the same OSPF area on both routers.",
    )


def dhcp_scenario(lab_id: str, level: str) -> LabScenario:
    return LabScenario(
        lab_id=lab_id,
        level=level,
        topic="DHCP Troubleshooting",
        incident="A client receives an APIPA address and cannot access the network.",
        symptom="PC-HR-01 shows a 169.254.x.x address and has no default gateway.",
        devices=[
            Device("PC-HR-01", "HR Workstation"),
            Device("R-HQ-01", "Router / DHCP Relay"),
            Device("SRV-DHCP-01", "DHCP Server"),
        ],
        fault="DHCP relay/helper configuration is missing or incorrect for the client VLAN.",
        expected_command="show running-config | include helper",
        expected_fix="Configure the correct ip helper-address on the client VLAN interface.",
    )


BUILDERS = {
    "VLAN": vlan_scenario,
    "TRUNK": trunk_scenario,
    "DHCP": dhcp_scenario,
    "OSPF": ospf_scenario,
}


def generate_scenario(
    lab_id: str,
    topic: str,
    level: str,
    track: str = "CCNA"
) -> LabScenario:
    topic = topic.upper()
    track = track.upper()

    if topic == "RANDOM":
        topic = random.choice(list(BUILDERS.keys()))

    if topic not in BUILDERS:
        raise ValueError(f"Unsupported topic: {topic}")

    scenario = BUILDERS[topic](lab_id, level)

    if track == "CCNP":
        if topic == "VLAN":
            scenario.incident = (
                "Finance users experience inconsistent Layer 2 connectivity "
                "across the access and distribution switching environment."
            )

            if level == "Easy":
                scenario.symptom = (
                    "One Finance workstation cannot communicate with another "
                    "host in the same VLAN."
                )

        elif topic == "TRUNK":
            scenario.incident = (
                "VLAN reachability is inconsistent across the campus uplink."
            )

        elif topic == "DHCP":
            scenario.incident = (
                "Clients in a routed VLAN fail to obtain DHCP leases "
                "through the relay path."
            )

        elif topic == "OSPF":
            scenario.incident = (
                "OSPF control-plane behavior is inconsistent between "
                "the HQ and Branch routing domains."
            )

    return scenario