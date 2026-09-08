import os,sqlite3,sys,tkinter as tk
from pathlib import Path
from tkinter import filedialog,messagebox,ttk
from inventory_core import DEVICE_TYPES,STATUSES,InventoryDB,build_html_report

APP="NETOPS Inventory"; VERSION="1.0.0"; ROOT=Path(__file__).resolve().parent
DATA=Path(os.environ.get("LOCALAPPDATA",Path.home()))/"NETOPS-Inventory" if getattr(sys,"frozen",False) else ROOT/"data"; DB=DATA/"network_inventory.db"
T={
"en":{"sub":"Network Inventory & Documentation Tool  •  Offline","dash":"DASHBOARD","inventory":"DEVICE INVENTORY","lang":"Language:","total":"TOTAL ASSETS","active":"ACTIVE","maint":"MAINTENANCE","offline":"OFFLINE","retired":"RETIRED","types":"DEVICES BY TYPE","form":"DEVICE DETAILS","asset_tag":"Asset tag:","hostname":"Hostname:","device_type":"Device type:","vendor":"Vendor:","model":"Model:","serial_number":"Serial number:","management_ip":"Management IP:","site":"Site:","rack":"Rack:","software_version":"Software/Firmware:","status":"Status:","owner":"Owner/Team:","purchase_date":"Purchase date:","warranty_expiry":"Warranty expiry:","notes":"Notes:","add":"Add device","update":"Update selected","delete":"Delete selected","clear":"Clear form","search":"Search:","filter":"Status:","refresh":"Refresh","import":"Import CSV","csv":"Export CSV","html":"Export HTML report","saved":"Device saved.","updated":"Device updated.","deleted":"Device deleted.","duplicate":"Asset tag, hostname or management IP already exists.","select":"Select a device first.","confirm":"Delete the selected device?","invalid":"Invalid data","imported":"Import complete: {added} added, {skipped} skipped."},
"sq":{"sub":"Inventari dhe Dokumentimi i Rrjetit  •  Offline","dash":"PANELI","inventory":"INVENTARI I PAJISJEVE","lang":"Gjuha:","total":"PAJISJE GJITHSEJ","active":"AKTIVE","maint":"MIRËMBAJTJE","offline":"JASHTË LINJE","retired":"TËRHEQURA","types":"PAJISJET SIPAS LLOJIT","form":"DETAJET E PAJISJES","asset_tag":"Kodi i asetit:","hostname":"Hostname:","device_type":"Lloji:","vendor":"Prodhuesi:","model":"Modeli:","serial_number":"Numri serik:","management_ip":"IP e menaxhimit:","site":"Lokacioni:","rack":"Rack:","software_version":"Software/Firmware:","status":"Statusi:","owner":"Pronari/Ekipi:","purchase_date":"Data e blerjes:","warranty_expiry":"Skadimi i garancisë:","notes":"Shënime:","add":"Shto pajisjen","update":"Përditëso","delete":"Fshi","clear":"Pastro formularin","search":"Kërko:","filter":"Statusi:","refresh":"Rifresko","import":"Importo CSV","csv":"Eksporto CSV","html":"Eksporto raport HTML","saved":"Pajisja u ruajt.","updated":"Pajisja u përditësua.","deleted":"Pajisja u fshi.","duplicate":"Kodi, hostname ose IP e menaxhimit ekziston.","select":"Fillimisht zgjidh një pajisje.","confirm":"Ta fshij pajisjen e zgjedhur?","invalid":"Të dhëna të pavlefshme","imported":"Importi përfundoi: {added} u shtuan, {skipped} u anashkaluan."}}

class App(tk.Tk):
 BG="#0b1423"; PANEL="#111f34"; BOX="#06101e"; FG="#eaf2ff"; CYAN="#5bd7ff"; BLUE="#2563eb"
 def __init__(self):
  super().__init__(); self.db=InventoryDB(DB); self.lang=tk.StringVar(value="English"); self.selected=None; self.title(f"{APP} v{VERSION}"); self.geometry("1400x780"); self.minsize(1150,680); self.configure(bg=self.BG); self._style(); self._header(); self._tabs(); self.translate(); self.refresh()
 @property
 def code(self): return "sq" if self.lang.get()=="Shqip" else "en"
 def tr(self,k): return T[self.code][k]
 def _style(self):
  s=ttk.Style(self); s.theme_use("clam"); s.configure("TNotebook",background=self.BG,borderwidth=0); s.configure("TNotebook.Tab",padding=(18,8),background="#d6d3cd",foreground="#111"); s.map("TNotebook.Tab",background=[("selected","white")]); s.configure("Treeview",background=self.PANEL,fieldbackground=self.PANEL,foreground=self.FG,rowheight=27); s.configure("Treeview.Heading",background=self.BLUE,foreground="white"); s.map("Treeview",background=[("selected",self.BLUE)])
 def _header(self):
  f=tk.Frame(self,bg=self.BG,height=76); f.pack(fill="x"); f.pack_propagate(False); tk.Label(f,text="NETOPS",bg=self.BG,fg=self.CYAN,font=("Segoe UI",22,"bold")).pack(side="left",padx=(20,4)); tk.Label(f,text="INVENTORY",bg=self.BG,fg="white",font=("Segoe UI",14,"bold")).pack(side="left"); self.subtitle=tk.Label(f,bg=self.BG,fg="white"); self.subtitle.pack(side="left",padx=20); self.langlab=tk.Label(f,bg=self.BG,fg="white"); self.langlab.pack(side="right",padx=(5,20)); c=ttk.Combobox(f,textvariable=self.lang,values=("English","Shqip"),state="readonly",width=10); c.pack(side="right"); c.bind("<<ComboboxSelected>>",lambda _e:self.translate())
 def _tabs(self):
  self.tabs=ttk.Notebook(self); self.tabs.pack(fill="both",expand=True,padx=18,pady=(0,18)); self.dashboard=tk.Frame(self.tabs,bg=self.PANEL); self.inventory=tk.Frame(self.tabs,bg=self.PANEL); self.tabs.add(self.dashboard,text=""); self.tabs.add(self.inventory,text=""); self._dashboard(); self._inventory()
 def _dashboard(self):
  cards=tk.Frame(self.dashboard,bg=self.PANEL); cards.pack(fill="x",padx=18,pady=25); self.cards={}
  for key,color in (("total",self.CYAN),("active","#64e572"),("maint","#ffd166"),("offline","#ff7070"),("retired","#aab4c3")):
   f=tk.Frame(cards,bg=self.BOX,highlightbackground=color,highlightthickness=1,width=220,height=110); f.pack(side="left",padx=8); f.pack_propagate(False); title=tk.Label(f,bg=self.BOX,fg=color,font=("Segoe UI",10,"bold")); title.pack(pady=(17,4)); value=tk.Label(f,text="0",bg=self.BOX,fg="white",font=("Segoe UI",24,"bold")); value.pack(); self.cards[key]=(title,value)
  self.types_title=tk.Label(self.dashboard,bg=self.PANEL,fg=self.CYAN,anchor="w",font=("Segoe UI",11,"bold")); self.types_title.pack(fill="x",padx=30,pady=(20,5)); self.types_text=tk.Text(self.dashboard,bg=self.BOX,fg=self.FG,font=("Consolas",12),height=16,state="disabled"); self.types_text.pack(fill="both",expand=True,padx=30,pady=(0,30))
 def _inventory(self):
  self.form_title=tk.Label(self.inventory,bg=self.PANEL,fg=self.CYAN,anchor="w",font=("Segoe UI",10,"bold")); self.form_title.pack(fill="x",padx=12,pady=(10,2)); form=tk.Frame(self.inventory,bg=self.BG); form.pack(fill="x"); self.fields={}; keys=list(InventoryDB.COLUMNS)
  for i,key in enumerate(keys):
   row=(i//5)*2; col=(i%5)*2; l=tk.Label(form,bg=self.BG,fg=self.FG); l.grid(row=row,column=col,padx=(10,3),pady=(6,1),sticky="w"); self.fields[key+"_label"]=l
   if key=="device_type": w=ttk.Combobox(form,values=DEVICE_TYPES,state="readonly",width=20); w.set("Switch")
   elif key=="status": w=ttk.Combobox(form,values=STATUSES,state="readonly",width=20); w.set("Active")
   else: w=tk.Entry(form,width=23)
   w.grid(row=row+1,column=col,padx=(10,3),pady=(0,7),sticky="w"); self.fields[key]=w
  actions=tk.Frame(self.inventory,bg=self.BG); actions.pack(fill="x"); self.buttons={};
  for key,cmd in (("add",self.add),("update",self.update),("delete",self.delete),("clear",self.clear),("refresh",self.refresh),("import",self.import_csv),("csv",self.export_csv),("html",self.export_html)):
   b=tk.Button(actions,command=cmd,padx=10,pady=5); b.pack(side="left",padx=(8,0),pady=7); self.buttons[key]=b
  self.search_lab=tk.Label(actions,bg=self.BG,fg=self.FG); self.search_lab.pack(side="left",padx=(16,3)); self.search=tk.Entry(actions,width=18); self.search.pack(side="left"); self.search.bind("<KeyRelease>",lambda _e:self.refresh()); self.filter_lab=tk.Label(actions,bg=self.BG,fg=self.FG); self.filter_lab.pack(side="left",padx=(12,3)); self.filter=ttk.Combobox(actions,values=("All",)+STATUSES,state="readonly",width=12); self.filter.set("All"); self.filter.pack(side="left"); self.filter.bind("<<ComboboxSelected>>",lambda _e:self.refresh())
  cols=("id","tag","hostname","type","vendor","model","serial","ip","site","rack","software","status","owner","purchase","warranty","notes","updated"); self.tree=ttk.Treeview(self.inventory,columns=cols,show="headings")
  widths=(40,90,130,90,90,110,120,115,100,65,120,85,100,90,100,180,140)
  for c,w in zip(cols,widths): self.tree.heading(c,text=c); self.tree.column(c,width=w,anchor="center")
  self.tree.pack(fill="both",expand=True,padx=12,pady=(0,12)); self.tree.bind("<<TreeviewSelect>>",self.load)
 def translate(self):
  self.subtitle.config(text=self.tr("sub")); self.langlab.config(text=self.tr("lang")); self.tabs.tab(0,text=self.tr("dash")); self.tabs.tab(1,text=self.tr("inventory")); self.form_title.config(text=self.tr("form")); self.types_title.config(text=self.tr("types")); self.search_lab.config(text=self.tr("search")); self.filter_lab.config(text=self.tr("filter"))
  for k in InventoryDB.COLUMNS:self.fields[k+"_label"].config(text=self.tr(k))
  for k,b in self.buttons.items():b.config(text=self.tr(k))
  for k,(title,_value) in self.cards.items():title.config(text=self.tr(k))
 def values(self): return {k:self.fields[k].get() for k in InventoryDB.COLUMNS}
 def add(self):
  try:self.db.add(self.values()); self.refresh(); messagebox.showinfo(APP,self.tr("saved"))
  except sqlite3.IntegrityError:messagebox.showwarning(APP,self.tr("duplicate"))
  except ValueError as e:messagebox.showerror(self.tr("invalid"),str(e))
 def update(self):
  if not self.selected:messagebox.showwarning(APP,self.tr("select"));return
  try:self.db.update(self.selected,self.values());self.refresh();messagebox.showinfo(APP,self.tr("updated"))
  except sqlite3.IntegrityError:messagebox.showwarning(APP,self.tr("duplicate"))
  except ValueError as e:messagebox.showerror(self.tr("invalid"),str(e))
 def delete(self):
  if not self.selected:messagebox.showwarning(APP,self.tr("select"));return
  if messagebox.askyesno(APP,self.tr("confirm")):self.db.delete(self.selected);self.selected=None;self.clear();self.refresh();messagebox.showinfo(APP,self.tr("deleted"))
 def clear(self):
  self.selected=None
  for k in InventoryDB.COLUMNS:
   self.fields[k].delete(0,"end")
  self.fields["device_type"].set("Switch");self.fields["status"].set("Active")
 def load(self,_e=None):
  s=self.tree.selection()
  if not s:return
  r=self.tree.item(s[0],"values");self.selected=int(r[0])
  for k,v in zip(InventoryDB.COLUMNS,r[1:16]):
   widget=self.fields[k]
   if isinstance(widget,ttk.Combobox):widget.set(v)
   else:widget.delete(0,"end");widget.insert(0,v)
 def refresh(self):
  for x in self.tree.get_children():self.tree.delete(x)
  for r in self.db.list(self.search.get() if hasattr(self,"search") else "",self.filter.get() if hasattr(self,"filter") else "All"):self.tree.insert("","end",values=r)
  st=self.db.stats()
  for k,dbk in (("total","total"),("active","active"),("maint","maintenance"),("offline","offline"),("retired","retired")):self.cards[k][1].config(text=st[dbk])
  self.types_text.config(state="normal");self.types_text.delete("1.0","end");self.types_text.insert("1.0","\n".join(f"{k:<20} {v:>5}" for k,v in sorted(st["types"].items())) or "No devices");self.types_text.config(state="disabled")
 def import_csv(self):
  p=filedialog.askopenfilename(filetypes=[("CSV","*.csv")]);
  if p:a,s=self.db.import_csv(p);self.refresh();messagebox.showinfo(APP,self.tr("imported").format(added=a,skipped=s))
 def export_csv(self):
  p=filedialog.asksaveasfilename(defaultextension=".csv",filetypes=[("CSV","*.csv")],initialfile="NETOPS-Network-Inventory.csv")
  if p:self.db.export_csv(p);messagebox.showinfo(APP,p)
 def export_html(self):
  p=filedialog.asksaveasfilename(defaultextension=".html",filetypes=[("HTML","*.html")],initialfile="NETOPS-Network-Inventory-Report.html")
  if p:Path(p).write_text(build_html_report(self.db.list()),encoding="utf-8");messagebox.showinfo(APP,p)

if __name__=="__main__":App().mainloop()
