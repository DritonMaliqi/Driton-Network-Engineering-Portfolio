import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from netops_backup import VaultDB, analyze_changes, detect_hostname, fingerprint, normalize_config


OLD = """hostname SW-ACCESS-01
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,50
 no shutdown
router ospf 10
 network 10.0.12.0 0.0.0.3 area 0
"""

NEW = """hostname SW-ACCESS-01
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 20,50
 shutdown
router ospf 10
 network 10.0.12.0 0.0.0.3 area 1
"""


class CoreTests(unittest.TestCase):
    def test_hostname(self): self.assertEqual(detect_hostname(OLD), "SW-ACCESS-01")
    def test_normalization_hash(self): self.assertEqual(fingerprint(OLD), fingerprint(OLD.replace("\n", "\r\n")))
    def test_change_risk(self):
        changes, counts = analyze_changes(OLD, NEW)
        self.assertGreaterEqual(counts["CRITICAL"], 2)
        self.assertTrue(any(c["line"].strip() == "shutdown" for c in changes))
    def test_database_and_duplicate_guard(self):
        with tempfile.TemporaryDirectory() as folder:
            db = VaultDB(Path(folder) / "test.db")
            first = db.add("SW1", "unit test", OLD)
            duplicate = db.add("SW1", "unit test", OLD)
            second = db.add("SW1", "unit test", NEW)
            self.assertIsNotNone(first); self.assertIsNone(duplicate); self.assertIsNotNone(second)
            self.assertEqual(len(db.list("SW1")), 2)


if __name__ == "__main__": unittest.main()
