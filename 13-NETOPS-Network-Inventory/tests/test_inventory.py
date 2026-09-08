import sqlite3,tempfile,unittest
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from inventory_core import InventoryDB,build_html_report

def device(tag="NET-001",hostname="SW-ACCESS-01",ip="192.168.99.11",status="Active"):
 return {"asset_tag":tag,"hostname":hostname,"device_type":"Switch","vendor":"Cisco","model":"C9200L-24P-4G","serial_number":"LAB12345","management_ip":ip,"site":"HQ","rack":"A01","software_version":"IOS XE 17.9","status":status,"owner":"Network Team","purchase_date":"2025-01-15","warranty_expiry":"2028-01-15","notes":"Lab asset"}

class InventoryTests(unittest.TestCase):
 def setUp(self):self.temp=tempfile.TemporaryDirectory();self.db=InventoryDB(Path(self.temp.name)/"test.db")
 def tearDown(self):self.temp.cleanup()
 def test_crud(self):
  item=self.db.add(device());self.assertEqual(self.db.get(item)[2],"SW-ACCESS-01");d=device();d["status"]="Maintenance";self.db.update(item,d);self.assertEqual(self.db.stats()["maintenance"],1);self.db.delete(item);self.assertEqual(self.db.stats()["total"],0)
 def test_duplicate_hostname_and_ip(self):
  self.db.add(device())
  with self.assertRaises(sqlite3.IntegrityError):self.db.add(device("NET-002","SW-ACCESS-01","192.168.99.12"))
  with self.assertRaises(sqlite3.IntegrityError):self.db.add(device("NET-003","SW-ACCESS-02","192.168.99.11"))
 def test_invalid_ip_and_date(self):
  d=device();d["management_ip"]="999.1.1.1"
  with self.assertRaises(ValueError):self.db.add(d)
  d=device();d["purchase_date"]="15/01/2025"
  with self.assertRaises(ValueError):self.db.add(d)
 def test_search_and_stats(self):
  self.db.add(device());self.db.add(device("NET-002","R-HQ-01","192.168.99.1","Offline"));self.assertEqual(len(self.db.list("R-HQ")),1);self.assertEqual(self.db.stats()["offline"],1)
 def test_html_escapes_content(self):
  self.db.add(device(hostname="SW-TEST"));report=build_html_report(self.db.list());self.assertIn("SW-TEST",report);self.assertIn("Total assets: 1",report)

if __name__=="__main__":unittest.main()
