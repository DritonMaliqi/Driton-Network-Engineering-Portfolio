import csv,html,re
from collections import Counter,defaultdict
from datetime import datetime

SEVERITIES={0:"Emergency",1:"Alert",2:"Critical",3:"Error",4:"Warning",5:"Notification",6:"Informational",7:"Debugging"}
MONTHS="Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()

def parse_line(line,line_number=0):
 line=line.rstrip("\r\n"); event={"line":line_number,"raw":line,"timestamp":"","device":"Unknown","facility":"UNKNOWN","severity":6,"severity_name":"Informational","mnemonic":"UNPARSED","message":line}
 pri=re.match(r"^<(\d{1,3})>",line)
 if pri:
  value=int(pri.group(1));event["severity"]=value%8;line=line[pri.end():].lstrip()
 cisco=re.search(r"%(?P<facility>[A-Z0-9_]+)-(?P<severity>[0-7])-(?P<mnemonic>[A-Z0-9_]+):\s*(?P<message>.*)$",line,re.I)
 if cisco:
  event.update(facility=cisco.group("facility").upper(),severity=int(cisco.group("severity")),mnemonic=cisco.group("mnemonic").upper(),message=cisco.group("message").strip())
  prefix=line[:cisco.start()].strip();dev=re.search(r"\b([A-Za-z][A-Za-z0-9_.-]*(?:-[A-Za-z0-9_.-]+)+)\s*$",prefix)
  if dev:event["device"]=dev.group(1)
  ts=re.search(r"(?:\*?\w{3}\s+\d{1,2}\s+\d\d:\d\d:\d\d(?:\.\d+)?)|(?:\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d)",prefix)
  if ts:event["timestamp"]=ts.group(0).lstrip("*")
 event["severity_name"]=SEVERITIES[event["severity"]]
 return event

def parse_logs(text):return [parse_line(line,i) for i,line in enumerate(text.splitlines(),1) if line.strip()]

RULES=[
 ("Interface down","CRITICAL",r"LINK-(?:3|5)-UPDOWN.*changed state to down|LINEPROTO-5-UPDOWN.*changed state to down","Check cabling/transceiver, interface errors, shutdown state, speed/duplex and the remote endpoint."),
 ("Interface err-disabled","CRITICAL",r"ERR_DISABLE|err-disabled","Identify the protection trigger, correct the root cause, then recover the port with shutdown/no shutdown."),
 ("OSPF adjacency loss","CRITICAL",r"OSPF-5-ADJCHG.*(?:DOWN|to Down|LOADING to DOWN)","Check link state, area, timers, MTU, authentication, ACLs and bidirectional reachability."),
 ("BGP neighbor down","CRITICAL",r"BGP-3-NOTIFICATION|BGP-5-ADJCHANGE.*(?:Down|down)","Verify peer reachability, TCP/179, remote-AS, update-source, authentication and routing."),
 ("Duplicate IP address","CRITICAL",r"IP-4-DUPADDR|duplicate address","Locate both MAC addresses, isolate the duplicate assignment and verify ARP after correction."),
 ("Authentication failure","WARNING",r"SEC_LOGIN-4-LOGIN_FAILED|LOGIN_FAILED|AUTH.*FAIL","Validate the source, AAA path and account status; investigate repeated or unauthorized attempts."),
 ("Spanning Tree inconsistency","CRITICAL",r"SPANTREE.*(?:BLOCK|INCONSIST|LOOPGUARD)|RECV_PVID_ERR","Compare trunk/native VLAN settings and STP state before changing topology."),
 ("HSRP state change","WARNING",r"HSRP-5-STATECHANGE|STANDBY-6-STATECHANGE","Confirm peer reachability, group, virtual IP, priority, preemption and tracking state."),
 ("High CPU condition","WARNING",r"CPUHOG|CPU.*(?:HIGH|EXCEED)|SYS-3-CPUHOG","Identify the process and traffic/control-plane trigger; avoid reload before collecting evidence."),
 ("Memory condition","WARNING",r"MALLOCFAIL|LOWMEM|MEMORY.*(?:LOW|FAIL)","Collect memory/process evidence and check for leaks, scale limits or abnormal control-plane load."),
 ("Configuration change","INFO",r"SYS-5-CONFIG_I|CONFIGURED_FROM","Confirm the authorized user, change ticket, affected commands and post-change verification."),
]

def detect_incidents(events):
 incidents=[]
 for e in events:
  hay=f"{e['facility']}-{e['severity']}-{e['mnemonic']} {e['message']}"
  for title,risk,pattern,action in RULES:
   if re.search(pattern,hay,re.I):incidents.append({"title":title,"risk":risk,"device":e["device"],"line":e["line"],"evidence":e["raw"],"action":action});break
 # Flapping: at least four state changes for the same interface.
 changes=defaultdict(list)
 for e in events:
  if e["mnemonic"]=="UPDOWN":
   m=re.search(r"Interface\s+([^,]+)",e["message"],re.I)
   if m:changes[(e["device"],m.group(1))].append(e)
 for (device,interface),items in changes.items():
  if len(items)>=4:incidents.append({"title":"Possible interface flapping","risk":"WARNING","device":device,"line":items[-1]["line"],"evidence":f"{len(items)} state changes detected for {interface}.","action":"Check physical errors, power, optics/cabling, negotiation and logs on both endpoints."})
 return incidents

def summarize(events,incidents=None):
 incidents=detect_incidents(events) if incidents is None else incidents
 return {"total":len(events),"critical":sum(e["severity"]<=2 for e in events),"errors":sum(e["severity"]==3 for e in events),"warnings":sum(e["severity"]==4 for e in events),"devices":Counter(e["device"] for e in events),"facilities":Counter(e["facility"] for e in events),"incidents":len(incidents)}

def export_csv(events,path):
 keys=("line","timestamp","device","facility","severity","severity_name","mnemonic","message","raw")
 with open(path,"w",newline="",encoding="utf-8-sig") as f:w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows({k:e[k] for k in keys} for e in events)

def build_html_report(events,incidents):
 s=summarize(events,incidents);esc=lambda x:html.escape(str(x));rows="".join(f"<tr><td>{i+1}</td><td class='{x['risk'].lower()}'>{x['risk']}</td><td>{esc(x['title'])}</td><td>{esc(x['device'])}</td><td>{x['line']}</td><td>{esc(x['evidence'])}</td><td>{esc(x['action'])}</td></tr>" for i,x in enumerate(incidents)) or "<tr><td colspan='7'>No rule-based incidents detected.</td></tr>"
 return f"""<!doctype html><html lang='en'><head><meta charset='utf-8'><title>NETOPS Syslog Analysis Report</title><style>body{{font-family:Segoe UI,Arial;margin:32px;color:#14213d}}h1{{color:#087ea4}}.cards{{display:flex;gap:12px;margin:18px 0}}.card{{padding:14px 22px;background:#eef5f8;border-left:5px solid #087ea4}}table{{border-collapse:collapse;width:100%;font-size:12px}}th{{background:#0b1f35;color:white}}th,td{{border:1px solid #ccd6e0;padding:7px;text-align:left;vertical-align:top}}.critical{{color:#c1121f;font-weight:bold}}.warning{{color:#b66a00;font-weight:bold}}.info{{color:#087ea4;font-weight:bold}}</style></head><body><h1>NETOPS Syslog Analysis Report</h1><p>Generated: {datetime.now():%Y-%m-%d %H:%M:%S}</p><div class='cards'><div class='card'>Events<br><b>{s['total']}</b></div><div class='card'>Critical severity<br><b>{s['critical']}</b></div><div class='card'>Errors<br><b>{s['errors']}</b></div><div class='card'>Warnings<br><b>{s['warnings']}</b></div><div class='card'>Detected incidents<br><b>{s['incidents']}</b></div></div><h2>Detected Incidents</h2><table><thead><tr><th>#</th><th>Risk</th><th>Incident</th><th>Device</th><th>Line</th><th>Evidence</th><th>Recommended verification</th></tr></thead><tbody>{rows}</tbody></table></body></html>"""
