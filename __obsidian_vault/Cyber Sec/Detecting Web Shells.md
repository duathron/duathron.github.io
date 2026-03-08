---
title: "Detecting Web Shells"
tags: [web-shells, detection, log-analysis, network-forensics, file-system, auditd, blue-team, soc, php, wireshark]
---

# Detecting Web Shells

TryHackMe room summary. Covers what web shells are, how they are deployed, and how to detect them through log analysis, file system inspection, and network traffic analysis.

---

## What Is a Web Shell?

A web shell is a malicious program uploaded to a target web server that enables an attacker to execute commands remotely via a browser or HTTP request. It functions as both an **initial access vector** (exploiting file upload vulnerabilities) and a **persistence mechanism**.

Once deployed, a web shell allows an attacker to continue through the kill chain:
- Reconnaissance
- Privilege escalation
- Lateral movement
- Data exfiltration

**Simple PHP example** – the shell checks for a `?cmd=` parameter in the URL, passes it to `shell_exec()`, and returns the output:

![[webshell-anatomy-php.svg]]

---

## Deployment & Real-World Examples

A web shell requires a **file upload vulnerability, misconfiguration, or prior access** to reach the server. Vulnerabilities arise when applications fail to validate file type, extension, content, or upload destination.

### Examples in the Wild

**Hafnium / ProxyLogon** – Chinese APT uploaded `.aspx` web shells to Windows Exchange servers in directories like `\inetpub\wwwroot\aspnet_client\` and modified existing `.aspx` files under `\FrontEnd\HttpProxy\owa\auth\`. Post-upload actions: credential dumping, lateral movement, persistence via new accounts, data exfiltration.

**Conti Ransomware** – Exploited the same Exchange vulnerability to upload `aspnetclient_log.aspx` to the `\aspnet_client\` directory. Within minutes: uploaded a backup shell, mapped the network, identified domain controllers and admins.

---

## Log-Based Detection

### Access Log Format

Every HTTP request to a web server is recorded in the access log. Fields vary by server software but generally include:

![[access-log-fields.svg]]

> The remote log name and authenticated user fields typically appear as `-` unless authentication was required.

### Web Indicators

**Unusual HTTP Methods & Request Patterns**

| Method | Normal Usage | Possible Abuse |
|--------|-------------|----------------|
| `GET` | Retrieve a resource | Recon or web shell interaction |
| `POST` | Submit data | Upload or interact with a web shell |
| `PUT` | Upload/replace a file | Upload a web shell directly |
| `DELETE` | Remove a resource | Cleanup after attack |
| `OPTIONS` | Query supported methods | Reconnaissance |
| `HEAD` | Headers only (no body) | Detect files without downloading |

**Patterns to watch for:**
- Repeated `GET` requests in quick succession → directory/upload path probing
- `POST` to a valid upload location following `GET` probing
- Repeated `GET` or `POST` to the same file → active web shell interaction

### Attack Sequence in Logs

![[attack-sequence-logs.svg]]

Typical sequence:
1. Attacker fuzzes for valid directories → mix of `404` and `200` responses
2. Finds an upload form → sends `POST` with shell file
3. Accesses the uploaded shell via `GET` with a `?cmd=` parameter

Note: shared client IP and User-Agent across all steps; timestamps in quick succession.

### Suspicious User-Agents & IP Addresses

- **Altered:** `Mozilla/4.0+(+Windows+NT+5.1)` (unusual encoding or truncation)
- **Outdated:** `Mozilla/4.0 (compatible; MSIE 6.0)` – IE6 released 2001
- **Blacklisted tools:** `curl/1.XX.X`, `wget/1.XX.X`, `sqlmap`, `wpscan`
- **External IP** on a network that normally only sees internal traffic

### Query Strings

- Abnormally long strings, especially with keywords like `cmd=`, `exec=`, `shell=`
- Base64-encoded parameters: `?query=whoami` → `?query=d2hvYW1p`
  Use [[Detecting Web Attacks#Network Traffic Analysis|CyberChef]] to decode.

### Missing Referrer

A missing referrer means the page was accessed directly rather than via a link. Not a conclusive indicator on its own (browsers may suppress referrers for privacy), but suspicious in combination with other indicators.

### Suspicious Request – Example

![[suspicious-web-request.svg]]

Indicators visible in this sample:
1. Known malicious or untrusted source IP
2. Abnormal timestamp (outside business hours)
3. `POST` with a suspicious query string to a malicious file
4. No referrer
5. Non-browser User-Agent string

### Auditd

Native Linux utility that records system events based on configured rules. Useful for detecting file creation, modification, and command execution by specific processes.

```bash
# Search audit log for events matching the web_shell rule
ausearch -k web_shell
```

Sample output:
```
time->Wed Jul 23 06:20:36 2025
"name = /uploads/webshell.php"
"OGID = www-data"
```

### Web + Auditd Correlation

Combining web access logs with auditd provides confirmation across two sources:
- A suspicious `POST` in web logs → matched `creat` or `execve` syscall in auditd
- Shows which process wrote the file and under which user account
- Builds a clearer picture of the attack sequence

### SIEM

SIEM platforms aggregate and correlate multiple log types in one place:
- Centralized collection from web logs, auditd, OS logs
- Targeted queries to surface web shell indicators
- More efficient than manual log review across disparate sources

---

## File System Analysis

The web shell must be stored somewhere on disk. Key locations to check:

| Server | Default Web Root |
|--------|-----------------|
| Apache | `/var/www/html/` |
| Nginx | `/usr/share/nginx/html/` |

Common upload paths attackers target: `/uploads/`, `/images/`, `/admin/`, `/tmp/`

> WordPress and Django store content in a database rather than the file system – malicious code may be injected into posts, themes, or settings and won't appear in file system searches.

### Suspicious File Indicators

- Executable extensions in non-code directories: `.php`, `.jsp`, `.aspx`
- Double extensions to disguise files: `image.jpg.php`
- Random or non-standard filenames that deviate from application files
- Recently modified files that don't correspond to known deployments

### find & grep

![[find-grep-commands.svg]]

```bash
# PHP files modified in July 2025
find /var/www -type f -name "*.php" -newerct "2025-07-01" ! -newerct "2025-08-01"
# → /var/www/html/uploads/awebshell.php

# Search WordPress uploads for eval() calls
grep -r "eval(" wp-content
# → /wp-content/uploads/awebshell2.php :eval(b64_dd($['cmd']));
```

See also: [[Linux-Terminal-Commands]] – `find`, `grep` reference with forensics-specific patterns.

---

## Network Traffic Analysis

Packet captures reveal what logs cannot: full request and response content, including POST bodies, uploaded file contents, and command output.

Indicators from log analysis apply here too:
- Unusual HTTP methods and request patterns
- Suspicious User-Agents and IP addresses
- Encoded payloads (`base64`, URL encoding)
- Malicious code or commands in request bodies
- Unexpected protocols or ports
- Web server processes spawning command-line tools

### Useful Wireshark Filters

```
http                                    # HTTP traffic only
http.request.method == "POST"           # POST requests
http.request.uri contains ".php"        # Requests to PHP files
http.user_agent                         # Inspect User-Agent values
```

Full reference: [Wireshark HTTP filters](https://wiki.wireshark.org/HTTP)

### Attack Sequence in Wireshark

![[__obsidian_vault/assets/img/Detecting Web Shells/wireshark-attack-sequence.svg]]

The same sequence from the log examples (fuzz → upload → shell interaction) is visible as individual packets, with timestamps and source IPs confirming the chain.

### Shell Payload Visible in Packet

![[wireshark-shell-payload.svg]]

In a `POST /upload.php` packet, the PHP shell source code is visible in the payload – directly confirming the upload attempt. This level of detail is not available in access logs alone.

---

## Related

- [[Detecting Web Attacks]] – Broader web attack detection: SQLi, brute force, XSS, WAF
- [[Linux-Terminal-Commands]] – `find`, `grep`, `auditd`, `strings` for file system and log analysis
- [[Snort]] – Network-level detection; complements PCAP-based web shell hunting
- [[2026-02-23-infinity-shell]] – Writeup: PHP one-liner webshell in a CMS image directory, Base64-encoded commands in Apache logs

---

## References

- [MITRE ATT&CK – Web Shell (T1505.003)](https://attack.mitre.org/techniques/T1505/003/)
- [CISA – Hafnium / ProxyLogon Advisory](https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-062a)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [Wireshark HTTP Filters](https://wiki.wireshark.org/HTTP)
- [TryHackMe Room](https://tryhackme.com/room/detectingwebshells)
