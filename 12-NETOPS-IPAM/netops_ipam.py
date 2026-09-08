import os
import sqlite3
import sys
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from ipam_core import IPAMDatabase, STATUSES, calculate_network, split_network, vlsm_plan

APP_NAME="NETOPS IPAM"; VERSION="1.0.0"; APP_DIR=Path(__file__).resolve().parent
DATA_DIR=(Path(os.environ.get("LOCALAPPDATA",Path.home()))/"NETOPS-IPAM" if getattr(sys,"frozen",False) else APP_DIR/"data")
DB_PATH=DATA_DIR/"netops_ipam.db"

T={
"en":{"subtitle":"IP Address Manager & Subnet Planner  •  Offline","calc":"SUBNET CALCULATOR","planner":"VLSM PLANNER","ipam":"IP ADDRESS MANAGER","lang":"Language:","input":"IPv4 address / CIDR:","calculate":"Calculate","clear":"Clear","result":"NETWORK DETAILS","parent":"Parent network:","newprefix":"New prefix:","split":"Split into equal subnets","requirements":"VLSM REQUIREMENTS  (one per line: Name, Hosts)","plan":"Create VLSM plan","plan_result":"SUBNET PLAN","ip":"IP address:","prefix":"Prefix:","hostname":"Hostname:","type":"Device type:","vlan":"VLAN:","location":"Location:","status":"Status:","description":"Description:","add":"Add allocation","update":"Update selected","delete":"Delete selected","search":"Search:","refresh":"Refresh","import":"Import CSV","export":"Export CSV","inventory":"IP ALLOCATIONS","saved":"Allocation saved.","updated":"Allocation updated.","deleted":"Allocation deleted.","duplicate":"This IP address already exists.","select":"Select a record first.","confirm":"Delete the selected allocation?","invalid":"Invalid input","imported":"CSV import complete: {added} added, {skipped} skipped."},
"sq":{"subtitle":"Menaxhuesi i Adresave IP dhe Planifikuesi i Subnet-eve  •  Offline","calc":"KALKULATORI I SUBNET-IT","planner":"PLANIFIKUESI VLSM","ipam":"MENAXHIMI I ADRESAVE IP","lang":"Gjuha:","input":"Adresa IPv4 / CIDR:","calculate":"Kalkulo","clear":"Pastro","result":"DETAJET E RRJETIT","parent":"Rrjeti prind:","newprefix":"Prefiksi i ri:","split":"Ndaje në subnet-e të barabarta","requirements":"KËRKESAT VLSM  (një për rresht: Emri, Hostët)","plan":"Krijo planin VLSM","plan_result":"PLANI I SUBNET-EVE","ip":"Adresa IP:","prefix":"Prefiksi:","hostname":"Hostname:","type":"Lloji i pajisjes:","vlan":"VLAN:","location":"Lokacioni:","status":"Statusi:","description":"Përshkrimi:","add":"Shto adresën","update":"Përditëso të zgjedhurën","delete":"Fshi të zgjedhurën","search":"Kërko:","refresh":"Rifresko","import":"Importo CSV","export":"Eksporto CSV","inventory":"ADRESAT IP","saved":"Adresa u ruajt.","updated":"Adresa u përditësua.","deleted":"Adresa u fshi.","duplicate":"Kjo adresë IP ekziston tashmë.","select":"Fillimisht zgjidh një rekord.","confirm":"Ta fshij adresën e zgjedhur?","invalid":"Të dhëna të pavlefshme","imported":"Importi CSV përfundoi: {added} u shtuan, {skipped} u anashkaluan."}}

class App(tk.Tk):
    BG="#0b1423"; PANEL="#111f34"; TEXT_BG="#06101e"; FG="#eaf2ff"; CYAN="#5bd7ff"; BLUE="#2563eb"
    def __init__(self):
        super().__init__(); self.db=IPAMDatabase(DB_PATH); self.lang=tk.StringVar(value="English"); self.selected=None
        self.title(f"{APP_NAME} v{VERSION}"); self.geometry("1365x760"); self.minsize(1100,650); self.configure(bg=self.BG)
        self.style(); self.header(); self.tabs_ui(); self.apply_language(); self.refresh()
    @property
    def code(self): return "sq" if self.lang.get()=="Shqip" else "en"
    def tr(self,k): return T[self.code][k]
    def style(self):
        s=ttk.Style(self); s.theme_use("clam"); s.configure("TNotebook",background=self.BG,borderwidth=0); s.configure("TNotebook.Tab",padding=(18,8),background="#d6d3cd",foreground="#111"); s.map("TNotebook.Tab",background=[("selected","white")]); s.configure("Treeview",background=self.PANEL,fieldbackground=self.PANEL,foreground=self.FG,rowheight=27); s.configure("Treeview.Heading",background=self.BLUE,foreground="white"); s.map("Treeview",background=[("selected",self.BLUE)])
    def header(self):
        f=tk.Frame(self,bg=self.BG,height=76); f.pack(fill="x"); f.pack_propagate(False)
        tk.Label(f,text="NETOPS",bg=self.BG,fg=self.CYAN,font=("Segoe UI",22,"bold")).pack(side="left",padx=(20,4)); tk.Label(f,text="IPAM",bg=self.BG,fg="white",font=("Segoe UI",14,"bold")).pack(side="left")
        self.subtitle=tk.Label(f,bg=self.BG,fg="white"); self.subtitle.pack(side="left",padx=22); self.langlabel=tk.Label(f,bg=self.BG,fg="white"); self.langlabel.pack(side="right",padx=(5,20)); cb=ttk.Combobox(f,textvariable=self.lang,values=("English","Shqip"),state="readonly",width=10); cb.pack(side="right"); cb.bind("<<ComboboxSelected>>",lambda _e:self.apply_language())
    def tabs_ui(self):
        self.tabs=ttk.Notebook(self); self.tabs.pack(fill="both",expand=True,padx=18,pady=(0,18)); self.calc_tab=tk.Frame(self.tabs,bg=self.PANEL); self.plan_tab=tk.Frame(self.tabs,bg=self.PANEL); self.ipam_tab=tk.Frame(self.tabs,bg=self.PANEL)
        for x in (self.calc_tab,self.plan_tab,self.ipam_tab): self.tabs.add(x,text="")
        self.calc_ui(); self.plan_ui(); self.ipam_ui()
    def btn(self,p,cmd): b=tk.Button(p,command=cmd,padx=13,pady=5); b.pack(side="left",padx=(0,8)); return b
    def heading(self,p): l=tk.Label(p,bg=self.PANEL,fg=self.CYAN,anchor="w"); l.pack(fill="x",padx=14,pady=(12,5)); return l
    def text_box(self,p): x=tk.Text(p,bg=self.TEXT_BG,fg=self.FG,insertbackground="white",font=("Consolas",10)); x.pack(fill="both",expand=True,padx=14,pady=(0,14)); return x
    def calc_ui(self):
        top=tk.Frame(self.calc_tab,bg=self.BG); top.pack(fill="x"); self.calc_input_label=tk.Label(top,bg=self.BG,fg=self.FG); self.calc_input_label.pack(side="left",padx=(12,4),pady=10); self.calc_entry=tk.Entry(top,width=30); self.calc_entry.pack(side="left"); self.calc_entry.insert(0,"192.168.10.25/24"); self.calc_btn=self.btn(top,self.calculate); self.calc_clear=self.btn(top,lambda:self.set_text(self.calc_result,"")); self.calc_heading=self.heading(self.calc_tab); self.calc_result=self.text_box(self.calc_tab)
    def plan_ui(self):
        top=tk.Frame(self.plan_tab,bg=self.BG); top.pack(fill="x"); self.parent_label=tk.Label(top,bg=self.BG,fg=self.FG); self.parent_label.pack(side="left",padx=(12,4),pady=10); self.parent_entry=tk.Entry(top,width=24); self.parent_entry.pack(side="left"); self.parent_entry.insert(0,"192.168.100.0/24"); self.prefix_label=tk.Label(top,bg=self.BG,fg=self.FG); self.prefix_label.pack(side="left",padx=(12,4)); self.new_prefix=tk.Spinbox(top,from_=0,to=32,width=5); self.new_prefix.pack(side="left"); self.new_prefix.delete(0,"end"); self.new_prefix.insert(0,"27"); self.split_btn=self.btn(top,self.equal_split); self.plan_btn=self.btn(top,self.create_vlsm)
        body=tk.PanedWindow(self.plan_tab,orient="horizontal",bg=self.PANEL,sashwidth=6); body.pack(fill="both",expand=True,padx=14,pady=14); left=tk.Frame(body,bg=self.PANEL); right=tk.Frame(body,bg=self.PANEL); body.add(left,minsize=300); body.add(right,minsize=600); self.req_heading=self.heading(left); self.requirements=self.text_box(left); self.requirements.insert("1.0","Finance, 50\nHuman Resources, 25\nServers, 10\nManagement, 5"); self.plan_heading=self.heading(right); self.plan_result=self.text_box(right)
    def ipam_ui(self):
        form=tk.Frame(self.ipam_tab,bg=self.BG); form.pack(fill="x"); self.fields={}; keys=("ip","prefix","hostname","type","vlan","location","status","description")
        for i,key in enumerate(keys):
            lab=tk.Label(form,bg=self.BG,fg=self.FG); lab.grid(row=i//4*2,column=(i%4)*2,padx=(10,3),pady=(8,2),sticky="w"); self.fields[key+"_label"]=lab
            if key=="status": widget=ttk.Combobox(form,values=STATUSES,state="readonly",width=20); widget.set("Assigned")
            else: widget=tk.Entry(form,width=23)
            widget.grid(row=i//4*2+1,column=(i%4)*2,padx=(10,3),pady=(0,8),sticky="w"); self.fields[key]=widget
        self.fields["prefix"].insert(0,"24")
        actions=tk.Frame(self.ipam_tab,bg=self.BG); actions.pack(fill="x"); self.add_btn=self.btn(actions,self.add_record); self.update_btn=self.btn(actions,self.update_record); self.delete_btn=self.btn(actions,self.delete_record); self.search_label=tk.Label(actions,bg=self.BG,fg=self.FG); self.search_label.pack(side="left",padx=(12,4)); self.search=tk.Entry(actions,width=24); self.search.pack(side="left"); self.search.bind("<KeyRelease>",lambda _e:self.refresh()); self.refresh_btn=self.btn(actions,self.refresh); self.import_btn=self.btn(actions,self.import_csv); self.export_btn=self.btn(actions,self.export_csv)
        self.inv_heading=self.heading(self.ipam_tab); cols=("id","ip","prefix","hostname","type","vlan","location","status","description","updated"); self.tree=ttk.Treeview(self.ipam_tab,columns=cols,show="headings")
        widths=(45,120,60,150,110,70,120,90,230,150)
        for c,w in zip(cols,widths): self.tree.heading(c,text=c); self.tree.column(c,width=w,anchor="center" if c not in {"description","hostname"} else "w")
        self.tree.pack(fill="both",expand=True,padx=14,pady=(0,14)); self.tree.bind("<<TreeviewSelect>>",self.load_selected)
    def apply_language(self):
        self.subtitle.config(text=self.tr("subtitle")); self.langlabel.config(text=self.tr("lang"))
        for i,k in enumerate(("calc","planner","ipam")): self.tabs.tab(i,text=self.tr(k))
        self.calc_input_label.config(text=self.tr("input")); self.calc_btn.config(text=self.tr("calculate")); self.calc_clear.config(text=self.tr("clear")); self.calc_heading.config(text=self.tr("result")); self.parent_label.config(text=self.tr("parent")); self.prefix_label.config(text=self.tr("newprefix")); self.split_btn.config(text=self.tr("split")); self.plan_btn.config(text=self.tr("plan")); self.req_heading.config(text=self.tr("requirements")); self.plan_heading.config(text=self.tr("plan_result")); self.inv_heading.config(text=self.tr("inventory")); self.search_label.config(text=self.tr("search"))
        for k in ("ip","prefix","hostname","type","vlan","location","status","description"): self.fields[k+"_label"].config(text=self.tr(k))
        for w,k in ((self.add_btn,"add"),(self.update_btn,"update"),(self.delete_btn,"delete"),(self.refresh_btn,"refresh"),(self.import_btn,"import"),(self.export_btn,"export")): w.config(text=self.tr(k))
    @staticmethod
    def set_text(widget,value): widget.delete("1.0","end"); widget.insert("1.0",value)
    def calculate(self):
        try:
            f=calculate_network(self.calc_entry.get()); labels={"en":["Input IP","Network/CIDR","Subnet mask","Wildcard mask","Broadcast","First usable","Last usable","Total addresses","Usable hosts","Private"],"sq":["IP hyrëse","Rrjeti/CIDR","Maska e subnet-it","Maska wildcard","Broadcast","IP e parë","IP e fundit","Adresa gjithsej","Hostë të përdorshëm","Private"]}[self.code]; vals=(f['input_ip'],f['cidr'],f['netmask'],f['wildcard'],f['broadcast'],f['first_usable'],f['last_usable'],f['total_addresses'],f['usable_hosts'],f['private']); self.set_text(self.calc_result,"\n".join(f"{a:<22} {b}" for a,b in zip(labels,vals)))
        except ValueError as e: messagebox.showerror(self.tr("invalid"),str(e))
    def table_text(self,rows):
        head=f"{'Name':<22}{'Network':<20}{'Mask':<16}{'Usable range':<35}{'Hosts':>8}\n"; line="─"*101+"\n"; body="".join(f"{r.get('name','Subnet'):<22}{r['cidr']:<20}{r['netmask']:<16}{r['first_usable']} - {r['last_usable']:<18}{r['usable_hosts']:>8}\n" for r in rows); return head+line+body
    def equal_split(self):
        try: self.set_text(self.plan_result,self.table_text(split_network(self.parent_entry.get(),self.new_prefix.get())))
        except ValueError as e: messagebox.showerror(self.tr("invalid"),str(e))
    def create_vlsm(self):
        try:
            req=[]
            for line in self.requirements.get("1.0","end").splitlines():
                if line.strip(): name,hosts=line.rsplit(",",1); req.append((name.strip(),int(hosts.strip())))
            self.set_text(self.plan_result,self.table_text(vlsm_plan(self.parent_entry.get(),req)))
        except (ValueError,TypeError) as e: messagebox.showerror(self.tr("invalid"),str(e))
    def values(self): return {k:self.fields[k].get() for k in ("ip","prefix","hostname","type","vlan","location","status","description")}
    def add_record(self):
        v=self.values()
        try: self.db.add(v["ip"],v["prefix"],v["hostname"],v["type"],v["vlan"],v["location"],v["status"],v["description"]); self.refresh(); messagebox.showinfo(APP_NAME,self.tr("saved"))
        except sqlite3.IntegrityError: messagebox.showwarning(APP_NAME,self.tr("duplicate"))
        except ValueError as e: messagebox.showerror(self.tr("invalid"),str(e))
    def update_record(self):
        if not self.selected: messagebox.showwarning(APP_NAME,self.tr("select")); return
        v=self.values()
        try: self.db.update(self.selected,ip_address=v["ip"],prefix=v["prefix"],hostname=v["hostname"],device_type=v["type"],vlan=v["vlan"],location=v["location"],status=v["status"],description=v["description"]); self.refresh(); messagebox.showinfo(APP_NAME,self.tr("updated"))
        except sqlite3.IntegrityError: messagebox.showwarning(APP_NAME,self.tr("duplicate"))
        except ValueError as e: messagebox.showerror(self.tr("invalid"),str(e))
    def delete_record(self):
        if not self.selected: messagebox.showwarning(APP_NAME,self.tr("select")); return
        if messagebox.askyesno(APP_NAME,self.tr("confirm")): self.db.delete(self.selected); self.selected=None; self.refresh(); messagebox.showinfo(APP_NAME,self.tr("deleted"))
    def refresh(self):
        for x in self.tree.get_children(): self.tree.delete(x)
        for r in self.db.list(self.search.get() if hasattr(self,"search") else ""): self.tree.insert("","end",values=r)
    def load_selected(self,_e=None):
        selected=self.tree.selection()
        if not selected:return
        r=self.tree.item(selected[0],"values"); self.selected=int(r[0]); vals=(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
        for k,v in zip(("ip","prefix","hostname","type","vlan","location","status","description"),vals): self.fields[k].delete(0,"end"); self.fields[k].insert(0,v)
    def import_csv(self):
        p=filedialog.askopenfilename(filetypes=[("CSV","*.csv")]);
        if p: a,s=self.db.import_csv(p); self.refresh(); messagebox.showinfo(APP_NAME,self.tr("imported").format(added=a,skipped=s))
    def export_csv(self):
        p=filedialog.asksaveasfilename(defaultextension=".csv",filetypes=[("CSV","*.csv")],initialfile="NETOPS-IPAM-Export.csv")
        if p: self.db.export_csv(p); messagebox.showinfo(APP_NAME,p)

if __name__=="__main__": App().mainloop()
