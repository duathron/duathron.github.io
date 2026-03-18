---
title: TryHackMe — Snort Challenge - The Basics
date: 2026-03-24 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - snort-challenges-1
  - medium
published: true
image:
  path: /assets/img/posts/snort-challenges-1/cover.png
  alt: Snort Challenge - The Basics
related_notes: ["[[Snort]]"]
---

## Overview

Practical follow-up to the [Snort Room](https://tryhackme.com/room/snort) in the SOC Level 1 path. Instead of reading about concepts, this room is about writing actual rules and testing them against PCAP files. Eight tasks covering different scenarios — from basic ICMP rules through FTP analysis to Log4Shell exploitation traffic.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Snort Challenge - The Basics |
| Difficulty | Medium |
| Tags | snort, ids, rule-writing, ftp, pcap, log4j, eternalblue |

---

## Task 2 — Simple Rules

The starting point: writing ICMP rules and running them against a PCAP. The basic structure was familiar from the Snort room:

```
alert icmp any any -> any any (msg:"ICMP Packet Found"; sid:1000001; rev:1;)
```

What turned out to be less straightforward: getting useful output. Snort doesn't print alerts to stdout by default — they go into a log file. The approach that worked: run Snort with `-A full -l .` to generate an `alert` file, then read that file directly:

```bash
grep -a "FTP login" alert | wc -l
```

<img src="/assets/img/posts/snort-challenges-1/task2-grep.png" alt="grep on the alert file returns the number of matched alerts" width="700">

This became the standard pattern for the rest of the room.

---

## Task 3 — FTP

### Bidirectional Rules and Port Placement

My first attempt used `any 21 <> any 21` — which seemed logical for FTP traffic. That rule produced no alerts. A bidirectional rule written that way only matches packets where *both* endpoints use port 21, which doesn't happen in practice. The correct approach:

```
alert tcp any any <> any 21 (...)
```

This matches both directions — client requests going to port 21 and server responses coming from port 21.

### Content Filters for Login Scenarios

```
# Failed login (530 User)
alert tcp any 21 -> any any (msg:"Failed FTP login detected!"; flow:established,from_server; content:"530 User"; sid:100002; rev:1;)

# Successful login (230 User)
alert tcp any 21 -> any any (msg:"Successful FTP login detected!"; flow:established,from_server; content:"230 User"; sid:100003; rev:1;)

# No password provided (331 Password)
alert tcp any 21 -> any any (msg:"Failed FTP login detected! No password provided."; flow:established,from_server; content:"331 Password"; sid:100004; rev:1;)

# Admin login without password
alert tcp any 21 -> any any (msg:"Failed FTP ADMIN login detected! No password provided."; flow:established,from_server; content:"331 Password"; content:"Administrator"; sid:100005; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task3-rules.png" alt="local.rules for Task 3 showing FTP rules" width="700">

---

## Task 4 — PNG and GIF

My first approach was to filter by file extension — looking for `.png` or `.gif` in the traffic. That produced nothing useful.

### Magic Bytes as a Reliable Signature

| Format | Magic Bytes (Hex) |
|--------|------------------|
| PNG | `89 50 4E 47` |
| GIF | `47 49 46 38` |

```
alert tcp any any <> any any (msg:"Found PNG file."; content:"|89 50 4E 47|"; sid:100001; rev:1;)
alert tcp any any <> any any (msg:"Found GIF file."; content:"|47 49 46 38|"; sid:100002; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task4-rules.png" alt="local.rules for Task 4 with magic byte rules" width="700">

<img src="/assets/img/posts/snort-challenges-1/task4-alert.png" alt="Alert output showing detected GIF files" width="700">

---

## Task 5 — Torrent Metafiles

```
alert tcp any any <> any any (msg:"Torrent file detected!"; content:".torrent"; nocase; sid:100001; rev:1;)
```

Running Snort with `-vde` made the full payload readable — the MIME type `application/x-bittorrent` and client name were both visible.

<img src="/assets/img/posts/snort-challenges-1/task5-payload.png" alt="Snort verbose output showing torrent payload" width="700">

---

## Task 6 — Rule Debugging

Most common issues:

- `:` instead of `;` as the option separator
- Missing `msg` option
- Duplicate `sid` values
- `<-` doesn't exist — only `->` and `<>`

```
# Broken — missing source port field
alert icmp any -> any any (msg: "Troubleshooting 2"; sid:1000001; rev:1;)

# Fixed
alert icmp any any -> any any (msg:"Troubleshooting 2"; sid:1000001; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task6-broken.png" alt="Broken rule — missing source port field" width="700">

<img src="/assets/img/posts/snort-challenges-1/task6-fixed.png" alt="Fixed rule with complete syntax" width="700">

---

## Task 7 — EternalBlue (MS17-010)

CVE-2017-0144, CVSS v2: 9.3.

```bash
sudo snort -c ./local.rules -r ms-17-010.pcap -vde -A full -l .
```

### Filtering for IPC$ — Escape Sequence Problem

A single `\` in a content string throws `bad escape sequence`. Fix:

```
content:"\\IPC$";
```

Reading the first ten packets from the generated log:

```bash
sudo snort -r snort.log.1772573153 -vde -n 10
```

---

## Task 8 — Log4Shell (CVE-2021-44228)

CVE-2021-44228, CVSS v2: 9.3.

### Packet Size Rule

```
alert tcp any any <> any any (msg:"Matching packet size.(770<>855)"; dsize:770<>855; sid:1000001; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task8-dsize.png" alt="dsize rule resulting in 41 alerts" width="700">

### Finding the Encoding Algorithm

The early packets were full of `%` characters — I assumed percent-encoding. Wrong. Further into the payload, `Base64` appeared as plain text inside the attack string.

<img src="/assets/img/posts/snort-challenges-1/task8-payload.png" alt="Hex dump of Log4Shell payload" width="700">

<img src="/assets/img/posts/snort-challenges-1/task8-base64.png" alt="Base64 visible in the Snort log payload" width="700">

---

## Tools Used

| Tool | Purpose |
|------|---------|
| Snort | Rule engine — PCAP analysis, alert generation |
| `grep` + `wc -l` | Parsing alert files |
| CyberChef | Base64 decoding |
| NVD | CVSS scores for CVE-2017-0144 and CVE-2021-44228 |

---

## Lessons Learned

**Port placement matters in bidirectional rules.** `any 21 <> any 21` matches nothing useful. The monitored port goes on the right side only: `any any <> any 21`.

**File extensions are unreliable as detection signatures.** Magic bytes are more reliable — the first bytes identify a file's format regardless of its name.

**Snort output doesn't pipe the way I expected.** Run with `-A full -l .` and work with the generated files.

**Double backslash for a literal backslash in content strings.** `\\IPC$` is the correct syntax.

**Read more of the payload before guessing.** Base64 only appeared further down in the Task 8 payload — committing to percent-encoding based on the first visible characters cost a wrong attempt.

---

## References

- [Snort Room (TryHackMe)](https://tryhackme.com/room/snort) — Basics, rule structure, operating modes
- [NVD — CVE-2017-0144 (EternalBlue)](https://nvd.nist.gov/vuln/detail/CVE-2017-0144)
- [NVD — CVE-2021-44228 (Log4Shell)](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [TryHackMe Room](https://tryhackme.com/room/snortchallenges1)
