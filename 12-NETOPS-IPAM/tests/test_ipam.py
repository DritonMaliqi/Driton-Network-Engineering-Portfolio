import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from ipam_core import IPAMDatabase, calculate_network, split_network, vlsm_plan


class CalculatorTests(unittest.TestCase):
    def test_ipv4_facts(self):
        result=calculate_network("192.168.10.25/24")
        self.assertEqual(result["cidr"],"192.168.10.0/24")
        self.assertEqual(result["wildcard"],"0.0.0.255")
        self.assertEqual(result["usable_hosts"],254)
        self.assertEqual(result["first_usable"],"192.168.10.1")

    def test_point_to_point_31(self):
        result=calculate_network("10.0.0.0/31")
        self.assertEqual(result["usable_hosts"],2)

    def test_equal_split(self):
        result=split_network("192.168.10.0/24",26)
        self.assertEqual(len(result),4)
        self.assertEqual(result[-1]["cidr"],"192.168.10.192/26")

    def test_vlsm_largest_first(self):
        result=vlsm_plan("192.168.100.0/24",[("Servers",10),("Finance",50),("HR",25)])
        self.assertEqual(result[0]["name"],"Finance")
        self.assertEqual(result[0]["cidr"],"192.168.100.0/26")
        self.assertEqual(result[1]["cidr"],"192.168.100.64/27")

    def test_vlsm_overflow(self):
        with self.assertRaises(ValueError): vlsm_plan("192.168.1.0/30",[("Large",20)])


class DatabaseTests(unittest.TestCase):
    def test_crud_and_duplicate_guard(self):
        with tempfile.TemporaryDirectory() as folder:
            db=IPAMDatabase(Path(folder)/"test.db")
            item=db.add("192.168.10.10",24,"PC-FIN-01","Workstation","10","HQ","Assigned","Finance PC")
            self.assertEqual(len(db.list()),1)
            with self.assertRaises(Exception): db.add("192.168.10.10",24)
            db.update(item,hostname="PC-FIN-02")
            self.assertEqual(db.get(item)[3],"PC-FIN-02")
            db.delete(item); self.assertEqual(db.list(),[])


if __name__=="__main__": unittest.main()
