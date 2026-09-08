import sys,tkinter as tk
from pathlib import Path
from tkinter import filedialog,messagebox,ttk
from syslog_core import SEVERITIES,build_html_report,detect_incidents,export_csv,parse_logs,summarize
APP="NETOPS Syslog Analyzer";VERSION="1.0.0"
T={"en":{"sub":"Network Log & Syslog Analyzer  •  Offline","analyzer":"LOG INPUT","events":"PARSED EVENTS","incidents":"DETECTED INCIDENTS","lang":"Language:","load":"Load log file","analyze":"Analyze","clear":"Clear","sample":"LOG / SYSLOG INPUT","filter":"Minimum severity:","search":"Search:","csv":"Export events CSV","html":"Export HTML report","total":"EVENTS","critical":"CRITICAL","errors":"ERRORS","warnings":"WARNINGS","found":"INCIDENTS","need":"Load or paste logs first.","done":"Analysis complete: {events} events and {incidents} incidents detected.","noanalysis":"Run an analysis first."},"sq":{"sub":"Analizuesi i Log-eve dhe Syslog-ut  •  Offline","analyzer":"HYRJA E LOG-EVE","events":"NGJARJET E ANALIZUARA","incidents":"INCIDENTET E ZBULUARA","lang":"Gjuha:","load":"Ngarko log-un","analyze":"Analizo","clear":"Pastro","sample":"LOG / SYSLOG","filter":"Severity minimale:","search":"Kërko:","csv":"Eksporto CSV","html":"Eksporto raport HTML","total":"NGJARJE","critical":"KRITIKE","errors":"GABIME","warnings":"PARALAJMËRIME","found":"INCIDENTE","need":"Fillimisht ngarko ose ngjit log-et.","done":"Analiza përfundoi: {events} ngjarje dhe {incidents} incidente.","noanalysis":"Fillimisht ekzekuto analizën."}}
class App(tk.Tk):
 BG="#0b1423";PANEL="#111f34";BOX="#06101e";FG="#eaf2ff";CYAN="#5bd7ff";BLUE="#2563eb"
 def __init__(self):
  super().__init__();self.lang=tk.StringVar(value="English");self.parsed=[];self.detected=[];self.title(f"{APP} v{VERSION}");self.geometry("1400x780");self.minsize(1100,650);self.configure(bg=self.BG);self.style();self.header();self.tabs_ui();self.translate()
 @property
 def code(self):return "sq" if self.lang.get()=="Shqip" else "en"
 def tr(self,k):return T[self.code][k]
 def style(self):
  s=ttk.Style(self);s.theme_use("clam");s.configure("TNotebook",background=self.BG,borderwidth=0);s.configure("TNotebook.Tab",padding=(18,8),background="#d6d3cd",foreground="#111");s.map("TNotebook.Tab",background=[("selected","white")]);s.configure("Treeview",background=self.PANEL,fieldbackground=self.PANEL,foreground=self.FG,rowheight=27);s.configure("Treeview.Heading",background=self.BLUE,foreground="white");s.map("Treeview",background=[("selected",self.BLUE)])
 def header(self):
  f=tk.Frame(self,bg=self.BG,height=76);f.pack(fill="x");f.pack_propagate(False);tk.Label(f,text="NETOPS",bg=self.BG,fg=self.CYAN,font=("Segoe UI",22,"bold")).pack(side="left",padx=(20,4));tk.Label(f,text="SYSLOG",bg=self.BG,fg="white",font=("Segoe UI",14,"bold")).pack(side="left");self.subtitle=tk.Label(f,bg=self.BG,fg="white");self.subtitle.pack(side="left",padx=20);self.langlab=tk.Label(f,bg=self.BG,fg="white");self.langlab.pack(side="right",padx=(5,20));c=ttk.Combobox(f,textvariable=self.lang,values=("English","Shqip"),state="readonly",width=10);c.pack(side="right");c.bind("<<ComboboxSelected>>",lambda _e:self.translate())
 def tabs_ui(self):
  self.tabs=ttk.Notebook(self);self.tabs.pack(fill="both",expand=True,padx=18,pady=(0,18));self.input_tab=tk.Frame(self.tabs,bg=self.PANEL);self.events_tab=tk.Frame(self.tabs,bg=self.PANEL);self.inc_tab=tk.Frame(self.tabs,bg=self.PANEL)
  for x in (self.input_tab,self.events_tab,self.inc_tab):self.tabs.add(x,text="")
  self.input_ui();self.events_ui();self.inc_ui()
 def button(self,p,cmd):b=tk.Button(p,command=cmd,padx=13,pady=5);b.pack(side="left",padx=(0,8));return b
 def input_ui(self):
  top=tk.Frame(self.input_tab,bg=self.BG);top.pack(fill="x");self.loadbtn=self.button(top,self.load);self.analyzebtn=self.button(top,self.analyze);self.clearbtn=self.button(top,self.clear);self.inputhead=tk.Label(self.input_tab,bg=self.PANEL,fg=self.CYAN,anchor="w");self.inputhead.pack(fill="x",padx=14,pady=(12,5));self.input=tk.Text(self.input_tab,bg=self.BOX,fg=self.FG,insertbackground="white",font=("Consolas",10));self.input.pack(fill="both",expand=True,padx=14,pady=(0,14))
 def cards(self,p):
  f=tk.Frame(p,bg=self.PANEL);f.pack(fill="x",padx=10,pady=10);self.cardsv={}
  for k,color in (("total",self.CYAN),("critical","#ff7070"),("errors","#ff9f68"),("warnings","#ffd166"),("found","#64e572")):
   x=tk.Frame(f,bg=self.BOX,highlightbackground=color,highlightthickness=1,width=190,height=75);x.pack(side="left",padx=5);x.pack_propagate(False);lab=tk.Label(x,bg=self.BOX,fg=color,font=("Segoe UI",9,"bold"));lab.pack(pady=(9,1));val=tk.Label(x,text="0",bg=self.BOX,fg="white",font=("Segoe UI",18,"bold"));val.pack();self.cardsv[k]=(lab,val)
 def events_ui(self):
  self.cards(self.events_tab);tools=tk.Frame(self.events_tab,bg=self.BG);tools.pack(fill="x");self.filterlab=tk.Label(tools,bg=self.BG,fg=self.FG);self.filterlab.pack(side="left",padx=(10,3));self.filter=ttk.Combobox(tools,values=("All","0 Emergency","1 Alert","2 Critical","3 Error","4 Warning","5 Notification","6 Informational","7 Debugging"),state="readonly",width=20);self.filter.set("All");self.filter.pack(side="left");self.filter.bind("<<ComboboxSelected>>",lambda _e:self.refresh_events());self.searchlab=tk.Label(tools,bg=self.BG,fg=self.FG);self.searchlab.pack(side="left",padx=(15,3));self.search=tk.Entry(tools,width=25);self.search.pack(side="left");self.search.bind("<KeyRelease>",lambda _e:self.refresh_events());self.csvbtn=self.button(tools,self.export_events);self.htmlbtn=self.button(tools,self.export_report)
  cols=("line","timestamp","device","facility","severity","mnemonic","message");self.tree=ttk.Treeview(self.events_tab,columns=cols,show="headings");
  for c,w in zip(cols,(55,155,135,110,105,160,600)):self.tree.heading(c,text=c);self.tree.column(c,width=w,anchor="w")
  self.tree.pack(fill="both",expand=True,padx=10,pady=10)
 def inc_ui(self):
  cols=("risk","incident","device","line","evidence","action");self.inctree=ttk.Treeview(self.inc_tab,columns=cols,show="headings");
  for c,w in zip(cols,(85,190,120,55,570,500)):self.inctree.heading(c,text=c);self.inctree.column(c,width=w,anchor="w")
  self.inctree.tag_configure("CRITICAL",foreground="#ff7070");self.inctree.tag_configure("WARNING",foreground="#ffd166");self.inctree.tag_configure("INFO",foreground="#8be9fd");self.inctree.pack(fill="both",expand=True,padx=10,pady=10)
 def translate(self):
  self.subtitle.config(text=self.tr("sub"));self.langlab.config(text=self.tr("lang"));
  for i,k in enumerate(("analyzer","events","incidents")):self.tabs.tab(i,text=self.tr(k))
  for w,k in ((self.loadbtn,"load"),(self.analyzebtn,"analyze"),(self.clearbtn,"clear"),(self.csvbtn,"csv"),(self.htmlbtn,"html")):w.config(text=self.tr(k))
  self.inputhead.config(text=self.tr("sample"));self.filterlab.config(text=self.tr("filter"));self.searchlab.config(text=self.tr("search"));
  for k,(lab,_v) in self.cardsv.items():lab.config(text=self.tr(k))
 def load(self):
  p=filedialog.askopenfilename(filetypes=[("Log/Text","*.log *.txt"),("All files","*.*")]);
  if p:self.input.delete("1.0","end");self.input.insert("1.0",Path(p).read_text(encoding="utf-8",errors="replace"))
 def clear(self):self.input.delete("1.0","end");self.parsed=[];self.detected=[];self.refresh_events();self.refresh_incidents();self.update_cards()
 def analyze(self):
  text=self.input.get("1.0","end-1c")
  if not text.strip():messagebox.showwarning(APP,self.tr("need"));return
  self.parsed=parse_logs(text);self.detected=detect_incidents(self.parsed);self.refresh_events();self.refresh_incidents();self.update_cards();messagebox.showinfo(APP,self.tr("done").format(events=len(self.parsed),incidents=len(self.detected)));self.tabs.select(self.events_tab)
 def update_cards(self):
  s=summarize(self.parsed,self.detected)
  for k,v in (("total",s["total"]),("critical",s["critical"]),("errors",s["errors"]),("warnings",s["warnings"]),("found",s["incidents"])):self.cardsv[k][1].config(text=v)
 def refresh_events(self):
  for x in self.tree.get_children():self.tree.delete(x)
  minsev=None if self.filter.get()=="All" else int(self.filter.get()[0]);q=self.search.get().lower()
  for e in self.parsed:
   if minsev is not None and e["severity"]>minsev:continue
   if q and q not in e["raw"].lower():continue
   self.tree.insert("","end",values=(e["line"],e["timestamp"],e["device"],e["facility"],f"{e['severity']} {e['severity_name']}",e["mnemonic"],e["message"]))
 def refresh_incidents(self):
  for x in self.inctree.get_children():self.inctree.delete(x)
  for i in self.detected:self.inctree.insert("","end",values=(i["risk"],i["title"],i["device"],i["line"],i["evidence"],i["action"]),tags=(i["risk"],))
 def export_events(self):
  if not self.parsed:messagebox.showwarning(APP,self.tr("noanalysis"));return
  p=filedialog.asksaveasfilename(defaultextension=".csv",filetypes=[("CSV","*.csv")],initialfile="NETOPS-Syslog-Events.csv")
  if p:export_csv(self.parsed,p);messagebox.showinfo(APP,p)
 def export_report(self):
  if not self.parsed:messagebox.showwarning(APP,self.tr("noanalysis"));return
  p=filedialog.asksaveasfilename(defaultextension=".html",filetypes=[("HTML","*.html")],initialfile="NETOPS-Syslog-Analysis-Report.html")
  if p:Path(p).write_text(build_html_report(self.parsed,self.detected),encoding="utf-8");messagebox.showinfo(APP,p)
if __name__=="__main__":App().mainloop()
