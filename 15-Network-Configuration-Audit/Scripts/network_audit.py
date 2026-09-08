from pathlib import Path
import csv
import argparse
import re
from datetime import datetime


BASE_DIR = Path(__file__).resolve().parent.parent
# CONFIG_DIR is now provided through command-line arguments
REPORT_DIR = BASE_DIR / "Reports"

REPORT_DIR.mkdir(parents=True, exist_ok=True)


def get_hostname(config_text: str, fallback: str) -> str:
    match = re.search(r"(?im)^hostname\s+(\S+)", config_text)
    if match:
        return match.group(1)
    return fallback


def add_result(results, device, severity, check, status, details, recommendation):
    results.append({
        "device": device,
        "severity": severity,
        "check": check,
        "status": status,
        "details": details,
        "recommendation": recommendation
    })


def audit_router(device, config, results):
    # --------------------------------------------------------
    # SSH VERSION
    # --------------------------------------------------------
    if re.search(r"(?im)^ip ssh version 2\s*$", config):
        add_result(
            results,
            device,
            "LOW",
            "SSH Version",
            "PASS",
            "SSH version 2 is configured.",
            "No action required."
        )
    else:
        add_result(
            results,
            device,
            "HIGH",
            "SSH Version",
            "FAIL",
            "SSH version 2 is not explicitly configured.",
            "Configure: ip ssh version 2"
        )

    # --------------------------------------------------------
    # TELNET ON VTY
    # --------------------------------------------------------
    telnet_found = re.search(
        r"(?im)^\s*transport input\s+.*telnet.*$",
        config
    )

    if telnet_found:
        add_result(
            results,
            device,
            "HIGH",
            "VTY Secure Access",
            "FAIL",
            "Telnet is permitted on VTY lines.",
            "Remove Telnet and allow SSH only: transport input ssh"
        )
    else:
        add_result(
            results,
            device,
            "LOW",
            "VTY Secure Access",
            "PASS",
            "Telnet is not permitted on VTY lines.",
            "No action required."
        )

    # --------------------------------------------------------
    # SERVICE PASSWORD ENCRYPTION
    # --------------------------------------------------------
    if re.search(r"(?im)^service password-encryption\s*$", config):
        add_result(
            results,
            device,
            "LOW",
            "Password Encryption",
            "PASS",
            "service password-encryption is configured.",
            "No action required."
        )
    else:
        add_result(
            results,
            device,
            "MEDIUM",
            "Password Encryption",
            "WARNING",
            "service password-encryption is missing.",
            "Consider enabling service password-encryption."
        )

    # --------------------------------------------------------
    # OSPF
    # --------------------------------------------------------
    if re.search(r"(?im)^\s*router ospf\s+\d+", config):
        add_result(
            results,
            device,
            "LOW",
            "OSPF Configuration",
            "PASS",
            "OSPF routing process is configured.",
            "Validate neighbor adjacency and area consistency."
        )
    else:
        add_result(
            results,
            device,
            "MEDIUM",
            "OSPF Configuration",
            "WARNING",
            "No OSPF routing process was detected.",
            "Verify whether dynamic routing is required."
        )


def audit_switch(device, config, results):
    # --------------------------------------------------------
    # FINANCE PORT VLAN
    # --------------------------------------------------------
    finance_port_match = re.search(
        r"(?ims)^interface FastEthernet0/2\s+"
        r".*?"
        r"switchport access vlan\s+(\d+)",
        config
    )

    if finance_port_match:
        vlan = finance_port_match.group(1)

        if vlan == "10":
            add_result(
                results,
                device,
                "LOW",
                "Finance Port VLAN",
                "PASS",
                "FastEthernet0/2 is assigned to VLAN 10.",
                "No action required."
            )
        else:
            add_result(
                results,
                device,
                "HIGH",
                "Finance Port VLAN",
                "FAIL",
                f"FastEthernet0/2 is assigned to VLAN {vlan}, expected VLAN 10.",
                "Configure FastEthernet0/2 with: switchport access vlan 10"
            )
    else:
        add_result(
            results,
            device,
            "MEDIUM",
            "Finance Port VLAN",
            "WARNING",
            "Could not determine VLAN assignment for FastEthernet0/2.",
            "Review interface configuration manually."
        )

    # --------------------------------------------------------
    # TRUNK ALLOWED VLANS
    # --------------------------------------------------------
    trunk_match = re.search(
        r"(?im)^\s*switchport trunk allowed vlan\s+([0-9,\-]+)",
        config
    )

    required_vlans = {"10", "20", "50"}

    if trunk_match:
        raw_vlans = trunk_match.group(1)
        allowed = set()

        for item in raw_vlans.split(","):
            item = item.strip()

            if "-" in item:
                try:
                    start, end = item.split("-", 1)
                    for vlan in range(int(start), int(end) + 1):
                        allowed.add(str(vlan))
                except ValueError:
                    pass
            else:
                allowed.add(item)

        missing = required_vlans - allowed

        if not missing:
            add_result(
                results,
                device,
                "LOW",
                "Trunk VLAN Compliance",
                "PASS",
                "Required VLANs 10, 20 and 50 are allowed on the trunk.",
                "No action required."
            )
        else:
            add_result(
                results,
                device,
                "HIGH",
                "Trunk VLAN Compliance",
                "FAIL",
                "Missing required trunk VLAN(s): " + ", ".join(sorted(missing)),
                "Add the missing VLANs to the trunk allowed VLAN list."
            )
    else:
        add_result(
            results,
            device,
            "MEDIUM",
            "Trunk VLAN Compliance",
            "WARNING",
            "No explicit trunk allowed VLAN list was detected.",
            "Verify the trunk configuration manually."
        )

    # --------------------------------------------------------
    # UNUSED ACTIVE INTERFACE
    # --------------------------------------------------------
    unused_match = re.search(
        r"(?ims)^interface FastEthernet0/24\s+"
        r".*?"
        r"description UNUSED\s+"
        r".*?"
        r"no shutdown",
        config
    )

    if unused_match:
        add_result(
            results,
            device,
            "MEDIUM",
            "Unused Interface Security",
            "WARNING",
            "FastEthernet0/24 is marked UNUSED but is administratively enabled.",
            "Apply shutdown to unused interfaces."
        )
    else:
        add_result(
            results,
            device,
            "LOW",
            "Unused Interface Security",
            "PASS",
            "No enabled interface explicitly marked UNUSED was detected.",
            "No action required."
        )


def detect_device_type(device, config):
    if re.search(r"(?im)^\s*switchport\b", config):
        return "SWITCH"

    if re.search(r"(?im)^\s*router ospf\b", config):
        return "ROUTER"

    if device.upper().startswith("SW-"):
        return "SWITCH"

    return "ROUTER"


def detect_ospf_area_mismatch(configs, results):
    network_areas = {}

    for device, config in configs.items():
        for network, wildcard, area in re.findall(
            r"(?im)^\s*network\s+(\S+)\s+(\S+)\s+area\s+(\S+)",
            config
        ):
            key = (network, wildcard)

            network_areas.setdefault(key, []).append({
                "device": device,
                "area": area
            })

    for key, entries in network_areas.items():
        areas = {entry["area"] for entry in entries}

        if len(entries) > 1 and len(areas) > 1:
            network, wildcard = key

            for entry in entries:
                add_result(
                    results,
                    entry["device"],
                    "CRITICAL",
                    "OSPF Area Consistency",
                    "FAIL",
                    (
                        f"Network {network} {wildcard} is configured in "
                        f"different OSPF areas across devices. "
                        f"{entry['device']} uses area {entry['area']}."
                    ),
                    "Configure both ends of the OSPF link in the same area."
                )


def write_csv(results, output_file):
    fieldnames = [
        "device",
        "severity",
        "check",
        "status",
        "details",
        "recommendation"
    ]

    with output_file.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)


def write_txt(results, output_file):
    with output_file.open("w", encoding="utf-8") as f:
        f.write("=" * 72 + "\n")
        f.write("PROJECT 15 - NETWORK CONFIGURATION AUDIT REPORT\n")
        f.write("=" * 72 + "\n\n")

        devices = sorted({r["device"] for r in results})

        for device in devices:
            f.write(f"DEVICE: {device}\n")
            f.write("-" * 72 + "\n")

            device_results = [r for r in results if r["device"] == device]

            for item in device_results:
                f.write(
                    f"[{item['status']}] "
                    f"[{item['severity']}] "
                    f"{item['check']}\n"
                )
                f.write(f"Details: {item['details']}\n")
                f.write(
                    f"Recommendation: {item['recommendation']}\n\n"
                )

            f.write("\n")

        pass_count = sum(1 for r in results if r["status"] == "PASS")
        warning_count = sum(1 for r in results if r["status"] == "WARNING")
        fail_count = sum(1 for r in results if r["status"] == "FAIL")

        f.write("=" * 72 + "\n")
        f.write("SUMMARY\n")
        f.write("=" * 72 + "\n")
        f.write(f"PASS    : {pass_count}\n")
        f.write(f"WARNING : {warning_count}\n")
        f.write(f"FAIL    : {fail_count}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Project 15 - Network Configuration Audit"
    )

    parser.add_argument(
        "--config-dir",
        default="Config-Samples",
        help="Configuration directory relative to the project root"
    )

    parser.add_argument(
        "--label",
        default="AUDIT",
        help="Label used in generated report filenames"
    )

    args = parser.parse_args()

    config_dir = BASE_DIR / args.config_dir

    print()
    print("=" * 65)
    print(" PROJECT 15 - NETWORK CONFIGURATION AUDIT")
    print("=" * 65)
    print()
    print(f"Configuration source : {config_dir}")
    print(f"Audit label          : {args.label}")
    print()

    config_files = sorted(config_dir.glob("*.txt"))

    if not config_files:
        print("[ERROR] No configuration files found.")
        return

    results = []
    configs = {}

    for file in config_files:
        config = file.read_text(encoding="utf-8-sig", errors="ignore")
        device = get_hostname(config, file.stem)

        configs[device] = config

        device_type = detect_device_type(device, config)

        print(f"[AUDIT] {device:<20} Type: {device_type}")

        if device_type == "SWITCH":
            audit_switch(device, config, results)
        else:
            audit_router(device, config, results)

    detect_ospf_area_mismatch(configs, results)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    csv_report = REPORT_DIR / f"Network-Audit-{args.label}-{timestamp}.csv"
    txt_report = REPORT_DIR / f"Network-Audit-{args.label}-{timestamp}.txt"

    write_csv(results, csv_report)
    write_txt(results, txt_report)

    print()
    print("-" * 65)

    pass_count = sum(1 for r in results if r["status"] == "PASS")
    warning_count = sum(1 for r in results if r["status"] == "WARNING")
    fail_count = sum(1 for r in results if r["status"] == "FAIL")

    print(f"PASS    : {pass_count}")
    print(f"WARNING : {warning_count}")
    print(f"FAIL    : {fail_count}")

    print()
    print("[REPORT] CSV:")
    print(csv_report)
    print()
    print("[REPORT] TXT:")
    print(txt_report)
    print()
    print("Audit completed successfully.")
    print()


if __name__ == "__main__":
    main()


