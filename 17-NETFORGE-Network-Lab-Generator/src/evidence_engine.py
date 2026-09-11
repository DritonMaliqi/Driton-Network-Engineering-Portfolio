def get_evidence(topic: str, level: str = "Easy"):
    topic = topic.upper()
    level = level.lower()

    if "VLAN" in topic:
        evidence = {
            "show vlan brief": """
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/2, Fa0/5, Fa0/6
10   FINANCE                          active    Fa0/1
20   HUMAN_RESOURCES                  active    Fa0/3, Fa0/4
50   SERVERS                          active    Fa0/10, Fa0/11
""".strip(),

            "show interfaces fa0/2 switchport": """
Name: Fa0/2
Switchport: Enabled
Administrative Mode: static access
Operational Mode: static access
Access Mode VLAN: 1 (default)
""".strip()
        }

        if level == "hard":
            evidence["show interfaces trunk"] = """
Port        Mode         Encapsulation  Status        Native vlan
Gi0/1       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/1       20,50,99

Port        Vlans allowed and active in management domain
Gi0/1       20,50

Port        Vlans in spanning tree forwarding state and not pruned
Gi0/1       20,50
""".strip()

        return evidence

    if "TRUNK" in topic:
        return {
            "show interfaces trunk": """
Port        Mode         Encapsulation  Status        Native vlan
Gi0/1       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/1       20,50,99

Port        Vlans allowed and active in management domain
Gi0/1       20,50
""".strip(),

            "show vlan brief": """
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
10   FINANCE                          active    Fa0/1, Fa0/2
20   HUMAN_RESOURCES                  active    Fa0/3, Fa0/4
50   SERVERS                          active    Fa0/10, Fa0/11
""".strip()
        }

    if "OSPF" in topic:
        evidence = {
            "show ip ospf neighbor": """
Neighbor ID     Pri   State           Dead Time   Address         Interface
""".strip(),

            "show ip ospf interface brief": """
Interface    PID   Area            IP Address/Mask      Cost  State Nbrs F/C
Gi0/0        100   0               10.0.12.1/30        1     P2P   0/0
""".strip(),

            "R-BRANCH-01 show ip ospf interface brief": """
Interface    PID   Area            IP Address/Mask      Cost  State Nbrs F/C
Gi0/0        100   1               10.0.12.2/30        1     P2P   0/0
""".strip()
        }

        if level == "hard":
            evidence["R-BRANCH-01 show running-config | section router ospf"] = """
router ospf 100
 router-id 2.2.2.2
 network 10.0.12.0 0.0.0.3 area 1
""".strip()

            evidence["R-BRANCH-01 show ip route"] = """
Gateway of last resort is not set

C    10.0.12.0/30 is directly connected, GigabitEthernet0/0
C    192.168.30.0/24 is directly connected, GigabitEthernet0/1
""".strip()

        return evidence

    if "DHCP" in topic:
        return {
            "ipconfig /all": """
Ethernet adapter Ethernet0:

   IPv4 Address. . . . . . . . . . . : 169.254.44.21
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Default Gateway . . . . . . . . . :
   DHCP Enabled. . . . . . . . . . . : Yes
""".strip(),

            "show running-config | include helper": "",

            "show ip interface brief": """
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0.20   192.168.20.1    YES manual up                    up
""".strip()
        }

    return {
        "status": "No evidence available for this topic."
    }
