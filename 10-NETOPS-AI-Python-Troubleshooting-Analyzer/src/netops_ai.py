import re
import sqlite3
import tkinter as tk
import html
import ipaddress
import os
import sys
from datetime import datetime
from pathlib import Path
from tkinter import filedialog, messagebox, ttk


APP_DIR = Path(__file__).resolve().parent
if getattr(sys, "frozen", False):
    DATA_DIR = Path(os.environ.get("LOCALAPPDATA", Path.home())) / "NETOPS-AI"
else:
    DATA_DIR = APP_DIR
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB_PATH = DATA_DIR / "netops_ai.db"

UI = {
    "sq": {"subtitle":"Analizues i Konfigurimeve Cisco  •  Offline","analyzer":"ANALIZUESI","compare":"KRAHASO PAJISJET","history":"HISTORIKU I INCIDENTEVE","device":"Pajisja:","load":"Ngarko konfigurimin","analyze":"Analizo","clear":"Pastro","input":"NGJIT KONFIGURIMIN / OUTPUT-IN","result":"REZULTATI I ANALIZËS","save":"Ruaj incidentin","load_a":"Ngarko Pajisjen A","load_b":"Ngarko Pajisjen B","compare_btn":"Krahaso","device_a":"PAJISJA A","device_b":"PAJISJA B","mismatches":"MOSPËRPUTHJET","date":"Data","status":"Statusi","details":"Shfaq detajet","resolve":"Shëno RESOLVED","export":"Eksporto raportin","delete":"Fshi incidentin","refresh":"Rifresko","language":"Gjuha:"},
    "en": {"subtitle":"Cisco Configuration Analyzer  •  Offline","analyzer":"ANALYZER","compare":"COMPARE DEVICES","history":"INCIDENT HISTORY","device":"Device:","load":"Load configuration","analyze":"Analyze","clear":"Clear","input":"PASTE CONFIGURATION / OUTPUT","result":"ANALYSIS RESULT","save":"Save incident","load_a":"Load Device A","load_b":"Load Device B","compare_btn":"Compare","device_a":"DEVICE A","device_b":"DEVICE B","mismatches":"MISMATCHES","date":"Date","status":"Status","details":"Show details","resolve":"Mark RESOLVED","export":"Export report","delete":"Delete incident","refresh":"Refresh","language":"Language:"}
}

EN_FINDINGS = {
"OSPF area mismatch":("OSPF area mismatch","The same OSPF network is assigned to different areas.","Assign the shared segment to the same OSPF area on both routers."),
"VLAN mungon në trunk":("VLAN missing from trunk","An access VLAN is not permitted on the trunk.","Add the missing VLAN to the trunk allowed-VLAN list."),
"DHCP nuk ka caktuar adresë":("DHCP address assignment failed","An APIPA address indicates that the client did not receive a DHCP lease.","Check the DHCP pool/server, client VLAN, relay and ip helper-address."),
"Interface administrativisht i mbyllur":("Interface administratively shut down","The shutdown command is present on an interface.","If the interface should be active, verify the link and apply no shutdown."),
"Default gateway nuk është gjetur":("Default gateway not found","An IP address exists but no Layer 2 management default gateway was found.","Verify the management gateway and configure ip default-gateway when required."),
"Kontrollo Native VLAN":("Check Native VLAN","A native VLAN is configured and must match on both trunk endpoints.","Compare the native VLAN on both ends and change it only when a mismatch is confirmed."),
"Port err-disabled":("Port is err-disabled","A protection mechanism automatically disabled the port.","Identify the trigger, correct it, then use shutdown/no shutdown."),
"Line protocol DOWN":("Line protocol DOWN","The physical or data-link layer is not operational.","Check cabling, speed/duplex, encapsulation and both link endpoints."),
"Gabime CRC në interface":("Interface CRC errors","A damaged cable/transceiver or duplex mismatch is likely.","Inspect the cable/transceiver and verify speed and duplex on both ends."),
"Duplex mismatch i mundshëm":("Possible duplex mismatch","One side may use half-duplex while the peer uses full/auto.","Use matching speed and duplex settings on both ends, normally auto/auto."),
"Port pa lidhje fizike":("Port has no physical link","The port does not detect a connected device or physical signal.","Check device power, cabling, transceiver and the remote port."),
"STP/VLAN inconsistency":("STP/VLAN inconsistency","STP blocked the port because of a VLAN mismatch.","Match native VLAN and trunk parameters on both ends before recovery."),
"EtherChannel i paformuar":("EtherChannel not formed","Member ports have inconsistent settings or incompatible negotiation modes.","Match mode, VLAN, trunk, speed/duplex and LACP/PAgP settings."),
"Port i bllokuar nga STP":("Port blocked by STP","STP is blocking a redundant path; this may be expected behavior.","Verify the root bridge and topology. Do not force the port into forwarding."),
"OSPF ngecur në EXSTART/EXCHANGE":("OSPF stuck in EXSTART/EXCHANGE","An MTU mismatch is the most common cause.","Match MTU on both ends; use mtu-ignore only with a justified design."),
"OSPF ngecur në INIT":("OSPF stuck in INIT","Hello packets are received one-way; multicast, ACL or link parameters may block the return path.","Check bidirectional communication, ACLs and OSPF interface parameters."),
"OSPF Hello/Dead mismatch":("OSPF Hello/Dead timer mismatch","OSPF neighbors use different Hello/Dead timers.","Match the OSPF Hello and Dead intervals on both ends."),
"Routing authentication mismatch":("Routing authentication mismatch","Authentication type, key ID or key differs between neighbors.","Match authentication settings without exposing the secret."),
"EIGRP K-values mismatch":("EIGRP K-values mismatch","EIGRP routers use different metric K-values.","Match metric weights/K-values throughout the EIGRP domain."),
"BGP neighbor nuk është Established":("BGP neighbor is not Established","TCP/179, reachability, remote-AS, update-source or authentication may be incorrect.","Verify reachability, remote-AS, source interface, ACL and peer password."),
"DHCP pool i shterur ose NAK":("DHCP pool exhausted or NAK received","The pool has no free addresses or client parameters do not match.","Correct network/default-router/exclusions or expand the pool according to the IP plan."),
"Dështim DNS":("DNS resolution failure","The hostname cannot be resolved even though IP connectivity may work.","Check the client DNS address, reachability, DNS service and record."),
"NAT nuk krijon përkthime":("NAT creates no translations","Traffic may not match the NAT rule, or inside/outside roles may be incorrect.","Check inside/outside roles, NAT ACL, routing and generate new traffic."),
"Trafik i bllokuar nga ACL":("Traffic blocked by ACL","An ACL is denying the required flow.","Locate the exact ACE and direction; make the smallest change and retain required denies."),
"HSRP nuk ka Active të qëndrueshëm":("HSRP has no stable Active router","Peer, group, virtual IP, authentication or VLAN settings may not match.","Match group, virtual IP and authentication; verify Layer 2 peer connectivity."),
"Komandë IOS e pasaktë ose e pambështetur":("Invalid or unsupported IOS command","The CLI rejected the command or the platform does not support it.","Check syntax and use an equivalent command supported by the platform."),
"VPN IPsec/IKE DOWN":("IPsec/IKE VPN is DOWN","Peer reachability, proposal, PSK, interesting traffic or NAT exemption may not match.","Compare peer, proposals, key, interesting traffic and return routing."),
"Router-on-a-stick pa dot1Q":("Router-on-a-stick missing dot1Q","A subinterface exists but dot1Q encapsulation was not found.","Configure dot1Q with the correct VLAN and verify the switch trunk."),
"OSPF pa interface/network aktiv":("OSPF has no active interface/network","The OSPF process exists but no participating interface was found.","Add only the planned interfaces using a network statement or interface-level OSPF."),
"ACL mohon të gjithë trafikun":("ACL denies all traffic","A deny-any statement exists without a visible permit.","Add only the required permits before the implicit/explicit deny and verify security behavior."),
"Nuk u gjet problem i qartë":("No clear problem detected","Automated rules did not identify a direct fault.","Collect the recommended outputs and troubleshoot the path layer by layer.")}


def resource_path(name):
    base = Path(getattr(sys, "_MEIPASS", APP_DIR))
    return base / name


def detect_device_name(text):
    """Return an explicit IOS hostname, otherwise a CLI prompt name."""
    match = re.search(r"(?im)^\s*hostname\s+([A-Za-z0-9_.-]+)\s*$", text)
    if match:
        return match.group(1)
    prompts = re.findall(r"(?m)^\s*([A-Za-z0-9_.-]+)(?:\([^\r\n)]*\))?[#>]", text)
    ignored = {"Switch", "Router"}
    return next((name for name in prompts if name not in ignored), "")


def _vlan_set(text, pattern):
    result = set()
    for raw in re.findall(pattern, text, re.I | re.M):
        for part in raw.split(","):
            part = part.strip()
            if "-" in part:
                try:
                    start, end = map(int, part.split("-", 1)); result.update(range(start, end + 1))
                except ValueError: pass
            elif part.isdigit(): result.add(int(part))
    return result


def compare_configs(first, second):
    """Compare facts explicitly present in two IOS configurations."""
    a_name, b_name = detect_device_name(first) or "Pajisja A", detect_device_name(second) or "Pajisja B"
    issues = []
    def issue(title, evidence, verify, fix, retest):
        issues.append((title, evidence, verify, fix, retest))

    a_native = _vlan_set(first, r"^\s*switchport\s+trunk\s+native\s+vlan\s+([\d,\-]+)")
    b_native = _vlan_set(second, r"^\s*switchport\s+trunk\s+native\s+vlan\s+([\d,\-]+)")
    if a_native and b_native and a_native != b_native:
        issue("Native VLAN mismatch", f"{a_name}: {sorted(a_native)} | {b_name}: {sorted(b_native)}",
              "show interfaces trunk në të dy switch-at", "Barazo native VLAN vetëm në portat që lidhen mes tyre.",
              "Kontrollo që të dy skajet tregojnë të njëjtën Native VLAN dhe STP të mos ketë inconsistent port.")

    a_allowed = _vlan_set(first, r"^\s*switchport\s+trunk\s+allowed\s+vlan\s+([\d,\-]+)")
    b_allowed = _vlan_set(second, r"^\s*switchport\s+trunk\s+allowed\s+vlan\s+([\d,\-]+)")
    if a_allowed and b_allowed and a_allowed != b_allowed:
        issue("Allowed VLAN mismatch", f"Vetëm te {a_name}: {sorted(a_allowed-b_allowed)} | Vetëm te {b_name}: {sorted(b_allowed-a_allowed)}",
              "show interfaces trunk në të dy skajet", "Lejo vetëm VLAN-et e kërkuara dhe bëje listën konsistente në linkun përkatës.",
              "Verifiko allowed/active VLAN dhe provo ping nga një host i VLAN-it të prekur.")

    def ospf_areas(text):
        return {(n, w): area for n, w, area in re.findall(r"(?im)^\s*network\s+(\S+)\s+(\S+)\s+area\s+(\S+)", text)}
    a_ospf, b_ospf = ospf_areas(first), ospf_areas(second)
    for key in sorted(set(a_ospf) & set(b_ospf)):
        if a_ospf[key] != b_ospf[key]:
            issue("OSPF area mismatch", f"Rrjeti {key[0]} {key[1]}: {a_name}=area {a_ospf[key]}, {b_name}=area {b_ospf[key]}",
                  "show ip ospf interface brief dhe show ip ospf neighbor në të dy routerët",
                  "Vendose segmentin e përbashkët në të njëjtën area.",
                  "Fqinjësia duhet të arrijë FULL dhe rrugët OSPF të shfaqen në tabelën e rutimit.")

    def interface_networks(text):
        nets = []
        for ip, mask in re.findall(r"(?im)^\s*ip address\s+(\d+(?:\.\d+){3})\s+(\d+(?:\.\d+){3})", text):
            try: nets.append((ip, str(ipaddress.ip_interface(f"{ip}/{mask}").network)))
            except ValueError: pass
        return nets
    a_nets, b_nets = interface_networks(first), interface_networks(second)
    if a_nets and b_nets and not ({n for _, n in a_nets} & {n for _, n in b_nets}):
        issue("Nuk u gjet subnet i përbashkët", f"{a_name}: {a_nets} | {b_name}: {b_nets}",
              "show ip interface brief dhe show cdp neighbors",
              "Konfirmo cilat interface lidhen fizikisht; korrigjo IP/maskën vetëm nëse duhet të jenë peer direkt.",
              "Ping IP-në e peer-it dhe kontrollo ARP/CDP. Ky sinjal mund të jetë normal nëse pajisjet nuk janë direkt të lidhura.")

    def channel_modes(text): return set(re.findall(r"(?im)^\s*channel-group\s+\d+\s+mode\s+(\S+)", text))
    a_modes, b_modes = channel_modes(first), channel_modes(second)
    compatible = ({"active"}, {"active", "passive"})
    if a_modes and b_modes:
        union = a_modes | b_modes
        bad = union <= {"passive"} or ("on" in union and len(union) > 1) or bool(union & {"desirable", "auto"} and union & {"active", "passive"})
        if bad:
            issue("EtherChannel mode mismatch", f"{a_name}: {sorted(a_modes)} | {b_name}: {sorted(b_modes)}",
                  "show etherchannel summary në të dy switch-at", "Përdor një çift kompatibil: LACP active/active ose active/passive; static on/on.",
                  "Port-channel duhet të jetë up dhe portat anëtare bundled (P).")

    def bgp(text):
        local = re.search(r"(?im)^\s*router bgp\s+(\d+)", text)
        peers = dict(re.findall(r"(?im)^\s*neighbor\s+(\d+(?:\.\d+){3})\s+remote-as\s+(\d+)", text))
        ips = {ip for ip, _ in interface_networks(text)}
        return (local.group(1) if local else None), peers, ips
    a_as, a_peers, a_ips = bgp(first); b_as, b_peers, b_ips = bgp(second)
    if a_as and b_as:
        for peer in a_ips & set(b_peers):
            if b_peers[peer] != a_as:
                issue("BGP remote-as mismatch", f"{b_name} pret AS {b_peers[peer]} për {peer}, por {a_name} është AS {a_as}.",
                      "show ip bgp summary dhe show running-config | section router bgp",
                      f"Në {b_name}, vendos remote-as sipas AS-it real të peer-it.", "Fqinjësia duhet të bëhet Established.")
        for peer in b_ips & set(a_peers):
            if a_peers[peer] != b_as:
                issue("BGP remote-as mismatch", f"{a_name} pret AS {a_peers[peer]} për {peer}, por {b_name} është AS {b_as}.",
                      "show ip bgp summary dhe show running-config | section router bgp",
                      f"Në {a_name}, vendos remote-as sipas AS-it real të peer-it.", "Fqinjësia duhet të bëhet Established.")

    if not issues:
        issue("Nuk u gjet mospërputhje e drejtpërdrejtë", f"U krahasuan {a_name} dhe {b_name} për parametrat e disponueshëm.",
              "Shto output-et operative (neighbors, trunk, routes) nëse problemi vazhdon.",
              "Mos bëj ndryshim pa evidencë shtesë.", "Përsërit testin origjinal nga burimi drejt destinacionit.")
    return a_name, b_name, issues


def analyze_config(text):
    cfg = text.replace("\r", "")
    findings = []

    def add(title, severity, confidence, cause, verify, fix):
        findings.append({
            "title": title, "severity": severity, "confidence": confidence,
            "cause": cause, "verify": verify, "fix": fix,
        })

    # OSPF area mismatch: same network statement configured in multiple areas.
    ospf_networks = {}
    for network, wildcard, area in re.findall(
        r"(?im)^\s*network\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+area\s+(\S+)", cfg
    ):
        ospf_networks.setdefault((network, wildcard), set()).add(area)
    for (network, wildcard), areas in ospf_networks.items():
        if len(areas) > 1:
            add("OSPF area mismatch", "CRITICAL", 99,
                f"Rrjeti {network} {wildcard} është vendosur në area të ndryshme: {', '.join(sorted(areas))}.",
                "show ip ospf interface brief\nshow ip ospf neighbor",
                "Vendose lidhjen e përbashkët në të njëjtën OSPF area në të dy routerët.")

    # Trunk allowed VLAN list compared with VLANs referenced in access ports.
    access_vlans = set(re.findall(r"(?im)^\s*switchport\s+access\s+vlan\s+(\d+)", cfg))
    trunk_lists = re.findall(r"(?im)^\s*switchport\s+trunk\s+allowed\s+vlan\s+([\d,\-]+)", cfg)
    allowed = set()
    for item in trunk_lists:
        for part in item.split(","):
            if "-" in part:
                a, b = map(int, part.split("-", 1)); allowed.update(map(str, range(a, b + 1)))
            elif part:
                allowed.add(part)
    missing = sorted(access_vlans - allowed, key=int) if trunk_lists else []
    if missing:
        add("VLAN mungon në trunk", "CRITICAL", 98,
            "VLAN-et e access portave nuk lejohen në trunk: " + ", ".join(missing) + ".",
            "show interfaces trunk\nshow vlan brief",
            "Shto VLAN-et që mungojnë në listën allowed VLAN të trunk-ut.")

    # APIPA is direct evidence of failed DHCP assignment.
    apipa = sorted(set(re.findall(r"\b169\.254\.\d{1,3}\.\d{1,3}\b", cfg)))
    if apipa:
        add("DHCP nuk ka caktuar adresë", "CRITICAL", 97,
            "Është gjetur adresë APIPA: " + ", ".join(apipa) + ".",
            "ipconfig /all\nshow ip dhcp binding\nshow running-config | include helper-address",
            "Kontrollo DHCP pool/serverin, VLAN-in e klientit dhe ip helper-address.")

    # Administratively shutdown interfaces.
    shutdown_interfaces = []
    current = None
    for line in cfg.splitlines():
        m = re.match(r"^interface\s+(\S+)", line.strip(), re.I)
        if m:
            current = m.group(1)
        elif current and re.match(r"^shutdown\s*$", line.strip(), re.I):
            shutdown_interfaces.append(current)
    if shutdown_interfaces:
        add("Interface administrativisht i mbyllur", "WARNING", 95,
            "U gjet komanda shutdown në: " + ", ".join(shutdown_interfaces) + ".",
            "show ip interface brief",
            "Nëse interfejsi duhet të jetë aktiv, hyr në interface dhe përdor no shutdown.")

    # Missing default gateway in switch/host-like pasted configuration.
    has_ip = bool(re.search(r"(?im)^\s*ip address\s+\d+\.\d+\.\d+\.\d+", cfg))
    is_router = bool(re.search(r"(?im)^\s*(router\s+(ospf|eigrp|bgp)|ip routing)", cfg))
    if has_ip and not is_router and not re.search(r"(?im)^\s*ip default-gateway\s+", cfg):
        add("Default gateway nuk është gjetur", "WARNING", 85,
            "Konfigurimi përmban IP, por nuk u gjet ip default-gateway.",
            "show running-config | include default-gateway\nshow ip interface brief",
            "Verifiko gateway-n e menaxhimit dhe shto ip default-gateway nëse pajisja është Layer 2.")

    # Native VLAN different from default is informational and should match peer.
    native = sorted(set(re.findall(r"(?im)^\s*switchport\s+trunk\s+native\s+vlan\s+(\d+)", cfg)))
    if native:
        add("Kontrollo Native VLAN", "INFO", 80,
            "Native VLAN e konfiguruar: " + ", ".join(native) + ". Duhet të jetë e njëjtë në të dy skajet.",
            "show interfaces trunk\nshow interfaces switchport",
            "Krahaso native VLAN në të dy portat trunk; ndryshoje vetëm nëse ka mospërputhje.")

    # Operational outputs: physical and data-link faults.
    operational_rules = [
        (r"(?im)\b(err-disabled|error-disabled)\b", "Port err-disabled", "CRITICAL", 99,
         "Porti është çaktivizuar automatikisht nga një mekanizëm mbrojtës.",
         "show interfaces status err-disabled\nshow errdisable recovery",
         "Gjej shkakun (port-security, BPDU Guard, link-flap), korrigjoje, pastaj shutdown/no shutdown."),
        (r"(?im)\bline protocol is down\b", "Line protocol DOWN", "CRITICAL", 94,
         "Shtresa fizike ose protokolli i lidhjes nuk është operacional.",
         "show interfaces\nshow controllers\nshow cdp neighbors",
         "Kontrollo kabllon, speed/duplex, encapsulation dhe konfigurimin në të dy skajet."),
        (r"(?im)\binput errors\b.*\bCRC\b|\bCRC\b.*\binput errors\b", "Gabime CRC në interface", "WARNING", 92,
         "Ka gjasa për kabllo/transceiver të dëmtuar ose duplex mismatch.",
         "show interfaces counters errors\nshow interfaces",
         "Kontrollo kabllon dhe transceiver-in; verifiko speed/duplex në të dy skajet."),
        (r"(?im)\bduplex mismatch\b|\bhalf-duplex\b", "Duplex mismatch i mundshëm", "WARNING", 90,
         "Njëra anë mund të jetë half-duplex ndërsa ana tjetër full/auto.",
         "show interfaces status\nshow interfaces | include duplex|collision",
         "Vendos speed dhe duplex në mënyrë të njëjtë në të dy skajet, zakonisht auto/auto."),
        (r"(?im)\bnotconnect\b", "Port pa lidhje fizike", "WARNING", 88,
         "Porti nuk detekton pajisje ose sinjal fizik.",
         "show interfaces status\nshow interfaces counters errors",
         "Kontrollo energjinë e pajisjes, kabllon, transceiver-in dhe portin e skajit tjetër."),
        (r"(?im)\binconsistent\b.*\b(native|vlan|pvid)\b|\bPVID_Inc\b", "STP/VLAN inconsistency", "CRITICAL", 97,
         "STP ka bllokuar portin për shkak të mospërputhjes së VLAN-it.",
         "show spanning-tree inconsistentports\nshow interfaces trunk",
         "Barazo native VLAN dhe parametrat trunk në të dy skajet; verifiko para rikthimit."),
        (r"(?im)\b(suspended|stand-alone)\b.*\b(Po|Port-channel|channel)|\bchannel-misconfig\b", "EtherChannel i paformuar", "CRITICAL", 96,
         "Anëtarët e EtherChannel kanë parametra të ndryshëm ose protokoll të papërshtatshëm.",
         "show etherchannel summary\nshow interfaces trunk",
         "Barazo mode, VLAN, trunk, speed/duplex dhe LACP/PAgP në të gjitha portat anëtare."),
        (r"(?im)\bSTP\b.*\bBLOCKING\b|\bAltn BLK\b", "Port i bllokuar nga STP", "INFO", 82,
         "STP po bllokon një rrugë redundante; kjo mund të jetë sjellje normale.",
         "show spanning-tree vlan <VLAN-ID>\nshow spanning-tree root",
         "Mos e aktivizo me forcë. Verifiko root bridge dhe topologjinë para çdo ndryshimi."),
    ]
    for pattern, title, severity, confidence, cause, verify, fix in operational_rules:
        if re.search(pattern, cfg): add(title, severity, confidence, cause, verify, fix)

    # Layer 3, routing, services, and security evidence from show/debug output.
    protocol_rules = [
        (r"(?im)\bOSPF\b.*\b(EXSTART|EXCHANGE)\b|\b(EXSTART|EXCHANGE)/DR\b", "OSPF ngecur në EXSTART/EXCHANGE", "CRITICAL", 96,
         "Shkaku më i shpeshtë është MTU mismatch mes fqinjëve OSPF.",
         "show ip ospf neighbor\nshow interfaces | include MTU",
         "Barazo MTU në të dy skajet; përdor ip ospf mtu-ignore vetëm kur është e arsyetuar."),
        (r"(?im)\bOSPF\b.*\bINIT\b|\bINIT/DROTHER\b", "OSPF ngecur në INIT", "CRITICAL", 94,
         "Hello merret vetëm në një drejtim; multicast, ACL ose parametrat e linkut mund të pengojnë kthimin.",
         "show ip ospf neighbor\nshow ip ospf interface\nshow access-lists",
         "Kontrollo komunikimin dykahësh, ACL-në dhe parametrat Hello/Dead/network type."),
        (r"(?im)\bMismatched.*Hello|Hello.*mismatch|Dead.*mismatch", "OSPF Hello/Dead mismatch", "CRITICAL", 98,
         "Fqinjët OSPF përdorin intervale të ndryshme Hello/Dead.",
         "show ip ospf interface",
         "Barazo ip ospf hello-interval dhe dead-interval në të dy skajet."),
        (r"(?im)\bMismatched.*authentication|authentication.*mismatch|invalid auth", "Routing authentication mismatch", "CRITICAL", 98,
         "Çelësi ose tipi i autentikimit nuk përputhet mes fqinjëve.",
         "show ip ospf interface\nshow ip protocols\nshow logging",
         "Verifiko tipin, key-id dhe çelësin në të dy skajet pa ekspozuar sekretin."),
        (r"(?im)\bEIGRP\b.*\bK[- ]?value.*mismatch|K[- ]?value.*mismatch", "EIGRP K-values mismatch", "CRITICAL", 98,
         "Routerët EIGRP përdorin metrika K të ndryshme.",
         "show ip protocols\nshow ip eigrp neighbors",
         "Barazo metric weights/K-values në të gjithë domain-in EIGRP."),
        (r"(?im)\bBGP\b.*\b(Idle|Active)\b|\b(Idle|Active)\b.*\bBGP\b", "BGP neighbor nuk është Established", "CRITICAL", 92,
         "TCP/179, reachability, remote-as, update-source ose autentikimi mund të jetë gabim.",
         "show ip bgp summary\nshow ip route <NEIGHBOR-IP>\nshow tcp brief",
         "Verifiko reachability, remote-as, source interface, ACL dhe password-in e fqinjit."),
        (r"(?im)\bDHCPD?[- ].*(NAK|POOL EXHAUSTED|no free leases)|\b0 available addresses\b", "DHCP pool i shterur ose NAK", "CRITICAL", 97,
         "Pool-i nuk ka adresa të lira ose parametrat e klientit nuk përputhen.",
         "show ip dhcp pool\nshow ip dhcp binding\nshow ip dhcp conflict",
         "Korrigjo network/default-router/exclusions ose zgjero pool-in sipas planit të adresimit."),
        (r"(?im)\b(NXDOMAIN|SERVFAIL|Non-existent domain|DNS request timed out)\b", "Dështim DNS", "CRITICAL", 97,
         "Emri nuk rezolvohet edhe nëse lidhja IP mund të funksionojë.",
         "nslookup <EMRI>\nnslookup <EMRI> <DNS-IP>\nping <DNS-IP>",
         "Kontrollo DNS IP te klienti, reachability, shërbimin DNS dhe rekordin përkatës."),
        (r"(?im)\bNAT translations:\s*0\b|\bTotal active translations:\s*0\b", "NAT nuk krijon përkthime", "WARNING", 90,
         "Trafiku nuk po përputhet me rregullin NAT ose inside/outside është gabim.",
         "show ip nat translations\nshow ip nat statistics\nshow access-lists",
         "Kontrollo ip nat inside/outside, ACL-në e NAT-it, route-n dhe provo trafik të ri."),
        (r"(?im)\b(Administratively prohibited|access denied by acl|denied.*access-list)\b", "Trafik i bllokuar nga ACL", "CRITICAL", 97,
         "Një ACL po mohon rrjedhën e kërkuar.",
         "show access-lists\nshow ip interface | include access list",
         "Gjej ACE-në dhe drejtimin e saktë; bëj ndryshimin minimal dhe testo edhe një trafik që duhet të mbetet i ndaluar."),
        (r"(?im)\bHSRP\b.*\b(Init|Speak|Standby)\b.*\b(Init|Speak)\b|\bActive router is unknown\b", "HSRP nuk ka Active të qëndrueshëm", "CRITICAL", 92,
         "Peer-i, grupi, virtual IP, autentikimi ose VLAN-i mund të mos përputhet.",
         "show standby brief\nshow standby\nshow interfaces trunk",
         "Barazo group/virtual IP/authentication dhe siguro komunikimin Layer 2 mes peer-ëve."),
        (r"(?im)\b(Invalid input|Incomplete command|Ambiguous command)\b", "Komandë IOS e pasaktë ose e pambështetur", "INFO", 99,
         "CLI nuk e pranoi komandën ose platforma/Packet Tracer nuk e mbështet.",
         "show version\nshow ?",
         "Kontrollo sintaksën dhe përdor komandën ekuivalente që mbështet platforma."),
        (r"(?im)\b(IPSEC|IKE|ISAKMP)\b.*\b(DOWN|FAILED|NO_PROPOSAL|AUTHENTICATION_FAILED)\b", "VPN IPsec/IKE DOWN", "CRITICAL", 96,
         "Peer reachability, policy/proposal, PSK, ACL interesante ose NAT exemption mund të mos përputhet.",
         "show crypto isakmp sa\nshow crypto ipsec sa\nshow crypto session",
         "Krahaso peer, IKE/IPsec proposal, çelësin, interesting traffic dhe rrugën e kthimit."),
    ]
    for pattern, title, severity, confidence, cause, verify, fix in protocol_rules:
        if re.search(pattern, cfg): add(title, severity, confidence, cause, verify, fix)

    # Configuration omissions and common unsafe defaults.
    if re.search(r"(?im)^\s*interface\s+\S+\.\d+", cfg) and not re.search(r"(?im)^\s*encapsulation\s+dot1q\s+\d+", cfg):
        add("Router-on-a-stick pa dot1Q", "CRITICAL", 94,
            "Ka subinterface, por nuk u gjet encapsulation dot1Q.",
            "show running-config interface <SUBINTERFACE>\nshow ip interface brief",
            "Vendos encapsulation dot1Q me VLAN-in e saktë dhe verifiko trunk-un në switch.")
    if re.search(r"(?im)^\s*router ospf\s+\d+", cfg) and not re.search(r"(?im)^\s*(network\s+\S+.*area|ip ospf\s+\d+\s+area)", cfg):
        add("OSPF pa interface/network aktiv", "WARNING", 91,
            "Procesi OSPF ekziston, por nuk u gjet interface i përfshirë në OSPF.",
            "show ip protocols\nshow ip ospf interface brief",
            "Përfshi vetëm interfejset e planifikuara me network statement ose ip ospf ... area.")
    if re.search(r"(?im)^\s*access-list\s+\d+\s+deny\s+any\s*$|^\s*deny\s+ip\s+any\s+any", cfg) and not re.search(r"(?im)^\s*(access-list\s+\d+\s+permit|permit\s+ip)", cfg):
        add("ACL mohon të gjithë trafikun", "CRITICAL", 98,
            "ACL përmban deny any pa një permit të dukshëm.",
            "show access-lists\nshow ip interface",
            "Përcakto trafikun që duhet lejuar para implicit/explicit deny dhe testo rregullat e sigurisë.")

    if not findings:
        add("Nuk u gjet problem i qartë", "INFO", 60,
            "Rregullat automatike nuk identifikuan një gabim të drejtpërdrejtë.",
            "show ip interface brief\nshow vlan brief\nshow interfaces trunk\nshow ip route",
            "Mblidh output-et e verifikimit dhe analizo lidhjen hap pas hapi.")
    return findings


class NetOpsApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.language = tk.StringVar(value="sq")
        self.title("NETOPS AI – Network Troubleshooting Analyzer")
        try: self.iconbitmap(str(resource_path("netops-ai.ico")))
        except (tk.TclError, OSError): pass
        self.geometry("1180x760")
        self.minsize(940, 650)
        self.configure(bg="#0b1220")
        self.db = sqlite3.connect(DB_PATH)
        self.db.execute("""CREATE TABLE IF NOT EXISTS incidents(
            id INTEGER PRIMARY KEY, created_at TEXT NOT NULL, device TEXT,
            config TEXT NOT NULL, result TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'ACTIVE')""")
        self.db.commit()
        self.protocol("WM_DELETE_WINDOW", self.close_app)
        self._style(); self._build(); self.refresh_history()

    def tr(self, key): return UI[self.language.get()][key]

    def switch_language(self, _event=None):
        values = {}
        for name in ("input_text", "output_text", "compare_a", "compare_b", "compare_output"):
            widget = getattr(self, name, None)
            if widget: values[name] = widget.get("1.0", "end").rstrip()
        device = self.device.get() if hasattr(self, "device") else "SW-ACCESS-01"
        for child in self.winfo_children(): child.destroy()
        self._build(); self.device.delete(0, "end"); self.device.insert(0, device)
        for name, value in values.items():
            widget = getattr(self, name); widget.config(state="normal"); widget.insert("1.0", value)
            if name in ("output_text", "compare_output"): widget.config(state="disabled")
        self.refresh_history()
        if values.get("input_text", "").strip(): self.run_analysis()
        if values.get("compare_a", "").strip() and values.get("compare_b", "").strip(): self.run_compare()

    def _style(self):
        s = ttk.Style(self); s.theme_use("clam")
        s.configure("TFrame", background="#0b1220")
        s.configure("Card.TFrame", background="#111c31")
        s.configure("TLabel", background="#0b1220", foreground="#e7eefc", font=("Segoe UI", 10))
        s.configure("Title.TLabel", font=("Segoe UI Semibold", 21), foreground="#62d6ff")
        s.configure("Card.TLabel", background="#111c31", foreground="#dbeafe")
        s.configure("TButton", font=("Segoe UI Semibold", 10), padding=8)
        s.configure("Treeview", background="#111c31", fieldbackground="#111c31", foreground="#e7eefc", rowheight=27)
        s.configure("Treeview.Heading", background="#1d4ed8", foreground="white", font=("Segoe UI Semibold", 9))
        s.map("Treeview", background=[("selected", "#2563eb")])

    def _build(self):
        header = ttk.Frame(self); header.pack(fill="x", padx=18, pady=(16, 8))
        ttk.Label(header, text="NETOPS AI", style="Title.TLabel").pack(side="left")
        ttk.Label(header, text=self.tr("subtitle")).pack(side="left", padx=18, pady=8)
        ttk.Label(header, text=self.tr("language")).pack(side="right", padx=(8, 4))
        lang = ttk.Combobox(header, textvariable=self.language, values=("sq", "en"), width=7, state="readonly")
        lang.pack(side="right"); lang.bind("<<ComboboxSelected>>", self.switch_language)

        notebook = ttk.Notebook(self); notebook.pack(fill="both", expand=True, padx=18, pady=(0, 18))
        analyzer = ttk.Frame(notebook); compare = ttk.Frame(notebook); history = ttk.Frame(notebook)
        notebook.add(analyzer, text=f"  {self.tr('analyzer')}  "); notebook.add(compare, text=f"  {self.tr('compare')}  "); notebook.add(history, text=f"  {self.tr('history')}  ")

        bar = ttk.Frame(analyzer); bar.pack(fill="x", pady=10)
        ttk.Label(bar, text=self.tr("device")).pack(side="left")
        self.device = ttk.Entry(bar, width=26); self.device.pack(side="left", padx=(6, 14)); self.device.insert(0, "SW-ACCESS-01")
        ttk.Button(bar, text=self.tr("load"), command=self.load_file).pack(side="left", padx=4)
        ttk.Button(bar, text=self.tr("analyze"), command=self.run_analysis).pack(side="left", padx=4)
        ttk.Button(bar, text=self.tr("clear"), command=self.clear).pack(side="left", padx=4)

        panes = ttk.Panedwindow(analyzer, orient="horizontal"); panes.pack(fill="both", expand=True)
        left = ttk.Frame(panes, style="Card.TFrame"); right = ttk.Frame(panes, style="Card.TFrame")
        panes.add(left, weight=1); panes.add(right, weight=1)
        ttk.Label(left, text=self.tr("input"), style="Card.TLabel").pack(anchor="w", padx=12, pady=(12, 5))
        self.input_text = tk.Text(left, bg="#07101e", fg="#d8e8ff", insertbackground="white", relief="flat", font=("Consolas", 10), wrap="none")
        self.input_text.pack(fill="both", expand=True, padx=12, pady=(0, 12))
        ttk.Label(right, text=self.tr("result"), style="Card.TLabel").pack(anchor="w", padx=12, pady=(12, 5))
        self.output_text = tk.Text(right, bg="#07101e", fg="#d8e8ff", insertbackground="white", relief="flat", font=("Consolas", 10), wrap="word", state="disabled")
        self.output_text.pack(fill="both", expand=True, padx=12, pady=(0, 8))
        ttk.Button(right, text=self.tr("save"), command=self.save_incident).pack(anchor="e", padx=12, pady=(0, 12))

        compare_bar = ttk.Frame(compare); compare_bar.pack(fill="x", pady=10)
        ttk.Button(compare_bar, text=self.tr("load_a"), command=lambda: self.load_compare(self.compare_a)).pack(side="left", padx=4)
        ttk.Button(compare_bar, text=self.tr("load_b"), command=lambda: self.load_compare(self.compare_b)).pack(side="left", padx=4)
        ttk.Button(compare_bar, text=self.tr("compare_btn"), command=self.run_compare).pack(side="left", padx=4)
        ttk.Button(compare_bar, text=self.tr("clear"), command=self.clear_compare).pack(side="left", padx=4)
        compare_panes = ttk.Panedwindow(compare, orient="horizontal"); compare_panes.pack(fill="both", expand=True)
        ca = ttk.Frame(compare_panes, style="Card.TFrame"); cb = ttk.Frame(compare_panes, style="Card.TFrame"); cr = ttk.Frame(compare_panes, style="Card.TFrame")
        compare_panes.add(ca, weight=1); compare_panes.add(cb, weight=1); compare_panes.add(cr, weight=1)
        ttk.Label(ca, text=self.tr("device_a"), style="Card.TLabel").pack(anchor="w", padx=10, pady=(10, 4))
        self.compare_a = tk.Text(ca, bg="#07101e", fg="#d8e8ff", insertbackground="white", relief="flat", font=("Consolas", 9), wrap="none")
        self.compare_a.pack(fill="both", expand=True, padx=10, pady=(0, 10))
        ttk.Label(cb, text=self.tr("device_b"), style="Card.TLabel").pack(anchor="w", padx=10, pady=(10, 4))
        self.compare_b = tk.Text(cb, bg="#07101e", fg="#d8e8ff", insertbackground="white", relief="flat", font=("Consolas", 9), wrap="none")
        self.compare_b.pack(fill="both", expand=True, padx=10, pady=(0, 10))
        ttk.Label(cr, text=self.tr("mismatches"), style="Card.TLabel").pack(anchor="w", padx=10, pady=(10, 4))
        self.compare_output = tk.Text(cr, bg="#07101e", fg="#d8e8ff", insertbackground="white", relief="flat", font=("Consolas", 9), wrap="word", state="disabled")
        self.compare_output.pack(fill="both", expand=True, padx=10, pady=(0, 10))

        columns = ("id", "date", "device", "status")
        self.tree = ttk.Treeview(history, columns=columns, show="headings")
        for col, label, width in [("id", "ID", 70), ("date", self.tr("date"), 180), ("device", self.tr("device").rstrip(":"), 260), ("status", self.tr("status"), 120)]:
            self.tree.heading(col, text=label); self.tree.column(col, width=width, anchor="center")
        self.tree.pack(fill="both", expand=True, pady=(12, 8))
        hbar = ttk.Frame(history); hbar.pack(fill="x", pady=(0, 12))
        ttk.Button(hbar, text=self.tr("details"), command=self.show_details).pack(side="left", padx=4)
        ttk.Button(hbar, text=self.tr("resolve"), command=self.resolve).pack(side="left", padx=4)
        ttk.Button(hbar, text=self.tr("export"), command=self.export_report).pack(side="left", padx=4)
        ttk.Button(hbar, text=self.tr("delete"), command=self.delete_incident).pack(side="left", padx=4)
        ttk.Button(hbar, text=self.tr("refresh"), command=self.refresh_history).pack(side="left", padx=4)

    def load_file(self):
        path = filedialog.askopenfilename(filetypes=[("Text and config", "*.txt *.cfg *.log"), ("All files", "*.*")])
        if path:
            try:
                content = Path(path).read_text(encoding="utf-8", errors="replace")
                self.input_text.delete("1.0", "end"); self.input_text.insert("1.0", content)
                self.apply_detected_device(content)
            except OSError as exc: messagebox.showerror("Gabim", str(exc))

    def load_compare(self, widget):
        path = filedialog.askopenfilename(filetypes=[("Text and config", "*.txt *.cfg *.log"), ("All files", "*.*")])
        if path:
            try:
                content = Path(path).read_text(encoding="utf-8", errors="replace")
                widget.delete("1.0", "end"); widget.insert("1.0", content)
            except OSError as exc: messagebox.showerror("Gabim", str(exc))

    def run_compare(self):
        first = self.compare_a.get("1.0", "end").strip(); second = self.compare_b.get("1.0", "end").strip()
        if not first or not second:
            messagebox.showwarning("Missing data" if self.language.get()=="en" else "Mungojnë të dhënat", "Load or paste both device configurations." if self.language.get()=="en" else "Ngarko ose ngjit konfigurimin e të dy pajisjeve."); return
        a_name, b_name, issues = compare_configs(first, second)
        blocks = [f"{'COMPARISON' if self.language.get() == 'en' else 'KRAHASIMI'}: {a_name} ↔ {b_name}\n"]
        for i, (title, evidence, verify, fix, retest) in enumerate(issues, 1):
            if self.language.get() == "en":
                title, evidence, verify, fix, retest = self.english_compare(title, evidence, verify, fix, retest)
                blocks.append(f"{i}. {title}\n\nEVIDENCE\n{evidence}\n\nVERIFY\n{verify}\n\nMINIMAL CHANGE\n{fix}\n\nRETEST\n{retest}")
            else:
                blocks.append(f"{i}. {title}\n\nEVIDENCA\n{evidence}\n\nVERIFIKO\n{verify}\n\nNDRYSHIMI MINIMAL\n{fix}\n\nRITESTIMI\n{retest}")
        result = ("\n\n" + "─" * 42 + "\n\n").join(blocks)
        self.compare_output.config(state="normal"); self.compare_output.delete("1.0", "end"); self.compare_output.insert("1.0", result); self.compare_output.config(state="disabled")

    def clear_compare(self):
        self.compare_a.delete("1.0", "end"); self.compare_b.delete("1.0", "end")
        self.compare_output.config(state="normal"); self.compare_output.delete("1.0", "end"); self.compare_output.config(state="disabled")

    def apply_detected_device(self, content):
        detected = detect_device_name(content)
        if detected:
            self.device.delete(0, "end"); self.device.insert(0, detected)

    def format_findings(self, findings):
        blocks = []
        for i, f in enumerate(findings, 1):
            retest = self.retest_for(f['title'])
            if self.language.get() == "en":
                title, cause, fix = EN_FINDINGS.get(f['title'], (f['title'], f['cause'], f['fix']))
                blocks.append(f"{i}. {title}\nSeverity: {f['severity']}  |  Confidence: {f['confidence']}%\n\n"
                              f"SYMPTOM\n{title} was identified in the loaded configuration/output.\n\n"
                              f"PROBABLE CAUSE\n{cause}\n\n"
                              f"EVIDENCE\nThe technical signature of this issue was found in the device data.\n\n"
                              f"VERIFY BEFORE CHANGE\n{f['verify']}\n\n"
                              f"MINIMAL CHANGE\n{fix}\n\n"
                              f"RETEST / CLOSURE\n{retest}")
            else:
                blocks.append(f"{i}. {f['title']}\nNiveli: {f['severity']}  |  Siguria: {f['confidence']}%\n\n"
                              f"SIMPTOMA\n{f['title']} u identifikua në konfigurimin/output-in e ngarkuar.\n\n"
                              f"SHKAKU I MUNDSHËM\n{f['cause']}\n\n"
                              f"EVIDENCA\nNënshkrimi teknik i këtij problemi u gjet në të dhënat e pajisjes.\n\n"
                              f"VERIFIKO PARA NDRYSHIMIT\n{f['verify']}\n\n"
                              f"NDRYSHIMI MINIMAL\n{f['fix']}\n\n"
                              f"RITESTIMI / MBYLLJA\n{retest}")
        return "\n\n" + ("\n\n" + "─" * 56 + "\n\n").join(blocks)

    @staticmethod
    def english_compare(title, evidence, verify, fix, retest):
        titles = {"Native VLAN mismatch":"Native VLAN mismatch","Allowed VLAN mismatch":"Allowed VLAN mismatch","OSPF area mismatch":"OSPF area mismatch","Nuk u gjet subnet i përbashkët":"No shared subnet found","EtherChannel mode mismatch":"EtherChannel mode mismatch","BGP remote-as mismatch":"BGP remote-AS mismatch","Nuk u gjet mospërputhje e drejtpërdrejtë":"No direct mismatch found"}
        phrases = {"Vetëm te ":"Only on ","Rrjeti ":"Network "," pret AS ":" expects AS "," për ":" for "," por ":", but "," është AS ":" is AS ","U krahasuan ":"Compared "," për parametrat e disponueshëm.":" using the available parameters."}
        for sq, en in phrases.items(): evidence = evidence.replace(sq, en)
        guidance = {
            "Native VLAN mismatch":("show interfaces trunk on both switches","Match the native VLAN only on the ports connected to each other.","Confirm both ends show the same native VLAN and no STP inconsistent port."),
            "Allowed VLAN mismatch":("show interfaces trunk on both endpoints","Permit only required VLANs and make the list consistent on that link.","Verify allowed/active VLANs and ping from a host in the affected VLAN."),
            "OSPF area mismatch":("show ip ospf interface brief and show ip ospf neighbor on both routers","Assign the shared segment to the same area.","The adjacency must reach FULL and OSPF routes must appear in the routing table."),
            "Nuk u gjet subnet i përbashkët":("show ip interface brief and show cdp neighbors","Confirm which interfaces are directly connected; change IP/mask only when they should be peers.","Ping the peer and check ARP/CDP. This may be normal if the devices are not directly connected."),
            "EtherChannel mode mismatch":("show etherchannel summary on both switches","Use a compatible pair: LACP active/active or active/passive; static on/on.","The port-channel must be up and member ports bundled (P)."),
            "BGP remote-as mismatch":("show ip bgp summary and show running-config | section router bgp","Set remote-AS to the peer's actual AS.","The BGP session must become Established."),
            "Nuk u gjet mospërputhje e drejtpërdrejtë":("Add operational output (neighbors, trunks, routes) if the issue persists.","Do not change configuration without additional evidence.","Repeat the original test from source to destination.")}
        ev, fx, rt = guidance.get(title, (verify, fix, retest))
        return titles.get(title, title), evidence, ev, fx, rt

    def retest_for(self, title):
        lower = title.lower()
        if self.language.get() == "en":
            if "bgp" in lower: return "Repeat show ip bgp summary; the session must be Established and expected prefixes must appear."
            if "ospf" in lower: return "Repeat show ip ospf neighbor; adjacency must reach FULL and OSPF routes must appear in show ip route."
            if "dhcp" in lower or "apipa" in lower: return "Renew the lease, check ipconfig /all and ping the default gateway."
            if "dns" in lower: return "Repeat nslookup, then ping the hostname and IP to separate DNS from IP connectivity."
            if "vlan" in lower or "trunk" in lower: return "Repeat show vlan brief/show interfaces trunk, then ping the gateway from the affected VLAN."
            if "acl" in lower: return "Repeat the permitted flow and one negative test that must remain blocked; verify counters."
            if "nat" in lower: return "Generate new traffic, verify translations/counters and confirm the return path."
            if "vpn" in lower or "ipsec" in lower: return "Generate interesting traffic, verify IKE/IPsec SAs and test both directions."
            if "etherchannel" in lower: return "Run show etherchannel summary; the port-channel must be up and members bundled."
            return "Repeat the original failing test, add one adjacent positive test and verify the return path."
        if "bgp" in lower: return "Përsërit show ip bgp summary; gjendja duhet të jetë Established dhe prefikset e pritura të shfaqen."
        if "ospf" in lower: return "Përsërit show ip ospf neighbor; fqinjësia duhet të arrijë FULL dhe rrugët OSPF të shfaqen në show ip route."
        if "dhcp" in lower or "apipa" in lower: return "Rinovo lease-in, kontrollo ipconfig /all dhe testo ping drejt gateway-t."
        if "dns" in lower: return "Përsërit nslookup për emrin, pastaj ping emrin dhe IP-në për të ndarë DNS-in nga lidhja IP."
        if "vlan" in lower or "trunk" in lower: return "Përsërit show vlan brief/show interfaces trunk, pastaj ping gateway-n nga hosti i VLAN-it."
        if "acl" in lower: return "Përsërit rrjedhën që duhet lejuar dhe një test negativ që duhet të mbetet i bllokuar; kontrollo counters."
        if "nat" in lower: return "Gjenero trafik të ri, kontrollo translations/counters dhe testo edhe rrugën e kthimit."
        if "vpn" in lower or "ipsec" in lower: return "Gjenero interesting traffic, kontrollo IKE/IPsec SA dhe provo komunikimin në të dy drejtimet."
        if "etherchannel" in lower: return "Kontrollo show etherchannel summary; port-channel dhe anëtarët duhet të jenë bundled/up."
        return "Përsërit testin origjinal që dështoi, verifiko një test fqinj pozitiv dhe kontrollo rrugën e kthimit."

    def run_analysis(self):
        cfg = self.input_text.get("1.0", "end").strip()
        if not cfg:
            messagebox.showwarning("Configuration missing" if self.language.get()=="en" else "Mungon konfigurimi", "Paste or load the configuration to analyze." if self.language.get()=="en" else "Ngjit ose ngarko konfigurimin që dëshiron të analizosh."); return
        self.apply_detected_device(cfg)
        result = self.format_findings(analyze_config(cfg))
        self.output_text.config(state="normal"); self.output_text.delete("1.0", "end"); self.output_text.insert("1.0", result); self.output_text.config(state="disabled")

    def save_incident(self):
        cfg = self.input_text.get("1.0", "end").strip()
        result = self.output_text.get("1.0", "end").strip()
        if not cfg or not result:
            messagebox.showwarning("Analysis missing" if self.language.get()=="en" else "Analiza mungon", "Load the configuration and select Analyze first." if self.language.get()=="en" else "Fillimisht ngarko konfigurimin dhe shtyp Analizo."); return
        self.db.execute("INSERT INTO incidents(created_at,device,config,result,status) VALUES(?,?,?,?,?)",
                        (datetime.now().strftime("%Y-%m-%d %H:%M"), self.device.get().strip(), cfg, result, "ACTIVE"))
        self.db.commit(); self.refresh_history(); messagebox.showinfo("Saved" if self.language.get()=="en" else "U ruajt", "Incident saved successfully." if self.language.get()=="en" else "Incidenti u ruajt me sukses.")

    def refresh_history(self):
        if not hasattr(self, "tree"): return
        self.tree.delete(*self.tree.get_children())
        for row in self.db.execute("SELECT id,created_at,device,status FROM incidents ORDER BY id DESC"):
            self.tree.insert("", "end", values=row)

    def selected_id(self):
        selection = self.tree.selection()
        if not selection:
            messagebox.showwarning("Select incident" if self.language.get()=="en" else "Zgjidh incidentin", "Select an incident from the list." if self.language.get()=="en" else "Zgjidh një incident nga lista."); return None
        return int(self.tree.item(selection[0], "values")[0])

    def resolve(self):
        incident_id = self.selected_id()
        if incident_id:
            self.db.execute("UPDATE incidents SET status='RESOLVED' WHERE id=?", (incident_id,)); self.db.commit(); self.refresh_history()

    def show_details(self):
        incident_id = self.selected_id()
        if not incident_id: return
        row = self.db.execute("SELECT device,config,result,status FROM incidents WHERE id=?", (incident_id,)).fetchone()
        win = tk.Toplevel(self); win.title(f"Incidenti #{incident_id} – {row[0]}"); win.geometry("850x650"); win.configure(bg="#0b1220")
        text = tk.Text(win, bg="#07101e", fg="#d8e8ff", font=("Consolas", 10), wrap="word")
        labels = ("STATUS", "DEVICE", "RESULT", "CONFIGURATION") if self.language.get()=="en" else ("STATUSI", "PAJISJA", "REZULTATI", "KONFIGURIMI")
        text.pack(fill="both", expand=True, padx=12, pady=12); text.insert("1.0", f"{labels[0]}: {row[3]}\n{labels[1]}: {row[0]}\n\n{labels[2]}:\n{row[2]}\n\n{labels[3]}:\n{row[1]}"); text.config(state="disabled")

    def export_report(self):
        incident_id = self.selected_id()
        if not incident_id: return
        row = self.db.execute("SELECT created_at,device,config,result,status FROM incidents WHERE id=?", (incident_id,)).fetchone()
        path = filedialog.asksaveasfilename(defaultextension=".html", initialfile=f"NETOPS-Incident-{incident_id}.html", filetypes=[("HTML report", "*.html")])
        if not path: return
        en = self.language.get()=="en"; diag = "Diagnosis" if en else "Diagnoza"; config_label = "Configuration / Evidence" if en else "Konfigurimi / Evidenca"; device_label = "Device" if en else "Pajisja"; date_label = "Date" if en else "Data"; status_label = "Status" if en else "Statusi"; footer = "Generated locally by NETOPS AI." if en else "Gjeneruar lokalisht nga NETOPS AI."
        report = f"""<!doctype html><html lang='{'en' if en else 'sq'}'><meta charset='utf-8'><title>NETOPS Incident #{incident_id}</title>
<style>body{{font-family:Segoe UI,Arial;margin:40px;color:#13213a}}header{{background:#0b1220;color:white;padding:24px;border-left:8px solid #38bdf8}}h1{{margin:0}}.meta{{background:#eef6ff;padding:14px;margin:18px 0}}pre{{white-space:pre-wrap;background:#f4f7fb;padding:16px;border:1px solid #d8e1ed}}@media print{{button{{display:none}}}}</style>
<header><h1>NETOPS AI – {'Incident Report' if en else 'Raport Incidenti'} #{incident_id}</h1></header><div class='meta'><b>{device_label}:</b> {html.escape(row[1] or '')}<br><b>{date_label}:</b> {row[0]}<br><b>{status_label}:</b> {row[4]}</div>
<h2>{diag}</h2><pre>{html.escape(row[3])}</pre><h2>{config_label}</h2><pre>{html.escape(row[2])}</pre><p>{footer}</p></html>"""
        try:
            Path(path).write_text(report, encoding="utf-8"); messagebox.showinfo("Report exported" if en else "Raporti u eksportua", "HTML report saved. Open it in a browser and use Print > Save as PDF." if en else "Raporti HTML u ruajt. Hape në browser dhe përdor Print > Save as PDF.")
        except OSError as exc: messagebox.showerror("Gabim", str(exc))

    def delete_incident(self):
        incident_id = self.selected_id()
        if incident_id and messagebox.askyesno("Confirm deletion" if self.language.get()=="en" else "Konfirmo fshirjen", f"Delete incident #{incident_id}?" if self.language.get()=="en" else f"Ta fshij incidentin #{incident_id}?"):
            self.db.execute("DELETE FROM incidents WHERE id=?", (incident_id,)); self.db.commit(); self.refresh_history()

    def clear(self):
        self.input_text.delete("1.0", "end"); self.output_text.config(state="normal"); self.output_text.delete("1.0", "end"); self.output_text.config(state="disabled")

    def close_app(self):
        self.db.close(); self.destroy()


if __name__ == "__main__":
    NetOpsApp().mainloop()
