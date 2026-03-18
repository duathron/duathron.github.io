---
title: TryHackMe — Invite Only
date: 2026-03-31 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - invite-only
  - easy
published: true
image:
  path: /assets/img/posts/invite-only/cover.png
  alt: Invite Only
related_notes:
  - "[[OSINT]]"
  - "[[Threat Intelligence]]"
  - "[[AsyncRAT]]"
  - "[[Malware Analysis]]"
---

## Overview

You are an SOC analyst at Managed Server Provider TrySecureMe. An L1 analyst has flagged two suspicious indicators — an IP address and a SHA256 hash — and escalated them for deeper analysis. The task: investigate these indicators using the in-house threat intelligence tool TryDetectThis2.0, trace the attack chain, and extract actionable threat intelligence.

This room is pure analysis — no exploitation, no shells. It simulates the kind of IOC investigation SOC analysts perform daily, combining file analysis with OSINT research to map out a malware campaign.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Invite Only |
| Difficulty | Easy |
| Tags | virustotal, osint, threat-intelligence, malware-analysis, asyncrat |

---

## Theory

### Indicators of Compromise (IOCs)

IOCs are forensic artefacts that indicate a potential security breach — file hashes, IP addresses, domain names, URLs, or behavioural patterns. In a SOC workflow, L1 analysts flag suspicious indicators during monitoring, and higher-tier analysts investigate them further. This room simulates exactly that handoff.

### VirusTotal

VirusTotal aggregates results from dozens of antivirus engines. Beyond simple detection, it provides context that turned out to be essential here: file relations (which files spawned which), community comments from researchers, and detection labels. I'd used VirusTotal before for basic hash lookups (like in the [[2026-02-27-mrphisher]] room), but this was the first time I actively navigated its Relations and Community tabs to trace an attack chain.

### AsyncRAT

AsyncRAT is a Remote Access Trojan — open-source, commonly delivered through multi-stage infection chains, frequently used alongside other tools for data theft. The room doesn't require deep knowledge of AsyncRAT, but understanding what it is helps make sense of the attack chain.

---

## Reconnaissance

### The Flagged Indicators

- **Flagged SHA256 Hash:** `5d0509f68a9b7c415a726be75a078180e3f02e59866f193b0a99eee8e39c874f`
- **Flagged IP:** `101.99.76.120`

The VM includes **TryDetectThis2.0** — an offline VirusTotal catalogue.

### Hash Analysis — File Identification

Searching the flagged hash in TryDetectThis2.0 immediately returns the file name and type.

### Mapping the Attack Chain — Relations

The Relations tab reveals how the flagged file fits into a larger attack chain:

**Execution Parents** — the files that spawned the flagged hash. These are the upstream components that delivered the malware.

<img src="/assets/img/posts/invite-only/relations.png" alt="VirusTotal Relations tab showing Execution Parents, Bundled Files, and Dropped Files" width="700">

**Dropped Files** — files the flagged executable created on disk. Following the second execution parent's hash into its own Relations tab reveals additional downstream payloads.

---

## Enumeration

### Identifying the Malware Family

The offline catalogue doesn't explicitly label the malware family. Searching the flagged IP on live VirusTotal and navigating to the **Community** tab reveals researcher comments — including a `malpedia` reference identifying the family as **AsyncRAT**.

<img src="/assets/img/posts/invite-only/community-comments.png" alt="VirusTotal Community Comments showing AsyncRAT malpedia label" width="700">

### Finding the Original Report

The same community comment references the original report: **"From Trust to Threat: Hijacked Discord Invites Used for Multi-Stage Malware Delivery"** by Check Point Research. The title and URL are right there — no need to Google.

### Security Vendors — Detection Labels

<img src="/assets/img/posts/invite-only/security-vendors.png" alt="VirusTotal Security Vendors showing asyncrat detection labels" width="700">

---

## Data Extraction & Recovery

### Answering from the Report

The remaining questions are answered by reading the [Check Point Research report](https://research.checkpoint.com/2025/from-trust-to-threat-hijacked-discord-invites-used-for-multi-stage-malware-delivery/).

The campaign exploits a flaw in Discord's invitation system: attackers hijack expired or deleted Discord invite links by registering them as custom vanity URLs on boosted servers. Users following previously trusted links end up on malicious Discord servers.

From there: **ClickFix** phishing lures users into executing malicious code, multi-stage loaders deliver AsyncRAT and a Skuld Stealer targeting crypto wallets, and **ChromeKatz** bypasses Chrome's App Bound Encryption to steal browser cookies.

### Tools Used

- **TryDetectThis2.0** — hash lookup, file relations, detection results
- **VirusTotal (live)** — malware family identification via community comments
- **Check Point Research report** — campaign details, TTPs, tool identification

---

## Lessons Learned

**Pivot, pivot, pivot.** The investigation starts with a hash and an IP, but the answers come from following the connections: hash → execution parents → dropped files → IP → community comments → external report. No single source gives the full picture.

**Community comments are underrated.** The VirusTotal Community tab provided both the malware family identification and the report title — information not available through automated detection labels alone.

**Read the report, not just the summary.** The Check Point report answers multiple questions, but more importantly it tells the story of the full attack chain.

**Trusted platforms can become attack vectors.** Expired Discord invite links can be silently hijacked — a design flaw with real consequences, especially for younger users in gaming communities.

---

## References

- [Check Point Research — From Trust to Threat](https://research.checkpoint.com/2025/from-trust-to-threat-hijacked-discord-invites-used-for-multi-stage-malware-delivery/)
- [Malpedia — AsyncRAT](https://malpedia.caad.fkie.fraunhofer.de/details/win.asyncrat)
- [VirusTotal](https://www.virustotal.com/)
- [TryHackMe Room](https://tryhackme.com/room/invite-only)
