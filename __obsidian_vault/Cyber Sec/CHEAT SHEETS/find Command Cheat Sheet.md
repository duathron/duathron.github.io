---
title: "find Command Cheat Sheet"
tags: [linux, find, cli, forensics, blue-team, cheatsheet]
---

# `find` Command Cheat Sheet

```
find <path> <options> <expression>
```

> [!example] Tools — find
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **find** | CLI (built-in) | Dateien nach Name, Zeit, Größe, Permissions, Owner suchen und Aktionen ausführen |
> | **xargs** | CLI (built-in) | find-Ergebnisse effizient an andere Befehle weitergeben |
> | **grep** | CLI (built-in) | In find-Ergebnissen nach Inhalten suchen (`-exec grep` oder via Pipe) |
> | **sha256sum** | CLI (built-in) | Hashes gefundener Dateien für IOC-Sammlung generieren |
> | **file** | CLI (built-in) | Tatsächlichen Dateityp prüfen (erkennt getarnte Webshells) |

---

## Syntax at a Glance

| Part | Description | Example |
|------|-------------|---------|
| `path` | Where to search | `/var/www`, `.`, `/` |
| `-type` | File type filter | see table below |
| `-name` | Match by filename | `"*.php"`, `"shell.php"` |
| `-iname` | Case-insensitive name match | `"*.PHP"` also matches `*.php` |
| `-mtime` | Modified time (in days) | `-1` = last 24h, `+30` = older than 30 days |
| `-mmin` | Modified time (in minutes) | `-60` = last hour |
| `-ctime` | Changed time (metadata, in days) | same syntax as `-mtime` |
| `-atime` | Last accessed time (in days) | same syntax as `-mtime` |
| `-newerct` | Modified after a specific date | `"2025-07-01"` |
| `-size` | Filter by file size | `+1M`, `-500k`, `100c` (bytes) |
| `-perm` | Filter by permissions | `-4000` = SUID set |
| `-perm /MODE` | Any matching permission bit | `/222` = any write bit set |
| `-empty` | Empty files or directories | — |
| `-user` | Owned by user | `www-data`, `root` |
| `-group` | Owned by group | `sudo` |
| `-nouser` | No matching UID on system | orphaned files |
| `-nogroup` | No matching GID on system | orphaned files |
| `-maxdepth N` | Limit search depth | `-maxdepth 2` |
| `-mindepth N` | Skip top N directory levels | `-mindepth 1` |
| `-regex` | Match full path with regex | GNU find only |
| `-exec` | Run command on each result | `{} \;` or `{} +` |
| `-delete` | Delete matched files directly | use with caution |
| `-ls` | Detailed listing per result | like `ls -dils` |
| `-print0` | NUL-separated output | safe with special chars |
| `-quit` | Stop after first match | — |
| `2>/dev/null` | Suppress permission errors | append to any command |

### `-type` Values

| Value | Meaning |
|-------|---------|
| `f` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `c` | Character device |
| `b` | Block device |
| `p` | Named pipe (FIFO) |
| `s` | Socket |

---

## ==By File Type==

```bash
find /var/www -type f          # Files only
find /etc -type d              # Directories only
find /usr/bin -type l          # Symlinks only
find /var/www -type f -empty   # Empty files
find /var/www -type d -empty   # Empty directories
```

---

## ==By Name & Extension==

```bash
find /var/www -name "*.php"
find /var/www -iname "*.php"                          # case-insensitive
find / -name "passwd" 2>/dev/null
find /var/www \( -iname "*.php" -o -iname "*.jsp" \) # multiple extensions
find /var/www -name "*.jpg.php" -o -name "*.png.php"  # double-extension (webshell disguise)
find /home -name ".*" -type f                          # hidden files
find . -regextype posix-extended -regex '.*\.(php|jsp|aspx)$'  # GNU find only
```

---

## ==By Time==

```bash
find /var/www -mtime -1                                           # last 24h
find /tmp -mmin -60                                               # last 60 minutes
find /var/log -mtime +30                                          # older than 30 days
find /var/www -type f -name "*.php" -newerct "2025-07-01" ! -newerct "2025-08-01"
find /etc -ctime -1                                               # metadata changed last 24h
```

> [!tip] `-mtime -1` vs. `-mtime 1`
> `-mtime -1` = geändert in den letzten 24 Stunden. `-mtime 1` = genau vor 24–48 Stunden. Für forensische Suche fast immer `-mtime -1` (mit Minus).

---

## ==By Size==

```bash
find /home -size +10M           # larger than 10 MB
find /tmp -size -500k           # smaller than 500 KB
find /var/www -size 48c         # exactly 48 bytes (e.g. one-liner webshell)
find /var/www -size +1k -size -100k
find / -type f -size +500M 2>/dev/null
```

---

## ==By Permissions==

```bash
find / -perm -4000 -type f 2>/dev/null   # SUID — privilege escalation target
find / -perm -2000 -type f 2>/dev/null   # SGID
find / -perm /6000 -type f 2>/dev/null   # SUID + SGID
find / -perm -o+w -type f 2>/dev/null    # world-writable files
find / -type d -perm -o+w 2>/dev/null    # world-writable directories
find /var/www -perm 777
find /var/www -perm /222                 # any write bit set
```

> [!warning] SUID-Binaries — Privilege Escalation
> `find / -perm -4000 -type f 2>/dev/null` ist einer der ersten Recon-Befehle nach einer Shell. Jedes SUID-Binary, das nicht zum System-Standard gehört, ist ein potenzieller Privilege-Escalation-Vektor. Gegen [GTFOBins](https://gtfobins.github.io) prüfen.

---

## ==By Owner==

```bash
find /var/www -user www-data
find /tmp -user root -type f
find / -nouser 2>/dev/null     # orphaned files — suspicious
find / -nogroup 2>/dev/null
```

---

## ==Combining Conditions==

```bash
# AND (default)
find /var/www -type f -name "*.php" -mtime -7

# OR
find /var/www \( -name "*.php" -o -name "*.jsp" \)

# NOT
find /var/www -not -name "*.html"

# PHP files modified recently AND owned by www-data
find /var/www -type f -name "*.php" -mtime -3 -user www-data
```

---

## ==Controlling Depth==

```bash
find /etc -maxdepth 2 -type f -name "*.conf"
find /var/www -mindepth 1 -maxdepth 3 -name "*.php"
```

---

## ==Excluding Directories (`-prune`)==

```bash
# Skip node_modules
find . -path "./node_modules" -prune -o -type f -name "*.js" -print

# Skip multiple directories
find . \( -path "./node_modules" -o -path "./.git" \) -prune -o -type f -print
```

---

## ==Actions==

```bash
find /var/www -name "*.php" -ls           # detailed listing per result
find / -name "wp-config.php" -quit        # stop after first match
find /tmp -name "*.tmp" -mtime +7 -print  # preview before deleting
find /tmp -name "*.tmp" -mtime +7 -delete # then delete
```

> [!warning] `-delete` immer erst mit `-print` testen
> `-delete` ist irreversibel. Erst mit `-print` die Trefferliste prüfen, dann erst `-delete` ausführen.

---

## ==Executing Commands (`-exec`)==

```bash
find /var/www -name "*.php" -exec ls -la {} \;
find /var/www -name "*.php" -exec sha256sum {} \;
find /var/www -name "*.php" -exec grep -l "shell_exec\|system\|passthru\|exec" {} \;
find /var/www -name "*.php" -mtime -1 -exec cp {} /tmp/evidence/ \;
```

> `{} \;` — runs the command once per file  
> `{} +` — passes all results at once (faster, like `xargs`)

---

## ==Combinations with Other Tools==

```bash
# Pipe to xargs
find /var/www -name "*.php" | xargs grep -l "base64_decode"

# -print0 + xargs -0 for filenames with spaces/special chars
find /var/www -name "*.php" -print0 | xargs -0 grep -l "base64_decode"

# Count results
find /var/www -name "*.php" | wc -l

# Sort by modification time (newest first)
find /var/www -name "*.php" -printf "%T@ %p\n" | sort -rn | head 20

# Check actual file type (catches disguised files)
find /var/www/uploads -type f | xargs file
```

> [!tip] `-print0` + `xargs -0`
> Immer `-print0` + `xargs -0` statt plain Pipe verwenden, wenn Dateinamen Leerzeichen oder Sonderzeichen enthalten können. Robustere Alternative zu `-exec`.

---

## ==Forensics & Blue Team Recipes==

```bash
# Webshell hunting — PHP in Upload-Verzeichnissen, kürzlich geändert
find /var/www -path "*/upload*" -name "*.php" -mtime -7

# Webshell hunting — typische Execution-Funktionen
find /var/www -name "*.php" -exec grep -lE "shell_exec|system|passthru|exec|eval\(" {} \;

# Dateien erstellt durch den Webserver-Prozess
find /var/www -user www-data -newer /var/www/html/index.php -type f

# Verdächtig kleine PHP-Dateien (One-Liner-Shells oft < 200 Bytes)
find /var/www -name "*.php" -size -200c

# Alle SUID-Binaries
find / -perm -4000 -type f 2>/dev/null | sort

# Dateien in /etc der letzten 24h (Config-Tampering)
find /etc -mtime -1 -type f 2>/dev/null

# Ausführbare Dateien in /tmp oder /dev/shm (Malware-Staging)
find /tmp /dev/shm -type f -perm /111 2>/dev/null

# Verwaiste Dateien (kein Owner)
find / -nouser -o -nogroup 2>/dev/null
```

---

## ==Red Team Recipes==

```bash
find / -type d -perm -o+w 2>/dev/null | grep -v proc   # world-writable dirs
find / -perm -4000 -type f 2>/dev/null                  # SUID binaries
find / -name "*.conf" -o -name "wp-config.php" 2>/dev/null
find / -name "id_rsa" -o -name "authorized_keys" 2>/dev/null
find /home -atime -1 -type f 2>/dev/null                # recently accessed
```

---

## ==Archiving & Backup==

```bash
find . -type f -mtime -7 -print0 | tar --null -T - -czvf recent7days.tar.gz
find /var/www -name "*.php" -mtime -1 -print0 | tar --null -T - -czvf /tmp/evidence.tar.gz
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `2>/dev/null` | Output floods with permission errors |
| `-mtime 1` statt `-mtime -1` | `1` = exactly 24–48h ago; `-1` = last 24h |
| Glob-Pattern ohne Anführungszeichen | Immer quoten: `"*.php"` nicht `*.php` |
| `-exec rm` ohne vorherigen Test | Erst `-print`, dann `-delete` |
| `-delete` auf Verzeichnisse ohne `-depth` | `-depth` Flag hinzufügen |

---

## Portability Note

GNU `find` (Linux) unterstützt `-printf`, `-iname`, `-regextype`, `-delete`. BSD/macOS `find` weicht ab. Für plattformübergreifende Scripts nur POSIX-Konstrukte verwenden.

---

## Bezug zu anderen Themen

- [[Linux-Terminal-Commands]] – Vollständige Linux-Referenz inkl. `grep`, `awk`, `stat`, `strings`
- [[Detecting Web Shells]] – Praktischer `find`-Einsatz im forensischen Kontext
