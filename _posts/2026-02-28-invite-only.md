---
title: "TryHackMe — Invite Only"
date: 2026-02-28 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - invite-only
  - easy
published: true
image:
  path: /assets/img/posts/invite-only/cover.png
  alt: "Invite Only"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Invite Only |
| Difficulty | Easy |
| Tags | virustotal, osint, threat-intelligence, malware-analysis, asyncrat |

You are an SOC analyst at Managed Server Provider TrySecureMe. An L1 analyst has flagged two suspicious indicators — an IP address and a SHA256 hash — and escalated them for deeper analysis. The task: investigate these indicators using the in-house threat intelligence tool TryDetectThis2.0, trace the attack chain, and extract actionable threat intelligence.

This room is pure analysis — no exploitation, no shells. It simulates the kind of IOC investigation SOC analysts perform daily, combining file analysis with OSINT research to map out a malware campaign.

---

## Theory

### Indicators of Compromise (IOCs)

IOCs are forensic artefacts that indicate a potential security breach — file hashes, IP addresses, domain names, URLs, or behavioural patterns. In a SOC workflow, L1 analysts flag suspicious indicators during monitoring, and higher-tier analysts investigate them further. This room simulates exactly that handoff — you receive two flagged indicators and work from there.

### VirusTotal

VirusTotal is a web-based platform that aggregates results from dozens of antivirus engines. Beyond simple detection, it provides context that turned out to be essential for this room: file relations (which files spawned which), community comments from researchers, and detection labels. I'd used VirusTotal before for basic hash lookups (like in the [MrPhisher](https://tryhackme.com/room/mrphisher) room), but this was the first time I actively navigated its Relations and Community tabs to trace an attack chain.

### AsyncRAT

AsyncRAT is a Remote Access Trojan — a type of malware that gives attackers remote control over compromised systems. I hadn't encountered it before this room. What I learned: it's open-source, commonly delivered through multi-stage infection chains, and frequently used alongside other tools for data theft. The room doesn't require deep knowledge of AsyncRAT, but understanding what it is helps make sense of the attack chain.

---

## Reconnaissance

### The Flagged Indicators

The room provides two starting points:

- **Flagged SHA256 Hash:** `5d0509f68a9b7c415a726be75a078180e3f02e59866f193b0a99eee8e39c874f`
- **Flagged IP:** `101.99.76.120`

The VM includes a desktop shortcut called **TryDetectThis2.0** — an offline VirusTotal catalogue. This is the primary analysis tool for the room.

### Hash Analysis — File Identification

Searching the flagged hash in TryDetectThis2.0 immediately returns the file name and type. The Details tab provides basic properties including the file type classification.

### Mapping the Attack Chain — Relations

The Relations tab is where the investigation gets interesting. It reveals how the flagged file fits into a larger attack chain:

**Execution Parents** — the files that spawned or executed the flagged hash. These are the upstream components in the infection chain: the files that delivered the malware onto the system.

<img src="/assets/img/posts/invite-only/relations.png" alt="VirusTotal Relations tab showing Execution Parents, Bundled Files, and Dropped Files" width="700">

**Dropped Files** — files that the flagged executable created on disk during execution. Following the second execution parent's hash into its own Relations tab reveals additional dropped files — the downstream payloads deployed after initial execution.

---

## Enumeration

### Identifying the Malware Family

The offline catalogue provides detection results but doesn't explicitly label the malware family. This is where live VirusTotal becomes necessary. Searching the flagged IP on the live site and navigating to the **Community** tab reveals comments from security researchers with detailed IOC breakdowns — including a `malpedia` reference identifying the malware family as **AsyncRAT**. I didn't know what Malpedia was at the time, but a quick search confirmed it's a curated database of malware families. The community comment had the answer right there.

<img src="/assets/img/posts/invite-only/community-comments.png" alt="VirusTotal Community Comments showing IOC context with AsyncRAT malpedia label and report reference" width="700">

### Finding the Original Report

The same community comment on the flagged IP's VirusTotal page references the original report by title: **"From Trust to Threat: Hijacked Discord Invites Used for Multi-Stage Malware Delivery"**. The report was published by Check Point Research and documents the full campaign.

The room suggests using Google to find the report, but the community comment provides a more direct path — the title is right there, along with the reference URL.

### Security Vendors — Detection Labels

The live VirusTotal page also shows the security vendor analysis, with detection labels and family classifications confirming the AsyncRAT attribution across multiple engines.

<img src="/assets/img/posts/invite-only/security-vendors.png" alt="VirusTotal Security Vendors analysis showing detection labels including asyncrat and alien family labels" width="700">

---

## Data Extraction & Recovery

### Answering from the Report

The remaining questions — which tool was used to steal Chrome cookies, which phishing technique was employed, and which platform was hijacked for redirection — are all answered by reading the [Check Point Research report](https://research.checkpoint.com/2025/from-trust-to-threat-hijacked-discord-invites-used-for-multi-stage-malware-delivery/).

The report details a multi-stage campaign that exploits a flaw in Discord's invitation system. Attackers hijack expired or deleted Discord invite links by registering them as custom vanity URLs on their own boosted servers. Users following previously trusted links — posted on forums, social media, or official community websites — unknowingly end up on malicious Discord servers.

From there, the attack chain uses the **ClickFix** phishing technique to lure users into executing malicious code, deploys multi-stage loaders that deliver AsyncRAT and a customised Skuld Stealer targeting crypto wallets, and uses **ChromeKatz** to bypass Chrome's App Bound Encryption and steal browser cookies.

What makes this campaign particularly noteworthy: Discord is a platform heavily used by gaming communities, many of whose members are young — including minors. The attack specifically exploits the trust that gaming communities place in shared invite links. An expired link on a Minecraft forum or a game's official Discord page becomes a silent trap once attackers claim the invite code.

### Tools Used

- **TryDetectThis2.0** (offline VirusTotal) — hash lookup, file relations, detection results
- **VirusTotal (live)** — malware family identification via community comments and detection labels
- **Check Point Research report** — campaign details, TTPs, tool identification

---

## Lessons Learned

**Pivot, pivot, pivot.** The investigation starts with a hash and an IP, but the answers come from following the connections: hash → execution parents → dropped files → IP → community comments → external report. Each indicator leads to the next. No single source gives the full picture — and learning to follow these threads is presumably a core part of what SOC work looks like in practice.

**Community comments are underrated.** The VirusTotal Community tab is easy to overlook, but security researchers regularly post structured IOC analysis there. In this case, it provided both the malware family identification and the report title — information that wasn't available through automated detection labels alone.

**Read the report, not just the summary.** The Check Point report answers multiple questions, but more importantly, it tells the story of the full attack chain. Understanding *how* the campaign works — from hijacked Discord invites through ClickFix phishing to cookie theft — is more valuable than any individual answer.

**Trusted platforms can become attack vectors.** Discord invite links are shared freely and assumed to be safe. The fact that expired links can be silently hijacked and redirected to malicious servers is a design flaw with real consequences — especially for younger users in gaming communities who may not question a link from a familiar source.

---

## References

- [Check Point Research — From Trust to Threat: Hijacked Discord Invites Used for Multi-Stage Malware Delivery](https://research.checkpoint.com/2025/from-trust-to-threat-hijacked-discord-invites-used-for-multi-stage-malware-delivery/)
- [Malpedia — AsyncRAT](https://malpedia.caad.fkie.fraunhofer.de/details/win.asyncrat)
- [VirusTotal](https://www.virustotal.com/)
- [TryHackMe Room](https://tryhackme.com/room/invite-only)
