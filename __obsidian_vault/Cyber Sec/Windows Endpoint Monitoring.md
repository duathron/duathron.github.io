---
title: "Windows Endpoint Monitoring"
tags: [windows, processes, event-logs, sysmon, powershell, soc, endpoint-security, blue-team]
---

# Windows Endpoint Monitoring

Zusammenfassung der drei TryHackMe-Räume **Core Windows Processes**, **Windows Event Logs** und **Sysmon**, die gemeinsam auf den Raum **Windows Logging for SOC** vorbereiten.

Der gemeinsame Nenner: Endpoints — also Workstations und Server — sind dort, wo Angreifer am meisten Zeit verbringen. Wer nicht weiß, wie ein gesundes Windows-System aussieht, kann kein kompromittiertes erkennen.

---

## Raum 1: Core Windows Processes

### Wozu das Ganze?

Antivirus reicht nicht mehr. EDR (Endpoint Detection and Response) auch nicht immer. Was bleibt: ein Analyst, der weiß, wie Windows normalerweise aussieht, kann erkennen, wenn etwas nicht stimmt — auch wenn kein Tool Alarm schlägt.

Die zentrale Frage bei jedem Prozess: **Ist das normales Verhalten, oder ist da etwas eingeklinkt?**

> [!example] Tools — Core Windows Processes
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **Task Manager** | GUI (built-in) | Schnelle Prozessübersicht; Spalten "Image path name" und "Command line" einblenden |
> | **Process Explorer** | GUI (Sysinternals) | Prozessbaum, Image Path, Handles, DLLs, Parent-Child-Beziehungen |
> | **Process Hacker** | GUI (Open Source) | Wie Process Explorer, zusätzliche Details zu Memory und Threads |
> | **tasklist** | CLI (built-in) | Prozessliste mit PIDs und zugehörigen Services |
> | **Get-Process** | PowerShell | Prozessliste skriptfähig abfragen |
> | **sc.exe** | CLI (built-in) | Services und SCM abfragen (`sc query`, `sc qc <service>`) |
>
> **Tipp:** In Task Manager unbedingt die Spalten "Image path name" und "Command line" einblenden — ohne diese sieht man nur den Prozessnamen, nicht wo er liegt oder mit welchen Parametern er läuft.

---

### Die Core Processes im Überblick

#### ==System (PID 4)==

- Läuft im **Kernel-Mode**, keine User-Mode-Adresse
- PID ist immer **4** — das ist eine der wenigen festen PIDs in Windows
- Parent: keiner (erstellt von `ntoskrnl.exe`)
- Startort: `N/A` (Process Explorer) oder `C:\Windows\System32\ntoskrnl.exe` (Process Hacker)
- Instanzen: genau **1**

**Suspicious:** PID ≠ 4, mehr als eine Instanz, sichtbarer Parent-Prozess

---

#### ==smss.exe — Session Manager Subsystem==

- Erster **User-Mode-Prozess** beim Bootvorgang
- Erstellt Session 0 (OS) und Session 1 (User):
  - Session 0 → `csrss.exe` + `wininit.exe`
  - Session 1 → `csrss.exe` + `winlogon.exe`
- Kopiert sich selbst in neue Sessions und terminiert sich danach → child-Instanzen erscheinen ohne Parent
- Verwaltet Environment Variables und Virtual Memory Paging Files
- Image Path: `C:\Windows\System32\smss.exe`
- User: `NT AUTHORITY\SYSTEM`
- Instanzen: 1 master + je 1 child pro Session (child terminiert nach Session-Erstellung)

**Suspicious:** Parent ≠ System (PID 4), mehr als eine laufende Instanz, anderer Image Path, anderer User

---

#### ==csrss.exe — Client Server Runtime Process==

- User-Mode-Seite des Windows-Subsystems
- Zuständig für: Win32-Konsolfenster, Thread-Erstellung/Löschung, Laufwerksbuchstaben-Mapping, Windows-Shutdown
- Wird von `smss.exe` gestartet, das sich danach terminiert → **kein sichtbarer Parent**
- Mindestens **2 Instanzen** erwartet (Session 0 und Session 1)
- Image Path: `C:\Windows\System32\csrss.exe`
- User: `NT AUTHORITY\SYSTEM`

**Suspicious:** sichtbarer Parent-Prozess, anderer Image Path, Tippfehler-Varianten (`crss.exe`, `cssrs.exe`), User ≠ SYSTEM

---

#### ==wininit.exe — Windows Initialization Process==

- Startet die drei Kernprozesse in **Session 0**:
  - `services.exe` (Service Control Manager)
  - `lsass.exe` (Local Security Authority)
  - `lsaiso.exe` (nur wenn Credential Guard aktiv)
- Kein sichtbarer Parent (smss.exe hat sich terminiert)
- Image Path: `C:\Windows\System32\wininit.exe`
- User: `NT AUTHORITY\SYSTEM`
- Instanzen: genau **1**

**Suspicious:** sichtbarer Parent, mehrere Instanzen, anderer Image Path, Tippfehler

---

#### ==services.exe — Service Control Manager (SCM)==

- Verwaltet alle Windows-Dienste: laden, starten, stoppen, interagieren
- Speichert Dienstinformationen in `HKLM\System\CurrentControlSet\Services`
- Abfragbar über `sc.exe`
- Wichtige Child-Prozesse: `svchost.exe`, `spoolsv.exe`, `msmpeng.exe`, `dllhost.exe`
- Parent: `wininit.exe`
- Image Path: `C:\Windows\System32\services.exe`
- User: `NT AUTHORITY\SYSTEM`
- Instanzen: genau **1**

**Suspicious:** Parent ≠ wininit.exe, mehrere Instanzen, anderer Image Path

---

#### ==svchost.exe — Service Host==

- Hostet Windows-Dienste, die als DLLs implementiert sind
- **Immer** mit `-k`-Parameter gestartet, der Dienste in Gruppen zusammenfasst
  - Beispiel: `C:\Windows\System32\svchost.exe -k DcomLaunch`
  - Ab Windows 10 (>3,5 GB RAM): jeder Dienst läuft in eigenem Prozess
- Parent: immer `services.exe`
- User: `NT AUTHORITY\SYSTEM`, `LOCAL SERVICE` oder `NETWORK SERVICE`
- Instanzen: **viele** — das ist normal

**Suspicious:**
- Kein `-k`-Parameter in der Command Line
- Parent ≠ services.exe
- Tippfehler (`scvhost.exe`, `svch0st.exe`)
- User außerhalb der drei erlaubten Konten
- Image Path außerhalb `C:\Windows\System32\`

> [!warning] Angreifer-Taktik: svchost
> Malware benennt sich `svchost.exe` oder leicht abweichend und läuft dann nicht als Kind von `services.exe`. Alternativ: Malware registriert sich als Dienst-DLL und wird über ein legitimes `svchost.exe` geladen. Der fehlende `-k`-Parameter ist der zuverlässigste Indikator.

---

#### ==lsass.exe — Local Security Authority Subsystem Service==

- Erzwingt die Windows-Sicherheitsrichtlinie
- Verifiziert Logins, verwaltet Passwortänderungen, erstellt Access Tokens
- Schreibt ins **Windows Security Log**
- Erstellt Security Tokens für SAM, Active Directory, NETLOGON
- Konfig-Registry: `HKLM\System\CurrentControlSet\Control\Lsa`
- Parent: `wininit.exe`
- Image Path: `C:\Windows\System32\lsass.exe`
- User: `NT AUTHORITY\SYSTEM`
- Instanzen: genau **1**

**Suspicious:** Parent ≠ wininit.exe, mehrere Instanzen, Tippfehler (`lass.exe`, `lssass.exe`, `lsasss.exe`)

> [!warning] Angreifer-Taktik: lsass
> `lsass.exe` ist das primäre Ziel für **Credential Dumping**. Tools wie **Mimikatz** (`sekurlsa::logonpasswords`) greifen auf den Speicher dieses Prozesses zu, um Password-Hashes oder Klartextpasswörter zu extrahieren. Erkennbar via Sysmon EID 10 (Process Access auf lsass als TargetImage).

---

#### ==winlogon.exe — Windows Logon Process==

- Verarbeitet die **Secure Attention Sequence** (STRG+ALT+ENTF)
- Lädt das User-Profil (`NTUSER.DAT` → `HKCU`)
- Startet `userinit.exe`, das die User-Shell lädt
- Zuständig für Bildschirm sperren, Screensaver
- Parent: de facto kein sichtbarer Parent (smss.exe terminiert sich)
- Image Path: `C:\Windows\System32\winlogon.exe`
- User: `NT AUTHORITY\SYSTEM`
- Instanzen: **eine pro User-Session**

**Suspicious:** identifizierbarer Parent ≠ smss.exe, Tippfehler (`winnlogon.exe`), Shell-Registry-Wert ≠ `explorer.exe`

---

#### ==explorer.exe — Windows Explorer==

- Stellt die grafische Benutzeroberfläche bereit: Taskbar, Desktop, Datei-Explorer
- Parent: `userinit.exe` (terminiert sich danach → kein sichtbarer Parent)
- Image Path: `C:\Windows\explorer.exe`
- User: der eingeloggte User (nicht SYSTEM)
- Instanzen: **eine pro eingeloggtem User**

**Suspicious:** Parent ≠ userinit.exe, läuft als SYSTEM, mehrere Instanzen unter demselben User, anderer Image Path

---

### Angreifer-Muster auf einen Blick

| Technik | Beschreibung |
|---------|-------------|
| **Masquerading** | Malware nennt sich wie ein Systemprozess (`svchost.exe`, `lsass.exe`) oder verwendet Tippfehler |
| **Falscher Image Path** | Prozess heißt richtig, läuft aber aus `C:\Users\` statt `C:\Windows\System32\` |
| **Falscher Parent** | `svchost.exe` läuft nicht als Kind von `services.exe` → Alarmsignal |
| **Falsche Instanzanzahl** | Zweite `lsass.exe` oder zweite `services.exe` |
| **Credential Dumping** | Zugriff auf `lsass.exe`-Speicher via Mimikatz → Hashes extrahieren |
| **DLL-Injection via svchost** | Malware registriert sich als Dienst-DLL, wird über legitimes `svchost.exe` geladen |
| **Process Hollowing** | Legitimer Prozess wird gestartet, sein Code durch Malware ersetzt |

---

## Raum 2: Windows Event Logs

### Was sind Windows Event Logs?

Windows protokolliert nahezu jede Systemaktivität in strukturierten Event Logs. Für SOC-Analysten sind das die primären Datenquellen, bevor Sysmon oder externe Tools ins Spiel kommen.

Log-Dateien liegen in: `C:\Windows\System32\winevt\Logs\`

#### Log-Kategorien

| Log | Inhalt |
|-----|--------|
| **Application** | Events von Anwendungen und Programmen |
| **System** | Events des Windows-Betriebssystems und Treiber |
| **Security** | Login-Events, Audit-Events, Zugriffsversuche |
| **Setup** | Windows-Installations- und Update-Events |
| **Forwarded Events** | Von Remote-Systemen weitergeleitete Events |

Zusätzlich: `Applications and Services Logs` — anwendungsspezifische Logs, darunter auch das **Sysmon Operational Log** (`Microsoft-Windows-Sysmon/Operational`).

---

> [!example] Tools — Windows Event Logs
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **Event Viewer** (`eventvwr.msc`) | GUI (built-in) | Native Log-Analyse; Filter, Custom Views, EVTX-Dateien öffnen, Remote-Verbindung |
> | **wevtutil** | CLI (built-in) | Log-Abfragen, Export, Log-Management aus der Kommandozeile |
> | **Get-WinEvent** | PowerShell | Flexibles Querying mit FilterHashtable oder XPath; bevorzugtes Tool für SOC-Arbeit |
> | **Get-EventLog** | PowerShell (legacy) | Älter, weniger flexibel — durch Get-WinEvent ersetzt |
> | **CyberChef** | Web | Encodierte PowerShell-Payloads aus EID 4104 dekodieren (Base64, etc.) |

### Tools zum Lesen von Event Logs im Detail

#### Event Viewer (GUI)
- Integriert in Windows, keine Installation nötig
- Nützliche Features:
  - **Filter Current Log** — Event-ID-spezifische Filter
  - **Create Custom View** — Wiederverwendbare Filter über mehrere Logs hinweg
  - **Open Saved Log** — EVTX-Datei offline analysieren (wichtig für Forensik)
  - Verbindung zu Remote-Computer möglich

#### wevtutil (Kommandozeile)
```cmd
# Events aus einem Log auflisten
wevtutil qe Security /c:10 /rd:true /f:text

# Log-Metadaten anzeigen
wevtutil gl Security

# Verfügbare Logs auflisten
wevtutil el

# Log leeren (Angreifer nutzen das — EID 1102 wird dabei generiert)
wevtutil cl Security
```

#### Get-WinEvent (PowerShell)
```powershell
# Letzte 50 Events aus Security-Log
Get-WinEvent -LogName Security -MaxEvents 50

# Nach Event-ID filtern
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625}

# EVTX-Datei offline lesen
Get-WinEvent -Path C:\Logs\Security.evtx

# XPath-Query für gezielte Suche
Get-WinEvent -LogName Security -FilterXPath '*/System/EventID=4624'

# Alle verfügbaren Logs anzeigen
Get-WinEvent -ListLog *
```

> `Get-WinEvent` ist flexibler als das ältere `Get-EventLog` und das bevorzugte Tool für SOC-Arbeit. XPath-Queries lassen sich direkt aus Event Viewer kopieren und in PowerShell verwenden.

---

### Wichtige Security Event IDs

| Event ID | Beschreibung | SOC-Relevanz |
|----------|-------------|--------------|
| **4624** | Erfolgreicher Login | Baseline-Event; bei Anomalien: ungewöhnliche Uhrzeiten, Logon Type 3/10 |
| **4625** | Fehlgeschlagener Login | Brute Force, Password Spraying — viele 4625 auf einen Account |
| **4648** | Login mit expliziten Credentials | Lateral Movement — Credential-Nutzung außerhalb normaler Sitzung |
| **4672** | Privilegiertes Konto hat sich eingeloggt | Admin-Login-Tracking |
| **4688** | Prozess wurde erstellt | Command-Line-Auditing (muss aktiviert sein) |
| **4698** | Scheduled Task erstellt | Persistenz-Technik |
| **4699** | Scheduled Task gelöscht | Cleanup nach Kompromittierung |
| **4700/4701** | Scheduled Task aktiviert/deaktiviert | |
| **4720** | User-Account erstellt | Backdoor-Account-Erkennung |
| **4722** | User-Account aktiviert | |
| **4725** | User-Account deaktiviert | |
| **4726** | User-Account gelöscht | |
| **4732** | User zu lokaler Gruppe hinzugefügt | Privilege Escalation |
| **4756** | User zu globaler Gruppe hinzugefügt | |
| **7034** | Dienst unerwartet beendet | |
| **7045** | Neuer Dienst installiert | Persistence — häufig bei Malware |
| **1102** | Audit-Log gecleart | Indikator für Vertuschungsversuch |

#### Windows Logon Types

| Type | Name | Beschreibung |
|------|------|-------------|
| 2 | Interactive | Physischer Login an der Konsole |
| 3 | Network | Netzwerk-Login (z.B. SMB, IPC$) |
| 4 | Batch | Scheduled Tasks |
| 5 | Service | Dienst-Login |
| 7 | Unlock | Bildschirm entsperren |
| 8 | NetworkCleartext | Klartextpasswort über Netzwerk |
| 9 | NewCredentials | `runas /netonly` — lokaler Token, neue Netz-Credentials |
| 10 | RemoteInteractive | RDP |
| 11 | CachedInteractive | Login mit gecachten Credentials (offline) |

---

### PowerShell Logging

PowerShell ist für Angreifer attraktiv, weil viele Aktionen in einer einzigen Prozess-Session ablaufen — Sysmon sieht nur den Start von `powershell.exe`, nicht die einzelnen Befehle. Dafür gibt es drei relevante Log-Quellen:

> [!example] Tools — PowerShell Logging
> | Tool / Quelle | Zweck |
> |---------------|-------|
> | **ConsoleHost_history.txt** | Automatisches History-File; kein Setup nötig; enthält jeden eingegebenen Befehl |
> | **Event ID 4104** (Script Block Logging) | Vollständiger PowerShell-Code bei Ausführung; via Group Policy aktivieren |
> | **Get-WinEvent** | Zum Abfragen von EID 4104 aus `Microsoft-Windows-PowerShell/Operational` |
> | **CyberChef** | Base64-encodierte Payloads aus EID 4104 ScriptBlockText dekodieren |

#### PowerShell History File
```
C:\Users\<USER>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
```
Automatisch erstellt, jeder eingegebene Befehl wird gespeichert. Keine Konfiguration nötig.

#### Event ID 4104 — Script Block Logging
- Loggt den **vollständigen PowerShell-Code** bei Ausführung
- Aktivierung: via Group Policy (`Windows PowerShell → Turn on PowerShell Script Block Logging`)
- Log-Kanal: `Microsoft-Windows-PowerShell/Operational`
- Wichtig für Malware-Analyse: encodierte Payloads werden hier im Klartext geloggt (nach Ausführung)

```powershell
# Nach Event 4104 filtern
Get-WinEvent -LogName 'Microsoft-Windows-PowerShell/Operational' -FilterXPath '*/System/EventID=4104'
```

#### Downgrade Attacks
Angreifer können PowerShell auf Version 2 downgraden, die kein Script Block Logging unterstützt:
```powershell
powershell -Version 2 -Command "..."
```
Erkennbar an: plötzliche PowerShell v2-Aktivität auf Systemen, auf denen normalerweise v5 läuft.

---

### Log-Korrelation als SOC-Skill

Einzelne Events geben selten das vollständige Bild. Typische Korrelations-Patterns:

- **Brute Force:** Viele `4625` auf denselben Account → dann eine `4624` → dann `4672`
- **Lateral Movement:** `4648` (explizite Credentials) + `4624 Logon Type 3` auf Remote-Host
- **Persistence:** `4698` (Task erstellt) + `4688` (Prozess gestartet via Task) + `7045` (Dienst installiert)
- **Cleanup:** `1102` (Log gecleart) → immer verdächtig

---

## Raum 3: Sysmon

### Was ist Sysmon?

System Monitor (Sysmon) ist ein Windows-Dienst + Kernel-Treiber aus dem **Sysinternals-Paket** (Microsoft). Es läuft über Neustarts hinaus persistent, loggt System-Aktivitäten in das Windows Event Log und überlebt auch dann, wenn normale Security-Logs gecleart werden.

Sysmon liefert, was die Standard-Security-Logs nicht bieten:
- Vollständige Command Lines bei Prozessstart
- Parent-Child-Prozess-Beziehungen mit GUID-Tracking
- Netzwerkverbindungen inkl. Quellprozess
- File Creation Timestamps (auch Manipulation davon)
- Registry-Änderungen
- DLL-Loads, Treiber-Loads
- Process Injection Detection

> [!example] Tools — Sysmon
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **Sysmon** (`sysmon.exe`) | Dienst + Treiber (Sysinternals) | Erweiterte Endpoint-Telemetrie; Installation, Config-Laden, Deinstallation |
> | **Event Viewer** | GUI (built-in) | Sysmon-Events unter `Microsoft-Windows-Sysmon/Operational` lesen |
> | **Get-WinEvent** | PowerShell | Sysmon-Events per XPath-Query abfragen und korrelieren |
> | **SwiftOnSecurity sysmon-config** | XML-Config | Fertige, breit genutzte Sysmon-Konfiguration mit guten Exclude-Regeln |
> | **sysmon-modular** (Olaf Hartong) | XML-Config | Modulare Sysmon-Config; leicht anpassbar, gut für SOC-Teams |

**Installation und Verwaltung:**
```cmd
sysmon -accepteula -i sysmonconfig.xml   # Installieren mit Config
sysmon -c sysmonconfig.xml               # Config neu laden (ohne Neustart)
sysmon -c                                # Aktuelle Config anzeigen
sysmon -u                                # Deinstallieren
```

Log-Kanal: `Applications and Services Logs → Microsoft → Windows → Sysmon → Operational`

---

### Sysmon Event IDs — Übersicht

| Event ID | Name | Beschreibung | SOC-Priorität |
|----------|------|-------------|---------------|
| **1** | Process Creation | Neuer Prozess: Image, CommandLine, ParentImage, Hashes, User | ⭐⭐⭐ hoch |
| **2** | File Creation Time Changed | Timestamp-Manipulation — Malware deckt Spuren | mittel |
| **3** | Network Connection | TCP/UDP-Verbindungen inkl. Prozess, IP, Port | ⭐⭐⭐ hoch (disabled by default) |
| **4** | Sysmon Service State Changed | Sysmon gestartet/gestoppt | hoch |
| **5** | Process Terminated | Prozess beendet | niedrig |
| **6** | Driver Loaded | Kernel-Treiber geladen: Signatur, Hash | hoch |
| **7** | Image Loaded | DLL in Prozess geladen | mittel (sehr laut) |
| **8** | CreateRemoteThread | Prozess erstellt Thread in anderem Prozess | ⭐⭐⭐ hoch — Process Injection |
| **9** | RawAccessRead | Roher Disk-Lesezugriff (MBR-Manipulation) | hoch |
| **10** | Process Access | Prozess öffnet anderen Prozess (LSASS-Dumping!) | ⭐⭐⭐ hoch |
| **11** | File Created | Datei erstellt/überschrieben | mittel |
| **12** | Registry Object Add/Delete | Registry-Key erstellt/gelöscht | mittel |
| **13** | Registry Value Set | Registry-Wert gesetzt | mittel |
| **14** | Registry Object Renamed | Registry-Key umbenannt | mittel |
| **15** | File Stream Created | ADS (Alternate Data Stream) — Zone.Identifier, Browser-Downloads | mittel |
| **16** | Sysmon Config Changed | Konfiguration geändert | hoch |
| **17** | Pipe Created | Named Pipe erstellt (Malware-IPC) | mittel |
| **18** | Pipe Connected | Named Pipe verbunden | mittel |
| **19–21** | WMI Events | WMI Filter/Consumer/Binding registriert — Fileless Persistence | hoch |
| **22** | DNS Query | DNS-Anfrage eines Prozesses | mittel (sehr laut) |
| **23** | File Deleted | Datei gelöscht (archiviert in `C:\Sysmon\`) | mittel |
| **25** | Process Tampering | Process Hollowing / Herpaderp erkannt | ⭐⭐⭐ hoch |
| **26** | File Delete Detected | Wie ID 23, ohne Archivierung | mittel |
| **27** | File Block Executable | Ausführbare Datei blockiert | hoch |
| **29** | File Executable Detected | Ausführbare Datei erstellt | hoch |

---

### Die wichtigsten Event IDs im Detail

#### EID 1 — Process Creation (der Brot-und-Butter-Event)

Enthält alles, was man über einen Prozessstart wissen möchte:
- `Image` — vollständiger Pfad der ausführbaren Datei
- `CommandLine` — mit allen Parametern
- `ParentImage` + `ParentCommandLine` — woher der Prozess kam
- `ProcessGuid` + `ParentProcessGuid` — Korrelations-IDs, die PIDs eindeutig machen
- `Hashes` — MD5, SHA1, SHA256, IMPHASH
- `User` — unter welchem Konto gestartet

**Erkennungs-Beispiele:**
- `cmd.exe` als Child von `outlook.exe` → Phishing-Makro
- `powershell.exe` mit `-EncodedCommand` → obfuskiertes Skript
- `svchost.exe` ohne `-k`-Parameter

#### EID 3 — Network Connection

Standardmäßig deaktiviert (zu laut). Wenn aktiviert: welcher Prozess baut welche Verbindung auf, zu welcher IP/Port.

```powershell
# Verbindungen auf Port 4444 (Metasploit-Default)
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/System/EventID=3 and */EventData/Data[@Name="DestinationPort"]="4444"'
```

#### EID 8 — CreateRemoteThread (Process Injection)

Niedriges Volumen, hohes Signal. Wenn Prozess A einen Thread in Prozess B erstellt, ist das ein starker Indikator für Injection-Techniken.

#### EID 10 — Process Access (LSASS Dumping)

Zugriff von Prozess A auf Prozess B. Kritisch: jeder Prozess, der `lsass.exe` mit `GrantedAccess`-Flags öffnet, die Memory-Reads erlauben.

```powershell
# LSASS-Zugriffe überwachen
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/System/EventID=10 and */EventData/Data[@Name="TargetImage"]="C:\Windows\System32\lsass.exe"'
```

#### EID 15 — File Stream Created (ADS)

Alternate Data Streams werden von Malware genutzt, um Dateien zu verstecken. `Zone.Identifier` ist der ADS, den Browser bei Downloads setzen — kann auch als Tracking-Artefakt für Browser-Downloads verwendet werden.

#### EID 22 — DNS Query

Welcher Prozess fragt welche Domain an. Nützlich für C2-Traffic-Erkennung, aber laut. Empfehlung: bekannte Domains ausschließen, Rest loggen.

---

### Sysmon Konfiguration

Sysmon ohne Config ist blind. Die Config-Datei (XML) steuert, welche Events geloggt werden und welche ausgeschlossen werden.

**Include vs. Exclude:**
- Meiste Regeln sind **Excludes** — bekannte legitime Aktivität rausfiltern
- Wenige präzise **Includes** — spezifische Angriffsmuster erkennen

**Empfohlene Community-Configs:**
- **SwiftOnSecurity** (`sysmon-config`) — gut abgestimmte Exclude-Logik, weit verbreitet
- **sysmon-modular** (Olaf Hartong) — modularer Aufbau, leicht anpassbar

```xml
<!-- Beispiel: svchost.exe ohne -k erkennen -->
<ProcessCreate onmatch="include">
  <Image condition="is">C:\Windows\System32\svchost.exe</Image>
  <CommandLine condition="not contains">-k</CommandLine>
</ProcessCreate>

<!-- Beispiel: LSASS-Zugriffe loggen, außer von svchost.exe -->
<ProcessAccess onmatch="include">
  <TargetImage condition="is">C:\Windows\System32\lsass.exe</TargetImage>
</ProcessAccess>
<ProcessAccess onmatch="exclude">
  <SourceImage condition="is">C:\Windows\System32\svchost.exe</SourceImage>
</ProcessAccess>
```

---

### Sysmon-Queries mit PowerShell

```powershell
# Alle Sysmon-Events der letzten 24h
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/System/TimeCreated[timediff(@SystemTime) <= 86400000]'

# Process Creation nach spezifischem Image filtern
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/System/EventID=1 and */EventData/Data[@Name="Image"]="C:\Windows\System32\cmd.exe"'

# Netzwerkverbindungen eines bestimmten Prozesses
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/System/EventID=3 and */EventData/Data[@Name="Image"]="C:\Windows\System32\powershell.exe"'

# Alle Events eines Prozesses über seine GUID korrelieren
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' `
  -FilterXPath '*/EventData/Data[@Name="ProcessGuid"]="{GUID}"'
```

---

## Windows Logging for SOC — Was das alles zusammenhält

Die drei Räume bauen aufeinander auf:

1. **Core Windows Processes** → Baseline: Was ist normal? Welche Prozesse, welche Parents, welche Pfade?
2. **Windows Event Logs** → Die nativen Log-Quellen: Security-Events, PowerShell-Logging, welche IDs wann relevant sind
3. **Sysmon** → Die erweiterte Telemetrie: mehr Kontext, mehr Details, bessere Korrelation

Erst zusammen ergibt sich ein vollständiges Bild. Beispiel-Angriffskette und wie die Logs sie zeigen:

| Schritt | Was passiert | Log-Quelle | Tool |
|---------|-------------|-----------|------|
| Phishing-Mail mit Makro | `winword.exe` → `cmd.exe` → `powershell.exe` | Sysmon EID 1 | Get-WinEvent / Event Viewer |
| Encoded Payload läuft | PowerShell mit `-EncodedCommand` | EID 4104 (Script Block Logging) | Get-WinEvent + CyberChef |
| Reverse Shell baut Verbindung | Ausgehende Verbindung auf Port 4444 | Sysmon EID 3 | Get-WinEvent |
| LSASS-Dump via Mimikatz | Prozess öffnet `lsass.exe` mit Memory-Read-Rechten | Sysmon EID 10 | Get-WinEvent / Process Explorer |
| Neuer Admin-Account erstellt | `net user /add` | Windows EID 4720 + 4732 | Event Viewer / Get-WinEvent |
| Scheduled Task für Persistenz | Task angelegt | Windows EID 4698, Sysmon EID 11 | Event Viewer |
| Logs gecleart | `wevtutil cl Security` | Windows EID 1102 | Event Viewer |

---

## Tools-Übersicht

| Tool | Raum | Typ | Zweck |
|------|------|-----|-------|
| **Task Manager** | Raum 1 | GUI (built-in) | Schneller Überblick laufender Prozesse |
| **Process Explorer** | Raum 1 | GUI (Sysinternals) | Prozessbaum, Image Path, Parent-Child, DLLs |
| **Process Hacker** | Raum 1 | GUI (Open Source) | Wie Process Explorer, mehr Memory-Details |
| **sc.exe** | Raum 1 | CLI (built-in) | SCM und Services abfragen |
| **tasklist** | Raum 1 | CLI (built-in) | Prozessliste mit PIDs |
| **Get-Process** | Raum 1 | PowerShell | Prozessliste skriptfähig |
| **Event Viewer** | Raum 2 + 3 | GUI (built-in) | Native Log-Analyse, EVTX offline öffnen |
| **wevtutil** | Raum 2 | CLI (built-in) | Event-Log-Abfragen und -Management |
| **Get-WinEvent** | Raum 2 + 3 | PowerShell | Flexibles Log-Querying mit XPath |
| **CyberChef** | Raum 2 | Web | Base64-Payloads aus EID 4104 dekodieren |
| **Sysmon** | Raum 3 | Dienst + Treiber | Erweiterte Endpoint-Telemetrie |
| **SwiftOnSecurity Config** | Raum 3 | XML-Config | Fertige Sysmon-Konfiguration |
| **sysmon-modular** | Raum 3 | XML-Config | Modulare Sysmon-Konfiguration |

---

## Bezug zu anderen Themen

- [[Detecting Web Shells]] — Webshell-Erkennung via Logs; dort manuell mit `grep`, hier mit Sysmon automatisiert
- [[Detecting Web Attacks]] — Log-Analyse als gemeinsame Grundlage; Windows-Logs ergänzen Web-Server-Logs
- [[CHEAT SHEETS/PowerShell-Commands]] — `Get-WinEvent` und XPath-Queries; PowerShell als primäres Log-Analyse-Tool
- [[CHEAT SHEETS/Splunk SPL Cheat Sheet]] — Sysmon-Events und Windows-Security-Logs landen im SIEM; dort werden sie via SPL abgefragt
- [[CHEAT SHEETS/grep & Regex Cheat Sheet]] — Analoge Muster-Suche in Linux-Logs; Windows hat Get-WinEvent als Pendant
- [[CIA-Triad]] — Sysmon adressiert primär **Confidentiality** (Credential-Dumping-Erkennung) und **Integrity** (Process Tampering, Timestamp-Manipulation)

---

## Referenzen

- [TryHackMe — Core Windows Processes](https://tryhackme.com/room/btwindowsinternals)
- [TryHackMe — Windows Event Logs](https://tryhackme.com/room/windowseventlogs)
- [TryHackMe — Sysmon](https://tryhackme.com/room/sysmon)
- [TryHackMe — Windows Logging for SOC](https://tryhackme.com/room/windowsloggingforsoc)
- [Microsoft — Sysmon Documentation](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)
- [Microsoft — Sysmon Event Reference](https://learn.microsoft.com/en-us/windows/security/operating-system-security/sysmon/sysmon-events)
- [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
- [sysmon-modular (Olaf Hartong)](https://github.com/olafhartong/sysmon-modular)
- [NAS Bench — Windows System Processes for Blue Teams](https://nasbench.medium.com/windows-system-processes-an-overview-for-blue-teams-42fa7a617920)
