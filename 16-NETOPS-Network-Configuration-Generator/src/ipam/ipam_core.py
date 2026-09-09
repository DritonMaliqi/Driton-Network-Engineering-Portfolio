import csv
import ipaddress
import sqlite3
from datetime import datetime
from pathlib import Path


STATUSES = ("Available", "Reserved", "Assigned", "DHCP", "Deprecated")


def calculate_network(value):
    """Return practical IPv4 network facts for an address/prefix string."""
    interface = ipaddress.ip_interface(value.strip())
    if interface.version != 4:
        raise ValueError("Only IPv4 is supported in version 1.0.0")
    network = interface.network
    total = network.num_addresses
    if network.prefixlen == 32:
        first = last = network.network_address
        usable = 1
    elif network.prefixlen == 31:
        first, last = network.network_address, network.broadcast_address
        usable = 2
    else:
        first = network.network_address + 1
        last = network.broadcast_address - 1
        usable = max(total - 2, 0)
    wildcard = ipaddress.IPv4Address(int(ipaddress.IPv4Address("255.255.255.255")) ^ int(network.netmask))
    return {
        "input_ip": str(interface.ip), "network": str(network.network_address),
        "prefix": network.prefixlen, "cidr": str(network), "netmask": str(network.netmask),
        "wildcard": str(wildcard), "broadcast": str(network.broadcast_address),
        "first_usable": str(first), "last_usable": str(last),
        "total_addresses": total, "usable_hosts": usable,
        "private": interface.ip.is_private, "global": interface.ip.is_global,
    }


def split_network(value, new_prefix):
    network = ipaddress.ip_network(value.strip(), strict=False)
    new_prefix = int(new_prefix)
    if network.version != 4:
        raise ValueError("Only IPv4 is supported in version 1.0.0")
    if new_prefix < network.prefixlen:
        raise ValueError("The new prefix must be equal to or longer than the parent prefix")
    if 1 << (new_prefix - network.prefixlen) > 4096:
        raise ValueError("This request would create more than 4096 subnets")
    return [calculate_network(str(item.network_address) + f"/{item.prefixlen}") for item in network.subnets(new_prefix=new_prefix)]


def vlsm_plan(parent, requirements):
    """Allocate subnets largest-first. Requirements: [(name, host_count), ...]."""
    pool = ipaddress.ip_network(parent.strip(), strict=False)
    if pool.version != 4:
        raise ValueError("Only IPv4 is supported")
    pending = []
    for name, hosts in requirements:
        hosts = int(hosts)
        if hosts < 1:
            raise ValueError("Host requirements must be positive")
        needed = hosts + 2
        prefix = 32 - (needed - 1).bit_length()
        pending.append((name, hosts, max(0, min(30, prefix))))
    pending.sort(key=lambda x: x[2])
    cursor = int(pool.network_address)
    result = []
    for name, hosts, prefix in pending:
        block = 1 << (32 - prefix)
        cursor = ((cursor + block - 1) // block) * block
        subnet = ipaddress.ip_network((cursor, prefix))
        if not subnet.subnet_of(pool):
            raise ValueError("The parent network does not have enough address space")
        facts = calculate_network(str(subnet))
        facts.update({"name": name, "required_hosts": hosts})
        result.append(facts)
        cursor = int(subnet.broadcast_address) + 1
    return result


class IPAMDatabase:
    def __init__(self, path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as con:
            con.execute("""CREATE TABLE IF NOT EXISTS allocations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ip_address TEXT NOT NULL UNIQUE,
                prefix INTEGER NOT NULL,
                hostname TEXT NOT NULL DEFAULT '',
                device_type TEXT NOT NULL DEFAULT '',
                vlan TEXT NOT NULL DEFAULT '',
                location TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'Assigned',
                description TEXT NOT NULL DEFAULT '',
                updated_at TEXT NOT NULL
            )""")

    def connect(self): return sqlite3.connect(self.path)

    @staticmethod
    def validate(ip_address, prefix):
        ip = ipaddress.ip_address(ip_address.strip())
        if ip.version != 4: raise ValueError("Only IPv4 is supported")
        prefix = int(prefix)
        if not 0 <= prefix <= 32: raise ValueError("Prefix must be between 0 and 32")
        return str(ip), prefix

    def add(self, ip_address, prefix, hostname="", device_type="", vlan="", location="", status="Assigned", description=""):
        ip_address, prefix = self.validate(ip_address, prefix)
        if status not in STATUSES: raise ValueError("Invalid status")
        with self.connect() as con:
            cur = con.execute("""INSERT INTO allocations
                (ip_address,prefix,hostname,device_type,vlan,location,status,description,updated_at)
                VALUES(?,?,?,?,?,?,?,?,?)""", (ip_address,prefix,hostname.strip(),device_type.strip(),vlan.strip(),location.strip(),status,description.strip(),datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
            return cur.lastrowid

    def update(self, record_id, **fields):
        allowed = {"ip_address","prefix","hostname","device_type","vlan","location","status","description"}
        data = {k:v for k,v in fields.items() if k in allowed}
        ip, prefix = self.validate(data.get("ip_address", self.get(record_id)[1]), data.get("prefix", self.get(record_id)[2]))
        data["ip_address"], data["prefix"], data["updated_at"] = ip, prefix, datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        if "status" in data and data["status"] not in STATUSES: raise ValueError("Invalid status")
        keys=list(data); sql=", ".join(f"{k}=?" for k in keys)
        with self.connect() as con: con.execute(f"UPDATE allocations SET {sql} WHERE id=?", [data[k] for k in keys]+[record_id])

    def get(self, record_id):
        with self.connect() as con: return con.execute("SELECT * FROM allocations WHERE id=?",(record_id,)).fetchone()

    def delete(self, record_id):
        with self.connect() as con: con.execute("DELETE FROM allocations WHERE id=?",(record_id,))

    def list(self, search=""):
        with self.connect() as con:
            if search:
                q=f"%{search}%"
                return con.execute("""SELECT * FROM allocations WHERE ip_address LIKE ? OR hostname LIKE ? OR vlan LIKE ? OR location LIKE ? OR description LIKE ? ORDER BY printf('%03d.%03d.%03d.%03d', ip_address)""",(q,q,q,q,q)).fetchall()
            return con.execute("SELECT * FROM allocations ORDER BY printf('%03d.%03d.%03d.%03d', ip_address)").fetchall()

    def import_csv(self, path):
        added=skipped=0
        with open(path,newline="",encoding="utf-8-sig") as handle:
            for row in csv.DictReader(handle):
                try:
                    self.add(row["ip_address"],row.get("prefix",24),row.get("hostname",""),row.get("device_type",""),row.get("vlan",""),row.get("location",""),row.get("status","Assigned"),row.get("description","")); added+=1
                except (ValueError, sqlite3.IntegrityError, KeyError): skipped+=1
        return added, skipped

    def export_csv(self, path):
        headers=("id","ip_address","prefix","hostname","device_type","vlan","location","status","description","updated_at")
        with open(path,"w",newline="",encoding="utf-8-sig") as handle:
            writer=csv.writer(handle); writer.writerow(headers); writer.writerows(self.list())
