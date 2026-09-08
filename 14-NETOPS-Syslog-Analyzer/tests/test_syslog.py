import tempfile,unittest
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from syslog_core import build_html_report,detect_incidents,export_csv,parse_line,parse_logs,summarize

SAMPLE="""Sep  8 21:40:01 SW-ACCESS-01 %LINK-3-UPDOWN: Interface Gi0/1, changed state to down
Sep  8 21:41:12 R-HQ-01 %OSPF-5-ADJCHG: Process 100, Nbr 2.2.2.2 on Gi0/1 from FULL to DOWN
<164>Sep  8 21:45:00 R-HQ-01 %SEC_LOGIN-4-LOGIN_FAILED: Login failed [user: admin]
Sep  8 21:46:10 SW-CORE-01 %SYS-5-CONFIG_I: Configured from console by netadmin
"""
class Tests(unittest.TestCase):
 def test_cisco_parse(self):
  e=parse_line(SAMPLE.splitlines()[0],1);self.assertEqual(e["device"],"SW-ACCESS-01");self.assertEqual(e["facility"],"LINK");self.assertEqual(e["severity"],3);self.assertEqual(e["mnemonic"],"UPDOWN")
 def test_pri_and_cisco_severity(self):
  e=parse_line(SAMPLE.splitlines()[2],3);self.assertEqual(e["severity"],4);self.assertEqual(e["device"],"R-HQ-01")
 def test_incidents(self):
  incidents=detect_incidents(parse_logs(SAMPLE));titles={i["title"] for i in incidents};self.assertIn("Interface down",titles);self.assertIn("OSPF adjacency loss",titles);self.assertIn("Authentication failure",titles);self.assertIn("Configuration change",titles)
 def test_summary(self):
  events=parse_logs(SAMPLE);s=summarize(events);self.assertEqual(s["total"],4);self.assertEqual(s["errors"],1);self.assertEqual(s["warnings"],1)
 def test_exports(self):
  events=parse_logs(SAMPLE);inc=detect_incidents(events);html=build_html_report(events,inc);self.assertIn("OSPF adjacency loss",html)
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/"events.csv";export_csv(events,p);self.assertIn("SW-ACCESS-01",p.read_text(encoding="utf-8-sig"))
if __name__=="__main__":unittest.main()
