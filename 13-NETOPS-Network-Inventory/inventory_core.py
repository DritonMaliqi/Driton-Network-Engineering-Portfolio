import csv
import html
import ipaddress
import sqlite3
from collections import Counter
from datetime import datetime
from pathlib import Path

DEVICE_TYPES=("Router","Switch","Firewall","Access Point","Server","Load Balancer","Other")
STATUSES=("Active","Spare","Maintenance","Offline","Retired")

class InventoryDB:
    COLUMNS=("asset_tag","hostname","device_type","vendor","model","serial_number","management_ip","site","rack","software_version","status","owner","purchase_date","warranty_expiry","notes")
    def __init__(self,path):
        self.path=Path(path); self.path.parent.mkdir(parents=True,exist_ok=True)
        with self.connect() as con:
            con.execute("""CREATE TABLE IF NOT EXISTS devices(
              id INTEGER PRIMARY KEY AUTOINCREMENT, asset_tag TEXT NOT NULL UNIQUE,
              hostname TEXT NOT NULL UNIQUE, device_type TEXT NOT NULL, vendor TEXT NOT NULL DEFAULT '',
              model TEXT NOT NULL DEFAULT '', serial_number TEXT NOT NULL DEFAULT '',
              management_ip TEXT NOT NULL DEFAULT '', site TEXT NOT NULL DEFAULT '', rack TEXT NOT NULL DEFAULT '',
              software_version TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Active',
              owner TEXT NOT NULL DEFAULT '', purchase_date TEXT NOT NULL DEFAULT '', warranty_expiry TEXT NOT NULL DEFAULT '',
              notes TEXT NOT NULL DEFAULT '', updated_at TEXT NOT NULL)""")
            con.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_mgmt_ip ON devices(management_ip) WHERE management_ip <> ''")
    def connect(self): return sqlite3.connect(self.path)
    @staticmethod
    def _validate(data):
        clean={k:str(data.get(k,"")).strip() for k in InventoryDB.COLUMNS}
        if not clean["asset_tag"]: raise ValueError("Asset tag is required")
        if not clean["hostname"]: raise ValueError("Hostname is required")
        if clean["device_type"] not in DEVICE_TYPES: raise ValueError("Invalid device type")
        if clean["status"] not in STATUSES: raise ValueError("Invalid status")
        if clean["management_ip"]:
            ip=ipaddress.ip_address(clean["management_ip"])
            if ip.version!=4: raise ValueError("Only IPv4 management addresses are supported")
            clean["management_ip"]=str(ip)
        for key in ("purchase_date","warranty_expiry"):
            if clean[key]: datetime.strptime(clean[key],"%Y-%m-%d")
        return clean
    def add(self,data):
        d=self._validate(data); keys=list(self.COLUMNS)+["updated_at"]
        d["updated_at"]=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with self.connect() as con:
            cur=con.execute(f"INSERT INTO devices({','.join(keys)}) VALUES({','.join('?' for _ in keys)})",[d[k] for k in keys]); return cur.lastrowid
    def update(self,record_id,data):
        d=self._validate(data); d["updated_at"]=datetime.now().strftime("%Y-%m-%d %H:%M:%S"); keys=list(self.COLUMNS)+["updated_at"]
        with self.connect() as con: con.execute("UPDATE devices SET "+",".join(f"{k}=?" for k in keys)+" WHERE id=?",[d[k] for k in keys]+[record_id])
    def delete(self,record_id):
        with self.connect() as con: con.execute("DELETE FROM devices WHERE id=?",(record_id,))
    def get(self,record_id):
        with self.connect() as con: return con.execute("SELECT * FROM devices WHERE id=?",(record_id,)).fetchone()
    def list(self,search="",status="All"):
        where=[]; args=[]
        if search:
            q=f"%{search}%"; where.append("(asset_tag LIKE ? OR hostname LIKE ? OR management_ip LIKE ? OR vendor LIKE ? OR model LIKE ? OR site LIKE ? OR serial_number LIKE ?)"); args.extend([q]*7)
        if status!="All": where.append("status=?"); args.append(status)
        sql="SELECT * FROM devices"+(" WHERE "+" AND ".join(where) if where else "")+" ORDER BY site,hostname"
        with self.connect() as con: return con.execute(sql,args).fetchall()
    def stats(self):
        rows=self.list(); statuses=Counter(r[11] for r in rows); types=Counter(r[3] for r in rows)
        return {"total":len(rows),"active":statuses["Active"],"maintenance":statuses["Maintenance"],"offline":statuses["Offline"],"retired":statuses["Retired"],"types":dict(types)}
    def import_csv(self,path):
        added=skipped=0
        with open(path,newline="",encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                try: self.add(row); added+=1
                except (ValueError,sqlite3.IntegrityError,KeyError): skipped+=1
        return added,skipped
    def export_csv(self,path):
        headers=("id",)+self.COLUMNS+("updated_at",)
        with open(path,"w",newline="",encoding="utf-8-sig") as f:
            w=csv.writer(f); w.writerow(headers); w.writerows(self.list())

def build_html_report(rows,title="Network Asset Inventory"):
    generated=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    def esc(v): return html.escape(str(v))
    headers=("Asset Tag","Hostname","Type","Vendor / Model","Management IP","Site / Rack","Software","Status","Owner","Warranty")
    body=[]
    for r in rows:
        values=(r[1],r[2],r[3],f"{r[4]} {r[5]}".strip(),r[7],f"{r[8]} {r[9]}".strip(),r[10],r[11],r[12],r[14])
        body.append("<tr>"+"".join(f"<td>{esc(v)}</td>" for v in values)+"</tr>")
    return f"""<!doctype html><html lang='en'><head><meta charset='utf-8'><title>{esc(title)}</title>
<style>body{{font-family:Segoe UI,Arial;margin:32px;color:#14213d}}h1{{color:#087ea4}}.meta{{color:#555}}table{{border-collapse:collapse;width:100%;font-size:13px}}th{{background:#0b1f35;color:white}}th,td{{padding:8px;border:1px solid #ccd6e0;text-align:left}}tr:nth-child(even){{background:#f3f7fa}}.badge{{font-weight:bold}}</style></head>
<body><h1>{esc(title)}</h1><p class='meta'>Generated: {generated} | Total assets: {len(rows)}</p><table><thead><tr>{''.join(f'<th>{h}</th>' for h in headers)}</tr></thead><tbody>{''.join(body)}</tbody></table></body></html>"""
