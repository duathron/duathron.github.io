---
title: "Splunk SPL Cheat Sheet"
tags: [splunk, spl, siem, log-analysis, blue-team, soc, cheatsheet]
---

# Splunk SPL Cheat Sheet

SPL = **S**earch **P**rocessing **L**anguage — the query language used in Splunk to search, filter, and analyse indexed data.

```
index=<index> [sourcetype=<type>] [keyword] [field=value] | command1 | command2 ...
```

> [!example] Tools — Splunk
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **Splunk Web** | GUI | Hauptoberfläche: Search & Reporting, Dashboards, Alerts |
> | **SPL** | Query Language | Suchen, Filtern, Aggregieren und Visualisieren von Log-Daten |
> | **Splunk ESCU** | Detection Content | Fertige Detection Searches für SOC-Use-Cases |
> | **Boss of the SOC** | Übungsdatensatz | Reale Angriffsdaten für SPL-Praxis |
> | **regex101.com** | Web | PCRE-Tester für `rex`-Patterns in SPL |

---

## ==Core Concepts==

### How Splunk Structures Data

| Concept | Meaning |
|---------|---------|
| **Event** | A single indexed entry — one log line, one record, with a timestamp |
| **Index** | Named storage bucket. Default index is `main`. Windows logs often go to `wineventlog`. |
| **Sourcetype** | Defines the format/parser for data. Examples: `WinEventLog:Security`, `syslog`, `access_combined` |
| **Source** | The file or input path the data came from |
| **Host** | The machine that generated the event |
| **Field** | A named value extracted from events |
| **`_raw`** | The original, unmodified event text |
| **`_time`** | The event timestamp in UNIX format |

### SPL Pipeline Logic

```splunk
index=web_logs sourcetype=access_combined status=404
| stats count by src_ip
| sort -count
| head 10
```

> [!info] Pipeline-Logik
> Von links nach rechts lesen: Daten holen → nach Feld aggregieren → absteigend sortieren → Top 10 ausgeben. Jedes `|` leitet das Ergebnis an den nächsten Befehl weiter. Der erste Teil vor dem ersten `|` definiert immer den Daten-Scope.

---

## ==Search Basics==

### Selecting Data

```splunk
index=main                            # search the main index
index=*                               # all non-internal indexes
index=main OR index=web               # multiple indexes
sourcetype="WinEventLog:Security"
host="dc01.corp.local"
source="/var/log/auth.log"
```

### Keyword and Field Searches

```splunk
index=main failed login               # implicit AND
index=main "failed login"             # exact phrase
index=main failed OR error
index=main failed NOT debug
index=main status=404
index=main status!=200
index=main status>400
index=main src_ip=10.0.0.*            # wildcard
index=main user=admin*
index=main (failed OR error) user=*
```

> [!tip] Implicit AND
> Splunk behandelt ein Leerzeichen zwischen Begriffen als AND. `failed login` = Ereignisse, die beide Wörter enthalten. `AND` kann explizit geschrieben werden, ist aber nicht nötig.

---

## ==Time Modifiers==

### Syntax

```
earliest=<time> latest=<time>
```

### Relative Time Units

| Unit | Meaning | | Unit | Meaning |
|------|---------|--|------|---------|
| `s` | seconds | | `d` | days |
| `m` | minutes | | `w` | weeks |
| `h` | hours | | `mon` | months |

`@` rounds down to the nearest unit boundary: `@d` = midnight, `@h` = current hour start, `@mon` = month start.

### Examples

```splunk
earliest=-24h latest=now
earliest=-7d latest=now
earliest=@d                                                          # from midnight today
earliest=-30d@d latest=@d                                            # last 30 full days
earliest="04/19/2024:00:00:00" latest="04/20/2024:00:00:00"
earliest=1                                                           # all time
```

---

## ==Essential SPL Commands==

### ==Filtering & Selecting==

| Command | Syntax | Description |
|---------|--------|-------------|
| `search` | `\| search keyword` | Filter by keyword or field |
| `where` | `\| where field > 100` | Filter using eval-style expressions |
| `regex` | `\| regex field="pattern"` | Filter by regex |
| `fields` | `\| fields src_ip, status` | Keep only specified fields |
| `fields -` | `\| fields - _raw` | Remove specified fields |
| `dedup` | `\| dedup src_ip` | Remove duplicates |
| `head` | `\| head 20` | First N results |
| `tail` | `\| tail 20` | Last N results |

### ==Sorting & Outputting==

| Command | Syntax | Description |
|---------|--------|-------------|
| `sort` | `\| sort -count` | Sort. `-` = descending |
| `table` | `\| table _time, src_ip` | Display as formatted table |
| `rename` | `\| rename src_ip AS "Source IP"` | Rename field |

### ==Statistics==

| Command | Syntax | Description |
|---------|--------|-------------|
| `stats` | `\| stats count by src_ip` | Aggregate, grouped by field |
| `top` | `\| top limit=10 user` | Most common values |
| `rare` | `\| rare limit=5 user` | Least common values |
| `timechart` | `\| timechart span=1h count by status` | Count over time |
| `chart` | `\| chart count by host, status` | Chart table |
| `eventstats` | `\| eventstats avg(count) as avg` | Add aggregate stats back to each row |

#### Common `stats` Functions

| Function | Meaning | Example |
|----------|---------|---------|
| `count` | Number of events | `stats count by user` |
| `dc(field)` | Distinct count | `stats dc(user) by src_ip` |
| `sum(field)` | Sum of numeric field | `stats sum(bytes) by host` |
| `avg(field)` | Average | `stats avg(duration) by service` |
| `max(field)` | Maximum value | `stats max(bytes) by src_ip` |
| `min(field)` | Minimum value | `stats min(_time) by user` |
| `values(field)` | All distinct values as list | `stats values(src_ip) by user` |
| `earliest(field)` | Chronologically first | `stats earliest(_time) by user` |
| `latest(field)` | Chronologically last | `stats latest(src_ip) by user` |

```splunk
| stats count AS total, dc(src_ip) AS unique_ips, max(bytes) AS max_bytes by host
| timechart span=1h count by status
```

### ==Field Extraction==

| Command | Syntax | Description |
|---------|--------|-------------|
| `rex` | `\| rex "(?P<name>pattern)"` | Extract fields via named capture groups aus `_raw` |
| `rex field=` | `\| rex field=url "(?P<path>/[^?]+)"` | Extract aus spezifischem Feld |
| `rex mode=sed` | `\| rex mode=sed field=x "s/old/new/g"` | Find-and-replace |

```splunk
| rex "Failed password for (?P<username>\S+) from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| rex "\"(?P<method>GET|POST|PUT|DELETE) (?P<path>/[^ ]+)"
```

> [!tip] `rex` Named Capture Groups
> `(?P<fieldname>pattern)` — Splunk erstellt daraus ein neues Feld mit dem extrahierten Wert. Das Default-Feld ist `_raw`; für andere Felder: `field=<feldname>`.

### ==Computed Fields (`eval`)==

| Function | Meaning | Example |
|----------|---------|---------|
| `if(cond, a, b)` | Conditional | `eval result = if(status==200, "ok", "fail")` |
| `case(c1,v1,...)` | Multi-condition switch | `eval level = case(status<400,"ok", 1==1,"error")` |
| `lower(field)` / `upper(field)` | Case conversion | `eval user = lower(user)` |
| `len(field)` | String length | `eval url_len = len(url)` |
| `round(n, dec)` | Round number | `eval mb = round(bytes/1024/1024, 2)` |
| `strftime(_time, fmt)` | Format timestamp | `eval ts = strftime(_time, "%Y-%m-%d %H:%M")` |
| `cidrmatch("net", ip)` | IP in CIDR range? | `eval internal = cidrmatch("10.0.0.0/8", src_ip)` |
| `now()` | Current UNIX timestamp | `eval age = now() - _time` |

```splunk
| eval status_class = case(
    status >= 500, "Server Error",
    status >= 400, "Client Error",
    status >= 200, "Success",
    1==1, "Unknown"
  )

| eval network = if(cidrmatch("10.0.0.0/8", src_ip), "internal", "external")
```

---

## ==Important Default Fields==

| Field | Meaning |
|-------|---------|
| `_time` | Event timestamp (UNIX) |
| `_raw` | Original raw event text |
| `_indextime` | When the event was indexed |
| `host` | Hostname that sent the event |
| `source` | Source file or input |
| `sourcetype` | Parser/format identifier |
| `index` | Index the event lives in |

---

## ==Windows Event IDs (Key Reference)==

| EventCode | Meaning |
|-----------|---------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4648 | Logon using explicit credentials (RunAs) |
| 4672 | Special privileges assigned (admin logon) |
| 4688 | New process created |
| 4698 | Scheduled task created |
| 4699 | Scheduled task deleted |
| 4700 | Scheduled task enabled |
| 4720 | User account created |
| 4722 | User account enabled |
| 4725 | User account disabled |
| 4726 | User account deleted |
| 4732 | User added to local security group |
| 4756 | User added to universal security group |
| 7034 | Service crashed unexpectedly |
| 7045 | New service installed |
| 1102 | Audit log cleared |
| 4104 | PowerShell script block logged |
| 4103 | PowerShell module logged |

### Windows Logon Types

| Code | Type | Description |
|------|------|-------------|
| 2 | Interactive | Local keyboard/console login |
| 3 | Network | Network-based login (SMB etc.) |
| 4 | Batch | Scheduled task / batch job |
| 5 | Service | Service account login |
| 7 | Unlock | Screen unlock |
| 8 | NetworkCleartext | Network login with plaintext credentials |
| 9 | NewCredentials | RunAs with different credentials |
| 10 | RemoteInteractive | RDP / Terminal Services |
| 11 | CachedInteractive | Cached domain credentials (offline) |

---

## ==Blue Team Recipes==

### Authentication — Brute Force & Credential Attacks

```splunk
--- Failed logons by user ---
index=wineventlog EventCode=4625 earliest=-24h
| stats count by Account_Name, Source_Network_Address, Failure_Reason
| sort -count

--- IPs with >10 failed logons ---
index=wineventlog EventCode=4625 earliest=-1h
| stats count by Source_Network_Address
| where count > 10

--- Password spray: many users from one IP ---
index=wineventlog EventCode=4625 Logon_Type=3 earliest=-1h
| stats dc(Account_Name) AS unique_users count AS attempts by Source_Network_Address
| where unique_users > 10

--- Successful logon after multiple failures ---
index=wineventlog (EventCode=4625 OR EventCode=4624) earliest=-6h
| stats count(eval(EventCode=4625)) AS failures, count(eval(EventCode=4624)) AS successes by Account_Name, Source_Network_Address
| where failures > 5 AND successes > 0
```

### Process & Execution

```splunk
--- PowerShell script block logging ---
index=wineventlog EventCode=4104 earliest=-24h
| table _time, Computer, Account_Name, ScriptBlockText

--- Encoded PowerShell (obfuscation indicator) ---
index=wineventlog EventCode=4688 Process_Name="*powershell*" earliest=-24h
| search Creator_Process_Command="*-enc*" OR Creator_Process_Command="*-encodedcommand*"
| table _time, Computer, Account_Name, Creator_Process_Command

--- Suspicious child processes (Office → shell) ---
index=wineventlog EventCode=4688 earliest=-24h
| where match(Creator_Process_Name, "(?i)(winword|excel|outlook|powerpnt)")
  AND match(Process_Name, "(?i)(cmd|powershell|wscript|cscript|mshta)")
| table _time, Computer, Creator_Process_Name, Process_Name, Account_Name
```

### Persistence & Lateral Movement

```splunk
--- New scheduled tasks ---
index=wineventlog EventCode=4698 earliest=-24h
| table _time, Computer, Account_Name, Task_Name

--- New services installed ---
index=wineventlog EventCode=7045 earliest=-24h
| table _time, host, Service_Name, Service_File_Name, Service_Account

--- User added to admin group ---
index=wineventlog (EventCode=4732 OR EventCode=4756) earliest=-7d
| search Group_Name="*admin*"
| table _time, Computer, SubjectUserName, MemberName, Group_Name

--- Audit log cleared ---
index=wineventlog EventCode=1102 earliest=-30d
| table _time, host, SubjectUserName
```

### Web Log Analysis

```splunk
--- Top source IPs ---
index=web sourcetype=access_combined earliest=-24h
| stats count by clientip | sort -count | head 20

--- Directory traversal ---
index=web sourcetype=access_combined earliest=-24h
| regex uri="\.\./|%2e%2e%2f"
| table _time, clientip, method, uri, status

--- SQL injection patterns ---
index=web sourcetype=access_combined earliest=-24h
| regex uri="(?i)(union.*select|select.*from|'--|\bor\b.*=.*)"
| table _time, clientip, uri, status

--- Scanner user agents ---
index=web sourcetype=access_combined earliest=-24h
| regex useragent="(?i)(sqlmap|nikto|nmap|masscan|ffuf|hydra)"
| stats count by clientip, useragent | sort -count
```

### Network / Firewall

```splunk
--- High-volume outbound transfer ---
index=firewall earliest=-24h
| stats sum(bytes_out) AS total_bytes by src_ip
| eval mb = round(total_bytes / 1048576, 1)
| where mb > 100
| sort -mb

--- Unusual external ports ---
index=firewall earliest=-24h action=allowed
| where NOT cidrmatch("10.0.0.0/8", dest_ip)
| where dest_port NOT IN (80, 443, 53, 25, 587)
| stats count by src_ip, dest_ip, dest_port | sort -count
```

---

## ==Subsearches==

```splunk
--- IOC lookup: Ereignisse mit bekannten Bad IPs ---
index=web
  [inputlookup known_bad_ips.csv | fields src_ip]

--- IPs aus fehlgeschlagenen Logins auch in Web-Logs finden ---
index=web earliest=-1h
  [search index=wineventlog EventCode=4625 earliest=-1h
   | stats count by Source_Network_Address
   | where count > 5
   | rename Source_Network_Address AS clientip
   | fields clientip]
```

> [!info] Subsearch-Regeln
> Subsearches laufen vor dem äußeren Search und stehen in `[ ]`. Sie geben Feldwerte zurück, die als Filter wirken. Limit: 10.000 Ergebnisse standardmäßig.

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| `status=200 OR 404` | `404` ist ein einzelnes Keyword, kein Feldwert | `status=200 OR status=404` |
| Leading wildcard `*admin` | Sehr langsam, oft deaktiviert | `rex` oder `regex` verwenden |
| `stats count by _time` | Gruppiert nach exaktem Timestamp | `timechart` oder `bucket _time span=1h` |
| `where field = "value"` | Case-sensitive | `where lower(field) = "value"` |
| `rex` ohne `field=` | Extrahiert aus `_raw` — bei anderen Feldern explizit angeben | `\| rex field=uri "pattern"` |

---

## Bezug zu anderen Themen

- [[grep & Regex Cheat Sheet]] – `rex` in SPL nutzt PCRE — gleiche Syntax wie `grep -P`
- [[PowerShell-Commands]] – Windows Event IDs und PowerShell-Log-Quellen für Splunk-Suchen
- [[Linux-Terminal-Commands]] – Linux-Log-Quellen in Splunk (auth.log, syslog, apache)
- [[Snort]] – IDS-Alerts können als Sourcetype in Splunk zur Korrelation weitergeleitet werden
- [[Detecting Web Attacks]] – Web-Angriffsmuster als SPL-Queries in den Blue Team Recipes
- [[Detecting Web Shells]] – Webshell-Indikatoren aus Log-Analyse als SPL `regex`-Patterns
- [[find Command Cheat Sheet]] – Dateisystem-Suchen ergänzen Splunk-Analyse bei der Incident Response
