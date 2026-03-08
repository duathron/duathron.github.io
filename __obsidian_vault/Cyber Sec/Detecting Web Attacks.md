---
title: "Detecting Web Attacks"
tags: [web-attacks, detection, log-analysis, network-forensics, waf, sqli, xss, brute-force, blue-team, soc]
---

# Detecting Web Attacks

TryHackMe room summary. Covers client-side and server-side attacks, detection via logs and network traffic, and Web Application Firewalls (WAF).

---

## Overview

Web attacks are among the most common entry points for attackers. Public-facing websites often sit in front of databases and critical infrastructure. Detection relies on three complementary sources:

1. **Server-side access logs** – what was requested and when
2. **Network traffic captures** – what was actually sent and received
3. **WAF rules** – what can be blocked before it reaches the application

---

## Client-Side Attacks

Attacks that occur **inside the user's browser**. The server processes a legitimate-looking request – the malicious action happens client-side.

![[client-side-attacks-overview.svg]]

| Attack | Description |
|--------|-------------|
| **XSS (Cross-Site Scripting)** | Malicious script injected into a trusted page and executed in the victim's browser. Example: comment box without input filtering runs `<script>` tags that steal session cookies. |
| **CSRF (Cross-Site Request Forgery)** | Browser is tricked into sending unauthorized requests on behalf of the authenticated user. |
| **Clickjacking** | Invisible element overlaid on legitimate content – user clicks on something they can't see. |

### SOC Limitations

Server-side logs and network captures show **almost nothing** of what happens inside a browser. Client-side attacks can:
- Execute malicious code locally
- Steal information without generating suspicious HTTP requests
- Manipulate the browser environment silently

Detection requires endpoint monitoring or browser-side security controls – outside typical SOC tooling.

---

## Server-Side Attacks

Attacks that target **the server, application code, or backend**. These leave evidence in logs and network traffic.

![[server-side-attacks-overview.svg]]

| Attack | Description | Real-World Example |
|--------|-------------|-------------------|
| **Brute Force** | Automated, repeated login attempts using credential lists or common passwords | T-Mobile 2021 breach – PII of 50M+ customers exposed |
| **SQL Injection (SQLi)** | User input alters SQL queries via string concatenation instead of parameterized queries | MOVEit 2023 – 2,700+ organizations affected, incl. BBC, British Airways, US gov agencies |
| **Command Injection** | Unvalidated input passed directly to the OS – server executes attacker-controlled commands | — |

---

## Log-Based Detection

Every HTTP request is recorded in server access logs. Access logs won't show POST body data by default, but patterns in the metadata reveal attacks.

### Access Log Format

![[access-log-format.svg]]

| Field | Suspicious Indicator |
|-------|---------------------|
| Client IP | Known malicious IP, unusual geo-location |
| Timestamp | Requests at unusual hours, rapid succession |
| Status Code | Many `404` → directory fuzzing; `302` after repeated `POST` → successful brute force |
| Response Size | Abnormally large (data dump) or small (error) |
| Referrer | Doesn't match normal site navigation |
| User-Agent | Attack tools: `sqlmap`, `wpscan`, `ffuf`, `hydra` |

### Attack Sequence in Logs

![[attack-sequence-in-logs.svg]]

**Typical sequence:**

1. **Directory fuzzing** – many `GET` requests in rapid succession, mix of `404` and `200` responses
2. **Brute force** – repeated `POST` to `/login.php`, all returning `401`/`403`, until one returns `302 Found` (redirect to account page = success)
3. **SQLi** – requests to `/search` or similar with payloads like `' OR '1'='1` or `1' OR 'a'='a` visible in query strings (GET) – POST body not logged by default

### Log Limitations

Access logs do **not** record POST body data. A login attempt looks like:
```
10.10.10.100 [12/Aug/2025:14:32:10] "POST /login HTTP/1.1" 200 532 "/home.html" "Mozilla/5.0"
```
The credentials are invisible. GET requests may include query strings (and therefore SQLi payloads), but this depends on server configuration. For full request/response content → network traffic analysis.

---

## Network Traffic Analysis

Packet captures provide what logs cannot: **full request and response content**, including POST bodies, cookies, credentials, and query results.

> Limitation: encrypted traffic (HTTPS, SSH) hides payload content without decryption keys. Applies to unencrypted HTTP in these examples.

### Attack Sequence in Wireshark

![[__obsidian_vault/assets/img/Detecting Web Attacks/wireshark-attack-sequence.svg]]

Useful Wireshark filters for this context:

```
http                              # all HTTP traffic only
ip.dst == 10.10.20.200            # filter by destination IP
http.user_agent contains "sqlmap"
http.request.method == "POST"
http.response.code == 302
```

**Right-click → Follow → HTTP Stream** reconstructs the full conversation between client and server.

### Brute Force – Credentials Visible

![[wireshark-bruteforce-credentials.svg]]

In the packet details of the successful POST request (the one returning `302`), the submitted credentials are visible in plaintext in the HTTP body – e.g. `username=admin&password=password123`.

### SQLi – Response Data Visible

![[wireshark-sqli-response.svg]]

The SQLi payload (`' OR '1'='1`) and the server's response – including dumped table data (names, records) – are both visible in the packet. MySQL protocol traffic can also be analyzed directly in Wireshark.

---

## Web Application Firewall (WAF)

WAFs sit in front of the application and inspect full request packets before they reach the server. Unlike standard logs, WAFs can **decrypt TLS traffic** and act on the content.

![[waf-overview.svg]]

### Rule Types

![[waf-rules.svg]]

| Rule Type | Description | Example |
|-----------|-------------|---------|
| Block attack patterns | Known malicious payloads and signatures | Block User-Agent: `sqlmap` |
| Deny malicious sources | IP reputation, threat intel, geo-blocking | Block IPs from recent botnet campaigns |
| Custom rules | Tailored to specific application logic | Allow only GET/POST to `/login` |
| Rate limiting | Limits request frequency to prevent abuse | Max 5 login attempts/min per IP |

**Example rule:**
```
If User-Agent contains "sqlmap" → BLOCK
```

### Challenge-Response

Instead of outright blocking, WAFs can respond with CAPTCHA challenges – useful for rules that might affect legitimate users. Relevant because malicious bot traffic accounts for ~37% of global web traffic.

### Threat Intelligence Integration

Modern WAFs include:
- Built-in rule sets covering OWASP Top 10
- Automatically updated blocklists (known malicious IPs, suspicious User-Agents)
- Coverage for known APT group TTPs and recent CVEs

---

## Detection Sources – Comparison

| | Access Logs | Network Capture | WAF |
|--|-------------|----------------|-----|
| POST body visible | ✗ | ✓ | ✓ (with TLS termination) |
| GET query strings | Sometimes | ✓ | ✓ |
| Credentials | ✗ | ✓ (HTTP) | ✓ |
| Response data | ✗ | ✓ | ✓ |
| Real-time blocking | ✗ | ✗ | ✓ |
| Easy to query/grep | ✓ | Needs tool (Wireshark) | Depends on product |

---

## Related

- [[Snort]] – Network-level detection and rule writing; complements WAF and pcap analysis
- [[ffuf Cheat Sheet]] – The tool used for directory fuzzing; patterns appear in access logs exactly as described here
- [[Linux-Terminal-Commands]] – `grep`, `awk`, `cut`, `sort`, `uniq` for log analysis on the command line
- [[PowerShell-Commands]] – `Select-String`, `Get-WinEvent` for equivalent log analysis on Windows
- [[CIA-Triad]] – SQLi and brute force primarily threaten Confidentiality and Integrity

---

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [T-Mobile Breach 2021](https://www.t-mobile.com/news/network/additional-information-regarding-2021-cyberattack)
- [MOVEit Vulnerability 2023 – CISA Advisory](https://www.cisa.gov/news-events/cybersecurity-advisories/aa23-187a)
- [Cloudflare – Managed IP Lists](https://developers.cloudflare.com/waf/tools/lists/managed-lists/)
- [TryHackMe Room](https://tryhackme.com/room/detectingwebattacks)
