import unittest
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from netops_ai import analyze_config, detect_device_name, compare_configs, EN_FINDINGS, UI

class AnalyzerTests(unittest.TestCase):
    def test_missing_trunk_vlan(self):
        cfg = "switchport access vlan 10\nswitchport trunk allowed vlan 20,50"
        self.assertIn("VLAN mungon në trunk", [x["title"] for x in analyze_config(cfg)])

    def test_apipa(self):
        self.assertIn("DHCP nuk ka caktuar adresë", [x["title"] for x in analyze_config("IP 169.254.2.9")])

    def test_ospf_mismatch(self):
        cfg = "network 10.0.12.0 0.0.0.3 area 0\nnetwork 10.0.12.0 0.0.0.3 area 1"
        self.assertIn("OSPF area mismatch", [x["title"] for x in analyze_config(cfg)])

    def test_err_disabled(self):
        self.assertIn("Port err-disabled", [x["title"] for x in analyze_config("Gi0/2 err-disabled 10 auto auto")])

    def test_dns(self):
        self.assertIn("Dështim DNS", [x["title"] for x in analyze_config("DNS request timed out")])

    def test_ipsec(self):
        self.assertIn("VPN IPsec/IKE DOWN", [x["title"] for x in analyze_config("IKE SESSION DOWN AUTHENTICATION_FAILED")])

    def test_router_on_stick(self):
        self.assertIn("Router-on-a-stick pa dot1Q", [x["title"] for x in analyze_config("interface GigabitEthernet0/0.10\n ip address 192.168.10.1 255.255.255.0")])

    def test_hostname_detection(self):
        self.assertEqual(detect_device_name("hostname R-HQ-01\ninterface Gi0/0"), "R-HQ-01")

    def test_prompt_detection(self):
        self.assertEqual(detect_device_name("R1#show ip bgp summary\nNeighbor"), "R1")

    def test_compare_ospf_and_bgp(self):
        a = "hostname R1\ninterface Gi0/0\n ip address 10.0.12.1 255.255.255.252\nrouter ospf 1\n network 10.0.12.0 0.0.0.3 area 0\nrouter bgp 65001\n neighbor 10.0.12.2 remote-as 65002"
        b = "hostname R2\ninterface Gi0/0\n ip address 10.0.12.2 255.255.255.252\nrouter ospf 1\n network 10.0.12.0 0.0.0.3 area 1\nrouter bgp 65003\n neighbor 10.0.12.1 remote-as 65009"
        titles = [x[0] for x in compare_configs(a, b)[2]]
        self.assertIn("OSPF area mismatch", titles)
        self.assertIn("BGP remote-as mismatch", titles)

    def test_bilingual_catalogs(self):
        self.assertEqual(UI["en"]["analyze"], "Analyze")
        for sample in ("DNS request timed out", "Gi0/2 err-disabled 10", "BGP neighbor 10.0.0.2 is Idle"):
            for finding in analyze_config(sample):
                self.assertIn(finding["title"], EN_FINDINGS)

if __name__ == "__main__": unittest.main()
