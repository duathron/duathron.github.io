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

---

## grep Flags at a Glance

### Pattern & Mode

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

### Output Control

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

### Context

| Flag | Description | Example |
|------|-------------|---------|
| `-A N` | Print N lines **after** each match | `grep -A 3 'segfault' kern.log` |
| `-B N` | Print N lines **before** each match | `grep -B 2 'Failed' auth.log` |
| `-C N` | Print N lines **before and after** (context) | `grep -C 5 'error' app.log` |

### Files & Recursion

| Flag | Description | Example |
|------|-------------|---------|
| `-r` | Recursive search through directories | `grep -r 'password' /etc/` |
| `-R` | Recursive, follows symlinks | `grep -R 'token' /home/` |
| `--include` | Limit to files matching pattern | `grep -r --include='*.php' 'eval'` |
| `--exclude` | Skip files matching pattern | `grep -r --exclude='*.gz' 'error'` |
| `-m N` | Stop after N matching lines | `grep -m 5 'error' huge.log` |
| `-a` | Treat binary files as text | `grep -a 'password' binary_file` |
| `--null` / `-Z` | Separate filenames with NUL (for xargs -0) | `grep -rl 'shell' \| xargs -0 ls -la` |

### Regex Engine Comparison

| Mode | Flag | Special chars need escaping? | Extras |
|------|------|------------------------------|--------|
| BRE (Basic) | `-G` (default) | `+`, `?`, `\|`, `{` need `\` | Minimal features |
| ERE (Extended) | `-E` | No — `+?{}()` work directly | Recommended for most use |
| PCRE (Perl) | `-P` | No — and adds `\d \s \w` etc. | Lookahead/behind, `\b`, full Perl syntax |

> **Tip:** Use `-E` for most log analysis tasks. Use `-P` when you need `\d`, `\b`, lookaheads, or PCRE character classes.

---

## Regex Fundamentals

### Anchors

| Pattern | Meaning | Example |
|---------|---------|---------|
| `^` | Start of line | `^ERROR` — line starts with ERROR |
| `$` | End of line | `\.php$` — line ends with .php |
| `\b` | Word boundary (PCRE / ERE) | `\bfail\b` — word "fail", not "failure" |
| `\B` | Non-word boundary | `\Bfail\B` — "fail" inside a word |

### Quantifiers

| Pattern | Meaning | Example match |
|---------|---------|---------------|
| `.` | Any single character (except newline) | `f.o` → foo, f1o, f-o |
| `*` | 0 or more of previous | `fo*` → f, fo, foo, fooo |
| `+` | 1 or more of previous (ERE/PCRE) | `fo+` → fo, foo (not f) |
| `?` | 0 or 1 of previous (optional) | `colou?r` → color, colour |
| `{n}` | Exactly n times | `\d{3}` → 123 |
| `{n,}` | n or more times | `\d{2,}` → 12, 123, 1234 |
| `{n,m}` | Between n and m times | `\d{2,4}` → 12, 123, 1234 |

### Character Classes

| Pattern | Meaning |
|---------|---------|
| `[abc]` | Any one of a, b, c |
| `[^abc]` | Any character NOT a, b, c |
| `[a-z]` | Any lowercase letter |
| `[A-Z]` | Any uppercase letter |
| `[0-9]` | Any digit |
| `[a-zA-Z0-9]` | Any alphanumeric character |
| `[a-zA-Z0-9_]` | Any alphanumeric or underscore |

### POSIX Character Classes (BRE/ERE)

| Class | Equivalent | Meaning |
|-------|-----------|---------|
| `[:alpha:]` | `[a-zA-Z]` | Any letter |
| `[:digit:]` | `[0-9]` | Any digit |
| `[:alnum:]` | `[a-zA-Z0-9]` | Letter or digit |
| `[:space:]` | `[ \t\n\r]` | Whitespace |
| `[:blank:]` | `[ \t]` | Space or tab |
| `[:upper:]` | `[A-Z]` | Uppercase letter |
| `[:lower:]` | `[a-z]` | Lowercase letter |
| `[:punct:]` | | Punctuation characters |
| `[:print:]` | | Any printable character |

Usage: `grep '[[:digit:]]'` (double brackets required)

### PCRE Shorthand Classes (`-P` flag)

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

### Groups & Alternation

| Pattern | Meaning | Example |
|---------|---------|---------|
| `(abc)` | Capturing group | `(fail\|error)` |
| `(?:abc)` | Non-capturing group (PCRE) | `(?:GET\|POST)` |
| `a\|b` | OR — a or b (ERE: `a\|b`, BRE: `a\\\|b`) | `GET\|POST\|PUT` |
| `\1` | Backreference to group 1 | `(.).*\1` |

### Lookahead & Lookbehind (PCRE only, `-P`)

| Pattern | Meaning | Example |
|---------|---------|---------|
| `(?=...)` | Positive lookahead — must follow | `port\s(?=22)` |
| `(?!...)` | Negative lookahead — must NOT follow | `user(?!name)` |
| `(?<=...)` | Positive lookbehind — must precede | `(?<=port\s)\d+` |
| `(?<!...)` | Negative lookbehind — must NOT precede | `(?<!\.)\d{1,3}` |

```bash
# Find port number only when preceded by "port "
grep -P '(?<=port )\d+' /var/log/auth.log

# Find event ID 4325 only after "event ID"
grep -P '(?<=event ID)4325' /var/log/auth.log
```

### Escaping Special Characters

In regex, these characters have special meaning and must be escaped with `\` to match literally:

`. * + ? ^ $ { } [ ] ( ) | \`

```bash
# Match literal dot in IP address (unescaped . matches any char)
grep -E '192\.168\.1\.[0-9]+'   # correct
grep -E '192.168.1.[0-9]+'      # matches 192X168Y1Z123 too
```

---

## Special Characters — What They Mean

This section explains what each special character does in three different contexts: inside a regex pattern, in the shell (command line), and in the filesystem — because the same character can mean very different things depending on where it appears.

---

### `\` — Backslash

| Context | Meaning |
|---------|---------|
| **In regex** | **Escape character.** Removes the special meaning of the next character, turning it into a literal. `\.` matches a literal dot; `\*` matches a literal asterisk. Also introduces special sequences: `\d`, `\s`, `\w`, `\n`, `\t`, `\b`. |
| **In shell** | Escape character for the shell itself. `grep 'a\.b'` — the quotes prevent the shell from interpreting `\`. Without quotes, `\` may be consumed by the shell before grep sees the pattern. |
| **In filesystem** | No special meaning on Linux/macOS. On Windows, `\` is the path separator (`C:\Users\`). |

```bash
grep 'error\.'    # matches "error." (literal dot)
grep '\broot\b'   # \b = word boundary (PCRE/ERE)
grep '\\'         # matches a literal backslash (two \\ = one \ in regex)
```

> **Key rule:** To match a literal backslash, you need `\\` in the regex. Inside single quotes in bash, `\\` is passed as-is to grep.

---

### `/` — Forward Slash

| Context | Meaning |
|---------|---------|
| **In regex** | **No special meaning.** A `/` in a grep pattern matches a literal forward slash. No escaping needed. |
| **In shell** | **Path separator.** `/var/log/auth.log` — the `/` separates directory levels. `/` alone is the root directory. |
| **In sed / Perl / vi** | Used as the **delimiter** in substitution commands: `s/old/new/`. Can cause issues if the pattern itself contains `/` — then use a different delimiter: `s|old/path|new/path|`. |

```bash
grep '/etc/passwd' /var/log/auth.log     # matches literal /etc/passwd — no escaping needed
sed 's/foo/bar/'                          # / as delimiter
sed 's|/var/log|/mnt/logs|'              # | as alternative delimiter when path contains /
```

---

### `.` — Dot

| Context | Meaning |
|---------|---------|
| **In regex** | **Wildcard.** Matches **any single character** except a newline. `f.o` matches foo, f1o, f-o, f o — but NOT fo or fooo. |
| **In filesystem** | `.` = current directory. `..` = parent directory. `.file` = hidden file (starts with dot). |
| **As literal** | Must be escaped as `\.` to match an actual dot character in text. |

```bash
grep 'f.o'          # matches foo, f1o, f-o, f o (any char between f and o)
grep 'f\.o'         # matches only f.o (literal dot)
grep '192\.168\.'   # correct IP prefix — escaped dots
grep '192.168.'     # wrong — each . matches any character

# .* — the most common combination
grep '.*'           # matches everything (any char, zero or more times = entire line)
grep 'error.*fail'  # matches "error" followed by anything, then "fail"
```

> **Common mistake:** Searching for an IP like `grep '10.0.0.1'` — the dots match any character, so `10X0Y0Z1` would also match. Always use `10\.0\.0\.1`.

---

### `..` — Double Dot

| Context | Meaning |
|---------|---------|
| **In regex** | Two consecutive wildcards — matches **any two characters**. `..` matches `ab`, `1x`, `//`, ` !` — any two-character sequence. `.*` is the greedy "match everything" combination; `..` is specifically "exactly two arbitrary characters". |
| **In filesystem** | Parent directory. `cd ..` goes one level up. `../../etc/passwd` is a directory traversal path (two levels up, then into /etc). |

```bash
grep '^..$'         # lines containing exactly 2 characters
grep '^.\{8\}$'     # lines containing exactly 8 characters (BRE)
grep -E '^.{8}$'    # same with ERE

# Directory traversal detection in web logs (security context):
grep '\.\.'  /var/log/apache2/access.log          # basic check
grep -E '\.\./|\.\.\\'  /var/log/apache2/access.log  # Linux and Windows paths
```

---

### `*` — Asterisk

| Context | Meaning |
|---------|---------|
| **In regex** | **Quantifier: 0 or more** of the preceding element. `fo*` matches f, fo, foo, fooo. `.*` matches anything (including nothing). |
| **In shell (glob)** | **Wildcard: any sequence of characters** in filenames. `*.log` matches all files ending in .log. Different from regex — shell globs are expanded before the command runs. |
| **As literal** | Must be escaped as `\*` in regex to match a literal asterisk. |

```bash
grep 'fo*'          # regex: f followed by 0 or more o
ls *.log            # shell glob: all .log files (NOT regex)
grep '\*'           # matches a literal asterisk character
grep -F '1+1=2'     # -F disables regex entirely — safer for literal strings
```

> **Shell vs regex:** `grep '*.log'` does NOT work like `ls *.log`. In regex, `*` means "repeat", not "anything". Use `grep '\.log$'` to match files ending in .log.

---

### `^` — Caret

| Context | Meaning |
|---------|---------|
| **In regex (start of pattern)** | **Anchor: start of line.** `^ERROR` matches only lines that begin with ERROR. |
| **In character class `[^...]`** | **Negation.** `[^0-9]` matches any character that is NOT a digit. The `^` must be immediately after the opening `[`. |
| **Elsewhere in `[...]`** | Treated as a literal `^` character. `[a^b]` matches a, ^, or b. |
| **As literal** | Escape as `\^` to match a caret character. |

```bash
grep '^root'         # lines starting with "root"
grep '^[^#]'         # lines NOT starting with # (non-comment lines in config files)
grep '[^0-9]'        # lines containing a non-digit character
grep '\^'            # matches a literal ^ character
```

---

### `$` — Dollar Sign

| Context | Meaning |
|---------|---------|
| **In regex** | **Anchor: end of line.** `\.php$` matches lines ending with .php. `^$` matches empty lines. |
| **In shell** | **Variable expansion.** `$HOME`, `$USER`, `$1`. Always use single quotes `'...'` for grep patterns to prevent the shell from expanding `$`. |
| **As literal** | Escape as `\$` to match a dollar sign character. |

```bash
grep '\.php$'        # lines ending with .php
grep '^$'            # empty lines
grep -v '^$'         # non-empty lines (useful for removing blank lines from output)
grep '\$HOME'        # matches the literal string $HOME
grep '$HOME'         # WRONG with double quotes — shell expands $HOME first
grep '$HOME'         # correct with single quotes — passed literally to grep
```

> **Always use single quotes** around grep patterns. Double quotes allow shell variable expansion, which can silently break patterns containing `$`.

---

### `|` — Pipe

| Context | Meaning |
|---------|---------|
| **In regex (ERE/PCRE)** | **Alternation: OR.** `error\|warning` matches lines containing "error" OR "warning". In ERE (`-E`): `error\|warning`. In BRE (default): `error\\\|warning` (must escape). |
| **In shell** | **Pipe operator.** Passes the output of one command as input to the next. `grep 'error' syslog \| wc -l` — counts matching lines. Has nothing to do with regex. |
| **As literal** | Escape as `\|` in ERE, or use `[-]` — but a literal `\|` in a pattern is rarely needed. |

```bash
grep -E 'error|warning'         # ERE: matches either word
grep 'error\|warning'           # BRE: same, with escape
grep 'Failed' auth.log | wc -l  # shell pipe — not regex
```

---

### `[]` — Square Brackets (Character Class)

| Context | Meaning |
|---------|---------|
| **In regex** | **Character class.** Matches exactly one character from the set. `[abc]` = a, b, or c. `[0-9]` = any digit. `[^abc]` = anything except a, b, c. Ranges: `[a-z]`, `[A-Z]`, `[0-9]`. |
| **Special rules inside `[]`** | Most special characters lose their meaning inside `[]`. A `.` inside `[.]` matches a literal dot. A `*` inside `[*]` matches a literal asterisk. Exceptions: `^` (negation, if first), `-` (range, if between two chars), `\` (escape, in PCRE). |
| **In shell** | Shell glob for single character: `file[123].log` matches file1.log, file2.log, file3.log. |

```bash
grep '[Ee]rror'           # matches Error or error
grep '[0-9]\{3\}'         # 3 consecutive digits (BRE)
grep -E '[0-9]{3}'        # same, ERE
grep '[.]php'             # literal dot inside [] — matches .php
grep '[*]'                # literal asterisk — * loses special meaning inside []
grep '^[^#;]'             # lines not starting with # or ; (non-comment config lines)
```

---

### `()` — Parentheses (Groups)

| Context | Meaning |
|---------|---------|
| **In regex (ERE/PCRE)** | **Capturing group.** Groups part of a pattern together. Enables quantifiers on the group: `(ab)+` = one or more "ab". Enables alternation within: `(error\|fail)`. In BRE, must be escaped: `\(ab\)`. |
| **Non-capturing group (PCRE)** | `(?:...)` groups without capturing — use when you need grouping but not a backreference. |
| **Backreferences** | `\1` refers back to what group 1 matched. `(.).*\1` = a character, anything, then the same character again. |
| **In shell** | Used for subshells: `(cd /tmp && ls)`. No relation to regex. |

```bash
grep -E '(error|fail)ed'      # matches "errored" or "failed"
grep -E '(GET|POST|PUT)'      # matches any HTTP method
grep '\(abc\)'                # BRE: group (must escape parens)
grep -P '(?:https?|ftp)://'  # non-capturing group — matches http://, https://, ftp://
```

---

### `{}` — Curly Braces (Repetition)

| Context | Meaning |
|---------|---------|
| **In regex (ERE/PCRE)** | **Quantifier with exact count.** `[0-9]{3}` = exactly 3 digits. `[a-z]{2,5}` = 2 to 5 lowercase letters. In BRE, must be escaped: `\{3\}`. |
| **In shell** | Brace expansion: `{a,b,c}` or `{1..5}`. No relation to regex. |

```bash
grep -E '[0-9]{4}'        # exactly 4 digits (e.g. year)
grep -E '\b\d{1,3}\b'     # 1 to 3 digits as a whole word
grep '[0-9]\{3\}'         # BRE equivalent — must escape braces
```

---

### `?` — Question Mark

| Context | Meaning |
|---------|---------|
| **In regex (ERE/PCRE)** | **Quantifier: 0 or 1** of the preceding element — makes it optional. `colou?r` matches "color" and "colour". In BRE, must be escaped: `\?`. |
| **After quantifier (PCRE)** | **Non-greedy modifier.** `.*?` matches as few characters as possible (lazy), vs `.*` which matches as many as possible (greedy). |
| **In shell** | Single-character wildcard in globs: `file?.log` matches file1.log, filea.log. |

```bash
grep -E 'colou?r'         # matches color or colour
grep -E 'https?://'       # matches http:// or https://
grep -P '<.*?>'           # non-greedy: matches shortest possible tag
grep -E 'auth(entication)?' # matches "auth" or "authentication"
```

---

### `-` — Hyphen / Minus

| Context | Meaning |
|---------|---------|
| **Inside `[...]`** | **Range indicator** when between two characters: `[a-z]`, `[0-9]`, `[A-Za-z0-9]`. |
| **First or last in `[...]`** | Treated as a **literal hyphen** — `[-abc]` or `[abc-]` matches a hyphen, a, b, or c. |
| **Outside `[...]`** | No special meaning in regex. Matches a literal hyphen. |
| **In grep flags** | Prefix for flags: `-E`, `-i`, `-v`. `--` signals the end of options. |

```bash
grep '[a-z]'              # any lowercase letter
grep '[0-9-]'             # digit or literal hyphen (hyphen last in class)
grep '[-0-9]'             # hyphen or digit (hyphen first in class)
grep '192-168'            # literal hyphen between numbers — no escaping needed
```

---

### `#` — Hash / Pound

| Context | Meaning |
|---------|---------|
| **In regex** | **No special meaning.** Matches a literal `#` character. |
| **In shell / config files** | Comment character. Lines starting with `#` are ignored. |
| **In PCRE with verbose mode** | With `(?x)` flag, `#` starts a comment to end of line — enables annotated patterns. Rare in grep usage. |

```bash
grep '^#'                 # lines starting with # (comments in config files)
grep -v '^#'              # non-comment lines
grep -v '^[#;]'           # skip both # and ; comments (e.g. in .ini files)
grep -v '^[[:space:]]*#'  # skip comments that may have leading whitespace
```

---

### Greedy vs Non-Greedy (`.` and `*` together)

The combination `.*` is extremely common — and can produce surprising results:

```bash
# .* is GREEDY — matches as much as possible
echo '<b>bold</b> and <i>italic</i>' | grep -oE '<.*>'
# Result: <b>bold</b> and <i>italic</i>   (matches from first < to last >)

# .*? is NON-GREEDY (PCRE only) — matches as little as possible
echo '<b>bold</b> and <i>italic</i>' | grep -oP '<.*?>'
# Result: <b>   </b>   <i>   </i>   (matches each tag individually)
```

> In log analysis, `.*` between two anchors is usually fine. But when extracting specific fields (like HTML tags, JSON values, quoted strings), non-greedy `.*?` with `-P` is more reliable.

---

## Practical Log Analysis

### Auth Log (`/var/log/auth.log`)

```bash
# Failed SSH login attempts
grep "Failed password" /var/log/auth.log

# Successful SSH logins
grep "Accepted password\|Accepted publickey" /var/log/auth.log

# Top source IPs for failed logins
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head 20

# Failed logins for a specific user
grep "Failed password for root" /var/log/auth.log

# Invalid user attempts (non-existent accounts)
grep "Invalid user" /var/log/auth.log | awk '{print $8}' | sort | uniq -c | sort -rn

# sudo usage
grep "sudo" /var/log/auth.log | grep -v "pam_unix"

# Failed sudo attempts
grep "authentication failure" /var/log/auth.log | grep sudo

# User added to a group
grep "usermod\|groupadd\|adduser" /var/log/auth.log

# All events for a specific user
grep "user john\b" /var/log/auth.log
```

### Apache / Nginx Access Logs

```bash
# All 4xx and 5xx errors
grep -E '" [45][0-9]{2} ' /var/log/apache2/access.log

# 404s only
grep '" 404 ' /var/log/apache2/access.log

# POST requests (potential data submission / upload)
grep '"POST ' /var/log/apache2/access.log

# Requests to PHP files
grep -E '\.php(\?|")' /var/log/apache2/access.log

# Requests with suspicious query strings
grep -E '\?(cmd|exec|shell|system|passthru)=' /var/log/apache2/access.log

# Base64-encoded parameters in URLs
grep -E '\?[a-zA-Z]+=([A-Za-z0-9+/]{20,}={0,2})' /var/log/apache2/access.log

# Known attack tools in User-Agent
grep -iE '(sqlmap|nikto|nmap|masscan|dirbuster|gobuster|ffuf|wpscan|curl|wget)' /var/log/apache2/access.log

# Top requesting IPs
awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head 20

# Requests per HTTP status code
awk '{print $9}' /var/log/apache2/access.log | sort | uniq -c | sort -rn

# Rapid requests from one IP (brute force indicator)
grep "10.10.10.99" /var/log/apache2/access.log | awk '{print $4}' | sort | uniq -c | sort -rn
```

### Syslog & System Logs

```bash
# All errors and critical events
grep -iE 'error|critical|fail|panic' /var/log/syslog

# Kernel errors
grep "kernel" /var/log/syslog | grep -i "error\|oops\|panic"

# Segfaults
grep "segfault" /var/log/syslog

# OOM killer (out of memory)
grep -i "out of memory\|oom_kill" /var/log/syslog

# Service start/stop events
grep "systemd\[1\]" /var/log/syslog | grep -E "Started|Stopped|Failed"

# Cron job execution
grep "CRON" /var/log/syslog

# Events in a time window
grep "Mar  7" /var/log/syslog | grep -E "14:[0-9]{2}:[0-9]{2}"
```

### Webshell & Malware Hunting

```bash
# PHP files containing execution functions
grep -rE "(shell_exec|system|passthru|exec|popen)\s*\(" /var/www --include="*.php"

# eval() with base64 (classic obfuscated shell)
grep -rE "eval\s*\(\s*base64_decode" /var/www --include="*.php"

# base64_decode anywhere in PHP
grep -rl "base64_decode" /var/www --include="*.php"

# $_ superglobals used directly in execution (webshell pattern)
grep -rE '\$_(GET|POST|REQUEST|COOKIE)\s*\[' /var/www --include="*.php" | grep -E "(eval|system|exec)"

# Suspicious one-liner PHP files
find /var/www -name "*.php" -size -500c | xargs grep -lE "(system|exec|passthru)"

# Hidden .php files
find /var/www -name ".*.php" -type f
```

---

## Security-Relevant Regex Patterns

### Network Indicators

```bash
# IPv4 address (basic)
grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' file.txt

# IPv4 address (strict — validates 0-255 range, PCRE)
grep -oP '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b' file.txt

# IPv6 address
grep -oP '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}' file.txt

# HTTP/HTTPS URL
grep -oE 'https?://[a-zA-Z0-9./?=_%:-]+' file.txt

# Domain name
grep -oE '([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}' file.txt

# Email address
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' file.txt

# Port number in auth.log context
grep -oP '(?<=port )\d+' /var/log/auth.log

# MAC address
grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' file.txt
```

### File & Hash Indicators

```bash
# MD5 hash (32 hex chars)
grep -oE '[0-9a-fA-F]{32}' ioc_report.txt

# SHA1 hash (40 hex chars)
grep -oE '[0-9a-fA-F]{40}' ioc_report.txt

# SHA256 hash (64 hex chars)
grep -oE '[0-9a-fA-F]{64}' ioc_report.txt

# Windows file path
grep -oE 'C:\\[a-zA-Z0-9\\._-]+' report.txt

# Linux file path
grep -oE '/([a-zA-Z0-9._-]+/)+[a-zA-Z0-9._-]+' report.txt

# Suspicious file extensions in web logs
grep -E '\.(php|jsp|aspx|ashx|cfm|cgi|pl)\b' /var/log/apache2/access.log
```

### Encoded & Obfuscated Content

```bash
# Base64 string (20+ chars — avoids short false positives)
grep -oE '[A-Za-z0-9+/]{20,}={0,2}' file.txt

# Base64 string with word boundary (PCRE)
grep -oP '(?<![A-Za-z0-9+/])[A-Za-z0-9+/]{20,}={0,2}(?![A-Za-z0-9+/=])' file.txt

# URL-encoded characters (percent encoding)
grep -oE '%[0-9A-Fa-f]{2}' access.log | sort | uniq -c | sort -rn

# Unicode escape sequences (evasion technique)
grep -E '\\u[0-9a-fA-F]{4}' /var/log/apache2/access.log

# Log4Shell payload indicator (JNDI lookup)
grep -iE '\$\{jndi:' /var/log/apache2/access.log

# SQL injection patterns
grep -iE "(union\s+select|or\s+'[0-9]'='[0-9]|drop\s+table|--\s*$|;.*--)" /var/log/apache2/access.log

# XSS patterns
grep -iE "(<script|javascript:|on(load|error|click|mouseover)\s*=)" /var/log/apache2/access.log
```

### Windows Event Log Patterns (via exported text)

```bash
# Logon events
grep -E "EventID.*4624|4625|4648|4672" events.txt

# Process creation with command line
grep -A 5 "EventID.*4688" events.txt

# New service installed
grep -B 2 -A 10 "EventID.*7045" events.txt

# Audit log cleared
grep "EventID.*1102" events.txt

# Scheduled task created
grep -A 10 "EventID.*4698" events.txt
```

---

## Combining grep with Other Tools

### grep + sort + uniq (frequency analysis)

```bash
# Most common IPs in access log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head 20

# Most common User-Agents
awk -F'"' '{print $6}' access.log | sort | uniq -c | sort -rn | head 10

# Count failed logins per username
grep "Failed password" auth.log | awk '{print $9}' | sort | uniq -c | sort -rn

# Count HTTP status codes
awk '{print $9}' access.log | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn
```

### grep + cut / awk (field extraction)

```bash
# Extract only timestamps from auth.log matches
grep "Failed password" /var/log/auth.log | awk '{print $1, $2, $3}'

# Extract IP + port from SSH log
grep "Accepted" /var/log/auth.log | awk '{print $9, "port", $11}'

# Apache: extract status codes only
grep -oE '" [0-9]{3} ' access.log | grep -oE '[0-9]{3}'
```

### grep + xargs

```bash
# Search for a string in all PHP files
find /var/www -name "*.php" | xargs grep -l "base64_decode"

# Search safely with filenames containing spaces
find /var/www -name "*.php" -print0 | xargs -0 grep -lE "eval\("

# Hash all matched files for IOC collection
grep -rl "shell_exec" /var/www --include="*.php" | xargs sha256sum
```

### grep + tee (output to screen AND file)

```bash
# Save results while viewing them live
tail -f /var/log/auth.log | grep "Failed" | tee /tmp/failed_logins.txt
```

### Searching Compressed Logs

```bash
# zgrep — grep directly on .gz files (no decompression needed)
zgrep "Failed password" /var/log/auth.log.2.gz

# grep all rotated auth logs at once
zgrep "Failed password" /var/log/auth.log* 2>/dev/null
```

---

## Multiple Patterns

```bash
# OR — match either pattern (-E)
grep -E 'error|warning|critical' /var/log/syslog

# OR — multiple -e flags
grep -e 'error' -e 'warning' -e 'critical' /var/log/syslog

# AND — pipe grep into grep (both must match on same line)
grep 'Failed' /var/log/auth.log | grep 'root'

# AND — using PCRE lookahead
grep -P '(?=.*Failed)(?=.*root)' /var/log/auth.log

# NOT (exclude noise while searching)
grep 'error' /var/log/syslog | grep -v 'debug\|info'

# Patterns from a file (one per line)
grep -f /tmp/known_bad_ips.txt /var/log/apache2/access.log
```

---

## Blue Team Recipes

```bash
# --- Brute force detection: IPs with >10 failed SSH attempts ---
grep "Failed password" /var/log/auth.log \
  | awk '{print $11}' \
  | sort | uniq -c | sort -rn \
  | awk '$1 > 10 {print $1, $2}'

# --- Check for successful login after many failures (credential stuffing) ---
grep -E "Failed password|Accepted password" /var/log/auth.log \
  | grep "10.10.10.99"

# --- Detect new user accounts created ---
grep -E "useradd|adduser|new user" /var/log/auth.log

# --- Find all commands run via sudo ---
grep "sudo:" /var/log/auth.log | grep "COMMAND="

# --- Apache: scan for directory traversal attempts ---
grep -E "\.\./|\.\.%2[Ff]|%2[Ee]%2[Ee]" /var/log/apache2/access.log

# --- Find all non-200 responses to .php files ---
grep '\.php' /var/log/apache2/access.log | grep -v '" 200 '

# --- Timeline of a specific IP's activity ---
grep "10.10.10.99" /var/log/apache2/access.log | awk '{print $4, $6, $7, $9}'

# --- Count requests per minute for an IP (spot rate anomalies) ---
grep "10.10.10.99" /var/log/apache2/access.log \
  | awk '{print $4}' \
  | cut -d: -f1,2 \
  | sort | uniq -c

# --- Find log entries outside business hours (e.g. 22:00-06:00) ---
grep -E "\[../.../....:2[2-9]:|..:..\]|\[../.../....:0[0-5]:" /var/log/apache2/access.log
```

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| `grep 'a+b'` without `-E` | `+` not special in BRE | Use `grep -E 'a+b'` or `grep 'a\+b'` |
| `grep 'a\|b'` without `-E` | `\|` treated as literal in ERE | Use `grep -E 'a\|b'` |
| Unescaped `.` in IP patterns | Matches any char, not literal dot | Use `\.` instead of `.` |
| `-o` with anchors `^` / `$` | Only the matched part is printed, anchors may not behave as expected | Test with sample input |
| Forgetting quotes around pattern | Shell expands `*`, `?`, `[` before grep sees them | Always quote: `grep 'pattern'` |
| `grep -r 'pattern' /` on large filesystem | Very slow, many permission errors | Add `2>/dev/null` and use `--include` |
| Using BRE `{n}` without escape | In BRE, use `\{n\}` not `{n}` | Switch to `-E` to avoid this |
| Double quotes with `$` in pattern | Shell expands `$VAR` before grep sees it | Always use single quotes |
| `192.168.1.1` as IP pattern | `.` matches any char, not literal dot | Use `192\.168\.1\.1` |

---

## Quick Reference: grep Regex Modes

```bash
# BRE (default) — escape + ? | { } ( )
grep 'error\|warning'             # OR in BRE
grep 'error\+s'                   # 1 or more in BRE

# ERE (-E) — +, ?, |, {}, () work without escaping
grep -E 'error|warning'
grep -E 'failed? (login|auth)'
grep -E '[0-9]{3}'

# PCRE (-P) — full Perl syntax + \d \s \w + lookahead/behind
grep -P '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
grep -P '(?<=port )\d+'
grep -P '\b(root|admin|sudo)\b'
```

---

## Useful Tools & Resources

| Tool | Description |
|------|-------------|
| [regex101.com](https://regex101.com) | Interactive regex tester with explanation (supports PCRE, ERE) |
| [regexr.com](https://regexr.com) | Visual regex builder with cheatsheet |
| CyberChef | Decode base64, URL-encode, and test regex patterns offline |
| `pcregrep` | grep using PCRE library (alternative to `grep -P`) |
| `egrep` | Alias for `grep -E` — extended regex |
| `zgrep` | grep on compressed `.gz` files |

---

## Related

- [[find Command Cheat Sheet]] – Using `find` with `grep -exec` for file system searches
- [[Linux-Terminal-Commands]] – Full Linux reference including `awk`, `sed`, `cut`, `sort`, `uniq`
- [[Detecting Web Attacks]] – Log-based detection: brute force, SQLi, fuzzing patterns
- [[Detecting Web Shells]] – Grep-based webshell hunting in practice
- [[Snort]] – PCRE in Snort rules (`pcre:` option uses same syntax as `grep -P`)
