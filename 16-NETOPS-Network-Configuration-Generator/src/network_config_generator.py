import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from pathlib import Path
from datetime import datetime
import sys

SRC_DIR = Path(__file__).resolve().parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from vendors.cisco.routing import (
    generate_bgp as generate_cisco_bgp,
    generate_isis as generate_cisco_isis
)

from vendors.cisco.security import (
    generate_nat_pat as generate_cisco_nat_pat
)

from vendors.cisco.basic import (
    generate_hsrp as generate_cisco_hsrp,
    generate_vrf as generate_cisco_vrf
)

from vendors.cisco.vpn import (
    generate_ipsec_site_to_site as generate_cisco_ipsec
)

from vendors.fortigate.routing import (
    generate_bgp as generate_fortigate_bgp,
    generate_ospf as generate_fortigate_ospf,
    generate_static_route as generate_fortigate_static_route
)

from vendors.fortigate.firewall import (
    generate_interface as generate_fortigate_interface,
    generate_firewall_policy as generate_fortigate_firewall_policy
)

from vendors.fortigate.sdwan import (
    generate_sdwan as generate_fortigate_sdwan
)

from vendors.fortigate.vpn import (
    generate_ipsec_site_to_site as generate_fortigate_ipsec
)

from vendors.paloalto.routing import (
    generate_bgp as generate_paloalto_bgp,
    generate_ospf as generate_paloalto_ospf,
    generate_static_route as generate_paloalto_static_route,
    generate_layer3_interface as generate_paloalto_interface
)

from vendors.paloalto.security import (
    generate_zone as generate_paloalto_zone,
    generate_security_policy as generate_paloalto_security_policy,
    generate_nat_policy as generate_paloalto_nat_policy
)

BASE_DIR = Path(__file__).resolve().parent.parent
OUTPUT_DIR = BASE_DIR / "generated-configs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


class NetworkConfigGenerator:
    def __init__(self, root):
        self.root = root
        self.root.title("NETOPS Network Configuration Generator")
        self.root.geometry("1450x820")
        self.root.minsize(1100, 680)

        try:
            self.root.state("zoomed")
        except tk.TclError:
            pass

        self.build_sections = []
        self.current_generated_config = ""

        self.build_ui()

    def build_ui(self):
        header = ttk.Frame(self.root, padding=20)
        header.pack(fill="x")

        ttk.Label(
            header,
            text="NETOPS Network Configuration Generator",
            font=("Segoe UI", 20, "bold")
        ).pack(anchor="w")

        ttk.Label(
            header,
            text="Project 16 - Cisco Configuration Automation Toolkit"
        ).pack(anchor="w", pady=(4, 0))

        main = ttk.Frame(self.root, padding=(20, 0, 20, 20))
        main.pack(fill="both", expand=True)

        self.notebook = ttk.Notebook(main)
        self.notebook.pack(fill="x", pady=(0, 12))

        self.preview_frame = ttk.LabelFrame(
            main,
            text="Generated Configuration",
            padding=8
        )
        self.preview_frame.pack(fill="both", expand=True)

        preview_toolbar = ttk.Frame(self.preview_frame)
        preview_toolbar.pack(fill="x", pady=(0, 6))

        ttk.Button(
            preview_toolbar,
            text="Save Configuration",
            command=self.save_config
        ).pack(side="left")

        ttk.Button(
            preview_toolbar,
            text="Clear Preview",
            command=self.clear_preview
        ).pack(side="left", padx=(8, 0))

        ttk.Button(
            preview_toolbar,
            text="Add to Build",
            command=self.add_to_build
        ).pack(side="left", padx=(8, 0))

        ttk.Button(
            preview_toolbar,
            text="View Full Build",
            command=self.view_full_build
        ).pack(side="left", padx=(8, 0))

        ttk.Button(
            preview_toolbar,
            text="Clear Build",
            command=self.clear_build
        ).pack(side="left", padx=(8, 0))

        ttk.Label(
            preview_toolbar,
            text="Network Configuration Preview"
        ).pack(side="right")

        text_frame = ttk.Frame(self.preview_frame)
        text_frame.pack(fill="both", expand=True)

        self.preview = tk.Text(
            text_frame,
            wrap="none",
            font=("Consolas", 11),
            bg="#0d1117",
            fg="#e6edf3",
            insertbackground="white"
        )

        preview_scroll_y = ttk.Scrollbar(
            text_frame,
            orient="vertical",
            command=self.preview.yview
        )

        preview_scroll_x = ttk.Scrollbar(
            text_frame,
            orient="horizontal",
            command=self.preview.xview
        )

        self.preview.configure(
            yscrollcommand=preview_scroll_y.set,
            xscrollcommand=preview_scroll_x.set
        )

        self.preview.grid(
            row=0,
            column=0,
            sticky="nsew"
        )

        preview_scroll_y.grid(
            row=0,
            column=1,
            sticky="ns"
        )

        preview_scroll_x.grid(
            row=1,
            column=0,
            sticky="ew"
        )

        text_frame.rowconfigure(0, weight=1)
        text_frame.columnconfigure(0, weight=1)

        self.build_vlan_tab()
        self.build_trunk_tab()
        self.build_ospf_tab()
        self.build_dhcp_tab()
        self.build_static_route_tab()
        self.build_router_on_stick_tab()
        self.build_ssh_tab()
        self.build_acl_tab()
        self.build_full_device_tab()
        self.build_multivendor_tab()
        self.on_multivendor_vendor_change()


        self.status = ttk.Label(
            self.root,
            text="Ready",
            anchor="w",
            padding=(20, 8)
        )
        self.status.pack(fill="x")

    def build_vlan_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="VLAN + Access")

        ttk.Label(tab, text="VLAN ID").grid(row=0, column=0, sticky="w")
        self.vlan_id = ttk.Entry(tab, width=28)
        self.vlan_id.grid(row=1, column=0, pady=(2, 6))

        ttk.Label(tab, text="VLAN Name").grid(row=2, column=0, sticky="w")
        self.vlan_name = ttk.Entry(tab, width=28)
        self.vlan_name.grid(row=3, column=0, pady=(2, 6))

        ttk.Label(tab, text="Interface").grid(row=4, column=0, sticky="w")
        self.vlan_interface = ttk.Entry(tab, width=28)
        self.vlan_interface.grid(row=5, column=0, pady=(2, 6))
        self.vlan_interface.insert(0, "FastEthernet0/1")

        ttk.Button(
            tab,
            text="Generate VLAN Config",
            command=self.generate_vlan
        ).grid(row=6, column=0, sticky="ew")

    def build_trunk_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="Trunk")

        ttk.Label(tab, text="Interface").grid(row=0, column=0, sticky="w")
        self.trunk_interface = ttk.Entry(tab, width=28)
        self.trunk_interface.grid(row=1, column=0, pady=(2, 6))
        self.trunk_interface.insert(0, "GigabitEthernet0/1")

        ttk.Label(tab, text="Allowed VLANs").grid(row=2, column=0, sticky="w")
        self.trunk_vlans = ttk.Entry(tab, width=28)
        self.trunk_vlans.grid(row=3, column=0, pady=(2, 6))
        self.trunk_vlans.insert(0, "10,20,50")

        ttk.Label(tab, text="Native VLAN (optional)").grid(row=4, column=0, sticky="w")
        self.native_vlan = ttk.Entry(tab, width=28)
        self.native_vlan.grid(row=5, column=0, pady=(2, 6))

        ttk.Button(
            tab,
            text="Generate Trunk Config",
            command=self.generate_trunk
        ).grid(row=6, column=0, sticky="ew")

    def build_ospf_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="OSPF")

        fields = [
            ("Process ID", "100"),
            ("Router ID", "1.1.1.1"),
            ("Network", "192.168.10.0"),
            ("Wildcard Mask", "0.0.0.255"),
            ("Area", "0"),
        ]

        self.ospf_entries = []

        row = 0
        for label, default in fields:
            ttk.Label(tab, text=label).grid(row=row, column=0, sticky="w")
            entry = ttk.Entry(tab, width=28)
            entry.grid(row=row + 1, column=0, pady=(2, 6))
            entry.insert(0, default)
            self.ospf_entries.append(entry)
            row += 2

        ttk.Button(
            tab,
            text="Generate OSPF Config",
            command=self.generate_ospf
        ).grid(row=row, column=0, sticky="ew")

    def build_dhcp_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="DHCP")

        fields = [
            ("Pool Name", "FINANCE"),
            ("Network", "192.168.10.0"),
            ("Subnet Mask", "255.255.255.0"),
            ("Default Gateway", "192.168.10.1"),
            ("DNS Server", "8.8.8.8"),
        ]

        self.dhcp_entries = []

        row = 0
        for label, default in fields:
            ttk.Label(tab, text=label).grid(row=row, column=0, sticky="w")
            entry = ttk.Entry(tab, width=28)
            entry.grid(row=row + 1, column=0, pady=(2, 6))
            entry.insert(0, default)
            self.dhcp_entries.append(entry)
            row += 2

        ttk.Button(
            tab,
            text="Generate DHCP Config",
            command=self.generate_dhcp
        ).grid(row=row, column=0, sticky="ew")

    def build_static_route_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="Static Route")

        ttk.Label(tab, text="Destination Network").grid(row=0, column=0, sticky="w")
        self.route_network = ttk.Entry(tab, width=28)
        self.route_network.grid(row=1, column=0, pady=(2, 6))

        ttk.Label(tab, text="Subnet Mask").grid(row=2, column=0, sticky="w")
        self.route_mask = ttk.Entry(tab, width=28)
        self.route_mask.grid(row=3, column=0, pady=(2, 6))

        ttk.Label(tab, text="Next-Hop IP").grid(row=4, column=0, sticky="w")
        self.route_next_hop = ttk.Entry(tab, width=28)
        self.route_next_hop.grid(row=5, column=0, pady=(2, 6))

        ttk.Button(
            tab,
            text="Generate Static Route",
            command=self.generate_static_route
        ).grid(row=6, column=0, sticky="ew")

    def build_router_on_stick_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="Router-on-a-Stick")

        ttk.Label(tab, text="Physical Interface").grid(row=0, column=0, sticky="w")
        self.ros_interface = ttk.Entry(tab, width=28)
        self.ros_interface.grid(row=1, column=0, pady=(2, 6))
        self.ros_interface.insert(0, "GigabitEthernet0/0")

        ttk.Label(tab, text="VLAN ID").grid(row=2, column=0, sticky="w")
        self.ros_vlan = ttk.Entry(tab, width=28)
        self.ros_vlan.grid(row=3, column=0, pady=(2, 6))
        self.ros_vlan.insert(0, "10")

        ttk.Label(tab, text="IP Address").grid(row=4, column=0, sticky="w")
        self.ros_ip = ttk.Entry(tab, width=28)
        self.ros_ip.grid(row=5, column=0, pady=(2, 6))
        self.ros_ip.insert(0, "192.168.10.1")

        ttk.Label(tab, text="Subnet Mask").grid(row=6, column=0, sticky="w")
        self.ros_mask = ttk.Entry(tab, width=28)
        self.ros_mask.grid(row=7, column=0, pady=(2, 6))
        self.ros_mask.insert(0, "255.255.255.0")

        ttk.Button(
            tab,
            text="Generate Router-on-a-Stick",
            command=self.generate_router_on_stick
        ).grid(row=8, column=0, sticky="ew")

    def build_ssh_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="SSH Security")

        ttk.Label(tab, text="Hostname").grid(row=0, column=0, sticky="w")
        self.ssh_hostname = ttk.Entry(tab, width=28)
        self.ssh_hostname.grid(row=1, column=0, pady=(2, 6))
        self.ssh_hostname.insert(0, "R-HQ-01")

        ttk.Label(tab, text="Domain Name").grid(row=2, column=0, sticky="w")
        self.ssh_domain = ttk.Entry(tab, width=28)
        self.ssh_domain.grid(row=3, column=0, pady=(2, 6))
        self.ssh_domain.insert(0, "company.local")

        ttk.Label(tab, text="Username").grid(row=4, column=0, sticky="w")
        self.ssh_user = ttk.Entry(tab, width=28)
        self.ssh_user.grid(row=5, column=0, pady=(2, 6))
        self.ssh_user.insert(0, "admin")

        ttk.Label(tab, text="Secret").grid(row=6, column=0, sticky="w")
        self.ssh_secret = ttk.Entry(tab, width=28, show="*")
        self.ssh_secret.grid(row=7, column=0, pady=(2, 6))

        ttk.Button(
            tab,
            text="Generate SSH Security",
            command=self.generate_ssh
        ).grid(row=8, column=0, sticky="ew")

    def build_acl_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="ACL")

        ttk.Label(tab, text="ACL Number").grid(row=0, column=0, sticky="w")
        self.acl_number = ttk.Entry(tab, width=28)
        self.acl_number.grid(row=1, column=0, pady=(2, 6))
        self.acl_number.insert(0, "10")

        ttk.Label(tab, text="Action").grid(row=2, column=0, sticky="w")
        self.acl_action = ttk.Combobox(
            tab,
            values=["permit", "deny"],
            width=25,
            state="readonly"
        )
        self.acl_action.grid(row=3, column=0, pady=(2, 6))
        self.acl_action.current(0)

        ttk.Label(tab, text="Source Network").grid(row=4, column=0, sticky="w")
        self.acl_source = ttk.Entry(tab, width=28)
        self.acl_source.grid(row=5, column=0, pady=(2, 6))
        self.acl_source.insert(0, "192.168.10.0")

        ttk.Label(tab, text="Wildcard Mask").grid(row=6, column=0, sticky="w")
        self.acl_wildcard = ttk.Entry(tab, width=28)
        self.acl_wildcard.grid(row=7, column=0, pady=(2, 6))
        self.acl_wildcard.insert(0, "0.0.0.255")

        ttk.Button(
            tab,
            text="Generate ACL",
            command=self.generate_acl
        ).grid(row=8, column=0, sticky="ew")


    def build_full_device_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="Full Device")

        ttk.Label(tab, text="Device Type").grid(
            row=0, column=0, sticky="w"
        )

        self.full_device_type = ttk.Combobox(
            tab,
            values=["Router", "Switch"],
            width=25,
            state="readonly"
        )
        self.full_device_type.grid(
            row=1, column=0, pady=(2, 6), sticky="w"
        )
        self.full_device_type.current(0)

        ttk.Label(tab, text="Hostname").grid(
            row=0, column=1, sticky="w", padx=(20, 0)
        )

        self.full_hostname = ttk.Entry(tab, width=28)
        self.full_hostname.grid(
            row=1, column=1, pady=(2, 6), padx=(20, 0)
        )
        self.full_hostname.insert(0, "R-HQ-01")

        ttk.Label(tab, text="Enable Secret").grid(
            row=2, column=0, sticky="w"
        )

        self.full_enable_secret = ttk.Entry(
            tab,
            width=28,
            show="*"
        )
        self.full_enable_secret.grid(
            row=3, column=0, pady=(2, 6)
        )

        ttk.Label(tab, text="Management Interface").grid(
            row=2, column=1, sticky="w", padx=(20, 0)
        )

        self.full_interface = ttk.Entry(tab, width=28)
        self.full_interface.grid(
            row=3, column=1, pady=(2, 6), padx=(20, 0)
        )
        self.full_interface.insert(0, "GigabitEthernet0/0")

        ttk.Label(tab, text="Management IP").grid(
            row=4, column=0, sticky="w"
        )

        self.full_ip = ttk.Entry(tab, width=28)
        self.full_ip.grid(
            row=5, column=0, pady=(2, 6)
        )
        self.full_ip.insert(0, "192.168.10.1")

        ttk.Label(tab, text="Subnet Mask").grid(
            row=4, column=1, sticky="w", padx=(20, 0)
        )

        self.full_mask = ttk.Entry(tab, width=28)
        self.full_mask.grid(
            row=5, column=1, pady=(2, 6), padx=(20, 0)
        )
        self.full_mask.insert(0, "255.255.255.0")

        ttk.Label(tab, text="Default Gateway (Switch)").grid(
            row=6, column=0, sticky="w"
        )

        self.full_gateway = ttk.Entry(tab, width=28)
        self.full_gateway.grid(
            row=7, column=0, pady=(2, 6)
        )
        self.full_gateway.insert(0, "192.168.10.254")

        ttk.Label(tab, text="Domain Name").grid(
            row=6, column=1, sticky="w", padx=(20, 0)
        )

        self.full_domain = ttk.Entry(tab, width=28)
        self.full_domain.grid(
            row=7, column=1, pady=(2, 6), padx=(20, 0)
        )
        self.full_domain.insert(0, "company.local")

        ttk.Label(tab, text="SSH Username").grid(
            row=8, column=0, sticky="w"
        )

        self.full_username = ttk.Entry(tab, width=28)
        self.full_username.grid(
            row=9, column=0, pady=(2, 6)
        )
        self.full_username.insert(0, "admin")

        ttk.Label(tab, text="SSH Secret").grid(
            row=8, column=1, sticky="w", padx=(20, 0)
        )

        self.full_ssh_secret = ttk.Entry(
            tab,
            width=28,
            show="*"
        )
        self.full_ssh_secret.grid(
            row=9, column=1, pady=(2, 6), padx=(20, 0)
        )

        ttk.Label(tab, text="OSPF Process ID").grid(
            row=10, column=0, sticky="w"
        )

        self.full_ospf_process = ttk.Entry(tab, width=28)
        self.full_ospf_process.grid(
            row=11, column=0, pady=(2, 6)
        )
        self.full_ospf_process.insert(0, "100")

        ttk.Label(tab, text="OSPF Router ID").grid(
            row=10, column=1, sticky="w", padx=(20, 0)
        )

        self.full_router_id = ttk.Entry(tab, width=28)
        self.full_router_id.grid(
            row=11, column=1, pady=(2, 6), padx=(20, 0)
        )
        self.full_router_id.insert(0, "1.1.1.1")

        self.full_include_ssh = tk.BooleanVar(value=True)

        ttk.Checkbutton(
            tab,
            text="Include SSH Security",
            variable=self.full_include_ssh
        ).grid(
            row=12,
            column=0,
            sticky="w",
            pady=(5, 5)
        )

        self.full_include_ospf = tk.BooleanVar(value=True)

        ttk.Checkbutton(
            tab,
            text="Include OSPF (Router only)",
            variable=self.full_include_ospf
        ).grid(
            row=12,
            column=1,
            sticky="w",
            padx=(20, 0),
            pady=(5, 5)
        )

        ttk.Button(
            tab,
            text="Generate Full Device Configuration",
            command=self.generate_full_device
        ).grid(
            row=13,
            column=0,
            columnspan=2,
            sticky="ew",
            pady=(12, 0)
        )


    def build_multivendor_tab(self):
        tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(tab, text="Multi-Vendor")

        # ====================================================
        # TOP SELECTORS
        # ====================================================

        ttk.Label(tab, text="Vendor").grid(
            row=0, column=0, sticky="w"
        )

        self.mv_vendor = ttk.Combobox(
            tab,
            values=["Cisco", "FortiGate", "Palo Alto"],
            state="readonly",
            width=24
        )
        self.mv_vendor.grid(
            row=1,
            column=0,
            padx=(0, 20),
            pady=(2, 8)
        )
        self.mv_vendor.current(0)

        ttk.Label(tab, text="Platform").grid(
            row=0, column=1, sticky="w"
        )

        self.mv_platform = ttk.Combobox(
            tab,
            state="readonly",
            width=24
        )
        self.mv_platform.grid(
            row=1,
            column=1,
            padx=(0, 20),
            pady=(2, 8)
        )

        ttk.Label(tab, text="Technology").grid(
            row=0, column=2, sticky="w"
        )

        self.mv_technology = ttk.Combobox(
            tab,
            state="readonly",
            width=24
        )
        self.mv_technology.grid(
            row=1,
            column=2,
            pady=(2, 8)
        )

        ttk.Separator(
            tab,
            orient="horizontal"
        ).grid(
            row=2,
            column=0,
            columnspan=3,
            sticky="ew",
            pady=10
        )

        # ====================================================
        # DYNAMIC PARAMETER AREA
        # ====================================================

        self.mv_parameter_frame = ttk.LabelFrame(
            tab,
            text="Technology Parameters",
            padding=10
        )

        self.mv_parameter_frame.grid(
            row=3,
            column=0,
            columnspan=3,
            sticky="ew",
            pady=(0, 10)
        )

        self.mv_parameter_frame.columnconfigure(0, weight=1)
        self.mv_parameter_frame.columnconfigure(1, weight=1)
        self.mv_parameter_frame.columnconfigure(2, weight=1)

        self.mv_dynamic_entries = {}

        # ====================================================
        # GENERATE BUTTON
        # ====================================================

        ttk.Button(
            tab,
            text="Generate Multi-Vendor Config",
            command=self.generate_multivendor_config
        ).grid(
            row=4,
            column=0,
            columnspan=3,
            sticky="ew",
            pady=(12, 0)
        )

        # ====================================================
        # EVENTS
        # ====================================================

        self.mv_vendor.bind(
            "<<ComboboxSelected>>",
            self.on_multivendor_vendor_change
        )

        self.mv_technology.bind(
            "<<ComboboxSelected>>",
            self.on_multivendor_technology_change
        )

        self.on_multivendor_vendor_change()


    def get_multivendor_parameter_schema(self, vendor, technology):

        schemas = {

            # =================================================
            # CISCO
            # =================================================

            ("Cisco", "OSPF"): [
                ("process", "Process ID", "1"),
                ("router_id", "Router ID", "1.1.1.1"),
                ("network", "Network", "192.168.10.0"),
                ("wildcard", "Wildcard Mask", "0.0.0.255"),
                ("area", "Area", "0"),
            ],

            ("Cisco", "VLAN"): [
                ("vlan_id", "VLAN ID", "10"),
                ("vlan_name", "VLAN Name", "USERS"),
                ("interface", "Access Interface", "GigabitEthernet0/1"),
            ],

            ("Cisco", "Trunk"): [
                ("interface", "Trunk Interface", "GigabitEthernet0/24"),
                ("vlans", "Allowed VLANs", "10,20,30"),
                ("native", "Native VLAN", "99"),
            ],

            ("Cisco", "DHCP"): [
                ("pool", "Pool Name", "USERS"),
                ("network", "Network", "192.168.10.0"),
                ("mask", "Subnet Mask", "255.255.255.0"),
                ("gateway", "Default Gateway", "192.168.10.1"),
                ("dns", "DNS Server", "8.8.8.8"),
            ],

            ("Cisco", "Static Route"): [
                ("network", "Destination Network", "10.10.10.0"),
                ("mask", "Subnet Mask", "255.255.255.0"),
                ("next_hop", "Next Hop", "192.168.1.1"),
            ],

            ("Cisco", "ACL"): [
                ("number", "ACL Number", "10"),
                ("action", "Action", "permit"),
                ("source", "Source Network", "192.168.10.0"),
                ("wildcard", "Wildcard Mask", "0.0.0.255"),
            ],
            ("Cisco", "BGP"): [
                ("local_asn", "Local ASN", "65001"),
                ("router_id", "Router ID", "1.1.1.1"),
                ("neighbor_ip", "Neighbor IP", "203.0.113.2"),
                ("remote_asn", "Remote ASN", "65002"),
                ("network", "Network", "192.168.10.0"),
                ("mask", "Subnet Mask", "255.255.255.0"),
                ("description", "Neighbor Description", "ISP-01"),
            ],

            ("Cisco", "IS-IS"): [
                ("process_name", "Process Name", "CORE"),
                ("net", "NET", "49.0001.0000.0000.0001.00"),
                ("interface", "Interface", "GigabitEthernet0/1"),
                ("level", "IS-IS Level", "level-2-only"),
            ],

            ("Cisco", "NAT/PAT"): [
                ("inside_network", "Inside Network", "192.168.10.0"),
                ("wildcard", "Wildcard Mask", "0.0.0.255"),
                ("inside_interface", "Inside Interface", "GigabitEthernet0/1"),
                ("outside_interface", "Outside Interface", "GigabitEthernet0/0"),
            ],

            ("Cisco", "HSRP"): [
                ("interface", "Interface", "GigabitEthernet0/1"),
                ("group", "HSRP Group", "10"),
                ("virtual_ip", "Virtual IP", "192.168.10.1"),
                ("priority", "Priority", "110"),
                ("preempt", "Preempt", "True"),
            ],

            ("Cisco", "VRF"): [
                ("vrf_name", "VRF Name", "CUSTOMER-A"),
                ("rd", "Route Distinguisher", "65001:100"),
                ("interface", "Interface", "GigabitEthernet0/2"),
                ("ip_address", "IP Address", "192.168.100.1"),
                ("subnet_mask", "Subnet Mask", "255.255.255.0"),
            ],

            ("Cisco", "IPsec VPN"): [
                ("peer_ip", "Peer IP", "203.0.113.2"),
                ("pre_shared_key", "Pre-Shared Key", "LAB-KEY"),
                ("local_network", "Local Network", "192.168.10.0"),
                ("local_wildcard", "Local Wildcard", "0.0.0.255"),
                ("remote_network", "Remote Network", "192.168.20.0"),
                ("remote_wildcard", "Remote Wildcard", "0.0.0.255"),
                ("outside_interface", "Outside Interface", "GigabitEthernet0/0"),
            ],

            # =================================================
            # FORTIGATE
            # =================================================

            ("FortiGate", "NAT"): [
                ("policy_id", "Policy ID", "20"),
                ("name", "NAT Policy Name", "USERS-NAT"),
                ("source_interface", "Source Interface", "internal"),
                ("destination_interface", "Destination Interface", "wan1"),
                ("source_address", "Source Address", "all"),
                ("destination_address", "Destination Address", "all"),
                ("service", "Service", "ALL"),
            ],

            ("FortiGate", "IPsec VPN"): [
                ("tunnel_name", "Tunnel Name", "HQ-BRANCH"),
                ("remote_gateway", "Remote Gateway", "203.0.113.50"),
                ("local_interface", "Local Interface", "wan1"),
                ("pre_shared_key", "Pre-Shared Key", "NETOPS-LAB-KEY"),
                ("local_subnet", "Local Subnet", "192.168.10.0 255.255.255.0"),
                ("remote_subnet", "Remote Subnet", "192.168.20.0 255.255.255.0"),
                ("proposal", "Proposal", "aes256-sha256"),
                ("dh_group", "DH Group", "14"),
            ],
            ("FortiGate", "Interface"): [
                ("name", "Interface Name", "wan1"),
                ("ip_address", "IP Address", "203.0.113.2"),
                ("subnet_mask", "Subnet Mask", "255.255.255.0"),
                ("alias", "Alias", "NETOPS"),
            ],

            ("FortiGate", "Static Route"): [
                ("destination", "Destination", "0.0.0.0/0"),
                ("gateway", "Gateway", "203.0.113.2"),
                ("device", "Device", "wan1"),
            ],

            ("FortiGate", "Firewall Policy"): [
                ("policy_id", "Policy ID", "1"),
                ("name", "Policy Name", "LAN-to-Internet"),
                ("source_interface", "Source Interface", "internal"),
                ("destination_interface", "Destination Interface", "wan1"),
                ("source_address", "Source Address", "all"),
                ("destination_address", "Destination Address", "all"),
                ("service", "Service", "ALL"),
                ("nat", "NAT", "True"),
            ],

            ("FortiGate", "BGP"): [
                ("local_asn", "Local ASN", "65001"),
                ("router_id", "Router ID", "1.1.1.1"),
                ("neighbor_ip", "Neighbor IP", "203.0.113.2"),
                ("remote_asn", "Remote ASN", "65002"),
            ],

            ("FortiGate", "OSPF"): [
                ("router_id", "Router ID", "1.1.1.1"),
                ("network", "Network CIDR", "192.168.10.0/24"),
            ],

            ("FortiGate", "SD-WAN"): [
                ("member1", "WAN 1 Interface", "wan1"),
                ("gateway1", "WAN 1 Gateway", "203.0.113.2"),
                ("member2", "WAN 2 Interface", "wan2"),
                ("gateway2", "WAN 2 Gateway", "198.51.100.1"),
            ],

            # =================================================
            # PALO ALTO
            # =================================================

            ("Palo Alto", "Layer3 Interface"): [
                ("interface", "Interface", "ethernet1/1"),
                ("ip_cidr", "IP / CIDR", "203.0.113.2/24"),
                ("virtual_router", "Virtual Router", "default"),
            ],

            ("Palo Alto", "Zone"): [
                ("zone_name", "Zone Name", "UNTRUST"),
                ("interface", "Interface", "ethernet1/1"),
            ],

            ("Palo Alto", "Static Route"): [
                ("virtual_router", "Virtual Router", "default"),
                ("route_name", "Route Name", "DEFAULT-ROUTE"),
                ("destination", "Destination", "0.0.0.0/0"),
                ("next_hop", "Next Hop", "203.0.113.2"),
                ("interface", "Interface", "ethernet1/1"),
            ],

            ("Palo Alto", "Security Policy"): [
                ("rule_name", "Rule Name", "LAN-TO-INTERNET"),
                ("from_zone", "From Zone", "TRUST"),
                ("to_zone", "To Zone", "UNTRUST"),
                ("source", "Source", "any"),
                ("destination", "Destination", "any"),
                ("application", "Application", "any"),
                ("service", "Service", "application-default"),
                ("action", "Action", "allow"),
            ],

            ("Palo Alto", "NAT Policy"): [
                ("rule_name", "Rule Name", "SOURCE-NAT"),
                ("from_zone", "From Zone", "TRUST"),
                ("to_zone", "To Zone", "UNTRUST"),
                ("source", "Source", "any"),
                ("destination", "Destination", "any"),
                ("translated_interface", "Translated Interface", "ethernet1/1"),
            ],

            ("Palo Alto", "BGP"): [
                ("virtual_router", "Virtual Router", "default"),
                ("local_asn", "Local ASN", "65001"),
                ("router_id", "Router ID", "1.1.1.1"),
                ("peer_group", "Peer Group", "EBGP-PEERS"),
                ("peer_name", "Peer Name", "ISP-01"),
                ("peer_ip", "Peer IP", "203.0.113.2"),
                ("remote_asn", "Remote ASN", "65002"),
            ],

            ("Palo Alto", "OSPF"): [
                ("virtual_router", "Virtual Router", "default"),
                ("router_id", "Router ID", "1.1.1.1"),
                ("area", "Area", "0.0.0.0"),
                ("interface", "Interface", "ethernet1/2"),
            ],
        }

        return schemas.get(
            (vendor, technology),
            []
        )


    def refresh_multivendor_parameter_form(self):

        if not hasattr(self, "mv_parameter_frame"):
            return

        for widget in self.mv_parameter_frame.winfo_children():
            widget.destroy()

        self.mv_dynamic_entries = {}

        vendor = self.mv_vendor.get().strip()
        technology = self.mv_technology.get().strip()

        schema = self.get_multivendor_parameter_schema(
            vendor,
            technology
        )

        if not schema:
            ttk.Label(
                self.mv_parameter_frame,
                text=(
                    f"{vendor} / {technology} is listed, "
                    "but its Dynamic Parameter Form is not connected yet."
                )
            ).grid(
                row=0,
                column=0,
                columnspan=3,
                sticky="w",
                pady=8
            )
            return

        for index, item in enumerate(schema):

            key, label, default = item

            column = index % 3
            group_row = (index // 3) * 2

            ttk.Label(
                self.mv_parameter_frame,
                text=label
            ).grid(
                row=group_row,
                column=column,
                sticky="w",
                padx=(0, 20)
            )

            entry = ttk.Entry(
                self.mv_parameter_frame,
                width=26
            )

            entry.grid(
                row=group_row + 1,
                column=column,
                sticky="ew",
                padx=(0, 20),
                pady=(2, 8)
            )

            entry.insert(0, default)

            self.mv_dynamic_entries[key] = entry


    def on_multivendor_technology_change(self, event=None):

        self.refresh_multivendor_parameter_form()

        if hasattr(self, "status"):
            vendor = self.mv_vendor.get().strip()
            technology = self.mv_technology.get().strip()

            self.status.config(
                text=(
                    f"{vendor} / {technology} "
                    "dynamic parameters loaded."
                )
            )


    def get_mv_parameter(self, name, default=""):

        entry = self.mv_dynamic_entries.get(name)

        if entry is None:
            return default

        value = entry.get().strip()

        if value:
            return value

        return default

    def show_config(self, config):
        self.current_generated_config = config

        self.preview.delete("1.0", tk.END)
        self.preview.insert("1.0", config)

        self.status.config(
            text="Configuration generated successfully. Use Add to Build to include it in the final configuration."
        )

    def generate_vlan(self):
        vlan_id = self.vlan_id.get().strip()
        vlan_name = self.vlan_name.get().strip()
        interface = self.vlan_interface.get().strip()

        if not vlan_id.isdigit() or not (1 <= int(vlan_id) <= 4094):
            messagebox.showerror("Validation Error", "VLAN ID must be between 1 and 4094.")
            return

        if not vlan_name or not interface:
            messagebox.showerror("Validation Error", "VLAN Name and Interface are required.")
            return

        self.show_config(
            f"""!
vlan {vlan_id}
 name {vlan_name}
!
interface {interface}
 switchport mode access
 switchport access vlan {vlan_id}
 spanning-tree portfast
 no shutdown
!"""
        )

    def generate_trunk(self):
        interface = self.trunk_interface.get().strip()
        vlans = self.trunk_vlans.get().strip()
        native = self.native_vlan.get().strip()

        if not interface or not vlans:
            messagebox.showerror("Validation Error", "Interface and Allowed VLANs are required.")
            return

        lines = [
            "!",
            f"interface {interface}",
            " switchport mode trunk",
            f" switchport trunk allowed vlan {vlans}",
        ]

        if native:
            lines.append(f" switchport trunk native vlan {native}")

        lines.extend([" no shutdown", "!"])
        self.show_config("\n".join(lines))

    def generate_ospf(self):
        process, router_id, network, wildcard, area = [
            e.get().strip() for e in self.ospf_entries
        ]

        if not all([process, router_id, network, wildcard, area]):
            messagebox.showerror("Validation Error", "All OSPF fields are required.")
            return

        self.show_config(
            f"""!
router ospf {process}
 router-id {router_id}
 network {network} {wildcard} area {area}
!"""
        )

    def generate_dhcp(self):
        pool, network, mask, gateway, dns = [
            e.get().strip() for e in self.dhcp_entries
        ]

        if not all([pool, network, mask, gateway, dns]):
            messagebox.showerror("Validation Error", "All DHCP fields are required.")
            return

        self.show_config(
            f"""!
ip dhcp pool {pool}
 network {network} {mask}
 default-router {gateway}
 dns-server {dns}
!"""
        )

    def generate_static_route(self):
        network = self.route_network.get().strip()
        mask = self.route_mask.get().strip()
        next_hop = self.route_next_hop.get().strip()

        if not all([network, mask, next_hop]):
            messagebox.showerror("Validation Error", "All static-route fields are required.")
            return

        self.show_config(
            f"""!
ip route {network} {mask} {next_hop}
!"""
        )

    def generate_router_on_stick(self):
        interface = self.ros_interface.get().strip()
        vlan = self.ros_vlan.get().strip()
        ip = self.ros_ip.get().strip()
        mask = self.ros_mask.get().strip()

        if not all([interface, vlan, ip, mask]):
            messagebox.showerror("Validation Error", "All Router-on-a-Stick fields are required.")
            return

        self.show_config(
            f"""!
interface {interface}.{vlan}
 encapsulation dot1Q {vlan}
 ip address {ip} {mask}
 no shutdown
!"""
        )

    def generate_ssh(self):
        hostname = self.ssh_hostname.get().strip()
        domain = self.ssh_domain.get().strip()
        username = self.ssh_user.get().strip()
        secret = self.ssh_secret.get().strip()

        if not all([hostname, domain, username, secret]):
            messagebox.showerror("Validation Error", "All SSH fields are required.")
            return

        self.show_config(
            f"""!
hostname {hostname}
ip domain-name {domain}
username {username} privilege 15 secret {secret}
crypto key generate rsa modulus 2048
ip ssh version 2
!
line vty 0 4
 login local
 transport input ssh
!"""
        )

    def generate_acl(self):
        number = self.acl_number.get().strip()
        action = self.acl_action.get().strip()
        source = self.acl_source.get().strip()
        wildcard = self.acl_wildcard.get().strip()

        if not all([number, action, source, wildcard]):
            messagebox.showerror("Validation Error", "All ACL fields are required.")
            return

        self.show_config(
            f"""!
access-list {number} {action} {source} {wildcard}
!"""
        )


    def generate_full_device(self):
        device_type = self.full_device_type.get().strip()
        hostname = self.full_hostname.get().strip()
        enable_secret = self.full_enable_secret.get().strip()
        interface = self.full_interface.get().strip()
        ip_address = self.full_ip.get().strip()
        subnet_mask = self.full_mask.get().strip()
        gateway = self.full_gateway.get().strip()
        domain = self.full_domain.get().strip()
        username = self.full_username.get().strip()
        ssh_secret = self.full_ssh_secret.get().strip()
        ospf_process = self.full_ospf_process.get().strip()
        router_id = self.full_router_id.get().strip()

        if not hostname:
            messagebox.showerror(
                "Validation Error",
                "Hostname is required."
            )
            return

        if not enable_secret:
            messagebox.showerror(
                "Validation Error",
                "Enable Secret is required."
            )
            return

        if not all([interface, ip_address, subnet_mask]):
            messagebox.showerror(
                "Validation Error",
                "Management Interface, IP and Subnet Mask are required."
            )
            return

        lines = [
            "!",
            f"hostname {hostname}",
            "!",
            f"enable secret {enable_secret}",
            "service password-encryption",
            "no ip domain-lookup",
            "!"
        ]

        if device_type == "Router":
            lines.extend([
                f"interface {interface}",
                f" ip address {ip_address} {subnet_mask}",
                " no shutdown",
                "!"
            ])

        else:
            lines.extend([
                f"interface {interface}",
                f" ip address {ip_address} {subnet_mask}",
                " no shutdown",
                "!"
            ])

            if gateway:
                lines.extend([
                    f"ip default-gateway {gateway}",
                    "!"
                ])

        if self.full_include_ssh.get():

            if not all([domain, username, ssh_secret]):
                messagebox.showerror(
                    "Validation Error",
                    "Domain, Username and SSH Secret are required when SSH is enabled."
                )
                return

            lines.extend([
                f"ip domain-name {domain}",
                f"username {username} privilege 15 secret {ssh_secret}",
                "crypto key generate rsa modulus 2048",
                "ip ssh version 2",
                "!",
                "line vty 0 4",
                " login local",
                " transport input ssh",
                "!"
            ])

        if (
            device_type == "Router"
            and self.full_include_ospf.get()
        ):

            if not all([ospf_process, router_id]):
                messagebox.showerror(
                    "Validation Error",
                    "OSPF Process ID and Router ID are required."
                )
                return

            lines.extend([
                f"router ospf {ospf_process}",
                f" router-id {router_id}",
                " passive-interface default",
                f" no passive-interface {interface}",
                "!"
            ])

        lines.extend([
            "line console 0",
            " logging synchronous",
            "!",
            "end"
        ])

        self.show_config("\n".join(lines))

    def add_to_build(self):
        config = self.current_generated_config.strip()

        if not config:
            messagebox.showwarning(
                "Nothing to Add",
                "Generate a configuration first."
            )
            return

        # ----------------------------------------------------
        # Resolve metadata safely.
        # Existing Cisco tabs continue to work even when
        # Multi-Vendor variables are not involved.
        # ----------------------------------------------------

        vendor = "Cisco"
        platform = ""
        technology = "Generated Configuration"

        try:
            current_tab = self.notebook.tab(
                self.notebook.select(),
                "text"
            )
        except Exception:
            current_tab = ""

        if current_tab:
            technology = current_tab

        # Multi-Vendor tab metadata
        if current_tab.lower().replace(" ", "-") in (
            "multi-vendor",
            "multivendor"
        ):
            try:
                selected_vendor = self.mv_vendor.get().strip()
                if selected_vendor:
                    vendor = selected_vendor
            except Exception:
                pass

            try:
                selected_platform = self.mv_platform.get().strip()
                if selected_platform:
                    platform = selected_platform
            except Exception:
                pass

            try:
                selected_technology = self.mv_technology.get().strip()
                if selected_technology:
                    technology = selected_technology
            except Exception:
                pass

        # ----------------------------------------------------
        # Duplicate protection
        # Supports both the old string format and the new
        # structured Build Mode format.
        # ----------------------------------------------------

        normalized_config = "\n".join(
            line.rstrip()
            for line in config.strip().splitlines()
        ).strip()

        for existing in self.build_sections:

            if isinstance(existing, dict):
                existing_config = str(
                    existing.get("config", "")
                ).strip()
            else:
                existing_config = str(existing).strip()

            existing_normalized = "\n".join(
                line.rstrip()
                for line in existing_config.splitlines()
            ).strip()

            if existing_normalized == normalized_config:
                messagebox.showwarning(
                    "Duplicate Section",
                    "This exact configuration is already in the current build."
                )

                self.status.config(
                    text="Duplicate configuration was not added."
                )
                return

        # ----------------------------------------------------
        # Store section as structured metadata.
        # Do NOT modify the generated configuration itself.
        # ----------------------------------------------------

        section = {
            "vendor": vendor,
            "platform": platform,
            "technology": technology,
            "config": config
        }

        self.build_sections.append(section)

        self.status.config(
            text=f"Added to build. Sections: {len(self.build_sections)}"
        )

        details = f"Vendor: {vendor}"

        if platform:
            details += f"\nPlatform: {platform}"

        details += f"\nTechnology: {technology}"

        messagebox.showinfo(
            "Added to Build",
            "Configuration section added successfully."
            f"\n\n{details}"
            f"\n\nTotal sections: {len(self.build_sections)}"
        )


    def get_full_build(self):
        if not self.build_sections:
            return ""

        output = []

        for number, section in enumerate(
            self.build_sections,
            start=1
        ):

            # Backward compatibility with Build sections
            # created before this safety patch.
            if isinstance(section, dict):
                vendor = str(
                    section.get("vendor", "Unknown")
                ).strip()

                platform = str(
                    section.get("platform", "")
                ).strip()

                technology = str(
                    section.get(
                        "technology",
                        "Generated Configuration"
                    )
                ).strip()

                config = str(
                    section.get("config", "")
                ).strip()

            else:
                vendor = "Legacy"
                platform = ""
                technology = "Existing Build Section"
                config = str(section).strip()

            if not config:
                continue

            # ------------------------------------------------
            # IMPORTANT:
            # Do not remove or inject vendor commands.
            #
            # Cisco may use "end".
            # FortiGate uses nested config/end blocks.
            # Palo Alto has its own syntax.
            #
            # Each generated section must therefore remain
            # exactly as its generator produced it.
            # ------------------------------------------------

            header = [
                "############################################################",
                f"# NETOPS BUILD SECTION {number}",
                f"# Vendor: {vendor}",
            ]

            if platform:
                header.append(
                    f"# Platform: {platform}"
                )

            header.extend([
                f"# Technology: {technology}",
                "############################################################",
                ""
            ])

            output.extend(header)
            output.append(config)
            output.append("")

        return "\n".join(output).rstrip()


    def view_full_build(self):
        full_config = self.get_full_build()

        if not full_config:
            messagebox.showwarning(
                "Build Empty",
                "No configuration sections have been added yet."
            )
            return

        self.preview.delete("1.0", tk.END)
        self.preview.insert("1.0", full_config)

        self.status.config(
            text=(
                "Full build displayed. "
                f"Sections: {len(self.build_sections)}"
            )
        )


    def clear_build(self):
        if not self.build_sections:
            self.status.config(
                text="Build is already empty."
            )
            return

        answer = messagebox.askyesno(
            "Clear Build",
            "Remove all configuration sections from the current build?"
        )

        if not answer:
            return

        self.build_sections.clear()

        # Keep the last generated configuration available.
        # Clear Build should clear only the accumulated build.
        self.preview.delete("1.0", tk.END)

        self.status.config(
            text="Full configuration build cleared."
        )


    def on_multivendor_vendor_change(self, event=None):
        vendor = self.mv_vendor.get().strip()

        if vendor == "Cisco":
            platforms = [
                "IOS",
                "IOS-XE",
                "NX-OS",
                "ASA/FTD"
            ]

            technologies = [
                "BGP",
                "OSPF",
                "IS-IS",
                "VLAN",
                "Trunk",
                "NAT/PAT",
                "HSRP",
                "VRF",
                "IPsec VPN",
                "ACL",
                "DHCP",
                "Static Route"
            ]

        elif vendor == "FortiGate":
            platforms = [
                "FortiOS"
            ]

            technologies = [
                "Interface",
                "Static Route",
                "Firewall Policy",
                "NAT",
                "BGP",
                "OSPF",
                "SD-WAN",
                "IPsec VPN"
            ]

        elif vendor == "Palo Alto":
            platforms = [
                "PAN-OS"
            ]

            technologies = [
                "Layer3 Interface",
                "Zone",
                "Static Route",
                "Security Policy",
                "NAT Policy",
                "BGP",
                "OSPF"
            ]

        else:
            platforms = []
            technologies = []

        self.mv_platform["values"] = platforms
        self.mv_technology["values"] = technologies

        if platforms:
            self.mv_platform.current(0)

        if technologies:
            self.mv_technology.current(0)

        if hasattr(self, "status"):
            self.status.config(
                text=f"{vendor} platform and technology options loaded."
            )

    def generate_multivendor_config(self):
        vendor = self.mv_vendor.get().strip()
        technology = self.mv_technology.get().strip()

        def as_bool(value):
            return str(value).strip().lower() in (
                "true",
                "yes",
                "1",
                "on",
                "enable",
                "enabled"
            )

        def as_int(value, field_name):
            try:
                return int(str(value).strip())
            except ValueError:
                raise ValueError(
                    f"{field_name} must be a valid integer."
                )

        # ======================================================
        # MULTI-VENDOR VALIDATION MAPPING V1
        # ======================================================

        from core.validator import NetworkValidator

        validation_errors = []

        def add_result(result):
            if result and result.errors:
                validation_errors.extend(result.errors)

        def mv_value(name):
            return self.get_mv_parameter(name, "").strip()

        # ------------------------------------------------------
        # Required fields from the active Dynamic Parameter Form
        # ------------------------------------------------------

        active_schema = self.get_multivendor_parameter_schema(
            vendor,
            technology
        )

        for field_name, field_label, _default in active_schema:
            value = mv_value(field_name)

            add_result(
                NetworkValidator.validate_required(
                    value,
                    field_label
                )
            )

        # ------------------------------------------------------
        # VLAN validation
        # ------------------------------------------------------

        if "vlan_id" in self.mv_dynamic_entries:
            add_result(
                NetworkValidator.validate_vlan_id(
                    mv_value("vlan_id")
                )
            )

        if (
            vendor == "Cisco"
            and technology == "Trunk"
        ):
            vlan_text = mv_value("vlans")

            if vlan_text:
                for vlan_item in vlan_text.split(","):
                    vlan_item = vlan_item.strip()

                    if vlan_item:
                        add_result(
                            NetworkValidator.validate_vlan_id(
                                vlan_item
                            )
                        )

            native_vlan = mv_value("native")

            if native_vlan:
                add_result(
                    NetworkValidator.validate_vlan_id(
                        native_vlan
                    )
                )

        # ------------------------------------------------------
        # ASN validation
        # ------------------------------------------------------

        for field_name in (
            "local_asn",
            "remote_asn"
        ):
            if field_name in self.mv_dynamic_entries:
                add_result(
                    NetworkValidator.validate_asn(
                        mv_value(field_name)
                    )
                )

        # ------------------------------------------------------
        # Standard IPv4 fields
        # ------------------------------------------------------

        ipv4_fields = {
            "router_id": "Router ID",
            "neighbor_ip": "Neighbor IP",
            "peer_ip": "Peer IP",
            "virtual_ip": "Virtual IP",
            "ip_address": "IP Address",
            "gateway": "Gateway",
            "next_hop": "Next Hop",
            "remote_gateway": "Remote Gateway",
            "gateway1": "WAN 1 Gateway",
            "gateway2": "WAN 2 Gateway"
        }

        for field_name, field_label in ipv4_fields.items():
            if field_name in self.mv_dynamic_entries:
                add_result(
                    NetworkValidator.validate_ipv4(
                        mv_value(field_name),
                        field_label
                    )
                )

        # ------------------------------------------------------
        # Cisco IPv4 network fields
        # These schemas use network address + separate mask
        # ------------------------------------------------------

        if vendor == "Cisco":

            for field_name, field_label in (
                ("network", "Network"),
                ("source", "Source Network"),
                ("inside_network", "Inside Network"),
                ("local_network", "Local Network"),
                ("remote_network", "Remote Network")
            ):
                if field_name in self.mv_dynamic_entries:
                    add_result(
                        NetworkValidator.validate_ipv4(
                            mv_value(field_name),
                            field_label
                        )
                    )

        # ------------------------------------------------------
        # CIDR fields
        # ------------------------------------------------------

        if (
            vendor == "FortiGate"
            and technology == "OSPF"
            and "network" in self.mv_dynamic_entries
        ):
            add_result(
                NetworkValidator.validate_cidr(
                    mv_value("network"),
                    "Network CIDR"
                )
            )

        if (
            vendor == "FortiGate"
            and technology == "Static Route"
        ):
            add_result(
                NetworkValidator.validate_cidr(
                    mv_value("destination"),
                    "Destination"
                )
            )

        if (
            vendor == "Palo Alto"
            and technology == "Layer3 Interface"
        ):
            add_result(
                NetworkValidator.validate_cidr(
                    mv_value("ip_cidr"),
                    "IP / CIDR"
                )
            )

        if (
            vendor == "Palo Alto"
            and technology == "Static Route"
        ):
            add_result(
                NetworkValidator.validate_cidr(
                    mv_value("destination"),
                    "Destination"
                )
            )

        # ------------------------------------------------------
        # Subnet masks
        # ------------------------------------------------------

        for field_name, field_label in (
            ("mask", "Subnet Mask"),
            ("subnet_mask", "Subnet Mask")
        ):
            if field_name in self.mv_dynamic_entries:
                add_result(
                    NetworkValidator.validate_subnet_mask(
                        mv_value(field_name),
                        field_label
                    )
                )

        # ------------------------------------------------------
        # Wildcard fields
        # Syntactic IPv4 check only
        # ------------------------------------------------------

        for field_name, field_label in (
            ("wildcard", "Wildcard Mask"),
            ("local_wildcard", "Local Wildcard"),
            ("remote_wildcard", "Remote Wildcard")
        ):
            if field_name in self.mv_dynamic_entries:
                add_result(
                    NetworkValidator.validate_ipv4(
                        mv_value(field_name),
                        field_label
                    )
                )

        # ------------------------------------------------------
        # Interface fields
        # ------------------------------------------------------

        interface_fields = (
            "interface",
            "inside_interface",
            "outside_interface",
            "local_interface",
            "source_interface",
            "destination_interface",
            "device",
            "member1",
            "member2",
            "translated_interface"
        )

        for field_name in interface_fields:
            if field_name in self.mv_dynamic_entries:
                add_result(
                    NetworkValidator.validate_interface_name(
                        mv_value(field_name),
                        field_name.replace("_", " ").title()
                    )
                )

        # ------------------------------------------------------
        # FortiGate IPsec subnet format:
        # 192.168.10.0 255.255.255.0
        # ------------------------------------------------------

        if (
            vendor == "FortiGate"
            and technology == "IPsec VPN"
        ):
            for field_name, field_label in (
                ("local_subnet", "Local Subnet"),
                ("remote_subnet", "Remote Subnet")
            ):
                value = mv_value(field_name)
                parts = value.split()

                if len(parts) != 2:
                    validation_errors.append(
                        f"{field_label} must use NETWORK MASK format."
                    )
                else:
                    add_result(
                        NetworkValidator.validate_ipv4(
                            parts[0],
                            f"{field_label} Network"
                        )
                    )

                    add_result(
                        NetworkValidator.validate_subnet_mask(
                            parts[1],
                            f"{field_label} Mask"
                        )
                    )

        # ------------------------------------------------------
        # Stop generation when validation fails
        # ------------------------------------------------------

        if validation_errors:

            unique_errors = []

            for error in validation_errors:
                if error not in unique_errors:
                    unique_errors.append(error)

            messagebox.showerror(
                "Validation Error",
                "\n".join(
                    f"- {error}"
                    for error in unique_errors
                )
            )

            self.status.config(
                text=(
                    f"{vendor} / {technology}: "
                    "validation failed."
                )
            )

            return

        try:

            # ==================================================
            # CISCO
            # ==================================================

            if vendor == "Cisco":

                if technology == "OSPF":

                    process = self.get_mv_parameter(
                        "process",
                        "1"
                    )

                    router_id = self.get_mv_parameter(
                        "router_id",
                        "1.1.1.1"
                    )

                    network = self.get_mv_parameter(
                        "network",
                        "192.168.10.0"
                    )

                    wildcard = self.get_mv_parameter(
                        "wildcard",
                        "0.0.0.255"
                    )

                    area = self.get_mv_parameter(
                        "area",
                        "0"
                    )

                    config = (
                        "!\n"
                        f"router ospf {process}\n"
                        f" router-id {router_id}\n"
                        f" network {network} {wildcard} area {area}\n"
                        "!"
                    )

                    self.show_config(config)

                    self.status.config(
                        text="Cisco / OSPF configuration generated successfully."
                    )
                    return

                elif technology == "VLAN":

                    vlan_id = self.get_mv_parameter(
                        "vlan_id",
                        "10"
                    )

                    vlan_name = self.get_mv_parameter(
                        "vlan_name",
                        "USERS"
                    )

                    interface = self.get_mv_parameter(
                        "interface",
                        "GigabitEthernet0/1"
                    )

                    if (
                        not vlan_id.isdigit()
                        or not (1 <= int(vlan_id) <= 4094)
                    ):
                        raise ValueError(
                            "VLAN ID must be between 1 and 4094."
                        )

                    config = (
                        "!\n"
                        f"vlan {vlan_id}\n"
                        f" name {vlan_name}\n"
                        "!\n"
                        f"interface {interface}\n"
                        " switchport mode access\n"
                        f" switchport access vlan {vlan_id}\n"
                        " spanning-tree portfast\n"
                        " no shutdown\n"
                        "!"
                    )

                    self.show_config(config)

                    self.status.config(
                        text="Cisco / VLAN configuration generated successfully."
                    )
                    return

                elif technology == "Trunk":

                    interface = self.get_mv_parameter(
                        "interface",
                        "GigabitEthernet0/24"
                    )

                    vlans = self.get_mv_parameter(
                        "vlans",
                        "10,20,30"
                    )

                    native = self.get_mv_parameter(
                        "native",
                        "99"
                    )

                    lines = [
                        "!",
                        f"interface {interface}",
                        " switchport mode trunk",
                        f" switchport trunk allowed vlan {vlans}",
                    ]

                    if native:
                        lines.append(
                            f" switchport trunk native vlan {native}"
                        )

                    lines.extend([
                        " no shutdown",
                        "!"
                    ])

                    self.show_config("\n".join(lines))

                    self.status.config(
                        text="Cisco / Trunk configuration generated successfully."
                    )
                    return

                elif technology == "DHCP":

                    pool = self.get_mv_parameter(
                        "pool",
                        "USERS"
                    )

                    network = self.get_mv_parameter(
                        "network",
                        "192.168.10.0"
                    )

                    mask = self.get_mv_parameter(
                        "mask",
                        "255.255.255.0"
                    )

                    gateway = self.get_mv_parameter(
                        "gateway",
                        "192.168.10.1"
                    )

                    dns = self.get_mv_parameter(
                        "dns",
                        "8.8.8.8"
                    )

                    config = (
                        "!\n"
                        f"ip dhcp pool {pool}\n"
                        f" network {network} {mask}\n"
                        f" default-router {gateway}\n"
                        f" dns-server {dns}\n"
                        "!"
                    )

                    self.show_config(config)

                    self.status.config(
                        text="Cisco / DHCP configuration generated successfully."
                    )
                    return

                elif technology == "Static Route":

                    network = self.get_mv_parameter(
                        "network",
                        "10.10.10.0"
                    )

                    mask = self.get_mv_parameter(
                        "mask",
                        "255.255.255.0"
                    )

                    next_hop = self.get_mv_parameter(
                        "next_hop",
                        "192.168.1.1"
                    )

                    config = (
                        "!\n"
                        f"ip route {network} {mask} {next_hop}\n"
                        "!"
                    )

                    self.show_config(config)

                    self.status.config(
                        text="Cisco / Static Route configuration generated successfully."
                    )
                    return

                elif technology == "ACL":

                    number = self.get_mv_parameter(
                        "number",
                        "10"
                    )

                    action = self.get_mv_parameter(
                        "action",
                        "permit"
                    )

                    source = self.get_mv_parameter(
                        "source",
                        "192.168.10.0"
                    )

                    wildcard = self.get_mv_parameter(
                        "wildcard",
                        "0.0.0.255"
                    )

                    config = (
                        "!\n"
                        f"access-list {number} "
                        f"{action} "
                        f"{source} "
                        f"{wildcard}\n"
                        "!"
                    )

                    self.show_config(config)

                    self.status.config(
                        text="Cisco / ACL configuration generated successfully."
                    )
                    return

                elif technology == "BGP":

                    section = generate_cisco_bgp(
                        local_asn=self.get_mv_parameter(
                            "local_asn",
                            "65001"
                        ),
                        router_id=self.get_mv_parameter(
                            "router_id",
                            "1.1.1.1"
                        ),
                        neighbor_ip=self.get_mv_parameter(
                            "neighbor_ip",
                            "203.0.113.2"
                        ),
                        remote_asn=self.get_mv_parameter(
                            "remote_asn",
                            "65002"
                        ),
                        network=self.get_mv_parameter(
                            "network",
                            "192.168.10.0"
                        ),
                        mask=self.get_mv_parameter(
                            "mask",
                            "255.255.255.0"
                        ),
                        description=self.get_mv_parameter(
                            "description",
                            "ISP-01"
                        )
                    )

                elif technology == "IS-IS":

                    section = generate_cisco_isis(
                        process_name=self.get_mv_parameter(
                            "process_name",
                            "CORE"
                        ),
                        net=self.get_mv_parameter(
                            "net",
                            "49.0001.0000.0000.0001.00"
                        ),
                        interface=self.get_mv_parameter(
                            "interface",
                            "GigabitEthernet0/1"
                        ),
                        level=self.get_mv_parameter(
                            "level",
                            "level-2-only"
                        )
                    )

                elif technology == "NAT/PAT":

                    section = generate_cisco_nat_pat(
                        inside_network=self.get_mv_parameter(
                            "inside_network",
                            "192.168.10.0"
                        ),
                        wildcard=self.get_mv_parameter(
                            "wildcard",
                            "0.0.0.255"
                        ),
                        inside_interface=self.get_mv_parameter(
                            "inside_interface",
                            "GigabitEthernet0/1"
                        ),
                        outside_interface=self.get_mv_parameter(
                            "outside_interface",
                            "GigabitEthernet0/0"
                        )
                    )

                elif technology == "HSRP":

                    section = generate_cisco_hsrp(
                        interface=self.get_mv_parameter(
                            "interface",
                            "GigabitEthernet0/1"
                        ),
                        group=as_int(
                            self.get_mv_parameter(
                                "group",
                                "10"
                            ),
                            "HSRP Group"
                        ),
                        virtual_ip=self.get_mv_parameter(
                            "virtual_ip",
                            "192.168.10.1"
                        ),
                        priority=as_int(
                            self.get_mv_parameter(
                                "priority",
                                "110"
                            ),
                            "Priority"
                        ),
                        preempt=as_bool(
                            self.get_mv_parameter(
                                "preempt",
                                "True"
                            )
                        )
                    )

                elif technology == "VRF":

                    section = generate_cisco_vrf(
                        vrf_name=self.get_mv_parameter(
                            "vrf_name",
                            "CUSTOMER-A"
                        ),
                        route_distinguisher=self.get_mv_parameter(
                            "rd",
                            "65001:100"
                        ),
                        interface=self.get_mv_parameter(
                            "interface",
                            "GigabitEthernet0/2"
                        ),
                        ip_address=self.get_mv_parameter(
                            "ip_address",
                            "192.168.100.1"
                        ),
                        subnet_mask=self.get_mv_parameter(
                            "subnet_mask",
                            "255.255.255.0"
                        )
                    )

                elif technology == "IPsec VPN":

                    section = generate_cisco_ipsec(
                        peer_ip=self.get_mv_parameter(
                            "peer_ip",
                            "203.0.113.2"
                        ),
                        pre_shared_key=self.get_mv_parameter(
                            "pre_shared_key",
                            "LAB-KEY"
                        ),
                        local_network=self.get_mv_parameter(
                            "local_network",
                            "192.168.10.0"
                        ),
                        local_wildcard=self.get_mv_parameter(
                            "local_wildcard",
                            "0.0.0.255"
                        ),
                        remote_network=self.get_mv_parameter(
                            "remote_network",
                            "192.168.20.0"
                        ),
                        remote_wildcard=self.get_mv_parameter(
                            "remote_wildcard",
                            "0.0.0.255"
                        ),
                        outside_interface=self.get_mv_parameter(
                            "outside_interface",
                            "GigabitEthernet0/0"
                        )
                    )

                else:
                    messagebox.showwarning(
                        "Not Connected Yet",
                        f"{technology} is listed for Cisco, "
                        "but its Multi-Vendor generator is not connected yet."
                    )
                    return

            # ==================================================
            # FORTIGATE
            # ==================================================

            elif vendor == "FortiGate":

                if technology == "Interface":

                    section = generate_fortigate_interface(
                        name=self.get_mv_parameter(
                            "name",
                            "wan1"
                        ),
                        ip_address=self.get_mv_parameter(
                            "ip_address",
                            "203.0.113.2"
                        ),
                        subnet_mask=self.get_mv_parameter(
                            "subnet_mask",
                            "255.255.255.0"
                        ),
                        alias=self.get_mv_parameter(
                            "alias",
                            "NETOPS"
                        )
                    )

                elif technology == "Static Route":

                    section = generate_fortigate_static_route(
                        destination=self.get_mv_parameter(
                            "destination",
                            "0.0.0.0/0"
                        ),
                        gateway=self.get_mv_parameter(
                            "gateway",
                            "203.0.113.2"
                        ),
                        device=self.get_mv_parameter(
                            "device",
                            "wan1"
                        )
                    )

                elif technology == "Firewall Policy":

                    section = generate_fortigate_firewall_policy(
                        policy_id=as_int(
                            self.get_mv_parameter(
                                "policy_id",
                                "1"
                            ),
                            "Policy ID"
                        ),
                        name=self.get_mv_parameter(
                            "name",
                            "LAN-to-Internet"
                        ),
                        source_interface=self.get_mv_parameter(
                            "source_interface",
                            "internal"
                        ),
                        destination_interface=self.get_mv_parameter(
                            "destination_interface",
                            "wan1"
                        ),
                        source_address=self.get_mv_parameter(
                            "source_address",
                            "all"
                        ),
                        destination_address=self.get_mv_parameter(
                            "destination_address",
                            "all"
                        ),
                        service=self.get_mv_parameter(
                            "service",
                            "ALL"
                        ),
                        nat=as_bool(
                            self.get_mv_parameter(
                                "nat",
                                "True"
                            )
                        )
                    )

                elif technology == "BGP":

                    section = generate_fortigate_bgp(
                        local_asn=self.get_mv_parameter(
                            "local_asn",
                            "65001"
                        ),
                        router_id=self.get_mv_parameter(
                            "router_id",
                            "1.1.1.1"
                        ),
                        neighbor_ip=self.get_mv_parameter(
                            "neighbor_ip",
                            "203.0.113.2"
                        ),
                        remote_asn=self.get_mv_parameter(
                            "remote_asn",
                            "65002"
                        )
                    )

                elif technology == "OSPF":

                    section = generate_fortigate_ospf(
                        router_id=self.get_mv_parameter(
                            "router_id",
                            "1.1.1.1"
                        ),
                        network=self.get_mv_parameter(
                            "network",
                            "192.168.10.0/24"
                        )
                    )

                elif technology == "SD-WAN":

                    section = generate_fortigate_sdwan(
                        member1=self.get_mv_parameter(
                            "member1",
                            "wan1"
                        ),
                        member2=self.get_mv_parameter(
                            "member2",
                            "wan2"
                        ),
                        gateway1=self.get_mv_parameter(
                            "gateway1",
                            "203.0.113.2"
                        ),
                        gateway2=self.get_mv_parameter(
                            "gateway2",
                            "198.51.100.1"
                        )
                    )

                elif technology == "IPsec VPN":

                    section = generate_fortigate_ipsec(
                        tunnel_name=self.get_mv_parameter(
                            "tunnel_name",
                            "HQ-BRANCH"
                        ),
                        remote_gateway=self.get_mv_parameter(
                            "remote_gateway",
                            "203.0.113.50"
                        ),
                        local_interface=self.get_mv_parameter(
                            "local_interface",
                            "wan1"
                        ),
                        pre_shared_key=self.get_mv_parameter(
                            "pre_shared_key",
                            "NETOPS-LAB-KEY"
                        ),
                        local_subnet=self.get_mv_parameter(
                            "local_subnet",
                            "192.168.10.0 255.255.255.0"
                        ),
                        remote_subnet=self.get_mv_parameter(
                            "remote_subnet",
                            "192.168.20.0 255.255.255.0"
                        ),
                        proposal=self.get_mv_parameter(
                            "proposal",
                            "aes256-sha256"
                        ),
                        dh_group=self.get_mv_parameter(
                            "dh_group",
                            "14"
                        )
                    )

                else:
                    messagebox.showwarning(
                        "Not Connected Yet",
                        f"{technology} is listed for FortiGate, "
                        "but its Multi-Vendor generator is not connected yet."
                    )
                    return

            # ==================================================
            # PALO ALTO
            # ==================================================

            elif vendor == "Palo Alto":

                if technology == "Layer3 Interface":

                    section = generate_paloalto_interface(
                        interface=self.get_mv_parameter(
                            "interface",
                            "ethernet1/1"
                        ),
                        ip_cidr=self.get_mv_parameter(
                            "ip_cidr",
                            "203.0.113.2/24"
                        ),
                        virtual_router=self.get_mv_parameter(
                            "virtual_router",
                            "default"
                        )
                    )

                elif technology == "Zone":

                    section = generate_paloalto_zone(
                        zone_name=self.get_mv_parameter(
                            "zone_name",
                            "UNTRUST"
                        ),
                        interface=self.get_mv_parameter(
                            "interface",
                            "ethernet1/1"
                        )
                    )

                elif technology == "Static Route":

                    section = generate_paloalto_static_route(
                        virtual_router=self.get_mv_parameter(
                            "virtual_router",
                            "default"
                        ),
                        route_name=self.get_mv_parameter(
                            "route_name",
                            "DEFAULT-ROUTE"
                        ),
                        destination=self.get_mv_parameter(
                            "destination",
                            "0.0.0.0/0"
                        ),
                        next_hop=self.get_mv_parameter(
                            "next_hop",
                            "203.0.113.2"
                        ),
                        interface=self.get_mv_parameter(
                            "interface",
                            "ethernet1/1"
                        )
                    )

                elif technology == "Security Policy":

                    section = generate_paloalto_security_policy(
                        rule_name=self.get_mv_parameter(
                            "rule_name",
                            "LAN-TO-INTERNET"
                        ),
                        from_zone=self.get_mv_parameter(
                            "from_zone",
                            "TRUST"
                        ),
                        to_zone=self.get_mv_parameter(
                            "to_zone",
                            "UNTRUST"
                        ),
                        source=self.get_mv_parameter(
                            "source",
                            "any"
                        ),
                        destination=self.get_mv_parameter(
                            "destination",
                            "any"
                        ),
                        application=self.get_mv_parameter(
                            "application",
                            "any"
                        ),
                        service=self.get_mv_parameter(
                            "service",
                            "application-default"
                        ),
                        action=self.get_mv_parameter(
                            "action",
                            "allow"
                        )
                    )

                elif technology == "NAT Policy":

                    section = generate_paloalto_nat_policy(
                        rule_name=self.get_mv_parameter(
                            "rule_name",
                            "SOURCE-NAT"
                        ),
                        from_zone=self.get_mv_parameter(
                            "from_zone",
                            "TRUST"
                        ),
                        to_zone=self.get_mv_parameter(
                            "to_zone",
                            "UNTRUST"
                        ),
                        source=self.get_mv_parameter(
                            "source",
                            "any"
                        ),
                        destination=self.get_mv_parameter(
                            "destination",
                            "any"
                        ),
                        translated_interface=self.get_mv_parameter(
                            "translated_interface",
                            "ethernet1/1"
                        )
                    )

                elif technology == "BGP":

                    section = generate_paloalto_bgp(
                        virtual_router=self.get_mv_parameter(
                            "virtual_router",
                            "default"
                        ),
                        local_asn=self.get_mv_parameter(
                            "local_asn",
                            "65001"
                        ),
                        router_id=self.get_mv_parameter(
                            "router_id",
                            "1.1.1.1"
                        ),
                        peer_group=self.get_mv_parameter(
                            "peer_group",
                            "EBGP-PEERS"
                        ),
                        peer_name=self.get_mv_parameter(
                            "peer_name",
                            "ISP-01"
                        ),
                        peer_ip=self.get_mv_parameter(
                            "peer_ip",
                            "203.0.113.2"
                        ),
                        remote_asn=self.get_mv_parameter(
                            "remote_asn",
                            "65002"
                        )
                    )

                elif technology == "OSPF":

                    section = generate_paloalto_ospf(
                        virtual_router=self.get_mv_parameter(
                            "virtual_router",
                            "default"
                        ),
                        router_id=self.get_mv_parameter(
                            "router_id",
                            "1.1.1.1"
                        ),
                        area=self.get_mv_parameter(
                            "area",
                            "0.0.0.0"
                        ),
                        interface=self.get_mv_parameter(
                            "interface",
                            "ethernet1/2"
                        )
                    )

                else:
                    messagebox.showwarning(
                        "Not Connected Yet",
                        f"{technology} is listed for Palo Alto, "
                        "but its Multi-Vendor generator is not connected yet."
                    )
                    return

            else:
                messagebox.showerror(
                    "Vendor Error",
                    "Unsupported vendor."
                )
                return

            # ==================================================
            # GENERATOR RESULT
            # ==================================================

            config = getattr(section, "config", section)

            if not config:
                messagebox.showwarning(
                    "Empty Configuration",
                    "The selected generator returned no configuration."
                )
                return

            self.show_config(str(config))

            self.status.config(
                text=(
                    f"{vendor} / {technology} "
                    "configuration generated successfully."
                )
            )

        except Exception as exc:
            messagebox.showerror(
                "Generation Error",
                str(exc)
            )

    def save_config(self):
        full_build = self.get_full_build()

        if full_build:
            use_build = messagebox.askyesno(
                "Save Configuration",
                "A Full Build exists.\n\nDo you want to save the Full Build?\n\nChoose No to save only the configuration currently shown in Preview."
            )

            if use_build:
                content = full_build
            else:
                content = self.preview.get("1.0", tk.END).strip()
        else:
            content = self.preview.get("1.0", tk.END).strip()

        if not content:
            messagebox.showwarning(
                "Nothing to Save",
                "Generate a configuration first."
            )
            return

        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        default_name = f"NETOPS-Network-Config-{timestamp}.cfg"

        file_path = filedialog.asksaveasfilename(
            initialdir=str(OUTPUT_DIR),
            initialfile=default_name,
            defaultextension=".cfg",
            filetypes=[("Configuration files", "*.cfg"), ("Text files", "*.txt"), ("All files", "*.*")]
        )

        if not file_path:
            return

        Path(file_path).write_text(content + "\n", encoding="utf-8")
        self.status.config(text=f"Saved: {file_path}")
        messagebox.showinfo("Saved", "Configuration saved successfully.")

    def clear_preview(self):
        self.preview.delete("1.0", tk.END)
        self.status.config(text="Ready")


def main():
    root = tk.Tk()
    NetworkConfigGenerator(root)
    root.mainloop()


if __name__ == "__main__":
    main()








