---
title: "find Command Cheat Sheet"
tags: [linux, find, cli, forensics, blue-team, cheatsheet]
---

# `find` Command Cheat Sheet

```
find <path> <options> <expression>
```

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

## By File Type

```bash
# Files only
find /var/www -type f

# Directories only
find /etc -type d

# Symlinks only
find /usr/bin -type l

# Empty files
find /var/www -type f -empty

# Empty directories
find /var/www -type d -empty
```

---

## By Name & Extension

```bash
# All PHP files
find /var/www -name "*.php"

# Case-insensitive (catches .PHP, .Php, etc.)
find /var/www -iname "*.php"

# Exact filename
find / -name "passwd" 2>/dev/null

# Multiple extensions with OR
find /var/www \( -iname "*.php" -o -iname "*.jsp" \)

# Double-extension files (common webshell disguise)
find /var/www -name "*.jpg.php" -o -name "*.png.php"

# Hidden files (start with .)
find /home -name ".*" -type f

# Files matching a regex (GNU find only)
find . -regextype posix-extended -regex '.*\.(php|jsp|aspx)$'
```

---

## By Time

```bash
# Modified in the last 24 hours
find /var/www -mtime -1

# Modified in the last 60 minutes
find /tmp -mmin -60

# Modified in the last 10 minutes
find /tmp -mmin -10

# Modified more than 30 days ago
find /var/log -mtime +30

# Modified between two specific dates
find /var/www -type f -name "*.php" -newerct "2025-07-01" ! -newerct "2025-08-01"

# Changed (metadata) in the last 24h — catches permission/ownership changes too
find /etc -ctime -1

# Last accessed in the last 24h
find /home -atime -1 -type f 2>/dev/null
```

---

## By Size

```bash
# Larger than 10 MB
find /home -size +10M

# Smaller than 500 KB
find /tmp -size -500k

# Exactly 48 bytes (e.g. a known one-liner webshell)
find /var/www -size 48c

# Between 1 KB and 100 KB
find /var/www -size +1k -size -100k

# Larger than 500 MB (disk cleanup)
find / -type f -size +500M 2>/dev/null
```

---

## By Permissions

```bash
# SUID bit set (privilege escalation target)
find / -perm -4000 -type f 2>/dev/null

# SGID bit set
find / -perm -2000 -type f 2>/dev/null

# Both SUID and SGID
find / -perm /6000 -type f 2>/dev/null

# World-writable files
find / -perm -o+w -type f 2>/dev/null

# World-writable directories
find / -type d -perm -o+w 2>/dev/null

# Files with 777 permissions
find /var/www -perm 777

# Any write bit set (user, group, or other)
find /var/www -perm /222

# Files not writable by owner
find /var/www -type f ! -perm -u=w
```

---

## By Owner

```bash
# Files owned by www-data
find /var/www -user www-data

# Files owned by root
find /tmp -user root -type f

# Files not owned by any existing user (orphaned — suspicious)
find / -nouser 2>/dev/null

# Files not owned by any existing group
find / -nogroup 2>/dev/null
```

---

## Combining Conditions

```bash
# AND (default — conditions are AND-ed automatically)
find /var/www -type f -name "*.php" -mtime -7

# OR — use \( \) for grouping
find /var/www \( -name "*.php" -o -name "*.jsp" \)

# NOT
find /var/www -not -name "*.html"

# PHP files modified recently AND owned by www-data
find /var/www -type f -name "*.php" -mtime -3 -user www-data

# Large files that are NOT log files
find /var -size +50M -not -name "*.log"

# .txt or .md files (grouped OR)
find . \( -iname "*.txt" -o -iname "*.md" \) -print
```

---

## Controlling Depth

```bash
# Limit to 2 directory levels deep
find /etc -maxdepth 2 -type f -name "*.conf"

# Skip the starting directory itself (start from level 1 down)
find /var/www -mindepth 1 -maxdepth 3 -name "*.php"
```

---

## Excluding Directories (`-prune`)

```bash
# Skip node_modules
find . -path "./node_modules" -prune -o -type f -name "*.js" -print

# Skip multiple directories
find . \( -path "./node_modules" -o -path "./.git" \) -prune -o -type f -print

# Exclude a log subdirectory during search
find /var \( -path "/var/log/journal" -prune \) -o -type f -name "*.log" -print
```

---

## Actions

```bash
# Print full details per result (like ls -la) — no separate -exec ls needed
find /var/www -name "*.php" -ls

# Stop after the first match
find / -name "wp-config.php" -quit 2>/dev/null

# Delete matched files directly (test with -print first!)
find /tmp -name "*.tmp" -mtime +7 -print    # preview first
find /tmp -name "*.tmp" -mtime +7 -delete   # then delete
```

---

## Executing Commands on Results (`-exec`)

```bash
# Print full details for each result
find /var/www -name "*.php" -exec ls -la {} \;

# Hash every result (useful for IOC collection)
find /var/www -name "*.php" -exec sha256sum {} \;

# Search inside each found file for suspicious functions
find /var/www -name "*.php" -exec grep -l "shell_exec\|system\|passthru\|exec" {} \;

# Make all shell scripts executable
find . -type f -name "*.sh" -exec chmod +x {} \;

# Copy all results to an evidence folder
find /var/www -name "*.php" -mtime -1 -exec cp {} /tmp/evidence/ \;
```

> **`{} \;`** — runs the command once per file  
> **`{} +`** — passes all results at once (faster, like `xargs`)

---

## Useful Combinations with Other Tools

```bash
# Pipe results to xargs (faster than -exec for large result sets)
find /var/www -name "*.php" | xargs grep -l "base64_decode"

# Use -print0 + xargs -0 for filenames with spaces or special characters
find /var/www -name "*.php" -print0 | xargs -0 grep -l "base64_decode"

# Count results
find /var/www -name "*.php" | wc -l

# Total size of matched files
find /var/log -type f -name "*.log" -print0 | du -ch --files0-from=-

# Sort results by modification time (newest first)
find /var/www -name "*.php" -printf "%T@ %p\n" | sort -rn | head 20

# Find and check file type (catches disguised files)
find /var/www/uploads -type f | xargs file
```

> Prefer `-print0` + `xargs -0` over plain pipe when filenames may contain spaces or newlines.

---

## Archiving & Backup Recipes

```bash
# Create tar.gz of files modified in the last 7 days
find . -type f -mtime -7 -print0 | tar --null -T - -czvf recent7days.tar.gz

# Rsync only specific files found by find
find . -type f -name "*.log" -print0 | rsync --files-from=- --from0 ./ /backup/

# Archive evidence files
find /var/www -name "*.php" -mtime -1 -print0 | tar --null -T - -czvf /tmp/evidence.tar.gz
```

---

## Forensics & Blue Team Recipes

```bash
# Webshell hunting — PHP files in upload directories modified recently
find /var/www -path "*/upload*" -name "*.php" -mtime -7

# Webshell hunting — search for common execution functions
find /var/www -name "*.php" -exec grep -lE "shell_exec|system|passthru|exec|eval\(" {} \;

# Files created by the web server process
find /var/www -user www-data -newer /var/www/html/index.php -type f

# Suspicious small PHP files (one-liner shells are often < 200 bytes)
find /var/www -name "*.php" -size -200c

# All SUID binaries (compare against known-good baseline)
find / -perm -4000 -type f 2>/dev/null | sort

# Files modified in /etc in the last 24h (config tampering)
find /etc -mtime -1 -type f 2>/dev/null

# Executable files in /tmp or /dev/shm (malware staging areas)
find /tmp /dev/shm -type f -perm /111 2>/dev/null

# All files modified after a specific reference file
find /var/www -newer /tmp/reference_timestamp -type f

# Orphaned files (no owner — possible artifact of deleted accounts)
find / -nouser -o -nogroup 2>/dev/null
```

---

## Red Team Recipes

```bash
# World-writable directories (potential upload/drop zones)
find / -type d -perm -o+w 2>/dev/null | grep -v proc

# SUID binaries for privilege escalation
find / -perm -4000 -type f 2>/dev/null

# Config files that might contain credentials
find / -name "*.conf" -o -name "*.config" -o -name "wp-config.php" 2>/dev/null

# SSH keys
find / -name "id_rsa" -o -name "id_ed25519" -o -name "authorized_keys" 2>/dev/null

# Recently accessed files (attacker activity)
find /home -atime -1 -type f 2>/dev/null
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `2>/dev/null` | Output floods with permission errors |
| Using `-mtime 1` instead of `-mtime -1` | `1` = exactly 24–48h ago; `-1` = last 24h |
| Quoting glob patterns | Always quote: `"*.php"` not `*.php` |
| `-exec rm {} \;` without testing first | Run with `-print` first to preview, then switch to `-delete` |
| Searching `/` without `-type f` | Returns directories and symlinks too |
| Plain pipe with special filenames | Use `-print0 \| xargs -0` for names with spaces or newlines |
| `-delete` on directories | Add `-depth` flag when deleting directory trees |

---

## Portability Note

GNU `find` (Linux) supports extensions like `-printf`, `-iname`, `-regextype`, and `-delete`. BSD/macOS `find` may differ — some flags are absent or behave differently. For scripts intended to run on multiple platforms, stick to POSIX constructs or test on the target system.

---

## Related

- [[Linux-Terminal-Commands]] – Full Linux reference including `grep`, `awk`, `stat`, `strings`
- [[Detecting Web Shells]] – Practical `find` usage in a forensic context
