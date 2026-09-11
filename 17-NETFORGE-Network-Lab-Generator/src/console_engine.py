def normalize(command):
    return " ".join(command.lower().strip().split())


def get_common_outputs(topic):
    topic = topic.upper()

    if "VLAN" in topic:
        return {
            "ping 192.168.10.11": """
Pinging 192.168.10.11 with 32 bytes of data:
Request timed out.
Request timed out.
Request timed out.
Request timed out.

Ping statistics for 192.168.10.11:
    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)
""".strip(),

            "show ip route": """
Default gateway is not set

Host               Gateway           Last Use    Total Uses  Interface
ICMP redirect cache is empty
""".strip(),

            "show running-config": """
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
!
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 1
!
interface GigabitEthernet0/1
 switchport mode trunk
""".strip(),
        }

    if "TRUNK" in topic:
        return {
            "ping 192.168.10.1": """
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.10.1, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)
""".strip(),

            "show ip route": """
Gateway of last resort is not set

C    192.168.20.0/24 is directly connected
C    192.168.50.0/24 is directly connected
""".strip(),

            "show running-config": """
interface GigabitEthernet0/1
 switchport trunk allowed vlan 20,50,99
 switchport mode trunk
""".strip(),
        }

    if "OSPF" in topic:
        return {
            "ping 10.0.12.2": """
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.0.12.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5)
""".strip(),

            "show ip route": """
Gateway of last resort is not set

C    10.0.12.0/30 is directly connected, GigabitEthernet0/0
C    192.168.10.0/24 is directly connected
""".strip(),

            "show running-config": """
router ospf 100
 router-id 1.1.1.1
 network 10.0.12.0 0.0.0.3 area 0
 network 192.168.10.0 0.0.0.255 area 0
""".strip(),
        }

    if "DHCP" in topic:
        return {
            "ping 192.168.20.1": """
Pinging 192.168.20.1 with 32 bytes of data:
PING: transmit failed. General failure.
PING: transmit failed. General failure.
PING: transmit failed. General failure.
PING: transmit failed. General failure.
""".strip(),

            "show ip route": """
Gateway of last resort is not set

C    192.168.20.0/24 is directly connected, GigabitEthernet0/0.20
""".strip(),

            "show running-config": """
interface GigabitEthernet0/0.20
 encapsulation dot1Q 20
 ip address 192.168.20.1 255.255.255.0
""".strip(),
        }

    return {}


def get_hint(topic, hint_number):
    topic = topic.upper()

    hints = {
        "VLAN": [
            "Start at Layer 2. Compare the VLAN assignment of the affected switch ports.",
            "Check whether both Finance PCs are assigned to VLAN 10.",
            "Inspect Fa0/2 closely."
        ],

        "TRUNK": [
            "Check whether the required VLAN exists locally and then inspect the uplink.",
            "Compare the VLAN list with the trunk allowed VLAN list.",
            "VLAN 10 should cross Gi0/1."
        ],

        "OSPF": [
            "First verify basic IP connectivity between the two routers.",
            "If ping works but OSPF does not, inspect OSPF-specific parameters.",
            "Compare the OSPF area configured on the shared link."
        ],

        "DHCP": [
            "The APIPA address indicates that the client did not receive a DHCP lease.",
            "Check the Layer 3 interface serving the client VLAN.",
            "Look for the DHCP relay/helper-address configuration."
        ]
    }

    for key, values in hints.items():
        if key in topic:
            index = min(hint_number, len(values) - 1)
            return values[index]

    return "No hint available."


def command_not_found(command):
    first_word = command.split()[0] if command.split() else ""

    if first_word in {"show", "ping"}:
        return "% Invalid input detected at '^' marker."

    return f"% Unrecognized command: {command}"


def calculate_score(commands_used, hints_used):
    score = 100

    if commands_used > 3:
        score -= (commands_used - 3) * 5

    score -= hints_used * 10

    if score < 0:
        score = 0

    return score
