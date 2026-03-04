---
title: "TryHackMe — Snort Challenge - Live Attacks"
date: 2026-03-26 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - snort-challenges-2
  - medium
published: true
image:
  path: /assets/img/posts/snort-challenges-2/cover.png
  alt: "Snort Challenge - Live Attacks"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Snort Challenge - Live Attacks |
| Difficulty | Medium |
| Tags | snort, ips, live-traffic, ssh, reverse-shell, rule-writing |

Where the previous Snort rooms used PCAP files, this one is different: the traffic is live. The task is to write a Snort rule, run it in IPS mode against traffic that's actively hitting the machine, and get Snort to drop the right packets. When it works, a `flag.txt` appears on the desktop.

This is the first time I've used Snort against live traffic instead of a saved capture.

---

## Task 2 — Brute Force / SSH

### Analysing the Traffic

Before writing any rule, the first step was to figure out what's actually happening on the network. Running Snort in sniffer mode to get a quick look:

```bash
sudo snort -X -n 100 -A console
```

Looking through the output, one IP address kept showing up repeatedly: `10.10.245.36`. The connections were all going to `10.10.140.29:22` — port 22 is SSH. The source ports on the attacker side were ephemeral (high, changing ports), which is what a client looks like when it's making lots of outgoing connections. The payload in the packets confirmed it:

<img src="/assets/img/posts/snort-challenges-2/task2-ssh-traffic.png" alt="Snort hex output showing SSH-2.0-OpenSSH in the packet payload, traffic from 10.10.140.29:22 to 10.10.245.36" width="700">

The string `SSH-2.0-OpenSSH_8.2p1 Ubuntu` is visible directly in the payload. The pattern — one IP repeatedly hitting port 22 from many different ephemeral ports — looked like a brute force attempt.

### Writing the Rule

The goal: drop all traffic from the identified attacker IP. Using `drop` instead of `alert` because this is IPS mode — the packets should actually be blocked, not just logged.

```
drop tcp 10.10.245.36 any -> any any (msg:"Attacker IP dropped."; sid:1000001; rev:1;)
```

<img src="/assets/img/posts/snort-challenges-2/task2-rule.png" alt="local.rules showing the drop rule for 10.10.245.36" width="700">

### Running in IPS Mode

```bash
sudo snort -c ./local.rules -v -n 15000 -X -A full
```

The `-n 15000` limit was intentional — on a first attempt without any packet limit, the VM locked up completely. Snort was running in IPS mode against live traffic with no way to interrupt it. Setting a packet limit meant Snort would stop on its own after processing enough traffic to trigger the flag.

To check what Snort had actually captured, the generated log file was read back with:

```bash
sudo snort -r snort.log.xxxxxxxx -X -n 20
```

This showed the first packets from the log in hex dump format — confirming that the rule was matching the SSH traffic from the attacker IP. After running long enough, `flag.txt` appeared on the desktop as described in the room:

<img src="/assets/img/posts/snort-challenges-2/task2-flag.png" alt="flag.txt appearing on the desktop, opened showing the flag value" width="700">

> **Flag:** THM{[redacted]}

The remaining questions followed from the traffic analysis: the protocol is TCP, the port is 22, and that maps to SSH.

### A Wrong Turn First

Before landing on `10.10.245.36`, I had first blocked a different IP that was sending a lot of short requests over port 80. That also made a flag appear on the desktop — which confused me, because I couldn't answer the follow-up questions about the protocol and port correctly. After a full VM restart and a closer look at the traffic, the SSH pattern became much more obvious. It's possible the room just checks whether a working Snort rule is running, rather than validating which specific IP was blocked. Either way, the SSH traffic was clearly the intended target.

I also didn't use the IPS mode command from the Snort walkthrough room:

```bash
sudo snort -c local.rules -Q --daq afpacket -i eth0:eth1 -A full
```

That's the proper inline IPS setup with the `afpacket` DAQ module. My command worked anyway, but I'll need to revisit the difference between these two approaches at some point.

---

## Task 3 — Reverse Shell

### Analysing the Traffic

Same starting point: run Snort without a rule to see what's going on.

```bash
sudo snort -X -n 100 -A console
```

One thing stood out immediately: traffic going to port `4444`. Port 4444 is the default port for Metasploit's Meterpreter — a reverse shell tool. The source IP was `10.10.196.55`, and the payload showed terminal output: a shell prompt from the compromised machine was visible in the hex dump.

<img src="/assets/img/posts/snort-challenges-2/task3-shell-traffic.png" alt="Snort hex output showing traffic from 10.10.196.55:54332 to 10.10.144.156:4444 with shell prompt visible in payload" width="700">

The payload contains `ubuntu@ip-10-10-196-55:~$` — a bash prompt, sent over the network. That's what a reverse shell session looks like in the raw traffic.

### Writing the Rule

Using `drop` to actually block the connection, not just log it:

```
drop tcp any any -> any 4444 (msg:"Blocked outbound port 4444."; sid:1000001; rev:1;)
```

### Running Against Live Traffic

```bash
sudo snort -c ./local.rules -X -n 2000 -A full -K ASCII -l .
```

The `-K ASCII` flag tells Snort to write logs in plaintext instead of binary format. That made it possible to read through the log file directly without having to run `snort -r` to decode it first — useful for quickly checking what was actually captured. I'm not yet fully comfortable filtering Snort logs with BPF filters, so having readable plaintext was the more practical approach here. With better BPF filter skills, that route might be just as fast or faster.

<img src="/assets/img/posts/snort-challenges-2/task3-stats.png" alt="Snort Action Stats showing 122 alerts out of 2000 packets processed" width="700">

122 alerts out of 2000 packets. After running long enough, `flag.txt` appeared on the desktop:

<img src="/assets/img/posts/snort-challenges-2/task3-flag.png" alt="flag.txt on desktop showing flag value" width="700">

> **Flag:** THM{[redacted]}

The follow-up questions: protocol is TCP, port is 4444, and the tool commonly associated with that port is Metasploit.

---

## Tools Used

| Tool | Purpose |
|------|---------|
| Snort | Traffic analysis, IPS mode — live packet inspection and blocking |

---

## Lessons Learned

**Look at the traffic before writing rules.** Running Snort in sniffer mode first made the suspicious IPs obvious within seconds. Writing a rule without knowing what you're looking for would have meant guessing.

**Set a packet limit when running IPS mode on live traffic.** Without `-n`, Snort runs until manually interrupted. In a VM that's also the analysis environment, that can lock everything up. `-n 15000` gave Snort enough traffic to do its job and then stop cleanly.

**Port 4444 in the payload means something specific.** Seeing a port number in traffic is one thing, but seeing a bash prompt inside the packets going to that port makes it immediately clear what's happening — the machine is sending a remote attacker interactive shell access.

**Plaintext logs are easier to read, but not the only option.** Using `-K ASCII` wrote the logs in readable format, which made it quick to verify what Snort had captured without needing to run `snort -r`. The alternative — binary logs read back with `snort -r` and BPF filters — is probably just as effective once you are comfortable with the filter syntax. Something to get better at.

**Wrong answers can still trigger the flag.** Blocking the wrong IP still made the flag appear, which was confusing. It meant I had to restart and re-examine the traffic more carefully to get the actual answers right. The flag appearing isn't necessarily confirmation that the right threat was identified.

---

## References

- [Snort Room (TryHackMe)](https://tryhackme.com/room/snort) — Basics, rule structure, operating modes
- [Snort Challenge - The Basics (TryHackMe)](https://tryhackme.com/room/snortchallenges1) — Previous room in the series
- [TryHackMe Room](https://tryhackme.com/room/snortchallenges2)
