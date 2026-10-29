---
title: "Handbook for the Recently Compromised"
date: 2026-10-30 09:00:00 +0100
categories: [Writeups, TryHackMe]
tags: [windows-forensics, sysmon, powershell, living-off-the-land, cyberchef]
image:
  path: /assets/img/posts/handbook-for-the-recently-compromised/cover.png
---

## Introduction

This room drops you straight into a Sysmon log, already converted to XML, from a Windows host that's been compromised. There's no email, no pcap, just one event log and a trail of process-create events to follow from a disguised download, back to the process that kicked the whole thing off, and forward to the persistence mechanism the attacker left behind.

## Theory

- **Sysmon event chains.** Every process-create event records its own `ProcessId` alongside the `ParentProcessId` and `ParentImage` of whatever launched it. Grep for one value, find the matching event, read off its parent, grep for that: it's a chain you can walk by hand.
- **Command-line globbing as evasion.** Windows lets you reference a binary via a wildcard path expression instead of its literal name, so a command can invoke `certutil.exe` without the string `certutil` ever appearing directly in the command line that gets logged.
- **PowerShell Script Block Logging.** When enabled, this captures the actual code PowerShell executes, after any string concatenation or obfuscation has already been resolved. An attacker building a command out of dozens of joined string fragments still ends up logged in its plain, assembled form.

## Walkthrough

### Finding the download, certutil wildcarded

Starting broad, I grepped the converted log for anything mentioning `cert` or `wev`:

```bash
cat sysmon.xml | grep -niE '(cert|wev)'
```

Most of it is `wevtutil.exe` clearing event logs, which is for cleanup after the fact, not the way in. But one line stands out: a PowerShell command line that resolves `certutil.exe` indirectly, via `(gci C:\Windows\System32\certu*.exe)[0].FullName`, instead of calling it by name directly:

<img src="/assets/img/posts/handbook-for-the-recently-compromised/handbook-for-the-recently-compromised_01.png" width="700" alt="Grep across sysmon.xml for cert and wev, showing wevtutil log-clearing events and a PowerShell command resolving certutil via a wildcard path">

Pulling the full event for that PowerShell process shows the whole command: it resolves `certutil.exe` via the wildcard, uses it to download `pipeline-sync.ps1` from `http://pipeline-cdn.thm:8088/`, then immediately runs the downloaded script with `-ep bypass`. The event also gives up the user context (`THM-JCOLLINS\j.collins`) and a `ParentProcessId` of `6052`:

<img src="/assets/img/posts/handbook-for-the-recently-compromised/handbook-for-the-recently-compromised_02.png" width="700" alt="Full Sysmon event for the PowerShell process, showing the certutil wildcard download command, user j.collins, and ParentProcessId 6052">

### Tracing back to the initial execution

That `ParentProcessId` of `6052` is the next thread to pull. Grepping for the event where that's the process's own ID turns up `mshta.exe` launching a local file:

```bash
cat sysmon.xml | grep -niE '"ProcessId">6052<' -A15
```

<img src="/assets/img/posts/handbook-for-the-recently-compromised/handbook-for-the-recently-compromised_03.png" width="700" alt="Sysmon event for ProcessId 6052, showing mshta.exe executing pipeline-check.hta from the user's Downloads folder">

`mshta.exe "C:\Users\j.collins\Downloads\pipeline-check.hta"` is the actual start of the chain: an HTA file, opened directly, that runs PowerShell, which wildcard-resolves `certutil`, which downloads and executes `pipeline-sync.ps1`.

### Persistence: the scheduled task

With the download-and-execute stage mapped out, I went looking for what the downloaded script actually did once it ran. Grepping for `sched` finds a `schtasks.exe` call:

```bash
cat sysmon.xml | grep -niE 'sched' -A20
```

```
"C:\Windows\system32\schtasks.exe" /create /tn StudioPipelineSync /tr "powershell -nop -w hidden -f C:\Users\j.collins\AppData\Roaming\PipelineSync\pipeline-sync.ps1" /sc onlogon /rl highest /f
```

<img src="/assets/img/posts/handbook-for-the-recently-compromised/handbook-for-the-recently-compromised_04.png" width="700" alt="Sysmon event showing schtasks.exe creating a scheduled task named StudioPipelineSync that reruns pipeline-sync.ps1 on every logon">

The `ParentImage` on this event is `powershell.exe`, and its `ParentCommandLine` is `-ep bypass -f ...\pipeline-sync.ps1`, the exact script that got downloaded in the first stage. So the downloaded script's own job is to set up persistence: a scheduled task that reruns it on every logon, running with the highest available privilege level.

### Reading the script block: the flag as a base64 blob

PowerShell's Script Block Logging captured `pipeline-sync.ps1` in full, past whatever string-concatenation obfuscation it used to build its own commands. Past the beacon request and the same `schtasks` call seen above, two lines stood out:

```powershell
$blob = ('VEhNe3R'+'IM19Ha'+'D'+'BzdF93MX'+'RIX1Ro'+'M19'+'NMDVUfQ='+'=')
$flag = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($blob))
```

<img src="/assets/img/posts/handbook-for-the-recently-compromised/handbook-for-the-recently-compromised_05.png" width="700" alt="PowerShell Script Block Text log showing the deobfuscated pipeline-sync.ps1 content, including a base64-encoded blob assigned to a flag variable">

The script writes that decoded value out to a cache file under `%TEMP%\PipelineSync\`. Feeding the same base64 string into CyberChef's From Base64 gives the flag directly. No decryption needed this time, just string concatenation hiding a plain base64 blob in plain sight.

## Lessons Learned

- A wildcard glob in a command line (`certu*.exe`) is easy to miss if you're grepping for the literal binary name. I started broad with PowerShell itself and only noticed the wildcard once I was already reading the full command.
- Script Block Logging turning obfuscated, string-concatenated PowerShell back into its final, readable form was the part that actually made this solvable. Without it, the flag would've stayed buried in dozens of joined string fragments.
- Walking this log by `ProcessId`/`ParentProcessId`, one grep at a time, was slow, but it was the only way I had to put the chain back together with just one event log to go on.

## References

- [TryHackMe Room — Handbook for the Recently Compromised](https://tryhackme.com/room/handbookfortherecentlycompromised)
- [CyberChef](https://gchq.github.io/CyberChef/)
