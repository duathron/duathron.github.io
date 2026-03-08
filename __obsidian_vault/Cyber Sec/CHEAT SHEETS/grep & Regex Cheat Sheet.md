---
title: "grep & Regex Cheat Sheet"
tags: [linux, grep, regex, cli, log-analysis, forensics, blue-team, soc, cheatsheet]
---

# `grep` & Regex Cheat Sheet

grep = **G**lobally search for a **R**egular **E**xpression and **P**rint  
Scans files (or stdin) line by line and prints every line matching a pattern.

```
grep [options] 'pattern' file(s)
```

> [!example] Tools — grep & Regex
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **grep** | CLI (built-in) | Pattern-Suche in Dateien und stdin; Basis für Log-Analyse |
> | **egrep** | CLI (built-in) | Alias für `grep -E` — Extended Regex ohne Escaping |
> | **zgrep** | CLI (built-in) | grep direkt auf komprimierte `.gz`-Dateien |
> | **pcregrep** | CLI | grep mit PCRE-Library (Alternative zu `grep -P`) |
> | **awk** | CLI (built-in) | Feldextraktion aus grep-Ergebnissen (`awk '{print $9}'`) |
> | **regex101.com** | Web | Interaktiver Regex-Tester mit Erklärungen (PCRE, ERE) |
> | **CyberChef** | Web | Base64-Dekodierung, URL-Encoding, Regex-Tests offline |

---

## grep Flags at a Glance

### ==Pattern & Mode==

| Flag | Long Form | Description | Example |
|------|-----------|-------------|---------|
| `-E` | `--extended-regexp` | Extended regex (ERE) — enables `+`, `?`, `\|`, `{}` without escaping | `grep -E 'fail\|error'` |
| `-P` | `--perl-regexp` | PCRE — enables lookahead, lookbehind, `\d`, `\s`, `\w` etc. | `grep -P '\d{1,3}\.\d{1,3}'` |
| `-F` | `--fixed-strings` | Treat pattern as literal string (no regex) — faster for exact matches | `grep -F '192.168.1.1'` |
| `-G` | `--basic-regexp` | BRE — default mode (requires `\+`, `\?`, `\|`) | default |
| `-e` | `--regexp=PATTERN` | Specify pattern explicitly; allows multiple `-e` for OR | `grep -e 'error' -e 'fail'` |
| `-f` | `--file=FILE` | Read patterns from file (one per line) | `grep -f patterns.txt log` |
| `-i` | `--ignore-case` | Case-insensitive matching | `grep -i 'error'` |
| `-v` | `--invert-match` | Show lines that do NOT match | `grep -v 'debug'` |
| `-w` | `--word-regexp` | Match whole words only | `grep -w 'fail'` |
| `-x` | `--line-regexp` | Match whole lines only | `grep -x '404'` |

### ==Output Control==

| Flag | Description | Example |
|------|-------------|---------|
| `-n` | Print line numbers with output | `grep -n 'error' syslog` |
| `-c` | Count matching lines (suppress output) | `grep -c 'Failed' auth.log` |
| `-l` | List filenames with matches only | `grep -rl 'eval(' /var/www` |
| `-L` | List filenames WITHOUT matches | `grep -L 'error' *.log` |
| `-o` | Print only the matched part (not whole line) | `grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'` |
| `-q` | Quiet — no output, exit code only (0=match) | `grep -q 'root' /etc/passwd` |
| `-s` | Suppress error messages (unreadable files) | `grep -s 'error' /var/log/*` |
| `--color` | Highlight matches in terminal | `grep --color 'error' syslog` |

### ==Context==

| Flag | Description | Example |
|------|-------------|---------|
| `-A N` | Print N lines **after** each match | `grep -A 3 'segfault' kern.log` |
| `-B N` | Print N lines **before** each match | `grep -B 2 'Failed' auth.log` |
| `-C N` | Print N lines **before and after** (context) | `grep -C 5 'error' app.log` |

### ==Files & Recursion==

| Flag | Description | Example |
|------|-------------|---------|
| `-r` | Recursive search through directories | `grep -r 'password' /etc/` |
| `-R` | Recursive, follows symlinks | `grep -R 'token' /home/` |
| `--include` | Limit to files matching pattern | `grep -r --include='*.php' 'eval'` |
| `--exclude` | Skip files matching pattern | `grep -r --exclude='*.gz' 'error'` |
| `-m N` | Stop after N matching lines | `grep -m 5 'error' huge.log` |
| `-a` | Treat binary files as text | `grep -a 'password' binary_file` |
| `--null` / `-Z` | Separate filenames with NUL (for xargs -0) | `grep -rl 'shell' \| xargs -0 ls -la` |

### ==Regex Engine Comparison==

| Mode | Flag | Special chars need escaping? | Extras |
|------|------|------------------------------|--------|
| BRE (Basic) | `-G` (default) | `+`, `?`, `\|`, `{` need `\` | Minimal features |
| ERE (Extended) | `-E` | No — `+?{}()` work directly | Recommended for most use |
| PCRE (Perl) | `-P` | No — and adds `\d \s \w` etc. | Lookahead/behind, `\b`, full Perl syntax |

> [!tip] Welchen Modus verwenden?
> `-E` für die meisten Log-Analysen. `-P` wenn `\d`, `\b`, Lookaheads oder PCRE-Zeichenklassen gebraucht werden.

---

## Regex Fundamentals

### ==Anchors==

| Pattern | Meaning | Example |
|---------|---------|---------|
| `^` | Start of line | `^ERROR` — line starts with ERROR |
| `$` | End of line | `\.php$` — line ends with .php |
| `\b` | Word boundary (PCRE / ERE) | `\bfail\b` — word "fail", not "failure" |
| `\B` | Non-word boundary | `\Bfail\B` — "fail" inside a word |

### ==Quantifiers==

| Pattern | Meaning | Example match |
|---------|---------|---------------|
| `.` | Any single character (except newline) | `f.o` → foo, f1o, f-o |
| `*` | 0 or more of previous | `fo*` → f, fo, foo, fooo |
| `+` | 1 or more of previous (ERE/PCRE) | `fo+` → fo, foo (not f) |
| `?` | 0 or 1 of previous (optional) | `colou?r` → color, colour |
| `{n}` | Exactly n times | `\d{3}` → 123 |
| `{n,}` | n or more times | `\d{2,}` → 12, 123, 1234 |
| `{n,m}` | Between n and m times | `\d{2,4}` → 12, 123, 1234 |

### ==Character Classes==

| Pattern | Meaning |
|---------|---------|
| `[abc]` | Any one of a, b, c |
| `[^abc]` | Any character NOT a, b, c |
| `[a-z]` | Any lowercase letter |
| `[A-Z]` | Any uppercase letter |
| `[0-9]` | Any digit |
| `[a-zA-Z0-9]` | Any alphanumeric character |

### ==POSIX Character Classes (BRE/ERE)==

| Class | Equivalent | Meaning |
|-------|-----------|---------|
| `[:alpha:]` | `[a-zA-Z]` | Any letter |
| `[:digit:]` | `[0-9]` | Any digit |
| `[:alnum:]` | `[a-zA-Z0-9]` | Letter or digit |
| `[:space:]` | `[ \t\n\r]` | Whitespace |
| `[:blank:]` | `[ \t]` | Space or tab |
| `[:upper:]` | `[A-Z]` | Uppercase letter |
| `[:lower:]` | `[a-z]` | Lowercase letter |

Usage: `grep '[[:digit:]]'` (double brackets required)

### ==PCRE Shorthand Classes (`-P` flag)==

| Pattern | Meaning |
|---------|---------|
| `\d` | Digit `[0-9]` |
| `\D` | Non-digit |
| `\w` | Word character `[a-zA-Z0-9_]` |
| `\W` | Non-word character |
| `\s` | Whitespace `[ \t\n\r]` |
| `\S` | Non-whitespace |
| `\b` | Word boundary |
| `\t` | Tab |
| `\n` | Newline |

### ==Groups & Alternation==

| Pattern | Meaning | Example |
|---------|---------|---------|
| `(abc)` | Capturing group | `(fail\|error)` |
| `(?:abc)` | Non-capturing group (PCRE) | `(?:GET\|POST)` |
| `a\|b` | OR — a or b | `GET\|POST\|PUT` |
| `\1` | Backreference to group 1 | `(.).*\1` |

### ==Lookahead & Lookbehind (PCRE only, `-P`)==

| Pattern | Meaning | Example |
|---------|---------|---------|
| `(?=...)` | Positive lookahead — must follow | `port\s(?=22)` |
| `(?!...)` | Negative lookahead — must NOT follow | `user(?!name)` |
| `(?<=...)` | Positive lookbehind — must precede | `(?<=port\s)\d+` |
| `(?<!...)` | Negative lookbehind — must NOT precede | `(?<!\.)\d{1,3}` |

```bash
grep -P '(?<=port )\d+' /var/log/auth.log
grep -P '(?<=event ID)4325' /var/log/auth.log
```

---

## Special Characters — What They Mean

> [!info] Warum diese Sektion?
> Dasselbe Zeichen kann im Regex, in der Shell und im Dateisystem völlig unterschiedliche Bedeutungen haben. Die häufigsten Fehlerquellen sind `.` (Punkt als Wildcard vs. literal), `$` (Anker vs. Shell-Variable) und `*` (Quantifier vs. Shell-Glob).

### ==`\` — Backslash==

| Context | Meaning |
|---------|---------|
| **In regex** | Escape character. `\.` = literal dot; `\*` = literal asterisk. Introduces `\d`, `\s`, `\w`, `\n`, `\b`. |
| **In shell** | Shell-eigenes Escape-Zeichen. Single quotes verhindern, dass die Shell `\` verarbeitet. |
| **As literal** | `\\` im Regex matcht einen Backslash. |

### ==`.` — Dot==

| Context | Meaning |
|---------|---------|
| **In regex** | **Wildcard.** Matcht jedes einzelne Zeichen außer Newline. `f.o` → foo, f1o, f-o |
| **In filesystem** | `.` = aktuelles Verzeichnis; `..` = übergeordnetes Verzeichnis; `.file` = versteckte Datei |
| **As literal** | `\.` für einen echten Punkt |

```bash
grep '192\.168\.'   # korrekt — escaped dots
grep '192.168.'     # falsch — . matcht beliebiges Zeichen
```

> [!warning] Häufiger Fehler: IP-Adressen in grep
> `grep '10.0.0.1'` matcht auch `10X0Y0Z1`. Immer escapen: `grep '10\.0\.0\.1'`

### ==`*` — Asterisk==

| Context | Meaning |
|---------|---------|
| **In regex** | Quantifier: 0 oder mehr des vorherigen Elements. `fo*` → f, fo, foo |
| **In shell (glob)** | Wildcard für beliebige Zeichenfolge in Dateinamen. `*.log` — Shell-Expansion, kein Regex |
| **As literal** | `\*` im Regex |

### ==`^` — Caret==

| Context | Meaning |
|---------|---------|
| **In regex (Anfang)** | Anker: Zeilenanfang. `^ERROR` matcht nur Zeilen, die mit ERROR beginnen |
| **In `[^...]`** | Negation: matcht jedes Zeichen außer den aufgelisteten |

### ==`$` — Dollar Sign==

| Context | Meaning |
|---------|---------|
| **In regex** | Anker: Zeilenende. `\.php$` matcht Zeilen, die mit .php enden |
| **In shell** | Variable-Expansion: `$HOME`, `$USER` — deshalb immer **single quotes** für grep-Pattern verwenden |

> [!warning] Single quotes für grep-Pattern
> `grep '$HOME'` mit double quotes expandiert die Shell-Variable. Mit single quotes `'$HOME'` wird das Pattern literal an grep übergeben. **Immer single quotes verwenden.**

### ==`|` — Pipe==

| Context | Meaning |
|---------|---------|
| **In regex (ERE/PCRE)** | Alternation: OR. `error\|warning` matcht Zeilen mit "error" ODER "warning" |
| **In shell** | Pipe-Operator: leitet stdout eines Befehls als stdin zum nächsten weiter. Nichts mit Regex zu tun. |

### ==Greedy vs Non-Greedy==

```bash
# .* ist GREEDY — matcht so viel wie möglich
echo '<b>bold</b> and <i>italic</i>' | grep -oE '<.*>'
# Ergebnis: <b>bold</b> and <i>italic</i>

# .*? ist NON-GREEDY (PCRE) — matcht so wenig wie möglich
echo '<b>bold</b> and <i>italic</i>' | grep -oP '<.*?>'
# Ergebnis: <b>   </b>   <i>   </i>
```

---

## Practical Log Analysis

### ==Auth Log (`/var/log/auth.log`)==

```bash
grep "Failed password" /var/log/auth.log
grep "Accepted password\|Accepted publickey" /var/log/auth.log

# Top-IPs für fehlgeschlagene Logins
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head 20

# Ungültige User-Accounts
grep "Invalid user" /var/log/auth.log | awk '{print $8}' | sort | uniq -c | sort -rn

# sudo-Nutzung
grep "sudo" /var/log/auth.log | grep -v "pam_unix"

# Alle Events für einen bestimmten User
grep "user john\b" /var/log/auth.log
```

### ==Apache / Nginx Access Logs==

```bash
grep -E '" [45][0-9]{2} ' /var/log/apache2/access.log         # 4xx/5xx errors
grep '"POST ' /var/log/apache2/access.log                       # POST requests
grep -E '\.php(\?|")' /var/log/apache2/access.log              # PHP-Requests
grep -E '\?(cmd|exec|shell|system|passthru)=' /var/log/apache2/access.log  # suspicious params
grep -iE '(sqlmap|nikto|nmap|ffuf|gobuster)' /var/log/apache2/access.log  # Attack-Tools im UA

# Top-IPs
awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head 20
```

### ==Webshell & Malware Hunting==

```bash
grep -rE "(shell_exec|system|passthru|exec|popen)\s*\(" /var/www --include="*.php"
grep -rE "eval\s*\(\s*base64_decode" /var/www --include="*.php"
grep -rl "base64_decode" /var/www --include="*.php"
grep -rE '\$_(GET|POST|REQUEST|COOKIE)\s*\[' /var/www --include="*.php" | grep -E "(eval|system|exec)"
```

---

## Security-Relevant Regex Patterns

### ==Network Indicators==

```bash
# IPv4 (basic)
grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' file.txt

# IPv4 (strict, PCRE)
grep -oP '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b' file.txt

# HTTP/HTTPS URL
grep -oE 'https?://[a-zA-Z0-9./?=_%:-]+' file.txt

# Port aus auth.log (PCRE Lookbehind)
grep -oP '(?<=port )\d+' /var/log/auth.log
```

### ==Hash Indicators==

```bash
grep -oE '[0-9a-fA-F]{32}' ioc.txt   # MD5
grep -oE '[0-9a-fA-F]{40}' ioc.txt   # SHA1
grep -oE '[0-9a-fA-F]{64}' ioc.txt   # SHA256
```

### ==Encoded & Obfuscated Content==

```bash
grep -oE '[A-Za-z0-9+/]{20,}={0,2}' file.txt      # Base64
grep -iE '\$\{jndi:' /var/log/apache2/access.log   # Log4Shell
grep -iE "(union\s+select|drop\s+table|--\s*$)" /var/log/apache2/access.log  # SQLi
grep -iE "(<script|javascript:|on(load|error|click)\s*=)" /var/log/apache2/access.log  # XSS
```

---

## Blue Team Recipes

```bash
# Brute force: IPs mit >10 fehlgeschlagenen SSH-Versuchen
grep "Failed password" /var/log/auth.log \
  | awk '{print $11}' \
  | sort | uniq -c | sort -rn \
  | awk '$1 > 10 {print $1, $2}'

# Neue User-Accounts
grep -E "useradd|adduser|new user" /var/log/auth.log

# sudo-Befehle
grep "sudo:" /var/log/auth.log | grep "COMMAND="

# Directory Traversal in Apache-Logs
grep -E "\.\./|\.\.%2[Ff]|%2[Ee]%2[Ee]" /var/log/apache2/access.log

# Timeline einer IP
grep "10.10.10.99" /var/log/apache2/access.log | awk '{print $4, $6, $7, $9}'

# Requests pro Minute (Rate-Anomalien)
grep "10.10.10.99" /var/log/apache2/access.log \
  | awk '{print $4}' | cut -d: -f1,2 | sort | uniq -c
```

---

## Combining grep with Other Tools

```bash
# grep + sort + uniq (Häufigkeitsanalyse)
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head 20

# grep + xargs
find /var/www -name "*.php" -print0 | xargs -0 grep -lE "eval\("

# grep + tee (Ausgabe live + Datei)
tail -f /var/log/auth.log | grep "Failed" | tee /tmp/failed_logins.txt

# Komprimierte Logs
zgrep "Failed password" /var/log/auth.log.2.gz
zgrep "Failed password" /var/log/auth.log* 2>/dev/null
```

---

## Multiple Patterns

```bash
grep -E 'error|warning|critical' /var/log/syslog         # OR
grep -e 'error' -e 'warning' /var/log/syslog              # mehrere -e
grep 'Failed' /var/log/auth.log | grep 'root'             # AND (pipe)
grep -P '(?=.*Failed)(?=.*root)' /var/log/auth.log        # AND (Lookahead)
grep 'error' /var/log/syslog | grep -v 'debug\|info'      # NOT
grep -f /tmp/known_bad_ips.txt /var/log/apache2/access.log # Muster aus Datei
```

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| `grep 'a+b'` ohne `-E` | `+` nicht speziell in BRE | `grep -E 'a+b'` |
| Unescaped `.` in IP-Patterns | Matcht beliebiges Zeichen | `\.` statt `.` |
| Double quotes mit `$` | Shell expandiert Variable | Single quotes verwenden |
| `grep -r 'pattern' /` ohne `--include` | Sehr langsam | `--include='*.php'` hinzufügen |
| BRE `{n}` ohne Escape | In BRE: `\{n\}` nötig | `-E` verwenden |

---

## Bezug zu anderen Themen

- [[find Command Cheat Sheet]] – `find` mit `grep -exec` für Dateisystem-Suchen
- [[Linux-Terminal-Commands]] – Vollständige Linux-Referenz inkl. `awk`, `sed`, `cut`, `sort`, `uniq`
- [[Detecting Web Attacks]] – Log-basierte Erkennung: Brute Force, SQLi, Fuzzing
- [[Detecting Web Shells]] – Grep-basierte Webshell-Suche in der Praxis
- [[Snort]] – PCRE in Snort-Regeln (`pcre:` Option nutzt dieselbe Syntax wie `grep -P`)
