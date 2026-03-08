---
title: "Splunk SPL Cheat Sheet"
tags: [splunk, spl, siem, log-analysis, blue-team, soc, cheatsheet]
---

# Splunk SPL Cheat Sheet

SPL = **S**earch **P**rocessing **L**anguage — the query language used in Splunk to search, filter, and analyse indexed data.

```
index=<index> [sourcetype=<type>] [keyword] [field=value] | command1 | command2 ...
```

Every SPL search starts with a data source specification, optionally filters by keywords or field values, then pipes the results through one or more commands from left to right. The `|` is not a shell pipe — it chains SPL commands inside Splunk.

---

## Core Concepts

### How Splunk Structures Data

| Concept | Meaning |
|---------|---------|
| **Event** | A single indexed entry — one log line, one record, with a timestamp |
| **Index** | Named storage bucket. Default index is `main`. Windows logs often go to `wineventlog`, web logs to `web`. |
| **Sourcetype** | Defines the format/parser for data. Examples: `WinEventLog:Security`, `syslog`, `access_combined` |
| **Source** | The file or input path the data came from |
| **Host** | The machine that generated the event |
| **Field** | A named value extracted from events. Automatically extracted (`src_ip`, `status`) or user-defined. |
| **`_raw`** | The original, unmodified event text |
| **`_time`** | The event timestamp in UNIX format |

### SPL Pipeline Logic

```
index=web_logs sourcetype=access_combined status=404
| stats count by src_ip
| sort -count
| head 10
```

Reading left to right: get 404 events → count by source IP → sort descending → return top 10. Each `|` passes the result set to the next command. The first part before the first `|` always defines the data scope.

---

## Search Basics

### Selecting Data

```splunk
index=main                            # search the main index
index=*                               # all non-internal indexes
index=main OR index=web               # multiple indexes
sourcetype="WinEventLog:Security"     # filter by sourcetype
host="dc01.corp.local"                # specific host
source="/var/log/auth.log"            # specific source file
```

### Keyword and Field Searches

```splunk
index=main failed login               # implicit AND between terms
index=main "failed login"             # exact phrase
index=main failed OR error            # OR
index=main failed NOT debug           # NOT
index=main status=404                 # field=value match
index=main status!=200                # field != value
index=main status>400                 # numeric comparison
index=main src_ip=10.0.0.*            # wildcard on value
index=main user=admin*                # wildcard prefix match
index=main (failed OR error) user=*   # grouping with parens
```

> **Implicit AND:** Splunk treats a space between terms as AND. `failed login` means events containing both "failed" and "login". No need to write `failed AND login` — though it also works.

### Wildcards

| Pattern | Meaning |
|---------|---------|
| `*` | Zero or more characters. `admin*` matches admin, administrator, admin123 |
| `*admin*` | Contains "admin" anywhere in the field value |
| `*.exe` | Ends with .exe |

Wildcards only work at the end of a term or field value (leading wildcards are slow and often disabled). Use `| regex` or `| rex` for more flexible matching.

---

## Time Modifiers

Time modifiers narrow the search window inline, overriding the Time Range Picker.

### Syntax

```
earliest=<time> latest=<time>
```

### Relative Time Units

| Unit | Meaning |
|------|---------|
| `s` | seconds |
| `m` | minutes |
| `h` | hours |
| `d` | days |
| `w` | weeks |
| `mon` | months |
| `y` | years |

### Snap-to (`@`)

`@` rounds down to the nearest unit boundary:

| Modifier | Meaning |
|----------|---------|
| `@d` | Snap to start of today (midnight) |
| `@h` | Snap to start of current hour |
| `@w0` | Snap to start of Sunday |
| `@mon` | Snap to start of current month |

### Examples

```splunk
earliest=-24h latest=now             # last 24 hours
earliest=-7d latest=now              # last 7 days
earliest=-1h@h                       # from start of the last complete hour
earliest=@d                          # from midnight today
earliest=-30d@d latest=@d            # last 30 full days, no partial today
earliest=-mon@mon latest=@mon        # last complete calendar month
earliest="04/19/2024:00:00:00" latest="04/20/2024:00:00:00"   # exact range
earliest=1                           # from UNIX time start (all time)
```

```splunk
# Inline time modifier in search
index=web_logs earliest=-1h latest=now status=500
```

---

## Essential SPL Commands

### Filtering & Selecting

| Command | Syntax | Description |
|---------|--------|-------------|
| `search` | `\| search keyword` | Filter events by keyword or field value — same syntax as the initial search |
| `where` | `\| where field > 100` | Filter using eval-style expressions. Needed for numeric comparisons between fields. |
| `regex` | `\| regex field="pattern"` | Filter by regex match on a field. Use to exclude (`!=`) or include. |
| `fields` | `\| fields src_ip, status` | Keep only specified fields (reduces result size) |
| `fields -` | `\| fields - _raw, _bkt` | Remove specified fields |
| `dedup` | `\| dedup src_ip` | Remove duplicate events based on field value |
| `head` | `\| head 20` | Return first N results |
| `tail` | `\| tail 20` | Return last N results |

```splunk
| search status=404
| where count > 100
| where src_ip != dest_ip
| regex _raw="Failed password for \w+"
| fields _time, src_ip, user, status
| dedup user
```

### Sorting & Outputting

| Command | Syntax | Description |
|---------|--------|-------------|
| `sort` | `\| sort -count` | Sort results. `-` = descending, `+` or none = ascending |
| `sort limit=` | `\| sort limit=50 -count` | Sort and cap results |
| `table` | `\| table _time, src_ip, user` | Display results as a formatted table |
| `rename` | `\| rename src_ip AS "Source IP"` | Rename field for display |

```splunk
| sort -count
| sort +_time
| sort limit=100 -bytes
| table _time, host, user, action, status
| rename EventCode AS "Event ID", Account_Name AS "User"
```

### Statistics

| Command | Syntax | Description |
|---------|--------|-------------|
| `stats` | `\| stats count by src_ip` | Aggregate statistics, grouped by field(s) |
| `top` | `\| top limit=10 user` | Most common values of a field |
| `rare` | `\| rare limit=5 user` | Least common values |
| `timechart` | `\| timechart span=1h count by status` | Count over time, grouped by field |
| `chart` | `\| chart count by host, status` | Create a chart table |
| `eventstats` | `\| eventstats avg(count) as avg_count` | Add aggregate stats back to each event row |

#### Common `stats` Functions

| Function | Meaning | Example |
|----------|---------|---------|
| `count` | Number of events | `stats count by user` |
| `count(field)` | Count non-null values | `stats count(src_ip) by host` |
| `dc(field)` | Distinct count (unique values) | `stats dc(user) by src_ip` |
| `sum(field)` | Sum of numeric field | `stats sum(bytes) by host` |
| `avg(field)` | Average | `stats avg(duration) by service` |
| `max(field)` | Maximum value | `stats max(bytes) by src_ip` |
| `min(field)` | Minimum value | `stats min(_time) by user` |
| `values(field)` | All distinct values as list | `stats values(src_ip) by user` |
| `list(field)` | All values (including duplicates) | `stats list(action) by user` |
| `earliest(field)` | Chronologically first value | `stats earliest(_time) by user` |
| `latest(field)` | Chronologically last value | `stats latest(src_ip) by user` |

```splunk
# Multiple aggregations in one stats
| stats count AS total_events, dc(src_ip) AS unique_ips, max(bytes) AS max_bytes by host

# Timechart: events per hour
| timechart span=1h count

# Timechart: events per hour, broken out by status code
| timechart span=1h count by status
```

### Field Extraction

| Command | Syntax | Description |
|---------|--------|-------------|
| `rex` | `\| rex "pattern(?P<n>...)"` | Extract fields from `_raw` using named capture groups |
| `rex field=` | `\| rex field=url "(?P<path>/[^?]+)"` | Extract from a specific field |
| `rex mode=sed` | `\| rex mode=sed field=x "s/old/new/g"` | Find-and-replace using sed-style regex |
| `extract` | `\| extract pairdelim=";" kvdelim="="` | Extract key=value pairs automatically |
| `kvform` | `\| kvform` | Extract key=value pairs from `_raw` |

```splunk
# Extract username from auth.log format
| rex "Failed password for (?P<username>\S+) from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"

# Extract HTTP method and path from access log
| rex "\"(?P<method>GET|POST|PUT|DELETE) (?P<path>/[^ ]+)"

# Mask credit card number (sed mode)
| rex mode=sed field=_raw "s/\d{4}-\d{4}-\d{4}-\d{4}/XXXX-XXXX-XXXX-XXXX/g"
```

> `(?P<fieldname>pattern)` — named capture group syntax. Splunk creates a new field with the extracted value.

### Computed Fields

| Command | Syntax | Description |
|---------|--------|-------------|
| `eval` | `\| eval new_field = expression` | Create or modify a field using an expression |
| `fieldformat` | `\| fieldformat bytes = tostring(bytes, "commas")` | Format field values for display (no data change) |

#### Common `eval` Functions

| Function | Meaning | Example |
|----------|---------|---------|
| `if(cond, a, b)` | Conditional | `eval result = if(status==200, "ok", "fail")` |
| `case(c1,v1, c2,v2,...)` | Multi-condition switch | `eval level = case(status<400,"ok", status<500,"warn", 1==1,"error")` |
| `len(field)` | String length | `eval url_len = len(url)` |
| `lower(field)` | Lowercase | `eval user = lower(user)` |
| `upper(field)` | Uppercase | `eval host = upper(host)` |
| `substr(field, start, len)` | Substring | `eval short = substr(url, 1, 50)` |
| `replace(field, regex, repl)` | Regex replace | `eval clean = replace(url, "\\?.*", "")` |
| `split(field, delim)` | Split into multivalue | `eval parts = split(url, "/")` |
| `mvindex(field, n)` | Get nth value from multivalue | `eval first_part = mvindex(parts, 0)` |
| `round(n, dec)` | Round number | `eval mb = round(bytes/1024/1024, 2)` |
| `tostring(n, "commas")` | Number to string with commas | `eval fmt = tostring(count, "commas")` |
| `tonumber(field)` | String to number | `eval port = tonumber(port_str)` |
| `now()` | Current UNIX timestamp | `eval age = now() - _time` |
| `strftime(_time, fmt)` | Format timestamp | `eval ts = strftime(_time, "%Y-%m-%d %H:%M:%S")` |
| `strptime(field, fmt)` | Parse time string to UNIX | `eval t = strptime(date_str, "%d/%b/%Y")` |
| `cidrmatch("net", ip)` | Check if IP in CIDR range | `eval internal = cidrmatch("10.0.0.0/8", src_ip)` |

```splunk
# Classify HTTP status codes
| eval status_class = case(
    status >= 500, "Server Error",
    status >= 400, "Client Error",
    status >= 300, "Redirect",
    status >= 200, "Success",
    1==1, "Unknown"
  )

# Compute session duration in minutes
| eval duration_min = round((end_time - start_time) / 60, 1)

# Flag internal vs external IPs
| eval network = if(cidrmatch("10.0.0.0/8", src_ip) OR cidrmatch("192.168.0.0/16", src_ip), "internal", "external")
```

### Lookups

```splunk
# Enrich events with a CSV lookup (e.g. known bad IPs)
| lookup threat_intel.csv src_ip OUTPUT threat_type, description

# Lookup with output rename
| lookup geo_lookup.csv src_ip OUTPUT country AS "Source Country"

# Inputlookup: read a lookup table as a dataset
| inputlookup known_bad_ips.csv
| where threat_score > 8
```

---

## Important Default Fields

| Field | Meaning |
|-------|---------|
| `_time` | Event timestamp (UNIX) |
| `_raw` | Original raw event text |
| `_indextime` | When the event was indexed (may differ from `_time`) |
| `host` | Hostname that sent the event |
| `source` | Source file or input |
| `sourcetype` | Parser/format identifier |
| `index` | Index the event lives in |
| `linecount` | Number of lines in the event |

---

## Common Sourcetypes and Their Fields

### `WinEventLog:Security` (Windows Security Events)

| Field | Meaning |
|-------|---------|
| `EventCode` | Windows Event ID (4624, 4625, 4688...) |
| `Account_Name` | Target account name |
| `Account_Domain` | Domain of the account |
| `Logon_Type` | Logon type code (see table below) |
| `Source_Network_Address` | Source IP of the logon |
| `Process_Name` | Path of the process |
| `SubjectUserName` | Account initiating the action |
| `TargetUserName` | Account being acted upon |
| `Computer` | Hostname of the logged system |
| `Failure_Reason` | Why logon failed |

#### Windows Logon Types

| Code | Type | Description |
|------|------|-------------|
| 2 | Interactive | Local keyboard/console login |
| 3 | Network | Network-based login (SMB, etc.) |
| 4 | Batch | Scheduled task / batch job |
| 5 | Service | Service account login |
| 7 | Unlock | Screen unlock / session resume |
| 8 | NetworkCleartext | Network login with plaintext credentials |
| 9 | NewCredentials | RunAs with different credentials |
| 10 | RemoteInteractive | RDP / Terminal Services |
| 11 | CachedInteractive | Cached domain credentials (offline) |

#### Key Windows Event IDs

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
| 4732 | User added to security-enabled local group |
| 4756 | User added to security-enabled universal group |
| 7034 | Service crashed unexpectedly |
| 7045 | New service installed |
| 1102 | Audit log cleared |
| 4104 | PowerShell script block logged |
| 4103 | PowerShell module logged |

### `access_combined` / `access_log` (Apache/Nginx)

| Field | Meaning |
|-------|---------|
| `clientip` | Client IP address |
| `method` | HTTP method (GET, POST...) |
| `uri` | Requested URI path |
| `status` | HTTP status code |
| `bytes` | Response size in bytes |
| `referer` | Referrer header |
| `useragent` | User-Agent string |

### `syslog` (Linux System Logs)

| Field | Meaning |
|-------|---------|
| `host` | Originating host |
| `process` | Process name (sshd, sudo...) |
| `pid` | Process ID |
| `message` | Log message body |
| `severity` | Syslog severity level |

---

## Blue Team Recipes

### Authentication — Brute Force & Credential Attacks

```splunk
--- Failed logons by user (last 24h) ---
index=wineventlog EventCode=4625 earliest=-24h
| stats count by Account_Name, Source_Network_Address, Failure_Reason
| sort -count

--- IPs with >10 failed logons (brute force indicator) ---
index=wineventlog EventCode=4625 earliest=-1h
| stats count by Source_Network_Address
| where count > 10
| sort -count

--- Successful logon after multiple failures (possible credential stuffing) ---
index=wineventlog (EventCode=4625 OR EventCode=4624) earliest=-6h
| stats count(eval(EventCode=4625)) AS failures, count(eval(EventCode=4624)) AS successes by Account_Name, Source_Network_Address
| where failures > 5 AND successes > 0
| table Account_Name, Source_Network_Address, failures, successes

--- Password spray: many users from one IP ---
index=wineventlog EventCode=4625 Logon_Type=3 earliest=-1h
| stats dc(Account_Name) AS unique_users count AS attempts by Source_Network_Address
| where unique_users > 10
| sort -unique_users

--- RDP logon events ---
index=wineventlog EventCode=4624 Logon_Type=10 earliest=-24h
| table _time, Account_Name, Source_Network_Address, Computer
| sort -_time
```

### Process & Execution

```splunk
--- All new processes on a host ---
index=wineventlog EventCode=4688 earliest=-1h
| table _time, Computer, Account_Name, Process_Name, Creator_Process_Name
| sort -_time

--- PowerShell script block logging ---
index=wineventlog EventCode=4104 earliest=-24h
| table _time, Computer, Account_Name, ScriptBlockText
| sort -_time

--- Encoded PowerShell commands (obfuscation indicator) ---
index=wineventlog EventCode=4688 Process_Name="*powershell*" earliest=-24h
| search Creator_Process_Command="*-enc*" OR Creator_Process_Command="*-encodedcommand*"
| table _time, Computer, Account_Name, Creator_Process_Command

--- Suspicious child processes (cmd/powershell spawned by Office apps) ---
index=wineventlog EventCode=4688 earliest=-24h
| where match(Creator_Process_Name, "(?i)(winword|excel|outlook|powerpnt)") AND match(Process_Name, "(?i)(cmd|powershell|wscript|cscript|mshta)")
| table _time, Computer, Creator_Process_Name, Process_Name, Account_Name
```

### Persistence & Lateral Movement

```splunk
--- New scheduled tasks ---
index=wineventlog EventCode=4698 earliest=-24h
| table _time, Computer, Account_Name, Task_Name, Task_Content
| sort -_time

--- New services installed ---
index=wineventlog EventCode=7045 earliest=-24h
| table _time, host, Service_Name, Service_File_Name, Service_Type, Service_Account

--- User account created ---
index=wineventlog EventCode=4720 earliest=-7d
| table _time, Computer, SubjectUserName, TargetUserName, Account_Domain

--- User added to admin group ---
index=wineventlog (EventCode=4732 OR EventCode=4756) earliest=-7d
| search Group_Name="*admin*" OR Group_Name="*Admin*"
| table _time, Computer, SubjectUserName, MemberName, Group_Name

--- Audit log cleared ---
index=wineventlog EventCode=1102 earliest=-30d
| table _time, host, SubjectUserName
```

### Web Log Analysis

```splunk
--- Top source IPs by request count ---
index=web sourcetype=access_combined earliest=-24h
| stats count by clientip
| sort -count
| head 20

--- HTTP 4xx and 5xx error rates by URI ---
index=web sourcetype=access_combined earliest=-24h status>=400
| stats count by uri, status
| sort -count

--- Directory traversal attempts ---
index=web sourcetype=access_combined earliest=-24h
| regex uri="\.\./|%2e%2e%2f|%2e%2e/"
| table _time, clientip, method, uri, status

--- SQL injection patterns in URI ---
index=web sourcetype=access_combined earliest=-24h
| regex uri="(?i)(union.*select|select.*from|'--|\bor\b.*=.*)"
| table _time, clientip, uri, status

--- Requests with suspicious user agents (scanners) ---
index=web sourcetype=access_combined earliest=-24h
| regex useragent="(?i)(sqlmap|nikto|nmap|masscan|dirbuster|gobuster|ffuf|hydra)"
| stats count by clientip, useragent
| sort -count

--- Requests to PHP files with non-200 status ---
index=web sourcetype=access_combined earliest=-24h
| regex uri="\.php(\?|$)"
| where status != 200
| table _time, clientip, uri, status
| sort -_time

--- Webshell indicators: PHP execution functions in POST data ---
index=web sourcetype=access_combined method=POST earliest=-24h
| regex _raw="(?i)(system|exec|shell_exec|passthru|eval)\s*\("
| table _time, clientip, uri, status
```

### Network / Firewall

```splunk
--- Top destination ports ---
index=firewall earliest=-24h action=allowed
| stats count by dest_port
| sort -count
| head 20

--- Connections to unusual external ports ---
index=firewall earliest=-24h action=allowed
| where NOT cidrmatch("10.0.0.0/8", dest_ip) AND NOT cidrmatch("192.168.0.0/16", dest_ip)
| where dest_port NOT IN (80, 443, 53, 25, 587, 143, 993, 995)
| stats count by src_ip, dest_ip, dest_port
| sort -count

--- High-volume outbound data transfer ---
index=firewall earliest=-24h
| stats sum(bytes_out) AS total_bytes by src_ip
| eval mb = round(total_bytes / 1048576, 1)
| where mb > 100
| sort -mb

--- DNS queries to new domains ---
index=dns earliest=-24h
| stats count by query
| sort count       # rare = potentially new/unusual
```

---

## Field Manipulation Patterns

```splunk
--- Rename fields for readability ---
| rename Source_Network_Address AS src_ip, Account_Name AS user, EventCode AS event_id

--- Compute time difference (seconds since last seen) ---
| sort _time
| streamstats current=f last(_time) AS prev_time by user
| eval gap_seconds = _time - prev_time

--- Classify by IP range ---
| eval network_zone = case(
    cidrmatch("10.0.0.0/8", src_ip), "internal",
    cidrmatch("172.16.0.0/12", src_ip), "internal",
    cidrmatch("192.168.0.0/16", src_ip), "internal",
    1==1, "external"
  )

--- Extract domain from URL ---
| rex field=url "https?://(?P<domain>[^/]+)"

--- Flag events outside business hours (UTC) ---
| eval hour = tonumber(strftime(_time, "%H"))
| eval off_hours = if(hour < 8 OR hour > 18, 1, 0)
| where off_hours = 1
```

---

## Subsearches

A subsearch runs first, returns a field-value list, and passes it to the outer search as a filter:

```splunk
--- Find hosts where admin logged in, then get all events from those hosts ---
index=wineventlog EventCode=4624
  [search index=wineventlog EventCode=4624 Account_Name=administrator
   | fields host
   | dedup host]

--- IOC lookup: find events matching a list of known bad IPs ---
index=web
  [inputlookup known_bad_ips.csv | fields src_ip]

--- Find events from IPs that also appeared in failed login events ---
index=web earliest=-1h
  [search index=wineventlog EventCode=4625 earliest=-1h
   | stats count by Source_Network_Address
   | where count > 5
   | rename Source_Network_Address AS clientip
   | fields clientip]
```

> Subsearches run before the outer search and are enclosed in `[ ]`. They must return field values that match fields in the outer search. Subsearches are limited to 10,000 results by default.

---

## Transactions

Group related events into a single transaction:

```splunk
--- Group events by session ID ---
| transaction session_id maxspan=30m maxpause=5m

--- Group logon/logoff events by user ---
index=wineventlog (EventCode=4624 OR EventCode=4634) earliest=-24h
| transaction Account_Name maxspan=8h startswith=EventCode=4624 endswith=EventCode=4634
| table Account_Name, duration, eventcount, _time

--- Web session by IP with 5-minute inactivity timeout ---
index=web sourcetype=access_combined
| transaction clientip maxspan=2h maxpause=5m
| where eventcount > 50
| table clientip, duration, eventcount
```

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| `status=200 OR 404` | Parsed as `status=200 OR 404` (404 is a lone keyword, not a field match) | Use `status=200 OR status=404` |
| Wildcard at start: `*admin` | Leading wildcards are very slow, often disabled | Use `rex` or `regex` instead |
| `stats count by _time` | Groups by exact timestamp — rarely useful | Use `timechart` or `bucket _time span=1h` first |
| Forgetting `| head` on large datasets | Query returns millions of events | Always add `| head 10000` when exploring |
| `where field = "value"` | Case-sensitive; won't match "Value" or "VALUE" | Use `where lower(field) = "value"` |
| Double quotes vs single quotes | SPL uses double quotes for strings in `eval`/`where`, single quotes around field names with spaces | `eval x = "test"`, `| table 'field name'` |
| Mixing `search` and `where` | `search` uses SPL keyword syntax, `where` uses eval syntax | `\| search status=404` vs `\| where status==404` |
| `rex` extracting from wrong field | Default field is `_raw`; for other fields, specify `field=` | `\| rex field=uri "pattern"` |

---

## Quick Reference: SPL Command Categories

```splunk
# --- Data scope ---
index=main sourcetype=syslog host=webserver01

# --- Filtering ---
| search status=500
| where bytes > 10000
| regex uri="\.php$"
| dedup src_ip

# --- Field management ---
| fields _time, src_ip, status, bytes
| rename src_ip AS "Source IP"
| eval status_class = if(status >= 400, "error", "ok")
| rex "Failed password for (?P<user>\S+)"

# --- Statistics ---
| stats count by src_ip
| stats dc(user) AS unique_users, count AS attempts by src_ip
| top 10 useragent
| timechart span=1h count by status

# --- Sorting & display ---
| sort -count
| head 20
| table _time, src_ip, user, status, action
```

---

## Useful Resources

| Resource | Description |
|----------|-------------|
| [Splunk Search Reference](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference) | Official SPL command reference |
| [Splunk Quick Reference PDF](https://www.splunk.com/pdfs/solution-guides/splunk-quick-reference-guide.pdf) | Official cheat sheet (PDF) |
| [Splunk Security Content](https://research.splunk.com) | Ready-to-use detection searches from Splunk ESCU |
| [Boss of the SOC (BOTS)](https://github.com/splunk/botsv1) | Practice dataset with real attack scenarios |
| [TryHackMe — Splunk Rooms](https://tryhackme.com/hacktivities?tab=search&value=splunk) | Hands-on Splunk labs |
| [Splunk Lantern](https://lantern.splunk.com) | Guided searches and use-case library |

---

## Related

- [[grep & Regex Cheat Sheet]] – `rex` in SPL uses PCRE — same syntax as `grep -P`
- [[PowerShell-Commands]] – Windows event IDs and PowerShell log sources relevant to Splunk searches
- [[Linux-Terminal-Commands]] – Linux log sources ingested into Splunk (auth.log, syslog, apache)
- [[Snort]] – IDS alerts can be forwarded to Splunk as a sourcetype for correlation
- [[Detecting Web Attacks]] – Web attack patterns translated into SPL queries in the Blue Team Recipes above
- [[Detecting Web Shells]] – Webshell indicators from log analysis, applicable as SPL `regex` patterns
- [[find Command Cheat Sheet]] – Filesystem searches that complement Splunk log analysis during incident response
