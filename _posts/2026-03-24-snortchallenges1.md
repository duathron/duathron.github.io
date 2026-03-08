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

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Snort Challenge - The Basics |
| Difficulty | Medium |
| Tags | snort, ids, rule-writing, ftp, pcap, log4j, eternalblue |

Practical follow-up to the [Snort Room](https://tryhackme.com/room/snort) in the SOC Level 1 path. Instead of reading about concepts, this room is about writing actual rules and testing them against PCAP files. Eight tasks covering different scenarios — from basic ICMP rules through FTP analysis to Log4Shell exploitation traffic.

---

## Task 2 — Simple Rules

The starting point: writing ICMP rules and running them against a PCAP. The basic structure was familiar from the Snort room:

```
alert icmp any any -> any any (msg:"ICMP Packet Found"; sid:1000001; rev:1;)
```

What turned out to be less straightforward: getting useful output. Snort doesn't just print alerts to stdout by default — they go into a log file. Piping directly into `grep` doesn't work the way I expected with BPF filters, because BPF filters operate at the packet level, not on alert strings. The approach that worked: run Snort with `-A full -l .` to generate an `alert` file, then read that file directly:

```bash
grep -a "FTP login" alert | wc -l
```

<img src="/assets/img/posts/snort-challenges-1/task2-grep.png" alt="grep on the alert file returns the number of matched alerts" width="700">

This became the standard pattern for the rest of the room: let Snort run, then work with the generated files.

---

## Task 3 — FTP

The goal here was to detect FTP traffic and distinguish between different login scenarios using FTP response codes. Getting the first rule to work took longer than expected.

### Bidirectional Rules and Port Placement

My first attempt used `any 21 <> any 21` — which seemed logical for FTP traffic on port 21. That rule produced no alerts. After some trial and error, I figured out why: a bidirectional rule written that way only matches packets where *both* endpoints are using port 21, which doesn't happen in practice. The correct approach is to put the monitored port on the right side only:

```
alert tcp any any <> any 21 (...)
```

This matches both directions — client requests going to port 21 and server responses coming from port 21.

### Content Filters for Login Scenarios

FTP response codes identify connection states precisely. Once the port placement was sorted, each follow-up task was a variation of the same base rule with a different `content` filter:

```
# Failed login (530 User)
alert tcp any 21 -> any any (msg:"Failed FTP login detected!"; flow:established,from_server; content:"530 User"; sid:100002; rev:1;)

# Successful login (230 User)
alert tcp any 21 -> any any (msg:"Successful FTP login detected!"; flow:established,from_server; content:"230 User"; sid:100003; rev:1;)

# No password provided (331 Password)
alert tcp any 21 -> any any (msg:"Failed FTP login detected! No password provided."; flow:established,from_server; content:"331 Password"; sid:100004; rev:1;)
```

The last task combined two `content` fields to detect an admin login attempt without a password specifically:

```
alert tcp any 21 -> any any (msg:"Failed FTP ADMIN login detected! No password provided."; flow:established,from_server; content:"331 Password"; content:"Administrator"; sid:100005; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task3-rules.png" alt="local.rules for Task 3 showing the FTP rules" width="700">

The `flow:established,from_server` modifier limits matching to server response packets rather than client requests.

---

## Task 4 — PNG and GIF

My first approach was to filter by file extension — looking for `.png` or `.gif` in the traffic. That produced nothing useful. File extensions might appear in HTTP headers, but they're not reliably present in the packet payload during the actual transfer.

### Magic Bytes as a Reliable Signature

The working approach: magic bytes. Every file format starts with a fixed byte sequence that identifies it regardless of filename or extension.

| Format | Magic Bytes (Hex) |
|--------|------------------|
| PNG | `89 50 4E 47` |
| GIF | `47 49 46 38` |

Snort rules using hex content syntax:

```
alert tcp any any <> any any (msg:"Found PNG file."; content:"|89 50 4E 47|"; sid:100001; rev:1;)
alert tcp any any <> any any (msg:"Found GIF file."; content:"|47 49 46 38|"; sid:100002; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task4-rules.png" alt="local.rules for Task 4 with magic byte rules for PNG and GIF" width="700">

Snort reliably detected GIF packets regardless of filename.

<img src="/assets/img/posts/snort-challenges-1/task4-alert.png" alt="Alert output and Snort verbose output showing detected GIF files" width="700">

---

## Task 5 — Torrent Metafiles

Torrent files don't have stable magic bytes — the header varies between clients. But they do always contain an `announce` key (the tracker URL) or an `info` section. The simplest rule that worked:

```
alert tcp any any <> any any (msg:"Torrent file detected!"; content:".torrent"; nocase; sid:100001; rev:1;)
```

Running Snort with `-vde` made the full payload readable, which opened up additional options: the MIME type `application/x-bittorrent` and the client name were both visible in the traffic.

<img src="/assets/img/posts/snort-challenges-1/task5-payload.png" alt="Snort verbose output showing torrent payload including announce URL and client information" width="700">

---

## Task 6 — Rule Debugging

Broken rules to fix. The most common issues:

- `:` instead of `;` as the separator between rule options
- Missing `msg` option
- Duplicate `sid` values
- Wrong direction operator: Snort does not support `<-`, only `->` and `<>`

Two rules that illustrated the syntax difference directly:

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

PCAP analysis of EternalBlue exploitation traffic (CVE-2017-0144, CVSS v2: 9.3).

### Initial Analysis with Existing Rules

```bash
sudo snort -c ./local.rules -r ms-17-010.pcap -vde -A full -l .
```

Alert counts and triggered rules were readable directly from the terminal output.

### Filtering for IPC$ — Escape Sequence Problem

To filter for the SMB path `\IPC$` in a content match, the obvious approach is to put the backslash directly in the content string. That throws a `bad escape sequence` error. The fix is a double backslash:

```
content:"\\IPC$";
```

### Inspecting Packets from the Generated Log

After the first run, a `snort.log.xxxxxxxx` file sits in the working directory. Reading the first ten packets from it:

```bash
sudo snort -r snort.log.1772573153 -vde -n 10
```

This shows the full payload of the first ten matched packets — useful for pulling out specific strings or paths.

---

## Task 8 — Log4Shell (CVE-2021-44228)

CVE-2021-44228, known as Log4Shell, has a CVSS v2 score of 9.3.

### Initial Analysis

```bash
sudo snort -c ./local.rules -r log4j.pcap -vde -A full -l .
```

Alert counts and triggered SIDs were visible directly in the terminal.

### Packet Size Rule

A rule filtering by packet size:

```
alert tcp any any <> any any (msg:"Matching packet size.(770<>855)"; dsize:770<>855; sid:1000001; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-1/task8-dsize.png" alt="dsize rule resulting in 41 alerts in the Action Stats output" width="700">

### Finding the Encoding Algorithm

The question asked for the encoding algorithm used in the attack payload. Looking at the first packets, the payload was full of `%` and `+` characters — my first assumption was that this pointed to percent-encoding. That was wrong; those characters were part of URL-encoded strings in the HTTP request, not the answer the question was looking for.

Further into the payload, the actual answer showed up explicitly: `Base64` appeared as plain text inside the attack string itself.

<img src="/assets/img/posts/snort-challenges-1/task8-payload.png" alt="Hex dump of the Log4Shell payload" width="700">

<img src="/assets/img/posts/snort-challenges-1/task8-base64.png" alt="strings and grep showing Base64 explicitly in the Snort log payload" width="700">

The Base64-encoded string from the payload can be decoded in CyberChef using **From Base64**.

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

**Port placement matters in bidirectional rules.** Writing `any 21 <> any 21` seems intuitive for FTP traffic, but it only matches packets where both endpoints use port 21 — which never happens. The monitored port goes on the right side only: `any any <> any 21`. I only figured this out after the rule produced zero alerts.

**File extensions are unreliable as detection signatures.** My first instinct in Task 4 was to search for `.png` and `.gif` in the traffic — that returned nothing. Magic bytes are more reliable: the first bytes of a file identify its format regardless of what the file is named.

**Snort output doesn't pipe the way I expected.** BPF filters work at the packet level, not on alert strings. Running with `-A full -l .` and then working with the generated files was the approach that actually worked.

**Double backslash for a literal backslash in content strings.** A single `\` in a Snort content string throws a `bad escape sequence` error. `\\IPC$` is the correct syntax.

**Read more of the payload before guessing.** In Task 8, the visible part of the early packets was full of `%` characters, so I assumed percent-encoding was the answer. The actual encoding — Base64 — only appeared further down in the payload and was written out explicitly. 

---

## References

- [Snort Room (TryHackMe)](https://tryhackme.com/room/snort) — Basics, rule structure, operating modes
- [NVD — CVE-2017-0144 (EternalBlue)](https://nvd.nist.gov/vuln/detail/CVE-2017-0144)
- [NVD — CVE-2021-44228 (Log4Shell)](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [TryHackMe Room](https://tryhackme.com/room/snortchallenges1)
