import difflib
import hashlib
import os
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk


APP_NAME = "NETOPS Config Vault"
APP_VERSION = "1.0.0"
APP_DIR = Path(__file__).resolve().parent
DATA_DIR = (Path(os.environ.get("LOCALAPPDATA", Path.home())) / "NETOPS-Config-Vault"
            if getattr(sys, "frozen", False) else APP_DIR / "data")
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB_PATH = DATA_DIR / "config_vault.db"

TEXT = {
    "en": {
        "subtitle": "Network Configuration Backup & Change Detector  •  Offline",
        "capture": "CAPTURE", "history": "BACKUP HISTORY", "compare": "COMPARE VERSIONS",
        "language": "Language:", "device": "Device:", "source": "Source:",
        "paste": "PASTE CISCO IOS CONFIGURATION", "load": "Load file", "save": "Save backup",
        "clear": "Clear", "refresh": "Refresh", "details": "Show configuration",
        "delete": "Delete backup", "baseline": "Version A (baseline):", "current": "Version B (current):",
        "compare_btn": "Compare", "export": "Export report", "result": "CHANGE ANALYSIS",
        "id": "ID", "created": "Created", "hash": "Fingerprint", "lines": "Lines",
        "saved": "Backup saved successfully.", "duplicate": "This exact configuration is already the latest backup.",
        "need_config": "Paste or load a configuration first.", "need_device": "Enter a device name.",
        "need_two": "Select two different versions.", "confirm_delete": "Delete the selected backup?",
        "deleted": "Backup deleted.", "report_saved": "Report exported successfully.",
        "no_selection": "Select a backup first.", "source_default": "Manual capture",
    },
    "sq": {
        "subtitle": "Ruajtja dhe Zbulimi i Ndryshimeve të Konfigurimit  •  Offline",
        "capture": "RUAJTJA", "history": "HISTORIKU I BACKUP-EVE", "compare": "KRAHASO VERSIONET",
        "language": "Gjuha:", "device": "Pajisja:", "source": "Burimi:",
        "paste": "NGJIT KONFIGURIMIN CISCO IOS", "load": "Ngarko skedarin", "save": "Ruaj backup-in",
        "clear": "Pastro", "refresh": "Rifresko", "details": "Shfaq konfigurimin",
        "delete": "Fshi backup-in", "baseline": "Versioni A (bazë):", "current": "Versioni B (aktual):",
        "compare_btn": "Krahaso", "export": "Eksporto raportin", "result": "ANALIZA E NDRYSHIMEVE",
        "id": "ID", "created": "Data", "hash": "Gjurmë", "lines": "Rreshta",
        "saved": "Backup-i u ruajt me sukses.", "duplicate": "Ky konfigurim është identik me backup-in e fundit.",
        "need_config": "Fillimisht ngjit ose ngarko një konfigurim.", "need_device": "Shkruaj emrin e pajisjes.",
        "need_two": "Zgjidh dy versione të ndryshme.", "confirm_delete": "Ta fshij backup-in e zgjedhur?",
        "deleted": "Backup-i u fshi.", "report_saved": "Raporti u eksportua me sukses.",
        "no_selection": "Fillimisht zgjidh një backup.", "source_default": "Ruajtje manuale",
    },
}

RISK_LABEL = {"en": {"CRITICAL": "CRITICAL", "WARNING": "WARNING", "INFO": "INFO"},
              "sq": {"CRITICAL": "KRITIK", "WARNING": "PARALAJMËRIM", "INFO": "INFORMUES"}}


def normalize_config(text):
    """Normalize line endings and trailing whitespace without changing IOS meaning."""
    lines = [line.rstrip() for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")]
    while lines and not lines[-1]:
        lines.pop()
    return "\n".join(lines) + ("\n" if lines else "")


def detect_hostname(text):
    match = re.search(r"(?im)^\s*hostname\s+([A-Za-z0-9_.-]+)\s*$", text)
    if match:
        return match.group(1)
    match = re.search(r"(?m)^\s*([A-Za-z0-9_.-]+)(?:\([^\n)]*\))?[#>]", text)
    return match.group(1) if match else ""


def fingerprint(text):
    return hashlib.sha256(normalize_config(text).encode("utf-8")).hexdigest()


def _context_commands(lines):
    context = "global"
    result = []
    for raw in lines:
        line = raw.strip()
        if re.match(r"^(interface|router |ip access-list|route-map|vlan |line |class-map|policy-map)", line, re.I):
            context = line
        if line and line != "!":
            result.append((context, line))
    return result


def classify_change(line, action):
    command = line.strip().lstrip("+-").strip().lower()
    critical = (
        r"^no ip route", r"^shutdown$", r"^no router ", r"^no neighbor ",
        r"^no network ", r"^switchport trunk allowed vlan", r"^no switchport access vlan",
        r"^ip access-group", r"^no ip access-group", r"^deny (ip|tcp|udp) any any",
        r"^no crypto ", r"^no tunnel ", r"^no standby ", r"^no ip address",
    )
    warning = (
        r"^ip address", r"^switchport access vlan", r"^switchport mode", r"^channel-group",
        r"^spanning-tree", r"^ip route", r"^network ", r"^neighbor ", r"^redistribute",
        r"^passive-interface", r"^default-router", r"^ip helper-address", r"^permit ",
        r"^snmp-server", r"^logging host", r"^ntp server",
    )
    if any(re.search(p, command) for p in critical):
        return "CRITICAL"
    if any(re.search(p, command) for p in warning):
        return "WARNING"
    if action == "REMOVED" and command not in {"!", ""}:
        return "WARNING"
    return "INFO"


def analyze_changes(old_text, new_text):
    old = normalize_config(old_text).splitlines()
    new = normalize_config(new_text).splitlines()
    matcher = difflib.SequenceMatcher(a=old, b=new, autojunk=False)
    changes = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag in {"delete", "replace"}:
            for line in old[i1:i2]:
                if line.strip() and line.strip() != "!":
                    changes.append({"action": "REMOVED", "line": line, "risk": classify_change(line, "REMOVED")})
        if tag in {"insert", "replace"}:
            for line in new[j1:j2]:
                if line.strip() and line.strip() != "!":
                    changes.append({"action": "ADDED", "line": line, "risk": classify_change(line, "ADDED")})
    counts = {risk: sum(c["risk"] == risk for c in changes) for risk in ("CRITICAL", "WARNING", "INFO")}
    return changes, counts


def unified_diff(old_text, new_text, old_label="baseline", new_label="current"):
    return "\n".join(difflib.unified_diff(
        normalize_config(old_text).splitlines(), normalize_config(new_text).splitlines(),
        fromfile=old_label, tofile=new_label, lineterm=""
    ))


class VaultDB:
    def __init__(self, path=DB_PATH):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as con:
            con.execute("""CREATE TABLE IF NOT EXISTS backups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device TEXT NOT NULL, captured_at TEXT NOT NULL, source TEXT NOT NULL,
                content TEXT NOT NULL, sha256 TEXT NOT NULL, line_count INTEGER NOT NULL
            )""")
            con.execute("CREATE INDEX IF NOT EXISTS idx_backups_device_date ON backups(device, captured_at DESC)")

    def connect(self):
        return sqlite3.connect(self.path)

    def latest_hash(self, device):
        with self.connect() as con:
            row = con.execute("SELECT sha256 FROM backups WHERE device=? ORDER BY id DESC LIMIT 1", (device,)).fetchone()
        return row[0] if row else None

    def add(self, device, source, content):
        clean = normalize_config(content)
        digest = fingerprint(clean)
        if self.latest_hash(device) == digest:
            return None
        with self.connect() as con:
            cur = con.execute("INSERT INTO backups(device,captured_at,source,content,sha256,line_count) VALUES(?,?,?,?,?,?)",
                              (device, datetime.now().strftime("%Y-%m-%d %H:%M:%S"), source, clean, digest, len(clean.splitlines())))
            return cur.lastrowid

    def list(self, device=None):
        sql = "SELECT id,device,captured_at,source,sha256,line_count FROM backups"
        args = ()
        if device:
            sql += " WHERE device=?"; args = (device,)
        sql += " ORDER BY id DESC"
        with self.connect() as con:
            return con.execute(sql, args).fetchall()

    def get(self, backup_id):
        with self.connect() as con:
            return con.execute("SELECT id,device,captured_at,source,content,sha256,line_count FROM backups WHERE id=?", (backup_id,)).fetchone()

    def delete(self, backup_id):
        with self.connect() as con:
            con.execute("DELETE FROM backups WHERE id=?", (backup_id,))


class App(tk.Tk):
    BG, PANEL, TEXT_BG, FG, CYAN, BLUE = "#0b1423", "#111f34", "#06101e", "#eaf2ff", "#5bd7ff", "#2563eb"

    def __init__(self):
        super().__init__()
        self.db = VaultDB()
        self.lang = tk.StringVar(value="English")
        self.current_report = ""
        self.title(f"{APP_NAME} v{APP_VERSION}")
        self.geometry("1365x760"); self.minsize(1050, 650); self.configure(bg=self.BG)
        self._style(); self._header(); self._tabs(); self.apply_language()

    @property
    def code(self): return "sq" if self.lang.get() == "Shqip" else "en"
    def tr(self, key): return TEXT[self.code][key]

    def _style(self):
        style = ttk.Style(self); style.theme_use("clam")
        style.configure("TNotebook", background=self.BG, borderwidth=0)
        style.configure("TNotebook.Tab", padding=(18, 8), background="#d6d3cd", foreground="#111")
        style.map("TNotebook.Tab", background=[("selected", "#ffffff")])
        style.configure("Treeview", background=self.PANEL, fieldbackground=self.PANEL, foreground=self.FG, rowheight=27)
        style.configure("Treeview.Heading", background=self.BLUE, foreground="white")
        style.map("Treeview", background=[("selected", self.BLUE)])

    def _header(self):
        bar = tk.Frame(self, bg=self.BG, height=76); bar.pack(fill="x"); bar.pack_propagate(False)
        tk.Label(bar, text="NETOPS", bg=self.BG, fg=self.CYAN, font=("Segoe UI", 22, "bold")).pack(side="left", padx=(20, 4))
        tk.Label(bar, text="CONFIG VAULT", bg=self.BG, fg="white", font=("Segoe UI", 13, "bold")).pack(side="left", pady=(9, 0))
        self.subtitle = tk.Label(bar, bg=self.BG, fg="white", font=("Segoe UI", 10)); self.subtitle.pack(side="left", padx=20)
        self.lang_label = tk.Label(bar, bg=self.BG, fg="white"); self.lang_label.pack(side="right", padx=(5, 20))
        lang = ttk.Combobox(bar, textvariable=self.lang, values=("English", "Shqip"), state="readonly", width=10)
        lang.pack(side="right"); lang.bind("<<ComboboxSelected>>", lambda _e: self.apply_language())

    def _tabs(self):
        self.tabs = ttk.Notebook(self); self.tabs.pack(fill="both", expand=True, padx=18, pady=(0,18))
        self.capture_tab = tk.Frame(self.tabs, bg=self.PANEL); self.history_tab = tk.Frame(self.tabs, bg=self.PANEL); self.compare_tab = tk.Frame(self.tabs, bg=self.PANEL)
        for tab in (self.capture_tab, self.history_tab, self.compare_tab): self.tabs.add(tab, text="")
        self._capture_ui(); self._history_ui(); self._compare_ui()

    def button(self, parent, command):
        b = tk.Button(parent, command=command, padx=15, pady=6); b.pack(side="left", padx=(0,8)); return b

    def _capture_ui(self):
        top = tk.Frame(self.capture_tab, bg=self.BG); top.pack(fill="x")
        self.device_label = tk.Label(top, bg=self.BG, fg=self.FG); self.device_label.pack(side="left", padx=(12,4), pady=10)
        self.device = tk.Entry(top, width=24); self.device.pack(side="left")
        self.source_label = tk.Label(top, bg=self.BG, fg=self.FG); self.source_label.pack(side="left", padx=(18,4))
        self.source = tk.Entry(top, width=35); self.source.pack(side="left")
        self.load_btn = self.button(top, self.load_file); self.save_btn = self.button(top, self.save_backup); self.clear_btn = self.button(top, self.clear_capture)
        self.capture_heading = tk.Label(self.capture_tab, bg=self.PANEL, fg=self.CYAN, anchor="w"); self.capture_heading.pack(fill="x", padx=14, pady=(12,5))
        self.input_text = tk.Text(self.capture_tab, bg=self.TEXT_BG, fg=self.FG, insertbackground="white", font=("Consolas",10), undo=True)
        self.input_text.pack(fill="both", expand=True, padx=14, pady=(0,14))

    def _history_ui(self):
        self.tree = ttk.Treeview(self.history_tab, columns=("id","device","created","source","hash","lines"), show="headings")
        for c, w in (("id",55),("device",190),("created",170),("source",300),("hash",170),("lines",80)):
            self.tree.heading(c,text=c); self.tree.column(c,width=w,anchor="center" if c != "source" else "w")
        self.tree.pack(fill="both", expand=True, padx=10, pady=10)
        buttons=tk.Frame(self.history_tab,bg=self.BG); buttons.pack(fill="x",padx=10,pady=(0,10))
        self.details_btn=self.button(buttons,self.show_backup); self.delete_btn=self.button(buttons,self.delete_backup); self.refresh_btn=self.button(buttons,self.refresh)

    def _compare_ui(self):
        controls=tk.Frame(self.compare_tab,bg=self.BG); controls.pack(fill="x")
        self.base_label=tk.Label(controls,bg=self.BG,fg=self.FG); self.base_label.pack(side="left",padx=(12,4),pady=10)
        self.base_combo=ttk.Combobox(controls,state="readonly",width=42); self.base_combo.pack(side="left")
        self.new_label=tk.Label(controls,bg=self.BG,fg=self.FG); self.new_label.pack(side="left",padx=(15,4))
        self.new_combo=ttk.Combobox(controls,state="readonly",width=42); self.new_combo.pack(side="left")
        self.compare_btn=self.button(controls,self.compare_versions); self.export_btn=self.button(controls,self.export_report)
        self.result_heading=tk.Label(self.compare_tab,bg=self.PANEL,fg=self.CYAN,anchor="w"); self.result_heading.pack(fill="x",padx=14,pady=(10,5))
        self.result=tk.Text(self.compare_tab,bg=self.TEXT_BG,fg=self.FG,insertbackground="white",font=("Consolas",10),state="disabled")
        self.result.tag_configure("critical",foreground="#ff7070"); self.result.tag_configure("warning",foreground="#ffd166"); self.result.tag_configure("info",foreground="#8be9fd")
        self.result.pack(fill="both",expand=True,padx=14,pady=(0,14))

    def apply_language(self):
        self.subtitle.config(text=self.tr("subtitle")); self.lang_label.config(text=self.tr("language"))
        for i,key in enumerate(("capture","history","compare")): self.tabs.tab(i,text=self.tr(key))
        self.device_label.config(text=self.tr("device")); self.source_label.config(text=self.tr("source")); self.capture_heading.config(text=self.tr("paste"))
        for widget,key in ((self.load_btn,"load"),(self.save_btn,"save"),(self.clear_btn,"clear"),(self.details_btn,"details"),(self.delete_btn,"delete"),(self.refresh_btn,"refresh"),(self.compare_btn,"compare_btn"),(self.export_btn,"export")):
            widget.config(text=self.tr(key))
        self.base_label.config(text=self.tr("baseline")); self.new_label.config(text=self.tr("current")); self.result_heading.config(text=self.tr("result"))
        for col,key in (("id","id"),("device","device"),("created","created"),("source","source"),("hash","hash"),("lines","lines")):
            self.tree.heading(col,text=self.tr(key))

    def load_file(self):
        path=filedialog.askopenfilename(filetypes=[("Text/config files","*.txt *.cfg *.conf *.log"),("All files","*.*")])
        if not path: return
        content=Path(path).read_text(encoding="utf-8",errors="replace"); self.input_text.delete("1.0","end"); self.input_text.insert("1.0",content)
        name=detect_hostname(content)
        if name: self.device.delete(0,"end"); self.device.insert(0,name)
        self.source.delete(0,"end"); self.source.insert(0,Path(path).name)

    def clear_capture(self):
        self.input_text.delete("1.0","end"); self.device.delete(0,"end"); self.source.delete(0,"end")

    def save_backup(self):
        content=self.input_text.get("1.0","end-1c"); device=self.device.get().strip() or detect_hostname(content)
        if not content.strip(): messagebox.showwarning(APP_NAME,self.tr("need_config")); return
        if not device: messagebox.showwarning(APP_NAME,self.tr("need_device")); return
        saved=self.db.add(device,self.source.get().strip() or self.tr("source_default"),content)
        messagebox.showinfo(APP_NAME,self.tr("saved") if saved else self.tr("duplicate")); self.refresh()

    def refresh(self):
        for item in self.tree.get_children(): self.tree.delete(item)
        rows=self.db.list()
        for row in rows: self.tree.insert("","end",values=(row[0],row[1],row[2],row[3],row[4][:16],row[5]))
        labels=[f"#{r[0]} | {r[1]} | {r[2]} | {r[3]}" for r in rows]
        self.base_combo["values"]=labels; self.new_combo["values"]=labels
        if len(labels)>=2: self.base_combo.current(1); self.new_combo.current(0)

    def selected_id(self):
        selected=self.tree.selection()
        return int(self.tree.item(selected[0],"values")[0]) if selected else None

    def show_backup(self):
        backup_id=self.selected_id()
        if not backup_id: messagebox.showwarning(APP_NAME,self.tr("no_selection")); return
        row=self.db.get(backup_id); win=tk.Toplevel(self); win.title(f"Backup #{row[0]} – {row[1]}"); win.geometry("900x650")
        box=tk.Text(win,bg=self.TEXT_BG,fg=self.FG,font=("Consolas",10)); box.pack(fill="both",expand=True); box.insert("1.0",row[4]); box.config(state="disabled")

    def delete_backup(self):
        backup_id=self.selected_id()
        if not backup_id: messagebox.showwarning(APP_NAME,self.tr("no_selection")); return
        if messagebox.askyesno(APP_NAME,self.tr("confirm_delete")):
            self.db.delete(backup_id); self.refresh(); messagebox.showinfo(APP_NAME,self.tr("deleted"))

    @staticmethod
    def combo_id(combo):
        match=re.match(r"#(\d+)",combo.get()); return int(match.group(1)) if match else None

    def compare_versions(self):
        a_id,b_id=self.combo_id(self.base_combo),self.combo_id(self.new_combo)
        if not a_id or not b_id or a_id==b_id: messagebox.showwarning(APP_NAME,self.tr("need_two")); return
        a,b=self.db.get(a_id),self.db.get(b_id); changes,counts=analyze_changes(a[4],b[4])
        lang=self.code
        title=(f"CONFIGURATION CHANGE REPORT\n" if lang=="en" else "RAPORTI I NDRYSHIMEVE TË KONFIGURIMIT\n")
        header=(f"Device: {a[1]} → {b[1]}\nBaseline: #{a[0]} | {a[2]}\nCurrent:  #{b[0]} | {b[2]}\n"
                if lang=="en" else f"Pajisja: {a[1]} → {b[1]}\nBaza:    #{a[0]} | {a[2]}\nAktuali: #{b[0]} | {b[2]}\n")
        summary=(f"Summary: {counts['CRITICAL']} critical, {counts['WARNING']} warning, {counts['INFO']} informational changes.\n"
                 if lang=="en" else f"Përmbledhje: {counts['CRITICAL']} kritike, {counts['WARNING']} paralajmërime, {counts['INFO']} informuese.\n")
        lines=[title,header,summary,"─"*88+"\n"]
        for n,c in enumerate(changes,1): lines.append(f"{n}. [{RISK_LABEL[lang][c['risk']]}] {c['action']}: {c['line']}\n")
        if not changes: lines.append("No configuration differences detected.\n" if lang=="en" else "Nuk u gjet asnjë ndryshim në konfigurim.\n")
        lines.extend(["\n","─"*88,"\nUNIFIED DIFF\n",unified_diff(a[4],b[4],f"backup-{a[0]}",f"backup-{b[0]}")])
        self.current_report="".join(lines); self.result.config(state="normal"); self.result.delete("1.0","end")
        for line in self.current_report.splitlines(True):
            tag="critical" if "CRITICAL" in line or "KRITIK" in line else "warning" if "WARNING" in line or "PARALAJMËRIM" in line else "info" if "[INFO]" in line or "[INFORMUES]" in line else ""
            self.result.insert("end",line,tag)
        self.result.config(state="disabled")

    def export_report(self):
        if not self.current_report: messagebox.showwarning(APP_NAME,self.tr("need_two")); return
        path=filedialog.asksaveasfilename(defaultextension=".txt",filetypes=[("Text report","*.txt"),("All files","*.*")],initialfile=f"NETOPS-Change-Report-{datetime.now():%Y%m%d-%H%M%S}.txt")
        if path: Path(path).write_text(self.current_report,encoding="utf-8-sig"); messagebox.showinfo(APP_NAME,self.tr("report_saved"))


if __name__ == "__main__":
    app=App(); app.refresh(); app.mainloop()
